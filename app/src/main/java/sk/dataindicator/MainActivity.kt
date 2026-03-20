/**
 * Hlavná obrazovka aplikácie.
 *
 * Monitorovanie sa ovláda jedným prepínačom (SwitchMaterial).
 * Navigácia na ostatné sekcie cez spodnú lištu.
 */
package sk.dataindicator

import android.os.Build
import android.content.Context
import android.content.Intent
import android.content.pm.PackageInfo
import android.content.pm.ShortcutManager
import android.graphics.drawable.Icon
import android.os.Bundle
import android.widget.TextView
import android.widget.Toast
import androidx.activity.result.contract.ActivityResultContracts
import androidx.appcompat.app.AlertDialog
import com.google.android.material.switchmaterial.SwitchMaterial
import sk.dataindicator.service.NetworkStateService
import sk.dataindicator.utils.PermissionUtils

class MainActivity : BaseActivity() {

    private lateinit var versionText: TextView
    private lateinit var statusText: TextView
    private lateinit var monitoringSwitch: SwitchMaterial

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

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        initViews()
        checkPermissions()
        maybeOfferHomeScreenShortcut()
    }

    private fun initViews() {
        versionText = findViewById(R.id.versionText)
        statusText = findViewById(R.id.statusText)
        monitoringSwitch = findViewById(R.id.monitoringSwitch)

        versionText.text = getAppVersionLabel()

        monitoringSwitch.setOnCheckedChangeListener { _, isChecked ->
            if (isChecked) startNetworkMonitoring() else stopNetworkMonitoring()
        }

        setupBottomNavigation()
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

    private fun checkPermissions() {
        if (!PermissionUtils.hasOverlayPermission(this)) {
            statusText.text = getString(R.string.permission_overlay_needed)
            monitoringSwitch.isEnabled = false
            overlayPermissionLauncher.launch(PermissionUtils.createOverlayPermissionIntent(this))
        } else {
            monitoringSwitch.isEnabled = true
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

    private fun startNetworkMonitoring() {
        if (PermissionUtils.hasEssentialPermissions(this)) {
            val serviceIntent = Intent(this, NetworkStateService::class.java).apply {
                action = NetworkStateService.ACTION_START
            }
            startForegroundService(serviceIntent)
            statusText.text = getString(R.string.status_running)
            Toast.makeText(this, getString(R.string.start_monitoring), Toast.LENGTH_SHORT).show()
            moveTaskToBack(true)
        } else {
            // Nie sú povolenia – vrátiť prepínač späť
            monitoringSwitch.setOnCheckedChangeListener(null)
            monitoringSwitch.isChecked = false
            monitoringSwitch.setOnCheckedChangeListener { _, isChecked ->
                if (isChecked) startNetworkMonitoring() else stopNetworkMonitoring()
            }
            Toast.makeText(this, getString(R.string.permission_overlay_needed), Toast.LENGTH_SHORT).show()
            checkPermissions()
        }
    }

    private fun stopNetworkMonitoring() {
        val serviceIntent = Intent(this, NetworkStateService::class.java).apply {
            action = NetworkStateService.ACTION_STOP
        }
        startService(serviceIntent)
        statusText.text = getString(R.string.status_ready)
        Toast.makeText(this, getString(R.string.stop_monitoring), Toast.LENGTH_SHORT).show()
    }

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
}
