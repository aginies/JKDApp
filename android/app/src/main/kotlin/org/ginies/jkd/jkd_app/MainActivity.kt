package org.ginies.jkd.jkd_app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private lateinit var garminPlugin: GarminPlugin

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        garminPlugin = GarminPlugin(this)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            GarminPlugin.METHOD_CHANNEL
        ).setMethodCallHandler(garminPlugin)
        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            GarminPlugin.EVENT_CHANNEL
        ).setStreamHandler(garminPlugin)
        // SDK is initialized via "initialize" MethodChannel call from Flutter
        // after the engine is fully ready, to avoid "Reply already submitted" crash.
    }

    override fun onDestroy() {
        garminPlugin.shutdown()
        super.onDestroy()
    }
}
