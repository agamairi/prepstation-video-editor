import Cocoa
import FlutterMacOS
import Vision
import AVFoundation
import CoreImage

class SegmentationPlugin: NSObject, FlutterPlugin {
    private var cancelFlag = false

    static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "com.agamairi.prepstation/segmentation",
            binaryMessenger: registrar.messenger
        )
        let instance = SegmentationPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "isAvailable":
            if #available(macOS 14.0, *) {
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
            let selectionRect = parseRect(from: args)
            segmentFrame(videoPath: videoPath, timestampUs: timestampUs, selectionRect: selectionRect, result: result)

        case "generateMaskVideo":
            guard let args = call.arguments as? [String: Any],
                  let videoPath = args["videoPath"] as? String,
                  let outputPath = args["outputPath"] as? String,
                  let inPointUs = args["inPointUs"] as? Int64,
                  let outPointUs = args["outPointUs"] as? Int64 else {
                result(FlutterError(code: "INVALID_ARGS", message: nil, details: nil))
                return
            }
            let selectionRect = parseRect(from: args)
            cancelFlag = false
            generateMaskVideo(
                videoPath: videoPath,
                outputPath: outputPath,
                inPointUs: inPointUs,
                outPointUs: outPointUs,
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

    private func segmentFrame(videoPath: String, timestampUs: Int64, selectionRect: CGRect?, result: @escaping FlutterResult) {
        guard #available(macOS 14.0, *) else {
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
                guard let segResult = self.performInstanceSegmentation(
                    cgImage: cgImage,
                    selectionRect: selectionRect,
                    previousLabelMap: nil,
                    previousSelectedIndices: nil
                ) else {
                    DispatchQueue.main.async { result(nil) }
                    return
                }

                let ciImage = CIImage(cvPixelBuffer: segResult.mask)
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

    @available(macOS 14.0, *)
    private struct SegResult {
        let mask: CVPixelBuffer
        let labelMap: CVPixelBuffer
        let selectedIndices: IndexSet
    }

    @available(macOS 14.0, *)
    private func performInstanceSegmentation(
        cgImage: CGImage,
        selectionRect: CGRect?,
        previousLabelMap: CVPixelBuffer?,
        previousSelectedIndices: IndexSet?
    ) -> SegResult? {
        let request = VNGenerateForegroundInstanceMaskRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        do {
            try handler.perform([request])
        } catch {
            return nil
        }

        guard let observation = request.results?.first else { return nil }

        let allInstances = observation.allInstances
        guard !allInstances.isEmpty else { return nil }

        var selectedIndices: IndexSet

        if let prevMap = previousLabelMap, let prevSel = previousSelectedIndices {
            selectedIndices = matchInstancesByIoU(
                observation: observation,
                allInstances: allInstances,
                previousSelectedIndices: prevSel,
                previousLabelMap: prevMap,
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

        do {
            let maskedImage = try observation.generateMaskedImage(
                ofInstances: selectedIndices,
                from: handler,
                croppedToInstancesExtent: false
            )
            return SegResult(
                mask: maskedImage,
                labelMap: observation.instanceMask,
                selectedIndices: selectedIndices
            )
        } catch {
            return nil
        }
    }

    @available(macOS 14.0, *)
    private func findInstancesInRect(
        observation: VNInstanceMaskObservation,
        allInstances: IndexSet,
        selectionRect: CGRect,
        imageWidth: Int,
        imageHeight: Int,
        handler: VNImageRequestHandler
    ) -> IndexSet {
        let labelMap = observation.instanceMask
        let w = CVPixelBufferGetWidth(labelMap)
        let h = CVPixelBufferGetHeight(labelMap)

        CVPixelBufferLockBaseAddress(labelMap, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(labelMap, .readOnly) }

        let base = CVPixelBufferGetBaseAddress(labelMap)!.assumingMemoryBound(to: UInt8.self)
        let stride = CVPixelBufferGetBytesPerRow(labelMap)

        let sx = max(0, Int(selectionRect.origin.x * CGFloat(w)))
        let sy = max(0, Int(selectionRect.origin.y * CGFloat(h)))
        let ex = min(w, Int((selectionRect.origin.x + selectionRect.width) * CGFloat(w)))
        let ey = min(h, Int((selectionRect.origin.y + selectionRect.height) * CGFloat(h)))

        var found = IndexSet()
        for y in sy..<ey {
            for x in sx..<ex {
                let val = Int(base[y * stride + x])
                if val > 0 && allInstances.contains(val) {
                    found.insert(val)
                }
            }
        }
        return found
    }

    @available(macOS 14.0, *)
    private func matchInstancesByIoU(
        observation: VNInstanceMaskObservation,
        allInstances: IndexSet,
        previousSelectedIndices: IndexSet,
        previousLabelMap: CVPixelBuffer,
        handler: VNImageRequestHandler
    ) -> IndexSet {
        let curLabelMap = observation.instanceMask
        let curW = CVPixelBufferGetWidth(curLabelMap)
        let curH = CVPixelBufferGetHeight(curLabelMap)
        let prevW = CVPixelBufferGetWidth(previousLabelMap)
        let prevH = CVPixelBufferGetHeight(previousLabelMap)

        guard curW == prevW && curH == prevH else { return IndexSet() }

        CVPixelBufferLockBaseAddress(curLabelMap, .readOnly)
        CVPixelBufferLockBaseAddress(previousLabelMap, .readOnly)
        defer {
            CVPixelBufferUnlockBaseAddress(curLabelMap, .readOnly)
            CVPixelBufferUnlockBaseAddress(previousLabelMap, .readOnly)
        }

        let curBase = CVPixelBufferGetBaseAddress(curLabelMap)!.assumingMemoryBound(to: UInt8.self)
        let curStride = CVPixelBufferGetBytesPerRow(curLabelMap)
        let prevBase = CVPixelBufferGetBaseAddress(previousLabelMap)!.assumingMemoryBound(to: UInt8.self)
        let prevStride = CVPixelBufferGetBytesPerRow(previousLabelMap)

        var prevCount = 0
        var perInstanceCount: [Int: Int] = [:]
        var perInstanceOverlap: [Int: Int] = [:]

        for y in 0..<curH {
            for x in 0..<curW {
                let prevVal = Int(prevBase[y * prevStride + x])
                let curVal = Int(curBase[y * curStride + x])
                let wasFG = prevVal > 0 && previousSelectedIndices.contains(prevVal)
                if wasFG { prevCount += 1 }
                if curVal > 0 && allInstances.contains(curVal) {
                    perInstanceCount[curVal, default: 0] += 1
                    if wasFG {
                        perInstanceOverlap[curVal, default: 0] += 1
                    }
                }
            }
        }

        guard prevCount > 0 else { return IndexSet() }

        let threshold: Float = 0.3
        var result = IndexSet()
        for idx in allInstances {
            let count = perInstanceCount[idx] ?? 0
            let overlap = perInstanceOverlap[idx] ?? 0
            let union = prevCount + count - overlap
            let iou = union > 0 ? Float(overlap) / Float(union) : 0
            if iou > threshold {
                result.insert(idx)
            }
        }
        return result
    }

    private func generateMaskVideo(
        videoPath: String,
        outputPath: String,
        inPointUs: Int64,
        outPointUs: Int64,
        selectionRect: CGRect?,
        result: @escaping FlutterResult
    ) {
        guard #available(macOS 14.0, *) else {
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
            writerInput.expectsMediaDataInRealTime = false

            let adaptor = AVAssetWriterInputPixelBufferAdaptor(
                assetWriterInput: writerInput,
                sourcePixelBufferAttributes: [
                    kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
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
            let totalFrames = max(1, Int(durationSecs * Double(fps)))

            let ciContext = CIContext()
            var previousLabelMap: CVPixelBuffer? = nil
            var previousSelectedIndices: IndexSet? = nil
            var framesWritten = 0
            let outW = Int(outputSize.width)
            let outH = Int(outputSize.height)

            for frameIdx in 0..<totalFrames {
                if self.cancelFlag { break }

                let frameTime = inTime + CMTime(value: CMTimeValue(frameIdx), timescale: CMTimeScale(fps))

                guard let cgImage = try? generator.copyCGImage(at: frameTime, actualTime: nil) else {
                    continue
                }

                guard let segResult = self.performInstanceSegmentation(
                    cgImage: cgImage,
                    selectionRect: selectionRect,
                    previousLabelMap: previousLabelMap,
                    previousSelectedIndices: previousSelectedIndices
                ) else {
                    continue
                }

                previousLabelMap = segResult.labelMap
                previousSelectedIndices = segResult.selectedIndices

                let maskCI = CIImage(cvPixelBuffer: segResult.mask)
                let scaleX = CGFloat(outW) / maskCI.extent.width
                let scaleY = CGFloat(outH) / maskCI.extent.height
                let scaled = maskCI.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))

                let opaqueFilter = CIFilter(name: "CIColorMatrix")!
                opaqueFilter.setValue(scaled, forKey: kCIInputImageKey)
                opaqueFilter.setValue(CIVector(x: 1, y: 0, z: 0, w: 0), forKey: "inputRVector")
                opaqueFilter.setValue(CIVector(x: 0, y: 1, z: 0, w: 0), forKey: "inputGVector")
                opaqueFilter.setValue(CIVector(x: 0, y: 0, z: 1, w: 0), forKey: "inputBVector")
                opaqueFilter.setValue(CIVector(x: 0, y: 0, z: 0, w: 0), forKey: "inputAVector")
                opaqueFilter.setValue(CIVector(x: 0, y: 0, z: 0, w: 1), forKey: "inputBiasVector")

                guard let rgbMask = opaqueFilter.outputImage else { continue }

                var pixelBuffer: CVPixelBuffer?
                guard let pool = adaptor.pixelBufferPool else { continue }
                CVPixelBufferPoolCreatePixelBuffer(nil, pool, &pixelBuffer)
                guard let outputBuffer = pixelBuffer else { continue }

                ciContext.render(rgbMask, to: outputBuffer)

                let presentationTime = CMTime(value: CMTimeValue(frameIdx), timescale: CMTimeScale(fps))

                while !writerInput.isReadyForMoreMediaData {
                    Thread.sleep(forTimeInterval: 0.01)
                }

                if adaptor.append(outputBuffer, withPresentationTime: presentationTime) {
                    framesWritten += 1
                }
            }

            writerInput.markAsFinished()
            let semaphore = DispatchSemaphore(value: 0)
            writer.finishWriting { semaphore.signal() }
            semaphore.wait()

            if self.cancelFlag || framesWritten == 0 {
                try? FileManager.default.removeItem(at: outputURL)
                DispatchQueue.main.async { result(nil) }
            } else {
                DispatchQueue.main.async { result(outputPath) }
            }
        }
    }

}
