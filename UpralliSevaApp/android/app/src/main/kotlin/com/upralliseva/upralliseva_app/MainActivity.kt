package com.upralliseva.upralliseva_app

import android.content.Intent
import android.net.Uri
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val channelName = "app/share"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "whatsapp" -> shareToWhatsApp(call.argument("path"), call.argument("package"), result)
                    else -> result.notImplemented()
                }
            }
    }

    private fun shareToWhatsApp(path: String?, pkg: String?, result: MethodChannel.Result) {
        if (path == null) {
            result.error("no_path", "path required", null); return
        }
        try {
            val file = File(path)
            val uri: Uri = FileProvider.getUriForFile(this, "$packageName.fileprovider", file)
            val intent = Intent(Intent.ACTION_SEND).apply {
                type = "application/pdf"
                putExtra(Intent.EXTRA_STREAM, uri)
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                setPackage(pkg ?: "com.whatsapp")
            }
            intent.flags = intent.flags or Intent.FLAG_ACTIVITY_NEW_TASK
            startActivity(intent)
            result.success(true)
        } catch (e: Exception) {
            // WhatsApp ಇಲ್ಲ ಅಥವಾ ದೋಷ — Dart ನಲ್ಲಿ fallback ಆಗುತ್ತದೆ
            result.error("failed", e.message, null)
        }
    }
}
