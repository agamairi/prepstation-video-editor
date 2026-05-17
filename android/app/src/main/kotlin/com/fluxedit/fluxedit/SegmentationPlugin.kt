package com.fluxedit.fluxedit

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.media.MediaCodec
import android.media.MediaCodecInfo
import android.media.MediaFormat
import android.media.MediaMetadataRetriever
import android.media.MediaMuxer
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.io.File
import java.nio.ByteBuffer
import java.util.concurrent.Executors
import java.util.concurrent.atomic.AtomicBoolean
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.segmentation.Segmentation
import com.google.mlkit.vision.segmentation.selfie.SelfieSegmenterOptions

class SegmentationPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
    private lateinit var channel: MethodChannel
    private val executor = Executors.newSingleThreadExecutor()
    private val cancelFlag = AtomicBoolean(false)

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "com.fluxedit/segmentation")
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "isAvailable" -> result.success(true)

            "segmentFrame" -> {
                val videoPath = call.argument<String>("videoPath") ?: run {
                    result.error("INVALID_ARGS", null, null); return
                }
                val timestampUs = call.argument<Long>("timestampUs") ?: run {
                    result.error("INVALID_ARGS", null, null); return
                }
                segmentFrame(videoPath, timestampUs, result)
            }

            "generateMaskVideo" -> {
                val videoPath = call.argument<String>("videoPath") ?: run {
                    result.error("INVALID_ARGS", null, null); return
                }
                val outputPath = call.argument<String>("outputPath") ?: run {
                    result.error("INVALID_ARGS", null, null); return
                }
                val inPointUs = call.argument<Long>("inPointUs") ?: run {
                    result.error("INVALID_ARGS", null, null); return
                }
                val outPointUs = call.argument<Long>("outPointUs") ?: run {
                    result.error("INVALID_ARGS", null, null); return
                }
                cancelFlag.set(false)
                generateMaskVideo(videoPath, outputPath, inPointUs, outPointUs, result)
            }

            "cancelProcessing" -> {
                cancelFlag.set(true)
                result.success(null)
            }

            else -> result.notImplemented()
        }
    }

    private fun segmentFrame(videoPath: String, timestampUs: Long, result: MethodChannel.Result) {
        executor.execute {
            try {
                val retriever = MediaMetadataRetriever()
                retriever.setDataSource(videoPath)
                val bitmap = retriever.getFrameAtTime(timestampUs, MediaMetadataRetriever.OPTION_CLOSEST)
                retriever.release()

                if (bitmap == null) {
                    runOnMain { result.success(null) }
                    return@execute
                }

                val options = SelfieSegmenterOptions.Builder()
                    .setDetectorMode(SelfieSegmenterOptions.SINGLE_IMAGE_MODE)
                    .build()
                val segmenter = Segmentation.getClient(options)
                val inputImage = InputImage.fromBitmap(bitmap, 0)

                segmenter.process(inputImage)
                    .addOnSuccessListener { segmentationMask ->
                        val mask = segmentationMask.buffer
                        val maskWidth = segmentationMask.width
                        val maskHeight = segmentationMask.height

                        val maskBitmap = Bitmap.createBitmap(maskWidth, maskHeight, Bitmap.Config.ARGB_8888)
                        mask.rewind()
                        for (y in 0 until maskHeight) {
                            for (x in 0 until maskWidth) {
                                val confidence = mask.float
                                val gray = (confidence * 255).toInt().coerceIn(0, 255)
                                maskBitmap.setPixel(x, y, Color.rgb(gray, gray, gray))
                            }
                        }

                        val stream = ByteArrayOutputStream()
                        maskBitmap.compress(Bitmap.CompressFormat.PNG, 100, stream)
                        maskBitmap.recycle()

                        runOnMain { result.success(stream.toByteArray()) }
                    }
                    .addOnFailureListener {
                        runOnMain { result.success(null) }
                    }

                bitmap.recycle()
            } catch (e: Exception) {
                runOnMain { result.success(null) }
            }
        }
    }

    private fun generateMaskVideo(
        videoPath: String,
        outputPath: String,
        inPointUs: Long,
        outPointUs: Long,
        result: MethodChannel.Result
    ) {
        executor.execute {
            try {
                val retriever = MediaMetadataRetriever()
                retriever.setDataSource(videoPath)

                val width = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_WIDTH)?.toInt() ?: 1920
                val height = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_HEIGHT)?.toInt() ?: 1080
                val fps = 30

                val outputFile = File(outputPath)
                if (outputFile.exists()) outputFile.delete()

                val muxer = MediaMuxer(outputPath, MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4)

                val format = MediaFormat.createVideoFormat(MediaFormat.MIMETYPE_VIDEO_AVC, width, height)
                format.setInteger(MediaFormat.KEY_BIT_RATE, 4_000_000)
                format.setInteger(MediaFormat.KEY_FRAME_RATE, fps)
                format.setInteger(MediaFormat.KEY_I_FRAME_INTERVAL, 1)
                format.setInteger(
                    MediaFormat.KEY_COLOR_FORMAT,
                    MediaCodecInfo.CodecCapabilities.COLOR_FormatYUV420Flexible
                )

                val codec = MediaCodec.createEncoderByType(MediaFormat.MIMETYPE_VIDEO_AVC)
                codec.configure(format, null, null, MediaCodec.CONFIGURE_FLAG_ENCODE)
                codec.start()

                val durationUs = outPointUs - inPointUs
                val totalFrames = ((durationUs / 1_000_000.0) * fps).toInt()
                var trackIndex = -1
                var trackAdded = false

                val options = SelfieSegmenterOptions.Builder()
                    .setDetectorMode(SelfieSegmenterOptions.SINGLE_IMAGE_MODE)
                    .build()

                for (frameIdx in 0 until totalFrames) {
                    if (cancelFlag.get()) break

                    val frameTimeUs = inPointUs + (frameIdx.toLong() * 1_000_000L / fps)
                    val bitmap = retriever.getFrameAtTime(frameTimeUs, MediaMetadataRetriever.OPTION_CLOSEST)
                        ?: continue

                    val segmenter = Segmentation.getClient(options)
                    val inputImage = InputImage.fromBitmap(bitmap, 0)

                    val latch = java.util.concurrent.CountDownLatch(1)
                    var maskBitmap: Bitmap? = null

                    segmenter.process(inputImage)
                        .addOnSuccessListener { segmentationMask ->
                            val mask = segmentationMask.buffer
                            val maskW = segmentationMask.width
                            val maskH = segmentationMask.height

                            val bmp = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
                            val canvas = Canvas(bmp)
                            val tempBmp = Bitmap.createBitmap(maskW, maskH, Bitmap.Config.ARGB_8888)

                            mask.rewind()
                            for (y in 0 until maskH) {
                                for (x in 0 until maskW) {
                                    val confidence = mask.float
                                    val gray = (confidence * 255).toInt().coerceIn(0, 255)
                                    tempBmp.setPixel(x, y, Color.rgb(gray, gray, gray))
                                }
                            }

                            canvas.drawBitmap(
                                tempBmp,
                                android.graphics.Rect(0, 0, maskW, maskH),
                                android.graphics.Rect(0, 0, width, height),
                                Paint()
                            )
                            tempBmp.recycle()
                            maskBitmap = bmp
                            latch.countDown()
                        }
                        .addOnFailureListener { latch.countDown() }

                    latch.await()
                    bitmap.recycle()

                    maskBitmap?.let { mb ->
                        val inputBufIdx = codec.dequeueInputBuffer(10_000)
                        if (inputBufIdx >= 0) {
                            val inputBuf = codec.getInputBuffer(inputBufIdx) ?: return@let
                            inputBuf.clear()

                            val yuvData = bitmapToNV12(mb, width, height)
                            inputBuf.put(yuvData)

                            val pts = frameIdx.toLong() * 1_000_000L / fps
                            codec.queueInputBuffer(inputBufIdx, 0, yuvData.size, pts, 0)
                        }
                        mb.recycle()
                    }

                    val bufferInfo = MediaCodec.BufferInfo()
                    while (true) {
                        val outputBufIdx = codec.dequeueOutputBuffer(bufferInfo, 0)
                        if (outputBufIdx == MediaCodec.INFO_OUTPUT_FORMAT_CHANGED && !trackAdded) {
                            trackIndex = muxer.addTrack(codec.outputFormat)
                            muxer.start()
                            trackAdded = true
                        } else if (outputBufIdx >= 0) {
                            val outputBuf = codec.getOutputBuffer(outputBufIdx) ?: break
                            if (trackAdded) {
                                muxer.writeSampleData(trackIndex, outputBuf, bufferInfo)
                            }
                            codec.releaseOutputBuffer(outputBufIdx, false)
                        } else {
                            break
                        }
                    }
                }

                codec.signalEndOfInputStream()
                val bufferInfo = MediaCodec.BufferInfo()
                while (true) {
                    val outputBufIdx = codec.dequeueOutputBuffer(bufferInfo, 10_000)
                    if (outputBufIdx < 0) break
                    val outputBuf = codec.getOutputBuffer(outputBufIdx) ?: break
                    if (trackAdded) {
                        muxer.writeSampleData(trackIndex, outputBuf, bufferInfo)
                    }
                    codec.releaseOutputBuffer(outputBufIdx, false)
                    if (bufferInfo.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM != 0) break
                }

                codec.stop()
                codec.release()
                if (trackAdded) muxer.stop()
                muxer.release()
                retriever.release()

                if (cancelFlag.get()) {
                    outputFile.delete()
                    runOnMain { result.success(null) }
                } else {
                    runOnMain { result.success(outputPath) }
                }
            } catch (e: Exception) {
                File(outputPath).delete()
                runOnMain { result.success(null) }
            }
        }
    }

    private fun bitmapToNV12(bitmap: Bitmap, width: Int, height: Int): ByteArray {
        val argb = IntArray(width * height)
        bitmap.getPixels(argb, 0, width, 0, 0, width, height)

        val yuvSize = width * height * 3 / 2
        val yuv = ByteArray(yuvSize)

        var yIdx = 0
        var uvIdx = width * height

        for (y in 0 until height) {
            for (x in 0 until width) {
                val pixel = argb[y * width + x]
                val r = (pixel shr 16) and 0xFF
                val g = (pixel shr 8) and 0xFF
                val b = pixel and 0xFF

                val yVal = ((66 * r + 129 * g + 25 * b + 128) shr 8) + 16
                yuv[yIdx++] = yVal.coerceIn(0, 255).toByte()

                if (y % 2 == 0 && x % 2 == 0 && uvIdx < yuvSize - 1) {
                    val uVal = ((-38 * r - 74 * g + 112 * b + 128) shr 8) + 128
                    val vVal = ((112 * r - 94 * g - 18 * b + 128) shr 8) + 128
                    yuv[uvIdx++] = uVal.coerceIn(0, 255).toByte()
                    yuv[uvIdx++] = vVal.coerceIn(0, 255).toByte()
                }
            }
        }

        return yuv
    }

    private fun runOnMain(block: () -> Unit) {
        android.os.Handler(android.os.Looper.getMainLooper()).post(block)
    }
}
