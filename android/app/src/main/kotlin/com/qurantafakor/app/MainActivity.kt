package com.qurantafakor.app

import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Main Activity for the Quran app.
 *
 * Extends AudioServiceActivity (required by audio_service package for
 * background Quran audio playback).
 */
class MainActivity : AudioServiceActivity() {
    private val channelName = "com.qurantafakor.app/app_control"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).setMethodCallHandler { call, result ->
            if (call.method == "restartApp") {
                result.success(true)
                RestartActivity.restartApp(this)
            } else {
                result.notImplemented()
            }
        }
    }
}
