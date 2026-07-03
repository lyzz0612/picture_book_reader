package com.example.picture_book_reader

import android.content.Intent
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

/**
 * 自动更新：接收 Dart 侧 installApk 调用，
 * 通过 FileProvider + ACTION_VIEW 拉起系统包安装器。
 *
 * 对应 lib/services/update_service.dart 中的 MethodChannel("app.installer")。
 */
class MainActivity : FlutterActivity() {

    companion object {
        private const val CHANNEL = "app.installer"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "installApk" -> {
                        val path = call.argument<String>("path")
                        if (path == null) {
                            result.error("INVALID_PATH", "path is null", null)
                            return@setMethodCallHandler
                        }
                        try {
                            installApk(path)
                            result.success(null)
                        } catch (e: Exception) {
                            result.error("INSTALL_FAILED", e.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun installApk(path: String) {
        val file = File(path)
        if (!file.exists()) {
            throw IllegalArgumentException("APK not found: $path")
        }
        val authority = "$packageName.fileprovider"
        val uri = FileProvider.getUriForFile(this, authority, file)
        val intent = Intent(Intent.ACTION_VIEW).apply {
            setDataAndType(uri, "application/vnd.android.package-archive")
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        startActivity(intent)
    }
}
