package com.fluxedit.fluxedit

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        SegmentationPlugin().onAttachedToEngine(
            object : io.flutter.embedding.engine.plugins.FlutterPlugin.FlutterPluginBinding {
                override fun getBinaryMessenger() = flutterEngine.dartExecutor.binaryMessenger
                override fun getTextureRegistry() = flutterEngine.renderer
                override fun getPlatformViewRegistry() = flutterEngine.platformViewsController.registry
                override fun getApplicationContext() = applicationContext
                override fun getFlutterAssets() = flutterAssets
            }
        )
    }
}
