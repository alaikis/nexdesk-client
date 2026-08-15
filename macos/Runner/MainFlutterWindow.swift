import Cocoa
import FlutterMacOS
import ScreenCaptureKit

class MainFlutterWindow: NSWindow {
    override func awakeFromNib() {
        let flutterViewController = FlutterViewController()
        let windowFrame = self.frame
        self.contentViewController = flutterViewController
        self.setFrame(windowFrame, display: true)

        RegisterGeneratedPlugins(registry: flutterViewController)

        // Setup screen capture method channel
        let channel = FlutterMethodChannel(name: "nex.flutter/screen_capture", binaryMessenger: flutterViewController.engine.binaryMessenger)
        let captureManager = ScreenCaptureManager.shared
        captureManager.setup(channel: channel)

        channel.setMethodCallHandler { call, result in
            switch call.method {
            case "requestPermission":
                captureManager.requestPermission(result: result)
            case "getScreenSize":
                captureManager.getScreenSize(result: result)
            case "enumerateWindows":
                captureManager.enumerateWindows(result: result)
            case "startCapture":
                let args = call.arguments as? [String: Any] ?? [:]
                let width = args["width"] as? Int ?? 1280
                let height = args["height"] as? Int ?? 720
                captureManager.startCapture(width: width, height: height, result: result)
            case "startWindowCapture":
                let args = call.arguments as? [String: Any] ?? [:]
                let windowId = args["windowId"] as? String ?? ""
                let x = args["x"] as? Int ?? 0
                let y = args["y"] as? Int ?? 0
                let width = args["width"] as? Int ?? 1280
                let height = args["height"] as? Int ?? 720
                captureManager.startWindowCapture(windowId: windowId, x: x, y: y, width: width, height: height, result: result)
            case "stopCapture":
                captureManager.stopCapture(result: result)
            default:
                result(FlutterMethodNotImplemented)
            }
        }

        // Input injection channel
        let inputChannel = FlutterMethodChannel(name: "nex.flutter/input_injector", binaryMessenger: flutterViewController.engine.binaryMessenger)
        inputChannel.setMethodCallHandler { call, result in
            switch call.method {
            case "injectMouseEvent":
                let args = call.arguments as? [String: Any] ?? [:]
                let x = args["x"] as? Double ?? 0
                let y = args["y"] as? Double ?? 0
                let button = args["button"] as? Int ?? 0
                let action = args["action"] as? Int ?? 0
                self.injectMouseEvent(x: x, y: y, button: button, action: action)
                result(true)
            case "injectKey":
                let args = call.arguments as? [String: Any] ?? [:]
                let keyCode = args["keyCode"] as? Int ?? 0
                let down = args["down"] as? Bool ?? true
                self.injectKey(keyCode: keyCode, down: down)
                result(true)
            default:
                result(FlutterMethodNotImplemented)
            }
        }

        super.awakeFromNib()
    }

    private func injectMouseEvent(x: Double, y: Double, button: Int, action: Int) {
        guard let event = CGEvent(mouseEventSource: nil, mouseType: action == 1 ? .leftMouseDown : .leftMouseUp, mouseCursorPosition: CGPoint(x: x, y: y), mouseButton: .left) else { return }
        event.post(tap: .cghidEventTap)
    }

    private func injectKey(keyCode: Int, down: Bool) {
        guard let event = CGEvent(keyboardEventSource: nil, virtualKey: CGKeyCode(keyCode), keyDown: down) else { return }
        event.post(tap: .cghidEventTap)
    }
}
