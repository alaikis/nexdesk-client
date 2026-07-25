import Flutter
import UIKit
import ReplayKit

@main
@objc class AppDelegate: FlutterAppDelegate {
    private var screenCaptureManager: ScreenCaptureManager?

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Setup screen capture method channel
        if let controller = window?.rootViewController as? FlutterViewController {
            let channel = FlutterMethodChannel(name: "nex.flutter/screen_capture", binaryMessenger: controller.binaryMessenger)
            screenCaptureManager = ScreenCaptureManager.shared
            screenCaptureManager?.setup(channel: channel)

            channel.setMethodCallHandler { [weak self] call, result in
                guard let self = self else { return }
                switch call.method {
                case "requestPermission":
                    self.screenCaptureManager?.requestPermission(result: result)
                case "getScreenSize":
                    self.screenCaptureManager?.getScreenSize(result: result)
                case "startCapture":
                    let args = call.arguments as? [String: Any] ?? [:]
                    let width = args["width"] as? Int ?? 1280
                    let height = args["height"] as? Int ?? 720
                    self.screenCaptureManager?.startCapture(width: width, height: height, result: result)
                case "stopCapture":
                    self.screenCaptureManager?.stopCapture(result: result)
                default:
                    result(FlutterMethodNotImplemented)
                }
            }

            // Input injection channel
            let inputChannel = FlutterMethodChannel(name: "nex.flutter/input_injector", binaryMessenger: controller.binaryMessenger)
            inputChannel.setMethodCallHandler { call, result in
                // iOS doesn't allow programmatic input injection for security
                result(FlutterError(code: "UNSUPPORTED", message: "Input injection not supported on iOS", details: nil))
            }
        }

        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}
