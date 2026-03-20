/**
 * Obrazovka konfigurácie správania overlay.
 *
 * V always-on režime sa indikátor zobrazuje nad všetkými aplikáciami.
 * Na tejto obrazovke ostáva dostupné iba nastavenie auto-štartu.
 */
package sk.dataindicator

import android.os.Bundle
import android.widget.Switch
import android.widget.TextView
import sk.dataindicator.config.ConfigManager

/**
 * UI pre auto-štart v always-on režime.
 */
class AppConfigActivity : BaseActivity() {

    private lateinit var configManager: ConfigManager
    private lateinit var autoStartSwitch: Switch
    private lateinit var noAppsSelectedText: TextView

    /**
     * Inicializuje obrazovku a načíta stav prepínača.
     */
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_app_config)
        setupBottomNavigation()

        configManager = ConfigManager.getInstance(this)

        initViews()
        setupListeners()

        supportActionBar?.title = getString(R.string.app_config_title)
        supportActionBar?.setDisplayHomeAsUpEnabled(true)
    }

    /**
     * Nastaví prvky UI a skryje časti, ktoré sa v always-on režime nepoužívajú.
     */
    private fun initViews() {
        autoStartSwitch = findViewById(R.id.autoStartSwitch)
        noAppsSelectedText = findViewById(R.id.noAppsSelectedText)

        autoStartSwitch.isChecked = configManager.isAutoStartEnabled
        noAppsSelectedText.text = getString(R.string.always_on_overlay_info)
    }

    /**
     * Uloží zmenu auto-štartu.
     */
    private fun setupListeners() {
        autoStartSwitch.setOnCheckedChangeListener { _, isChecked ->
            configManager.isAutoStartEnabled = isChecked
        }
    }

    /**
     * Navigácia späť v ActionBar.
     */
    override fun onSupportNavigateUp(): Boolean {
        onBackPressedDispatcher.onBackPressed()
        return true
    }
}
