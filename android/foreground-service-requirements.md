# Android Foreground Service Requirements

Screen capture on Android requires a foreground service with a persistent notification when using `MediaProjection`. Flutter's `flutter_webrtc` plugin manages the `MediaProjection` token internally, but the host app must provide the foreground service infrastructure.

## Required Changes

### 1. Kotlin Service Class

Create `android/app/src/main/kotlin/com/elstella/flutter_app/ScreenCaptureService.kt`:

```kotlin
package com.elstella.flutter_app

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Intent
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat

class ScreenCaptureService : Service() {
    companion object {
        const val CHANNEL_ID = "nex_screen_capture"
        const val NOTIF_ID = 1
    }

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Screen Capture",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Shows while screen is being shared"
                setShowBadge(false)
            }
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }

    private fun buildNotification(): Notification {
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("NEX Screen Share Active")
            .setContentText("Your screen is being shared remotely")
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setOngoing(true)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .build()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        startForeground(NOTIF_ID, buildNotification())
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null
}
```

### 2. Update `AndroidManifest.xml`

Restore the `<service>` declaration inside `<application>`:

```xml
<service
    android:name="com.elstella.flutter_app.ScreenCaptureService"
    android:foregroundServiceType="mediaProjection"
    android:exported="false" />
```

### 3. Request `MediaProjection` Permission at Runtime

From the Flutter side, invoke a platform channel to request `MediaProjection` before starting a session:

```dart
static const MethodChannel _channel = MethodChannel('nex.flutter/screen_capture');
Future<bool> requestScreenCapturePermission() async {
  try {
    return await _channel.invokeMethod('requestPermission') ?? false;
  } on PlatformException catch (_) {
    return false;
  }
}
```

### 4. Start/Stop Service from Flutter

```dart
Future<void> startService() async {
  await _channel.invokeMethod('startService');
}
Future<void> stopService() async {
  await _channel.invokeMethod('stopService');
}
```

## Notes

- The foreground service is only needed on Android 14+ (API 34) when using `MediaProjection`.
- On older Android versions, `MediaProjection` can run without a foreground service, but adding one is still recommended for user transparency.
