package de.lukas.multiapp

import android.app.KeyguardManager
import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.provider.Settings
import android.view.WindowManager
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

// FlutterFragmentActivity statt FlutterActivity: local_auth braucht eine
// FragmentActivity, um den Biometrie-Dialog anzeigen zu koennen.
class MainActivity : FlutterFragmentActivity() {

    private val channelName = "de.lukas.multiapp/wake"
    private val installerChannelName = "de.lukas.multiapp/installer"

    private val vibrationHandler = Handler(Looper.getMainLooper())
    private var vibrationStop: Runnable? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Damit eine Vollbild-Erinnerung den Bildschirm wirklich einschaltet und
        // ueber dem Sperrbildschirm erscheint. Ohne diese Flags startet die
        // Activity zwar, der Bildschirm bleibt aber dunkel.
        allowShowWhenLockedAndTurnScreenOn()
    }

    private fun allowShowWhenLockedAndTurnScreenOn() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
            val keyguard = getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager
            keyguard.requestDismissKeyguard(this, null)
        } else {
            @Suppress("DEPRECATION")
            window.addFlags(
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                    WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
                    WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD
            )
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    // Ab Android 14 ist fuer Vollbild-Meldungen eine eigene
                    // Freigabe noetig. Davor gilt sie als erteilt.
                    "canUseFullScreenIntent" -> {
                        if (Build.VERSION.SDK_INT >= 34) {
                            val manager =
                                getSystemService(Context.NOTIFICATION_SERVICE)
                                    as NotificationManager
                            result.success(manager.canUseFullScreenIntent())
                        } else {
                            result.success(true)
                        }
                    }
                    // Ausnahme von "Bitte nicht stoeren" darf sich die App
                    // nicht selbst geben, das muss der Nutzer freischalten.
                    "canBypassDnd" -> {
                        val manager =
                            getSystemService(Context.NOTIFICATION_SERVICE)
                                as NotificationManager
                        result.success(manager.isNotificationPolicyAccessGranted)
                    }
                    "openDndAccessSettings" -> {
                        startActivity(
                            Intent(
                                Settings.ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS
                            ).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        )
                        result.success(null)
                    }
                    // Vibriert unabhaengig von den Systemeinstellungen, weil
                    // es als Wecker laeuft. maxMillis ist eine harte Grenze:
                    // selbst wenn der Stopp-Aufruf ausbleibt, ist danach Ruhe.
                    "startAlarmVibration" -> {
                        val maxMillis = call.argument<Int>("maxMillis") ?: 120_000
                        startAlarmVibration(maxMillis.toLong())
                        result.success(null)
                    }
                    "stopAlarmVibration" -> {
                        stopAlarmVibration()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }

        // Eigener Update-Kanal: heruntergeladene APK dem System-Installer
        // uebergeben (wie bei Apps, die sich selbst aktualisieren).
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, installerChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    // Prozessorarten des Geraets, beste zuerst. Damit sucht
                    // sich die App die passende der drei APKs aus.
                    "supportedAbis" -> result.success(Build.SUPPORTED_ABIS.toList())
                    "canInstallPackages" -> result.success(canInstallPackages())
                    "openInstallPermissionSettings" -> {
                        openInstallPermissionSettings()
                        result.success(null)
                    }
                    "installApk" -> {
                        val path = call.argument<String>("path")
                        if (path.isNullOrBlank()) {
                            result.error("no_path", "Kein Pfad zur APK uebergeben.", null)
                        } else {
                            try {
                                installApk(path)
                                result.success(null)
                            } catch (error: Exception) {
                                result.error("install_failed", error.message, null)
                            }
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun vibrator(): Vibrator {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val manager =
                getSystemService(Context.VIBRATOR_MANAGER_SERVICE)
                    as VibratorManager
            manager.defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
        }
    }

    /// Langes Wecker-Muster in Dauerschleife, mit Alarm-Attributen: das
    /// vibriert auch dann, wenn die Vibration fuer Benachrichtigungen aus ist.
    private fun startAlarmVibration(maxMillis: Long) {
        stopAlarmVibration()
        val device = vibrator()
        if (!device.hasVibrator()) return

        val pattern = longArrayOf(0, 800, 400, 800, 400, 800, 1200)
        val attributes = AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_ALARM)
            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
            .build()

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            // 0 = Muster von vorne wiederholen.
            device.vibrate(VibrationEffect.createWaveform(pattern, 0), attributes)
        } else {
            @Suppress("DEPRECATION")
            device.vibrate(pattern, 0, attributes)
        }

        // Notbremse: ohne sie wuerde ein verpasster Stopp-Aufruf das Geraet
        // endlos vibrieren lassen.
        vibrationStop = Runnable { stopAlarmVibration() }
        vibrationHandler.postDelayed(vibrationStop!!, maxMillis)
    }

    private fun stopAlarmVibration() {
        vibrationStop?.let { vibrationHandler.removeCallbacks(it) }
        vibrationStop = null
        try {
            vibrator().cancel()
        } catch (_: Exception) {
            // Kein Vibrator vorhanden: nichts zu tun.
        }
    }

    override fun onPause() {
        super.onPause()
        // Verlaesst der Nutzer den Wecker-Schirm, hoert auch die Vibration auf.
        stopAlarmVibration()
    }

    override fun onDestroy() {
        stopAlarmVibration()
        super.onDestroy()
    }

    // Ab Android 8 gilt die Erlaubnis je App, davor war sie eine globale
    // Systemeinstellung.
    private fun canInstallPackages(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            packageManager.canRequestPackageInstalls()
        } else {
            true
        }
    }

    private fun openInstallPermissionSettings() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val intent = Intent(
            Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES,
            Uri.parse("package:$packageName")
        ).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        startActivity(intent)
    }

    private fun installApk(path: String) {
        val file = File(path)
        if (!file.exists()) throw IllegalStateException("Datei nicht gefunden: $path")

        val uri = FileProvider.getUriForFile(this, "$packageName.updates", file)
        val intent = Intent(Intent.ACTION_VIEW).apply {
            setDataAndType(uri, "application/vnd.android.package-archive")
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        startActivity(intent)
    }
}
