package com.yoonjaemin.passtime

import android.content.Intent
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "passtime/settings"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            channelName
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "openNfcSettings" -> {
                    val opened = openSettings(
                        listOf(
                            Settings.ACTION_NFC_SETTINGS,
                            Settings.ACTION_WIRELESS_SETTINGS,
                            Settings.ACTION_SETTINGS
                        )
                    )
                    result.success(opened)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun openSettings(actions: List<String>): Boolean {
        for (action in actions) {
            try {
                val intent = Intent(action)
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                startActivity(intent)
                return true
            } catch (_: Exception) {
                // 다음 후보 인텐트 시도
            }
        }
        return false
    }
}
