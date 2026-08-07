package com.elstella.flutter_app

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.PixelFormat
import android.hardware.display.DisplayManager
import android.hardware.display.VirtualDisplay
import android.media.Image
import android.media.ImageReader
import android.media.projection.MediaProjection
import android.media.projection.MediaProjectionManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Base64
import android.util.DisplayMetrics
import android.util.Log
import android.view.Surface
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.nio.ByteBuffer

class MainActivity : FlutterActivity() {
    private val TAG = "MainActivity"
    private val CHANNEL = "nex.flutter/screen_capture"
    private val REQUEST_SCREEN_CAPTURE = 1001

    private var mediaProjection: MediaProjection? = null
    private var virtualDisplay: VirtualDisplay? = null
    private var imageReader: ImageReader? = null
    private var screenWidth = 0
    private var screenHeight = 0
    private var screenDensity = 0
    private var resultPending: MethodChannel.Result? = null
    private var pendingStartArgs: Map<String, Int>? = null
    private val mainHandler = Handler(Looper.getMainLooper())
    private var channel: MethodChannel? = null
    private var isCapturing = false
    private var mediaProjectionResultCode = 0
    private var mediaProjectionData: Intent? = null

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)

        channel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "requestPermission" -> {
                    resultPending = result
                    pendingStartArgs = null
                    val mediaProjectionManager = getSystemService(Context.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
                    val intent = mediaProjectionManager.createScreenCaptureIntent()
                    startActivityForResult(intent, REQUEST_SCREEN_CAPTURE)
                }
                "startCapture" -> {
                    val width = call.argument<Int>("width") ?: 1280
                    val height = call.argument<Int>("height") ?: 720
                    val dpi = call.argument<Int>("dpi") ?: 160
                    if (mediaProjection != null && mediaProjectionData != null) {
                        startCapture(width, height, dpi)
                        result.success(true)
                    } else {
                        pendingStartArgs = mapOf("width" to width, "height" to height, "dpi" to dpi)
                        val mediaProjectionManager = getSystemService(Context.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
                        val intent = mediaProjectionManager.createScreenCaptureIntent()
                        startActivityForResult(intent, REQUEST_SCREEN_CAPTURE)
                    }
                }
                "stopCapture" -> {
                    stopCapture()
                    result.success(true)
                }
                "getScreenSize" -> {
                    val metrics = DisplayMetrics()
                    windowManager.defaultDisplay.getMetrics(metrics)
                    result.success(mapOf(
                        "width" to metrics.widthPixels,
                        "height" to metrics.heightPixels,
                        "dpi" to metrics.densityDpi
                    ))
                }
                else -> result.notImplemented()
            }
        }

        // Input injection channel via AccessibilityService
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "nex.flutter/input_injector").setMethodCallHandler { call, result ->
            when (call.method) {
                "injectMouseEvent" -> {
                    val x = call.argument<Double>("x") ?: 0.0
                    val y = call.argument<Double>("y") ?: 0.0
                    val button = call.argument<Int>("button") ?: 0
                    val action = call.argument<Int>("action") ?: 0
                    val display = windowManager.defaultDisplay
                    val size = android.graphics.Point()
                    display.getSize(size)
                    injectMouseEvent((x * size.x).toInt(), (y * size.y).toInt(), button, action)
                    result.success(true)
                }
                "injectKeyEvent" -> {
                    val keyCode = call.argument<Int>("keyCode") ?: 0
                    val action = call.argument<Int>("action") ?: 1
                    val modifiers = call.argument<Int>("modifiers") ?: 0
                    injectKeyEvent(keyCode, action, modifiers)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun startCapture(width: Int, height: Int, dpi: Int) {
        if (isCapturing) return
        if (mediaProjection == null) return

        val metrics = DisplayMetrics()
        windowManager.defaultDisplay.getMetrics(metrics)
        screenWidth = metrics.widthPixels
        screenHeight = metrics.heightPixels
        screenDensity = metrics.densityDpi

        imageReader = ImageReader.newInstance(screenWidth, screenHeight, PixelFormat.RGBA_8888, 2)
        imageReader?.setOnImageAvailableListener({ reader ->
            var image: Image? = null
            try {
                image = reader.acquireLatestImage()
                if (image != null && isCapturing) {
                    val planes = image.planes
                    val buffer = planes[0].buffer
                    val pixelStride = planes[0].pixelStride
                    val rowStride = planes[0].rowStride
                    val rowPadding = rowStride - pixelStride * screenWidth

                    val bitmap = Bitmap.createBitmap(
                        screenWidth + rowPadding / pixelStride,
                        screenHeight,
                        Bitmap.Config.ARGB_8888
                    )
                    bitmap.copyPixelsFromBuffer(buffer)

                    val scaledBitmap = Bitmap.createScaledBitmap(bitmap, width, height, true)
                    bitmap.recycle()

                    val stream = ByteArrayOutputStream()
                    scaledBitmap.compress(Bitmap.CompressFormat.JPEG, 80, stream)
                    val bytes = stream.toByteArray()
                    scaledBitmap.recycle()

                    val base64 = Base64.encodeToString(bytes, Base64.NO_WRAP)
                    mainHandler.post {
                        channel?.invokeMethod("onFrame", mapOf(
                            "data" to base64,
                            "width" to width,
                            "height" to height,
                            "timestamp" to System.currentTimeMillis()
                        ))
                    }
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error processing frame", e)
            } finally {
                image?.close()
            }
        }, mainHandler)

        val surface = imageReader?.surface
        if (surface != null && mediaProjection != null) {
            virtualDisplay = mediaProjection?.createVirtualDisplay(
                "nex_screen_capture",
                screenWidth,
                screenHeight,
                screenDensity,
                DisplayManager.VIRTUAL_DISPLAY_FLAG_AUTO_MIRROR,
                surface,
                null,
                mainHandler
            )
            isCapturing = true
        }
    }

    private fun stopCapture() {
        isCapturing = false
        virtualDisplay?.release()
        virtualDisplay = null
        imageReader?.close()
        imageReader = null
        mediaProjection?.stop()
        mediaProjection = null
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == REQUEST_SCREEN_CAPTURE) {
            if (resultCode == Activity.RESULT_OK && data != null) {
                mediaProjectionResultCode = resultCode
                mediaProjectionData = data
                val mediaProjectionManager = getSystemService(Context.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
                mediaProjection = mediaProjectionManager.getMediaProjection(resultCode, data)

                if (pendingStartArgs != null) {
                    val args = pendingStartArgs!!
                    pendingStartArgs = null
                    startCapture(args["width"]!!, args["height"]!!, args["dpi"]!!)
                    resultPending?.success(true)
                } else {
                    resultPending?.success(true)
                }
            } else {
                mediaProjection = null
                mediaProjectionData = null
                pendingStartArgs = null
                resultPending?.success(false)
            }
            resultPending = null
        }
    }

    private fun injectMouseEvent(x: Int, y: Int, button: Int, action: Int) {
        // Note: On Android Q+, this requires INJECT_EVENTS permission (system app)
        // or AccessibilityService for broader compatibility
        try {
            val eventTime = android.os.SystemClock.uptimeMillis()
            val motionEvent = android.view.MotionEvent.obtain(
                eventTime, eventTime,
                when (action) {
                    0 -> android.view.MotionEvent.ACTION_UP
                    1 -> android.view.MotionEvent.ACTION_DOWN
                    else -> android.view.MotionEvent.ACTION_MOVE
                },
                x.toFloat(), y.toFloat(), 0
            )
            motionEvent.source = android.view.InputDevice.SOURCE_TOUCHSCREEN
            // This requires INJECT_EVENTS permission
            // For production, use AccessibilityService instead
            window.injectMotionEvent(motionEvent)
            motionEvent.recycle()
        } catch (e: Exception) {
            Log.e(TAG, "Failed to inject mouse event", e)
        }
    }

    private fun injectKeyEvent(keyCode: Int, action: Int, modifiers: Int) {
        try {
            val eventTime = android.os.SystemClock.uptimeMillis()
            val keyEvent = android.view.KeyEvent(
                eventTime, eventTime,
                if (action == 1) android.view.KeyEvent.ACTION_DOWN else android.view.KeyEvent.ACTION_UP,
                keyCode, 0, modifiers
            )
            // This requires INJECT_EVENTS permission
            window.injectKeyEvent(keyEvent)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to inject key event", e)
        }
    }

    override fun onDestroy() {
        stopCapture()
        super.onDestroy()
    }
}
