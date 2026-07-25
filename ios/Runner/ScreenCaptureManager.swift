import Flutter
import UIKit
import ReplayKit
import AVFoundation

class ScreenCaptureManager: NSObject, RPPreviewViewControllerDelegate, RPScreenRecorderDelegate {
    static let shared = ScreenCaptureManager()
    private var channel: FlutterMethodChannel?
    private let recorder = RPScreenRecorder.shared()
    private var isCapturing = false

    func setup(channel: FlutterMethodChannel) {
        self.channel = channel
        recorder.delegate = self
    }

    func requestPermission(result: @escaping FlutterResult) {
        // On iOS, permission is requested when starting capture
        result(true)
    }

    func getScreenSize(result: @escaping FlutterResult) {
        let screen = UIScreen.main
        result([
            "width": Int(screen.bounds.width * screen.scale),
            "height": Int(screen.bounds.height * screen.scale),
            "scale": screen.scale
        ])
    }

    func startCapture(width: Int, height: Int, result: @escaping FlutterResult) {
        guard recorder.isAvailable else {
            result(FlutterError(code: "UNAVAILABLE", message: "Screen recording not available", details: nil))
            return
        }

        recorder.startCapture(handler: { [weak self] sampleBuffer, bufferType, error in
            guard let self = self, bufferType == .video, error == nil else { return }

            // Convert CMSampleBuffer to JPEG
            guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

            let ciImage = CIImage(cvPixelBuffer: imageBuffer)
            let context = CIContext()
            guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return }

            let uiImage = UIImage(cgImage: cgImage)
            guard let jpegData = uiImage.jpegData(compressionQuality: 0.7) else { return }

            // Send frame to Flutter
            let base64 = jpegData.base64EncodedString()
            DispatchQueue.main.async {
                self.channel?.invokeMethod("onFrame", arguments: [
                    "data": base64,
                    "width": cgImage.width,
                    "height": cgImage.height,
                    "timestamp": Date().timeIntervalSince1970 * 1000
                ])
            }
        }) { error in
            if let error = error {
                result(FlutterError(code: "START_ERROR", message: error.localizedDescription, details: nil))
            } else {
                self.isCapturing = true
                result(true)
            }
        }
    }

    func stopCapture(result: @escaping FlutterResult) {
        recorder.stopCapture { [weak self] error in
            self?.isCapturing = false
            if let error = error {
                result(FlutterError(code: "STOP_ERROR", message: error.localizedDescription, details: nil))
            } else {
                result(true)
            }
        }
    }

    // MARK: - RPScreenRecorderDelegate
    func screenRecorder(_ screenRecorder: RPScreenRecorder, didStopRecordingWith previewViewController: RPPreviewViewController?, error: Error?) {
        isCapturing = false
    }

    func screenRecorderDidChangeAvailability(_ screenRecorder: RPScreenRecorder) {
        // Handle availability change
    }
}
