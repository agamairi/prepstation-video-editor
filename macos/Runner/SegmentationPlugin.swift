import Cocoa
import FlutterMacOS
import Vision
import AVFoundation
import CoreImage

class SegmentationPlugin: NSObject, FlutterPlugin {
    private var cancelFlag = false

    static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "com.fluxedit/segmentation",
            binaryMessenger: registrar.messenger
        )
        let instance = SegmentationPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "isAvailable":
            if #available(macOS 12.0, *) {
                result(true)
            } else {
                result(false)
            }

        case "segmentFrame":
            guard let args = call.arguments as? [String: Any],
                  let videoPath = args["videoPath"] as? String,
                  let timestampUs = args["timestampUs"] as? Int64 else {
                result(FlutterError(code: "INVALID_ARGS", message: nil, details: nil))
                return
            }
            let quality = args["quality"] as? String ?? "balanced"
            segmentFrame(videoPath: videoPath, timestampUs: timestampUs, quality: quality, result: result)

        case "generateMaskVideo":
            guard let args = call.arguments as? [String: Any],
                  let videoPath = args["videoPath"] as? String,
                  let outputPath = args["outputPath"] as? String,
                  let inPointUs = args["inPointUs"] as? Int64,
                  let outPointUs = args["outPointUs"] as? Int64 else {
                result(FlutterError(code: "INVALID_ARGS", message: nil, details: nil))
                return
            }
            let quality = args["quality"] as? String ?? "balanced"
            cancelFlag = false
            generateMaskVideo(
                videoPath: videoPath,
                outputPath: outputPath,
                inPointUs: inPointUs,
                outPointUs: outPointUs,
                quality: quality,
                result: result
            )

        case "cancelProcessing":
            cancelFlag = true
            result(nil)

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    @available(macOS 12.0, *)
    private func qualityLevel(_ quality: String) -> VNGeneratePersonSegmentationRequest.QualityLevel {
        switch quality {
        case "fast": return .fast
        case "accurate": return .accurate
        default: return .balanced
        }
    }

    private func segmentFrame(videoPath: String, timestampUs: Int64, quality: String, result: @escaping FlutterResult) {
        guard #available(macOS 12.0, *) else {
            result(nil)
            return
        }

        DispatchQueue.global(qos: .userInitiated).async {
            let asset = AVAsset(url: URL(fileURLWithPath: videoPath))
            let generator = AVAssetImageGenerator(asset: asset)
            generator.appliesPreferredTrackTransform = true
            generator.requestedTimeToleranceBefore = .zero
            generator.requestedTimeToleranceAfter = .zero

            let time = CMTime(value: timestampUs, timescale: 1_000_000)

            do {
                let cgImage = try generator.copyCGImage(at: time, actualTime: nil)
                guard let maskBuffer = self.performSegmentation(cgImage: cgImage, quality: quality) else {
                    DispatchQueue.main.async { result(nil) }
                    return
                }

                let ciImage = CIImage(cvPixelBuffer: maskBuffer)
                let context = CIContext()
                guard let cgMask = context.createCGImage(ciImage, from: ciImage.extent) else {
                    DispatchQueue.main.async { result(nil) }
                    return
                }

                let rep = NSBitmapImageRep(cgImage: cgMask)
                let pngData = rep.representation(using: .png, properties: [:])
                DispatchQueue.main.async { result(pngData) }
            } catch {
                DispatchQueue.main.async { result(nil) }
            }
        }
    }

    @available(macOS 12.0, *)
    private func performSegmentation(cgImage: CGImage, quality: String) -> CVPixelBuffer? {
        let request = VNGeneratePersonSegmentationRequest()
        request.qualityLevel = qualityLevel(quality)
        request.outputPixelFormat = kCVPixelFormatType_OneComponent8

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try? handler.perform([request])

        return request.results?.first?.pixelBuffer
    }

    private func generateMaskVideo(
        videoPath: String,
        outputPath: String,
        inPointUs: Int64,
        outPointUs: Int64,
        quality: String,
        result: @escaping FlutterResult
    ) {
        guard #available(macOS 12.0, *) else {
            result(nil)
            return
        }

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            let asset = AVAsset(url: URL(fileURLWithPath: videoPath))
            guard let videoTrack = asset.tracks(withMediaType: .video).first else {
                DispatchQueue.main.async { result(nil) }
                return
            }

            let fps = videoTrack.nominalFrameRate
            let size = videoTrack.naturalSize.applying(videoTrack.preferredTransform)
            let outputSize = CGSize(width: abs(size.width), height: abs(size.height))

            let outputURL = URL(fileURLWithPath: outputPath)
            try? FileManager.default.removeItem(at: outputURL)

            guard let writer = try? AVAssetWriter(outputURL: outputURL, fileType: .mp4) else {
                DispatchQueue.main.async { result(nil) }
                return
            }

            let videoSettings: [String: Any] = [
                AVVideoCodecKey: AVVideoCodecType.h264,
                AVVideoWidthKey: Int(outputSize.width),
                AVVideoHeightKey: Int(outputSize.height),
            ]

            let writerInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
            let adaptor = AVAssetWriterInputPixelBufferAdaptor(
                assetWriterInput: writerInput,
                sourcePixelBufferAttributes: [
                    kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32ARGB,
                    kCVPixelBufferWidthKey as String: Int(outputSize.width),
                    kCVPixelBufferHeightKey as String: Int(outputSize.height),
                ]
            )

            writer.add(writerInput)
            writer.startWriting()
            writer.startSession(atSourceTime: .zero)

            let generator = AVAssetImageGenerator(asset: asset)
            generator.appliesPreferredTrackTransform = true
            generator.requestedTimeToleranceBefore = .zero
            generator.requestedTimeToleranceAfter = .zero

            let inTime = CMTime(value: inPointUs, timescale: 1_000_000)
            let outTime = CMTime(value: outPointUs, timescale: 1_000_000)
            let durationSecs = CMTimeGetSeconds(outTime - inTime)
            let totalFrames = Int(durationSecs * Double(fps))

            let ciContext = CIContext()

            for frameIdx in 0..<totalFrames {
                if self.cancelFlag { break }

                let frameTime = inTime + CMTime(value: CMTimeValue(frameIdx), timescale: CMTimeScale(fps))

                guard let cgImage = try? generator.copyCGImage(at: frameTime, actualTime: nil),
                      let maskBuffer = self.performSegmentation(cgImage: cgImage, quality: quality) else {
                    continue
                }

                let maskCI = CIImage(cvPixelBuffer: maskBuffer)
                let scaledMask = maskCI.transformed(by: CGAffineTransform(
                    scaleX: outputSize.width / maskCI.extent.width,
                    y: outputSize.height / maskCI.extent.height
                ))

                var pixelBuffer: CVPixelBuffer?
                CVPixelBufferPoolCreatePixelBuffer(nil, adaptor.pixelBufferPool!, &pixelBuffer)
                guard let outputBuffer = pixelBuffer else { continue }

                ciContext.render(scaledMask, to: outputBuffer)

                let presentationTime = CMTime(value: CMTimeValue(frameIdx), timescale: CMTimeScale(fps))

                while !writerInput.isReadyForMoreMediaData {
                    Thread.sleep(forTimeInterval: 0.01)
                }
                adaptor.append(outputBuffer, withPresentationTime: presentationTime)
            }

            writerInput.markAsFinished()
            let semaphore = DispatchSemaphore(value: 0)
            writer.finishWriting { semaphore.signal() }
            semaphore.wait()

            if self.cancelFlag {
                try? FileManager.default.removeItem(at: outputURL)
                DispatchQueue.main.async { result(nil) }
            } else {
                DispatchQueue.main.async { result(outputPath) }
            }
        }
    }
}
