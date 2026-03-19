package com.example.clickpix_ramon

import android.content.Intent
import android.net.Uri
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            DELIVERY_SHARE_CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "shareToWhatsApp" -> handleShareToWhatsApp(call, result)
                "composeEmail" -> handleComposeEmail(call, result)
                else -> result.notImplemented()
            }
        }
    }

    private fun handleShareToWhatsApp(
        call: MethodCall,
        result: MethodChannel.Result,
    ) {
        val filePaths = call.argument<List<String>>("filePaths").orEmpty()
        if (filePaths.isEmpty()) {
            result.success(false)
            return
        }
        val text = call.argument<String>("text").orEmpty()
        val uris = shareableUrisFor(filePaths)
        if (uris.isEmpty()) {
            result.success(false)
            return
        }

        val targetPackage = firstInstalledPackage(
            "com.whatsapp",
            "com.whatsapp.w4b",
        )
        val intent = buildShareIntent(uris, text).apply {
            if (targetPackage != null) {
                `package` = targetPackage
                grantUrisTo(targetPackage, uris)
            }
        }

        try {
            startActivity(intent)
            result.success(true)
        } catch (_: Exception) {
            result.success(false)
        }
    }

    private fun handleComposeEmail(
        call: MethodCall,
        result: MethodChannel.Result,
    ) {
        val recipients = call.argument<List<String>>("recipients").orEmpty()
        val filePaths = call.argument<List<String>>("filePaths").orEmpty()
        if (recipients.isEmpty() || filePaths.isEmpty()) {
            result.success(false)
            return
        }

        val subject = call.argument<String>("subject").orEmpty()
        val body = call.argument<String>("body").orEmpty()
        val uris = shareableUrisFor(filePaths)
        if (uris.isEmpty()) {
            result.success(false)
            return
        }

        val emailPackages = emailPackages()
        if (emailPackages.isEmpty()) {
            result.success(false)
            return
        }

        val intents = emailPackages.map { packageName ->
            buildEmailIntent(
                packageName = packageName,
                recipients = recipients,
                subject = subject,
                body = body,
                uris = uris,
            )
        }
        val chooser = Intent.createChooser(
            intents.first(),
            "Escolha o app de e-mail",
        ).apply {
            if (intents.size > 1) {
                putExtra(
                    Intent.EXTRA_INITIAL_INTENTS,
                    intents.drop(1).toTypedArray(),
                )
            }
        }

        try {
            startActivity(chooser)
            result.success(true)
        } catch (_: Exception) {
            result.success(false)
        }
    }

    private fun buildShareIntent(
        uris: List<Uri>,
        text: String,
    ): Intent {
        val intent = if (uris.size == 1) {
            Intent(Intent.ACTION_SEND).apply {
                putExtra(Intent.EXTRA_STREAM, uris.first())
            }
        } else {
            Intent(Intent.ACTION_SEND_MULTIPLE).apply {
                putParcelableArrayListExtra(
                    Intent.EXTRA_STREAM,
                    ArrayList(uris),
                )
            }
        }
        return intent.apply {
            type = "image/*"
            putExtra(Intent.EXTRA_TEXT, text)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }
    }

    private fun buildEmailIntent(
        packageName: String,
        recipients: List<String>,
        subject: String,
        body: String,
        uris: List<Uri>,
    ): Intent {
        val intent = buildShareIntent(uris, body).apply {
            `package` = packageName
            putExtra(Intent.EXTRA_EMAIL, recipients.toTypedArray())
            putExtra(Intent.EXTRA_SUBJECT, subject)
        }
        grantUrisTo(packageName, uris)
        return intent
    }

    private fun shareableUrisFor(filePaths: List<String>): List<Uri> {
        val authority = "${applicationContext.packageName}.deliveryshare.fileprovider"
        return filePaths.mapNotNull { path ->
            val trimmed = path.trim()
            if (trimmed.isEmpty()) {
                return@mapNotNull null
            }
            val file = File(trimmed)
            if (!file.exists()) {
                return@mapNotNull null
            }
            try {
                FileProvider.getUriForFile(this, authority, file)
            } catch (_: IllegalArgumentException) {
                null
            }
        }
    }

    private fun emailPackages(): List<String> {
        val intent = Intent(Intent.ACTION_SENDTO).apply {
            data = Uri.parse("mailto:")
        }
        return packageManager
            .queryIntentActivities(intent, 0)
            .map { it.activityInfo.packageName }
            .distinct()
    }

    private fun firstInstalledPackage(vararg candidates: String): String? {
        return candidates.firstOrNull { candidate ->
            try {
                packageManager.getPackageInfo(candidate, 0)
                true
            } catch (_: Exception) {
                false
            }
        }
    }

    private fun grantUrisTo(packageName: String, uris: List<Uri>) {
        for (uri in uris) {
            grantUriPermission(
                packageName,
                uri,
                Intent.FLAG_GRANT_READ_URI_PERMISSION,
            )
        }
    }

    companion object {
        private const val DELIVERY_SHARE_CHANNEL = "clickpix_ramon/delivery_share"
    }
}
