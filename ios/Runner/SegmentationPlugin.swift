import Flutter
import UIKit
import Vision
import AVFoundation
import CoreImage

class SegmentationPlugin: NSObject, FlutterPlugin {
    private var cancelFlag = false

    static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "com.fluxedit/segmentation",
            binaryMessenger: registrar.messenger()
        )
        let instance = SegmentationPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "isAvailable":
            if #available(iOS 17.0, *) {
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
            let selectionRect = parseRect(from: args)
            segmentFrame(videoPath: videoPath, timestampUs: timestampUs, quality: quality, selectionRect: selectionRect, result: result)

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
            let selectionRect = parseRect(from: args)
            cancelFlag = false
            generateMaskVideo(
                videoPath: videoPath,
                outputPath: outputPath,
                inPointUs: inPointUs,
                outPointUs: outPointUs,
                quality: quality,
                selectionRect: selectionRect,
                result: result
            )

        case "cancelProcessing":
            cancelFlag = true
            result(nil)

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func parseRect(from args: [String: Any]) -> CGRect? {
        guard let left = args["rectLeft"] as? Double,
              let top = args["rectTop"] as? Double,
              let right = args["rectRight"] as? Double,
              let bottom = args["rectBottom"] as? Double else {
            return nil
        }
        return CGRect(x: left, y: top, width: right - left, height: bottom - top)
    }

    private func segmentFrame(videoPath: String, timestampUs: Int64, quality: String, selectionRect: CGRect?, result: @escaping FlutterResult) {
        guard #available(iOS 17.0, *) else {
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
                guard let maskBuffer = self.performInstanceSegmentation(
                    cgImage: cgImage,
                    selectionRect: selectionRect,
                    previousMask: nil
                ) else {
                    DispatchQueue.main.async { result(nil) }
                    return
                }

                let ciImage = CIImage(cvPixelBuffer: maskBuffer)
                let context = CIContext()
                guard let cgMask = context.createCGImage(ciImage, from: ciImage.extent) else {
                    DispatchQueue.main.async { result(nil) }
                    return
                }

                let uiImage = UIImage(cgImage: cgMask)
                let pngData = uiImage.pngData()
                DispatchQueue.main.async { result(pngData) }
            } catch {
                DispatchQueue.main.async { result(nil) }
            }
        }
    }

    @available(iOS 17.0, *)
    private func performInstanceSegmentation(
        cgImage: CGImage,
        selectionRect: CGRect?,
        previousMask: CVPixelBuffer?
    ) -> CVPixelBuffer? {
        let request = VNGenerateForegroundInstanceMaskRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try? handler.perform([request])

        guard let observation = request.results?.first else { return nil }

        let allInstances = observation.allInstances
        guard !allInstances.isEmpty else { return nil }

        var selectedIndices: IndexSet

        if let previousMask = previousMask {
            selectedIndices = matchInstancesByIoU(
                observation: observation,
                allInstances: allInstances,
                previousMask: previousMask,
                imageWidth: cgImage.width,
                imageHeight: cgImage.height,
                handler: handler
            )
            if selectedIndices.isEmpty, let rect = selectionRect {
                selectedIndices = findInstancesInRect(
                    observation: observation,
                    allInstances: allInstances,
                    selectionRect: rect,
                    imageWidth: cgImage.width,
                    imageHeight: cgImage.height,
                    handler: handler
                )
            }
        } else if let rect = selectionRect {
            selectedIndices = findInstancesInRect(
                observation: observation,
                allInstances: allInstances,
                selectionRect: rect,
                imageWidth: cgImage.width,
                imageHeight: cgImage.height,
                handler: handler
            )
        } else {
            selectedIndices = allInstances
        }

        guard !selectedIndices.isEmpty else { return nil }

        let maskedImage = try? observation.generateMaskedImage(
            ofInstances: selectedIndices,
            from: handler,
            croppedToInstancesExtent: false
        )
        return maskedImage
    }

    @available(iOS 17.0, *)
    private func findInstancesInRect(
        observation: VNInstanceMaskObservation,
        allInstances: IndexSet,
        selectionRect: CGRect,
        imageWidth: Int,
        imageHeight: Int,
        handler: VNImageRequestHandler
    ) -> IndexSet {
        var result = IndexSet()

        for idx in allInstances {
            guard let mask = try? observation.generateMaskedImage(
                ofInstances: IndexSet([idx]),
                from: handler,
                croppedToInstancesExtent: false
            ) else { continue }

            if maskOverlapsRect(mask: mask, rect: selectionRect, imageWidth: imageWidth, imageHeight: imageHeight) {
                result.insert(idx)
            }
        }
        return result
    }

    @available(iOS 17.0, *)
    private func matchInstancesByIoU(
        observation: VNInstanceMaskObservation,
        allInstances: IndexSet,
        previousMask: CVPixelBuffer,
        imageWidth: Int,
        imageHeight: Int,
        handler: VNImageRequestHandler
    ) -> IndexSet {
        var result = IndexSet()
        let threshold: Float = 0.3

        let prevWidth = CVPixelBufferGetWidth(previousMask)
        let prevHeight = CVPixelBufferGetHeight(previousMask)

        CVPixelBufferLockBaseAddress(previousMask, .readOnly)
        let prevBase = CVPixelBufferGetBaseAddress(previousMask)!.assumingMemoryBound(to: UInt8.self)
        let prevStride = CVPixelBufferGetBytesPerRow(previousMask)

        var prevPixelCount = 0
        for y in 0..<prevHeight {
            for x in 0..<prevWidth {
                if prevBase[y * prevStride + x] > 128 { prevPixelCount += 1 }
            }
        }
        CVPixelBufferUnlockBaseAddress(previousMask, .readOnly)

        guard prevPixelCount > 0 else { return result }

        for idx in allInstances {
            guard let mask = try? observation.generateMaskedImage(
                ofInstances: IndexSet([idx]),
                from: handler,
                croppedToInstancesExtent: false
            ) else { continue }

            let maskWidth = CVPixelBufferGetWidth(mask)
            let maskHeight = CVPixelBufferGetHeight(mask)

            guard maskWidth == prevWidth && maskHeight == prevHeight else { continue }

            CVPixelBufferLockBaseAddress(mask, .readOnly)
            let maskBase = CVPixelBufferGetBaseAddress(mask)!.assumingMemoryBound(to: UInt8.self)
            let maskStride = CVPixelBufferGetBytesPerRow(mask)

            CVPixelBufferLockBaseAddress(previousMask, .readOnly)

            var intersection = 0
            var maskPixelCount = 0
            for y in 0..<maskHeight {
                for x in 0..<maskWidth {
                    let mv = maskBase[y * maskStride + x] > 128
                    let pv = prevBase[y * prevStride + x] > 128
                    if mv { maskPixelCount += 1 }
                    if mv && pv { intersection += 1 }
                }
            }

            CVPixelBufferUnlockBaseAddress(mask, .readOnly)
            CVPixelBufferUnlockBaseAddress(previousMask, .readOnly)

            let union = prevPixelCount + maskPixelCount - intersection
            let iou = union > 0 ? Float(intersection) / Float(union) : 0

            if iou > threshold {
                result.insert(idx)
            }
        }
        return result
    }

    private func maskOverlapsRect(mask: CVPixelBuffer, rect: CGRect, imageWidth: Int, imageHeight: Int) -> Bool {
        let maskWidth = CVPixelBufferGetWidth(mask)
        let maskHeight = CVPixelBufferGetHeight(mask)

        let startX = Int(rect.origin.x * CGFloat(maskWidth))
        let startY = Int(rect.origin.y * CGFloat(maskHeight))
        let endX = Int((rect.origin.x + rect.width) * CGFloat(maskWidth))
        let endY = Int((rect.origin.y + rect.height) * CGFloat(maskHeight))

        let clampedStartX = max(0, min(startX, maskWidth - 1))
        let clampedStartY = max(0, min(startY, maskHeight - 1))
        let clampedEndX = max(0, min(endX, maskWidth))
        let clampedEndY = max(0, min(endY, maskHeight))

        CVPixelBufferLockBaseAddress(mask, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(mask, .readOnly) }

        let base = CVPixelBufferGetBaseAddress(mask)!.assumingMemoryBound(to: UInt8.self)
        let stride = CVPixelBufferGetBytesPerRow(mask)

        for y in clampedStartY..<clampedEndY {
            for x in clampedStartX..<clampedEndX {
                if base[y * stride + x] > 128 {
                    return true
                }
            }
        }
        return false
    }

    private func renderMaskToARGB(
        mask: CVPixelBuffer,
        output: CVPixelBuffer,
        width: Int,
        height: Int,
        ciContext: CIContext
    ) {
        let maskCI = CIImage(cvPixelBuffer: mask)
        let scaleX = CGFloat(width) / maskCI.extent.width
        let scaleY = CGFloat(height) / maskCI.extent.height
        let scaledMask = maskCI.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))

        guard let cgMask = ciContext.createCGImage(scaledMask, from: CGRect(x: 0, y: 0, width: width, height: height)) else { return }

        CVPixelBufferLockBaseAddress(output, [])
        defer { CVPixelBufferUnlockBaseAddress(output, []) }

        let outBase = CVPixelBufferGetBaseAddress(output)!
        let outStride = CVPixelBufferGetBytesPerRow(output)

        guard let cgContext = CGContext(
            data: outBase,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: outStride,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
        ) else { return }

        cgContext.draw(cgMask, in: CGRect(x: 0, y: 0, width: width, height: height))
    }

    private func generateMaskVideo(
        videoPath: String,
        outputPath: String,
        inPointUs: Int64,
        outPointUs: Int64,
        quality: String,
        selectionRect: CGRect?,
        result: @escaping FlutterResult
    ) {
        guard #available(iOS 17.0, *) else {
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
            var previousMask: CVPixelBuffer? = nil

            for frameIdx in 0..<totalFrames {
                if self.cancelFlag { break }

                let frameTime = inTime + CMTime(value: CMTimeValue(frameIdx), timescale: CMTimeScale(fps))

                guard let cgImage = try? generator.copyCGImage(at: frameTime, actualTime: nil),
                      let maskBuffer = self.performInstanceSegmentation(
                          cgImage: cgImage,
                          selectionRect: selectionRect,
                          previousMask: previousMask
                      ) else {
                    continue
                }

                previousMask = maskBuffer

                var pixelBuffer: CVPixelBuffer?
                CVPixelBufferPoolCreatePixelBuffer(nil, adaptor.pixelBufferPool!, &pixelBuffer)
                guard let outputBuffer = pixelBuffer else { continue }

                self.renderMaskToARGB(
                    mask: maskBuffer,
                    output: outputBuffer,
                    width: Int(outputSize.width),
                    height: Int(outputSize.height),
                    ciContext: ciContext
                )

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
