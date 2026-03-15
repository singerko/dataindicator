/**
 * Hlavná obrazovka aplikácie.
 *
 * Umožňuje používateľovi spustiť/stopnúť overlay indikátor,
 * otvoriť nastavenia a konfiguráciu aplikácií.
 */
package sk.dataindicator

import android.os.Build
import android.content.Context
import android.content.Intent
import android.content.pm.PackageInfo
import android.content.pm.ShortcutManager
import android.graphics.drawable.Icon
import android.os.Bundle
import android.widget.Button
import android.widget.TextView
import android.widget.Toast
import androidx.activity.result.contract.ActivityResultContracts
import androidx.appcompat.app.AlertDialog
import sk.dataindicator.service.NetworkStateService
import sk.dataindicator.utils.PermissionUtils

/**
 * UI pre ovládanie služby, ktorá zobrazuje indikátor siete.
 */
class MainActivity : BaseActivity() {

    private lateinit var versionText: TextView
    private lateinit var statusText: TextView
    private lateinit var startButton: Button
    private lateinit var stopButton: Button
    private lateinit var settingsButton: Button
    private lateinit var appConfigButton: Button

    companion object {
        private const val SHORTCUT_PREFS = "main_ui_prefs"
        private const val KEY_SHORTCUT_PROMPT_SHOWN = "shortcut_prompt_shown"
        private const val HOME_SHORTCUT_ID = "data_indicator_home_shortcut"
    }

    private val overlayPermissionLauncher =
        registerForActivityResult(ActivityResultContracts.StartActivityForResult()) {
            checkPermissions()
        }

    private val notificationPermissionLauncher =
        registerForActivityResult(ActivityResultContracts.RequestPermission()) {
            checkPermissions()
        }
    
    /**
     * Inicializuje UI a skontroluje potrebné povolenia.
     */
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)
        
        initViews()
        checkPermissions()
        maybeOfferHomeScreenShortcut()
    }
    
    /**
     * Nájde UI prvky a priradí obsluhu tlačidiel.
     */
    private fun initViews() {
        versionText = findViewById(R.id.versionText)
        statusText = findViewById(R.id.statusText)
        startButton = findViewById(R.id.startButton)
        stopButton = findViewById(R.id.stopButton)
        settingsButton = findViewById(R.id.settingsButton)
        appConfigButton = findViewById(R.id.appConfigButton)

        versionText.text = getAppVersionLabel()
        
        startButton.setOnClickListener {
            startNetworkMonitoring()
        }
        
        stopButton.setOnClickListener {
            stopNetworkMonitoring()
        }
        
        settingsButton.setOnClickListener {
            startActivity(Intent(this, SettingsActivity::class.java))
        }
        
        appConfigButton.setOnClickListener {
            startActivity(Intent(this, AppConfigActivity::class.java))
        }
    }

    private fun getAppVersionLabel(): String {
        val packageInfo: PackageInfo = packageManager.getPackageInfo(packageName, 0)
        val versionName = packageInfo.versionName ?: "?"
        val versionCode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            packageInfo.longVersionCode
        } else {
            @Suppress("DEPRECATION")
            packageInfo.versionCode.toLong()
        }
        return getString(R.string.app_version_format, versionName, versionCode)
    }

    /**
     * Pri prvom spustení ponúkne používateľovi pridať appku na domovskú obrazovku.
     */
    private fun maybeOfferHomeScreenShortcut() {
        val prefs = getSharedPreferences(SHORTCUT_PREFS, Context.MODE_PRIVATE)
        if (prefs.getBoolean(KEY_SHORTCUT_PROMPT_SHOWN, false)) return

        val shortcutManager = getSystemService(ShortcutManager::class.java) ?: return
        val alreadyPinned = shortcutManager.pinnedShortcuts.any { it.id == HOME_SHORTCUT_ID }
        if (alreadyPinned || !shortcutManager.isRequestPinShortcutSupported) {
            prefs.edit().putBoolean(KEY_SHORTCUT_PROMPT_SHOWN, true).apply()
            return
        }

        AlertDialog.Builder(this)
            .setTitle(R.string.add_home_shortcut_title)
            .setMessage(R.string.add_home_shortcut_message)
            .setPositiveButton(R.string.add_home_shortcut_confirm) { _, _ ->
                requestHomeScreenShortcut(shortcutManager)
                prefs.edit().putBoolean(KEY_SHORTCUT_PROMPT_SHOWN, true).apply()
            }
            .setNegativeButton(R.string.add_home_shortcut_later) { _, _ ->
                prefs.edit().putBoolean(KEY_SHORTCUT_PROMPT_SHOWN, true).apply()
            }
            .show()
    }

    /**
     * Požiada launcher o pripnutie skratky appky na domovskú obrazovku.
     */
    private fun requestHomeScreenShortcut(shortcutManager: ShortcutManager) {
        val shortcutIntent = Intent(this, MainActivity::class.java).apply {
            action = Intent.ACTION_MAIN
        }

        val pinShortcut = android.content.pm.ShortcutInfo.Builder(this, HOME_SHORTCUT_ID)
            .setShortLabel(getString(R.string.app_name))
            .setIcon(Icon.createWithResource(this, R.mipmap.ic_launcher))
            .setIntent(shortcutIntent)
            .build()

        shortcutManager.requestPinShortcut(pinShortcut, null)
    }
    
    /**
     * Skontroluje overlay a notifikačné povolenia a upraví stav UI.
     */
    private fun checkPermissions() {
        if (!PermissionUtils.hasOverlayPermission(this)) {
            statusText.text = getString(R.string.permission_overlay_needed)
            startButton.isEnabled = false
            overlayPermissionLauncher.launch(PermissionUtils.createOverlayPermissionIntent(this))
        } else {
            startButton.isEnabled = true
            if (!PermissionUtils.hasNotificationPermission(this)) {
                statusText.text = getString(R.string.permission_notification_needed)
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    notificationPermissionLauncher.launch(PermissionUtils.notificationPermissionName())
                }
            } else {
                statusText.text = getString(R.string.status_ready)
            }
        }
    }
    
    /**
     * Spustí foreground službu, ktorá zobrazuje indikátor siete.
     */
    private fun startNetworkMonitoring() {
        if (PermissionUtils.hasEssentialPermissions(this)) {
            val serviceIntent = Intent(this, NetworkStateService::class.java).apply {
                action = NetworkStateService.ACTION_START
            }
            startForegroundService(serviceIntent)
            
            statusText.text = getString(R.string.status_running)
            startButton.isEnabled = false
            stopButton.isEnabled = true
            
            // Informovať používateľa o chýbajúcich notifikáciách
            if (!PermissionUtils.hasNotificationPermission(this)) {
                Toast.makeText(this, getString(R.string.start_monitoring), Toast.LENGTH_LONG).show()
            } else {
                Toast.makeText(this, getString(R.string.start_monitoring), Toast.LENGTH_SHORT).show()
            }
            
            // Minimalizovať aplikáciu
            moveTaskToBack(true)
        } else {
            Toast.makeText(this, getString(R.string.permission_overlay_needed), Toast.LENGTH_SHORT).show()
            checkPermissions()
        }
    }
    
    /**
     * Zastaví službu a vráti UI do pripraveného stavu.
     */
    private fun stopNetworkMonitoring() {
        val serviceIntent = Intent(this, NetworkStateService::class.java).apply {
            action = NetworkStateService.ACTION_STOP
        }
        startService(serviceIntent)
        
        statusText.text = getString(R.string.status_ready)
        startButton.isEnabled = true
        stopButton.isEnabled = false
        
        Toast.makeText(this, getString(R.string.stop_monitoring), Toast.LENGTH_SHORT).show()
    }
    
}
