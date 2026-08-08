package de.lukas.multiapp

import android.app.KeyguardManager
import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.media.RingtoneManager
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

    private val mainHandler = Handler(Looper.getMainLooper())
    private var vibrationStop: Runnable? = null
    private var showWhenLockedStop: Runnable? = null
    private var alarmPlayer: MediaPlayer? = null
    private var alarmSoundStop: Runnable? = null

    companion object {
        /// Spaetestens danach gilt wieder der Normalfall, egal was passiert.
        /// Der laengste einstellbare Wecker-Timeout sind 10 Minuten.
        private const val SHOW_WHEN_LOCKED_MAX_MILLIS = 15L * 60 * 1000
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Nur wenn eine Erinnerung die App geweckt hat, darf sie ueber dem
        // Sperrbildschirm erscheinen. Sonst waere die ganze App bei gesperrtem
        // Telefon bedienbar.
        applyShowWhenLocked(isReminderLaunch(intent))
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        // Laeuft die App schon, kommt die Erinnerung hier herein.
        if (isReminderLaunch(intent)) applyShowWhenLocked(true)
    }

    override fun onStop() {
        // Ist die App nicht mehr sichtbar, gilt wieder der Normalfall: hinter
        // dem Sperrbildschirm.
        applyShowWhenLocked(false)
        super.onStop()
    }

    /// Wurde die Activity von einer Medikamenten-Erinnerung gestartet?
    ///
    /// flutter_local_notifications haengt die Nutzlast als "payload" an das
    /// Intent; unsere Erinnerungen beginnen mit "med:".
    private fun isReminderLaunch(intent: Intent?): Boolean {
        val payload = intent?.getStringExtra("payload") ?: return false
        return payload.startsWith("med:")
    }

    /// Erlaubt oder verbietet die Anzeige ueber dem Sperrbildschirm.
    ///
    /// Bewusst ohne requestDismissKeyguard: ein Wecker soll ueber der Sperre
    /// erscheinen, sie aber nicht aufheben. Das Telefon bleibt gesperrt.
    ///
    /// Solange das Recht gesetzt ist, haelt Android die Activity sichtbar und
    /// ruft kein onStop auf. Bleibt der Wecker-Schirm also aus irgendeinem
    /// Grund offen, wuerde das Recht nicht zurueckgenommen. Deshalb laeuft es
    /// zusaetzlich nach [SHOW_WHEN_LOCKED_MAX_MILLIS] von selbst ab.
    /// Beendet die Wecker-Anzeige und geht hinter den Sperrbildschirm zurueck.
    ///
    /// Das Zuruecknehmen des Rechts allein genuegt nicht: es entscheidet nur,
    /// ob eine Activity ueber der Sperre erscheinen DARF. Steht sie schon da,
    /// bleibt sie stehen und waere weiter bedienbar. Deshalb wird die App bei
    /// gesperrtem Telefon aktiv in den Hintergrund geschickt; ist das Telefon
    /// entsperrt, bleibt alles wie es ist.
    private fun endAlarmPresentation() {
        applyShowWhenLocked(false)
        val keyguard = getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager
        if (keyguard.isKeyguardLocked) moveTaskToBack(true)
    }

    private fun applyShowWhenLocked(allow: Boolean) {
        showWhenLockedStop?.let { mainHandler.removeCallbacks(it) }
        showWhenLockedStop = null
        if (allow) {
            // Notbremse: greift auch, wenn der Wecker-Schirm nie schliesst.
            showWhenLockedStop = Runnable { endAlarmPresentation() }
            mainHandler.postDelayed(
                showWhenLockedStop!!,
                SHOW_WHEN_LOCKED_MAX_MILLIS
            )
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(allow)
            setTurnScreenOn(allow)
        } else {
            @Suppress("DEPRECATION")
            val flags = WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON
            if (allow) window.addFlags(flags) else window.clearFlags(flags)
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
                    // Spielt den Weckerton selbst ab. Ueber den
                    // Benachrichtigungskanal bleibt er bei stummem Telefon
                    // still, ueber den Alarm-Kanal nicht.
                    "startAlarmSound" -> {
                        val maxMillis = call.argument<Int>("maxMillis") ?: 120_000
                        startAlarmSound(maxMillis.toLong())
                        result.success(null)
                    }
                    "stopAlarmSound" -> {
                        stopAlarmSound()
                        result.success(null)
                    }
                    // Wird vom Wecker-Schirm gesetzt und beim Schliessen
                    // wieder zurueckgenommen: laeuft die App bereits, kommt
                    // die Erinnerung nicht ueber onCreate herein.
                    "setShowWhenLocked" -> {
                        applyShowWhenLocked(call.argument<Boolean>("allow") == true)
                        result.success(null)
                    }
                    "endAlarmPresentation" -> {
                        endAlarmPresentation()
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
        mainHandler.postDelayed(vibrationStop!!, maxMillis)
    }

    /// Weckerton in Dauerschleife ueber den Alarm-Kanal.
    ///
    /// Bewusst der Standard-Weckerton des Geraets: kein eigenes Tonmaterial
    /// im Paket, und der Nutzer kennt den Klang.
    private fun startAlarmSound(maxMillis: Long) {
        stopAlarmSound()
        val uri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
            ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
            ?: return

        try {
            alarmPlayer = MediaPlayer().apply {
                setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_ALARM)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .build()
                )
                setDataSource(this@MainActivity, uri)
                isLooping = true
                prepare()
                start()
            }
        } catch (error: Exception) {
            // Kein Ton verfuegbar: die Erinnerung erscheint trotzdem.
            alarmPlayer = null
            return
        }

        // Dieselbe Notbremse wie bei der Vibration.
        alarmSoundStop = Runnable { stopAlarmSound() }
        mainHandler.postDelayed(alarmSoundStop!!, maxMillis)
    }

    private fun stopAlarmSound() {
        alarmSoundStop?.let { mainHandler.removeCallbacks(it) }
        alarmSoundStop = null
        alarmPlayer?.let { player ->
            try {
                if (player.isPlaying) player.stop()
            } catch (_: Exception) {
                // Schon beendet.
            }
            player.release()
        }
        alarmPlayer = null
    }

    private fun stopAlarmVibration() {
        vibrationStop?.let { mainHandler.removeCallbacks(it) }
        vibrationStop = null
        try {
            vibrator().cancel()
        } catch (_: Exception) {
            // Kein Vibrator vorhanden: nichts zu tun.
        }
    }

    override fun onPause() {
        super.onPause()
        // Verlaesst der Nutzer den Wecker-Schirm, hoeren Ton und Vibration auf.
        stopAlarmVibration()
        stopAlarmSound()
    }

    override fun onDestroy() {
        stopAlarmVibration()
        stopAlarmSound()
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
