package com.alnlabs.myplanr

import android.content.Intent
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.activity.result.contract.ActivityResultContracts
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "com.alnlabs.myplanr/notification_sounds"
    private var pendingPickResult: MethodChannel.Result? = null

    private val ringtonePickerLauncher =
        registerForActivityResult(ActivityResultContracts.StartActivityForResult()) { result ->
            val pending = pendingPickResult
            pendingPickResult = null
            if (pending == null) return@registerForActivityResult

            if (result.resultCode != RESULT_OK) {
                pending.success(null)
                return@registerForActivityResult
            }

            val uri: Uri? =
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    result.data?.getParcelableExtra(
                        RingtoneManager.EXTRA_RINGTONE_PICKED_URI,
                        Uri::class.java,
                    )
                } else {
                    @Suppress("DEPRECATION")
                    result.data?.getParcelableExtra(RingtoneManager.EXTRA_RINGTONE_PICKED_URI)
                }

            if (uri == null) {
                pending.success(null)
                return@registerForActivityResult
            }

            val ringtone = RingtoneManager.getRingtone(applicationContext, uri)
            val title = ringtone?.getTitle(applicationContext)
            pending.success(
                mapOf(
                    "uri" to uri.toString(),
                    "title" to title,
                ),
            )
        }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "pickNotificationSound" -> {
                        if (pendingPickResult != null) {
                            result.error("busy", "Sound picker already open", null)
                            return@setMethodCallHandler
                        }
                        pendingPickResult = result
                        val currentUri = call.argument<String>("currentUri")
                        launchRingtonePicker(currentUri)
                    }

                    "getRingtoneTitle" -> {
                        val uriString = call.argument<String>("uri")
                        if (uriString.isNullOrEmpty()) {
                            result.success(null)
                            return@setMethodCallHandler
                        }
                        val ringtone =
                            RingtoneManager.getRingtone(applicationContext, Uri.parse(uriString))
                        result.success(ringtone?.getTitle(applicationContext))
                    }

                    "openAppNotificationSettings" -> {
                        val intent =
                            Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS).apply {
                                putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
                            }
                        startActivity(intent)
                        result.success(null)
                    }

                    else -> result.notImplemented()
                }
            }
    }

    private fun launchRingtonePicker(currentUri: String?) {
        val intent =
            Intent(RingtoneManager.ACTION_RINGTONE_PICKER).apply {
                putExtra(RingtoneManager.EXTRA_RINGTONE_TYPE, RingtoneManager.TYPE_NOTIFICATION)
                putExtra(RingtoneManager.EXTRA_RINGTONE_SHOW_DEFAULT, true)
                putExtra(RingtoneManager.EXTRA_RINGTONE_SHOW_SILENT, true)
                putExtra(
                    RingtoneManager.EXTRA_RINGTONE_DEFAULT_URI,
                    RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION),
                )
                if (!currentUri.isNullOrEmpty()) {
                    putExtra(RingtoneManager.EXTRA_RINGTONE_EXISTING_URI, Uri.parse(currentUri))
                }
            }
        ringtonePickerLauncher.launch(intent)
    }
}
