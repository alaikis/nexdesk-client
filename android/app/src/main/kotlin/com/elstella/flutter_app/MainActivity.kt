package com.elstella.flutter_app

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.os.Build
import android.provider.Settings
import android.util.Log
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

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
