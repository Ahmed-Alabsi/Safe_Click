package com.example.safecli

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.safecli/app"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "moveTaskToBack" -> {
                        moveTaskToBack(true)
                        result.success(true)
                    }
                    "openDefaultAppsSettings" -> {
                        // فتح إعدادات "فتح بشكل افتراضي" للتطبيق
                        try {
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                                // Android 12+ - صفحة إعدادات الروابط مباشرة
                                val intent = Intent(
                                    Settings.ACTION_APP_OPEN_BY_DEFAULT_SETTINGS,
                                    Uri.parse("package:$packageName")
                                )
                                startActivity(intent)
                            } else {
                                // Android أقدم - صفحة إعدادات التطبيق
                                val intent = Intent(
                                    Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                                    Uri.parse("package:$packageName")
                                )
                                startActivity(intent)
                            }
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("ERROR", e.message, null)
                        }
                    }
                    "isDefaultLinkHandler" -> {
                        // التحقق مما إذا كان التطبيق هو المعالج الافتراضي للروابط
                        try {
                            val pm = packageManager
                            val intent = Intent(Intent.ACTION_VIEW, Uri.parse("https://example.com"))
                            val resolveInfo = pm.resolveActivity(intent, 0)
                            val isDefault = resolveInfo?.activityInfo?.packageName == packageName
                            result.success(isDefault)
                        } catch (e: Exception) {
                            result.success(false)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }
}