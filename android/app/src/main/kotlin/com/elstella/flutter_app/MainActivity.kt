package com.elstella.flutter_app

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import android.os.SystemClock
import android.provider.Settings
import android.util.Log
import android.view.KeyEvent
import android.view.MotionEvent
import android.view.inputmethod.InputMethodManager
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.view.InputDevice
import android.view.View
import android.graphics.Point
import android.view.Display
import android.app.Service
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import androidx.core.app.NotificationCompat

class MainActivity : FlutterActivity() {
    private val TAG = "MainActivity"
    private val CHANNEL = "nex.flutter/screen_capture"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "requestPermission" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                        val mediaProjectionManager = getSystemService(Context.MEDIA_PROJECTION_SERVICE) as android.media.projection.MediaProjectionManager
                        try {
                            val intent = mediaProjectionManager.createScreenCaptureIntent()
                            if (intent != null) {
                                startActivityForResult(intent, REQUEST_SCREEN_CAPTURE)
                                result.success(true)
                            } else {
                                result.success(false)
                            }
                        } catch (e: Exception) {
                            Log.e(TAG, "Failed to create screen capture intent", e)
                            result.success(false)
                        }
                    } else {
                        result.success(true)
                    }
                }
                "startService" -> {
                    val serviceIntent = Intent(this, ScreenCaptureService::class.java)
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        startForegroundService(serviceIntent)
                    } else {
                        startService(serviceIntent)
                    }
                    result.success(true)
                }
                "stopService" -> {
                    val serviceIntent = Intent(this, ScreenCaptureService::class.java)
                    stopService(serviceIntent)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "nex.flutter/input_injector").setMethodCallHandler { call, result ->
            when (call.method) {
                "injectMouseEvent" -> {
                    val xPercent = call.argument<Double>("x") ?: 0.0
                    val yPercent = call.argument<Double>("y") ?: 0.0
                    val button = call.argument<Int>("button") ?: 0
                    val action = call.argument<Int>("action") ?: 0
                    val display = windowManager.defaultDisplay
                    val size = Point()
                    display.getSize(size)
                    val x = (xPercent * size.x).toInt()
                    val y = (yPercent * size.y).toInt()
                    val eventTime = SystemClock.uptimeMillis()
                    val event = when (action) {
                        1 -> MotionEvent.obtain(eventTime, eventTime, MotionEvent.ACTION_DOWN, x.toFloat(), y.toFloat(), 0)
                        0 -> MotionEvent.obtain(eventTime, eventTime, MotionEvent.ACTION_UP, x.toFloat(), y.toFloat(), 0)
                        else -> MotionEvent.obtain(eventTime, eventTime, MotionEvent.ACTION_MOVE, x.toFloat(), y.toFloat(), 0)
                    }
                    event.source = InputDevice.SOURCE_TOUCHSCREEN
                    val imm = getSystemService(Context.INPUT_METHOD_SERVICE) as InputMethodManager
                    imm.dispatchTouchEvent(event)
                    event.recycle()
                    result.success(true)
                }
                "injectKeyEvent" -> {
                    val keyCode = call.argument<Int>("keyCode") ?: 0
                    val action = call.argument<Int>("action") ?: 1
                    val modifiers = call.argument<Int>("modifiers") ?: 0
                    val eventTime = SystemClock.uptimeMillis()
                    if (action == 1) {
                        val downEvent = KeyEvent(eventTime, eventTime, KeyEvent.ACTION_DOWN, keyCode, 0, modifiers)
                        Instrumentation().sendKeySync(downEvent)
                    } else {
                        val upEvent = KeyEvent(eventTime, eventTime, KeyEvent.ACTION_UP, keyCode, 0, modifiers)
                        Instrumentation().sendKeySync(upEvent)
                    }
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == REQUEST_SCREEN_CAPTURE) {
            if (resultCode != Activity.RESULT_OK) {
                Log.w(TAG, "Screen capture permission denied")
            }
        }
    }

    companion object {
        private const val REQUEST_SCREEN_CAPTURE = 1001
    }
}
