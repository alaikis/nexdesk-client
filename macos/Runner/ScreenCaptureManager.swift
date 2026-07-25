import Cocoa
import FlutterMacOS
import ScreenCaptureKit
import AVFoundation

class ScreenCaptureManager: NSObject, SCStreamOutput, SCStreamDelegate {
    static let shared = ScreenCaptureManager()
    private var stream: SCStream?
    private var channel: FlutterMethodChannel?
    private var isCapturing = false

    func setup(channel: FlutterMethodChannel) {
        self.channel = channel
    }

    func requestPermission(result: @escaping FlutterResult) {
        // On macOS 12.3+, ScreenCaptureKit requires permission
        // The first call to startCapture will trigger the permission dialog
        result(true)
    }

    func getScreenSize(result: @escaping FlutterResult) {
        guard let display = NSScreen.main else {
            result(["width": 0, "height": 0, "scale": 1.0])
            return
        }
        result([
            "width": Int(display.frame.width),
            "height": Int(display.frame.height),
            "scale": display.backingScaleFactor
        ])
    }

    func startCapture(width: Int, height: Int, result: @escaping FlutterResult) {
        Task {
            do {
                // Get shareable content
                let content = try await SCShareableContent.current
                guard let display = content.displays.first else {
                    result(FlutterError(code: "NO_DISPLAY", message: "No display found", details: nil))
                    return
                }

                // Create filter for the display
                let filter = SCContentFilter(display: display, excludingWindows: [])

                // Configure stream
                let config = SCStreamConfiguration()
                config.width = width
                config.height = height
                config.minimumFrameInterval = CMTime(value: 1, timescale: 30) // 30 fps
                config.queueDepth = 3

                // Create stream
                stream = SCStream(filter: filter, configuration: config, delegate: self)

                // Add output
                try stream?.addStreamOutput(self, type: .screen, sampleHandlerQueue: .main)

                // Start capture
                try await stream?.startCapture()
                isCapturing = true
                result(true)
            } catch {
                result(FlutterError(code: "CAPTURE_ERROR", message: error.localizedDescription, details: nil))
            }
        }
    }

    func stopCapture(result: @escaping FlutterResult) {
        Task {
            do {
                try await stream?.stopCapture()
                stream = nil
                isCapturing = false
                result(true)
            } catch {
                result(FlutterError(code: "STOP_ERROR", message: error.localizedDescription, details: nil))
            }
        }
    }

    // MARK: - SCStreamOutput
    func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of outputType: SCStreamOutputType) {
        guard outputType == .screen else { return }

        // Convert CMSampleBuffer to JPEG data
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        let ciImage = CIImage(cvPixelBuffer: imageBuffer)
        let context = CIContext()
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return }

        let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
        guard let jpegData = bitmapRep.representation(using: .jpeg, properties: [.compressionFactor: 0.7]) else { return }

        // Send frame to Flutter
        let base64 = jpegData.base64EncodedString()
        DispatchQueue.main.async { [weak self] in
            self?.channel?.invokeMethod("onFrame", arguments: [
                "data": base64,
                "width": cgImage.width,
                "height": cgImage.height,
                "timestamp": Date().timeIntervalSince1970 * 1000
            ])
        }
    }

    // MARK: - SCStreamDelegate
    func stream(_ stream: SCStream, didStopWithError error: Error) {
        isCapturing = false
    }
}
