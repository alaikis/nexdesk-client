package com.elstella.flutter_app

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.GestureDescription
import android.graphics.Path
import android.os.Bundle
import android.util.Log
import android.view.KeyEvent
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo

class NexInputAccessibilityService : AccessibilityService() {
    companion object {
        private const val TAG = "NexInputService"
        var instance: NexInputAccessibilityService? = null
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        instance = this
        Log.i(TAG, "Accessibility service connected")
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent) {
        // No-op: we use this service purely for input injection
    }

    override fun onInterrupt() {
        // No-op
    }

    override fun onKeyEvent(event: KeyEvent): Boolean {
        return false
    }

    override fun onGesture(gestureDescription: GestureDescription): Boolean {
        return false
    }

    fun injectMouseEvent(x: Int, y: Int, button: Int, action: Int): Boolean {
        val path = Path()
        path.moveTo(x.toFloat(), y.toFloat())
        val gesture = GestureDescription.Builder()
            .addPath(path)
            .setStrokeId(System.currentTimeMillis())
            .setDuration(1)
            .build()
        return dispatchGesture(gesture, null, null)
    }

    override fun onDestroy() {
        instance = null
        super.onDestroy()
    }
}
