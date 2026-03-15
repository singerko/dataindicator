/**
 * Správca konfigurácie aplikácie.
 *
 * Ukladá a načítava nastavenia používateľa zo SharedPreferences
 * (farby, rozmery, zarovnanie, auto‑štart, povolené aplikácie, jazyk).
 */
package sk.dataindicator.config

import android.content.Context
import android.content.SharedPreferences
import android.graphics.Color

/**
 * Singleton, ktorý drží všetky používateľské nastavenia aplikácie.
 */
class ConfigManager private constructor(context: Context) {

    companion object {
        @Volatile
        private var INSTANCE: ConfigManager? = null
        
        /**
         * Vráti jedinú inštanciu ConfigManagera.
         */
        fun getInstance(context: Context): ConfigManager {
            return INSTANCE ?: synchronized(this) {
                INSTANCE ?: ConfigManager(context.applicationContext).also { INSTANCE = it }
            }
        }
        
        // Konštanty pre kľúče
        private const val PREFS_NAME = "data_indicator_config"
        
        // Farby
        private const val KEY_WIFI_COLOR = "wifi_color"
        private const val KEY_MOBILE_COLOR = "mobile_color"
        private const val KEY_NO_INTERNET_COLOR = "no_internet_color"
        
        // Rozmery
        private const val KEY_INDICATOR_HEIGHT = "indicator_height"
        private const val KEY_INDICATOR_WIDTH_PERCENT = "indicator_width_percent"
        
        // Zarovnanie
        private const val KEY_ALIGNMENT = "alignment"
        
        // Auto-štart
        private const val KEY_AUTO_START_ENABLED = "auto_start_enabled"
        
        // Overlay aplikácie
        private const val KEY_ALLOWED_APPS = "allowed_apps"
        
        // Jazyk
        private const val KEY_LANGUAGE = "language"
        
        // Predvolené hodnoty
        const val DEFAULT_WIFI_COLOR = "#4CAF50"           // Zelená
        const val DEFAULT_MOBILE_COLOR = "#F44336"         // Červená
        const val DEFAULT_NO_INTERNET_COLOR = "#9E9E9E"    // Sivá
        const val DEFAULT_HEIGHT = 4                       // dp
        const val DEFAULT_WIDTH_PERCENT = 100              // %
        const val DEFAULT_ALIGNMENT = "center"             // center, left, right
        const val DEFAULT_AUTO_START = true                // auto-štart zapnutý predvolene
        const val DEFAULT_LANGUAGE = "system"              // system, en, sk
    }
    
    /** SharedPreferences, kde sa ukladajú nastavenia. */
    private val prefs: SharedPreferences = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
    
    // Farby
    var wifiColor: String
        get() = prefs.getString(KEY_WIFI_COLOR, DEFAULT_WIFI_COLOR) ?: DEFAULT_WIFI_COLOR
        set(value) = prefs.edit().putString(KEY_WIFI_COLOR, value).apply()
    
    var mobileColor: String
        get() = prefs.getString(KEY_MOBILE_COLOR, DEFAULT_MOBILE_COLOR) ?: DEFAULT_MOBILE_COLOR
        set(value) = prefs.edit().putString(KEY_MOBILE_COLOR, value).apply()
    
    var noInternetColor: String
        get() = prefs.getString(KEY_NO_INTERNET_COLOR, DEFAULT_NO_INTERNET_COLOR) ?: DEFAULT_NO_INTERNET_COLOR
        set(value) = prefs.edit().putString(KEY_NO_INTERNET_COLOR, value).apply()
    
    // Rozmery
    var indicatorHeight: Int
        get() = prefs.getInt(KEY_INDICATOR_HEIGHT, DEFAULT_HEIGHT)
        set(value) = prefs.edit().putInt(KEY_INDICATOR_HEIGHT, value.coerceIn(1, 20)).apply()
    
    var indicatorWidthPercent: Int
        get() = prefs.getInt(KEY_INDICATOR_WIDTH_PERCENT, DEFAULT_WIDTH_PERCENT)
        set(value) = prefs.edit().putInt(KEY_INDICATOR_WIDTH_PERCENT, value.coerceIn(10, 100)).apply()
    
    // Zarovnanie
    var alignment: String
        get() = prefs.getString(KEY_ALIGNMENT, DEFAULT_ALIGNMENT) ?: DEFAULT_ALIGNMENT
        set(value) = prefs.edit().putString(KEY_ALIGNMENT, value).apply()
    
    // Auto-štart
    var isAutoStartEnabled: Boolean
        get() = prefs.getBoolean(KEY_AUTO_START_ENABLED, DEFAULT_AUTO_START)
        set(value) = prefs.edit().putBoolean(KEY_AUTO_START_ENABLED, value).apply()
    
    // Povolené aplikácie (uložené ako Set<String> s package names)
    var allowedApps: Set<String>
        get() = prefs.getStringSet(KEY_ALLOWED_APPS, emptySet()) ?: emptySet()
        set(value) = prefs.edit().putStringSet(KEY_ALLOWED_APPS, value).apply()
    
    // Jazyk aplikácie
    var language: String
        get() = prefs.getString(KEY_LANGUAGE, DEFAULT_LANGUAGE) ?: DEFAULT_LANGUAGE
        set(value) = prefs.edit().putString(KEY_LANGUAGE, value).apply()
    
    // Pomocné metódy
    /**
     * Vráti farbu pre daný typ siete ako Android Color int.
     */
    fun getColorForState(networkType: sk.dataindicator.service.NetworkStateService.NetworkType): Int {
        val colorString = when (networkType) {
            sk.dataindicator.service.NetworkStateService.NetworkType.WIFI -> wifiColor
            sk.dataindicator.service.NetworkStateService.NetworkType.MOBILE_DATA -> mobileColor
            sk.dataindicator.service.NetworkStateService.NetworkType.NO_INTERNET -> noInternetColor
        }
        return try {
            Color.parseColor(colorString)
        } catch (e: IllegalArgumentException) {
            // Fallback na predvolenú farbu
            when (networkType) {
                sk.dataindicator.service.NetworkStateService.NetworkType.WIFI -> Color.parseColor(DEFAULT_WIFI_COLOR)
                sk.dataindicator.service.NetworkStateService.NetworkType.MOBILE_DATA -> Color.parseColor(DEFAULT_MOBILE_COLOR)
                sk.dataindicator.service.NetworkStateService.NetworkType.NO_INTERNET -> Color.parseColor(DEFAULT_NO_INTERNET_COLOR)
            }
        }
    }
    
    /**
     * Prepočíta zarovnanie pásika na Android Gravity.
     */
    fun getGravityForAlignment(): Int {
        return when (alignment) {
            "left" -> android.view.Gravity.TOP or android.view.Gravity.START
            "right" -> android.view.Gravity.TOP or android.view.Gravity.END
            else -> android.view.Gravity.TOP or android.view.Gravity.CENTER_HORIZONTAL
        }
    }
    
    /**
     * Vráti všetky nastavenia na predvolené hodnoty.
     */
    fun resetToDefaults() {
        prefs.edit().clear().apply()
    }
    
    /**
     * Overí, či je reťazec platná farba (napr. `#FF0000`).
     */
    fun isValidColor(color: String): Boolean {
        return try {
            Color.parseColor(color)
            true
        } catch (e: IllegalArgumentException) {
            false
        }
    }
    
    // Metódy pre prácu s povolenými aplikáciami
    /**
     * Zistí, či je daná aplikácia povolená pre overlay.
     */
    fun isAppAllowed(packageName: String): Boolean {
        val allowed = allowedApps
        // Ak nie sú nastavené žiadne aplikácie, zobraziť všade
        // Ak sú nastavené aplikácie, zobraziť iba pre vybrané
        return if (allowed.isEmpty()) {
            true  // Zobraz všade
        } else {
            allowed.contains(packageName)  // Zobraz iba pre vybrané
        }
    }
    
    /**
     * Pridá aplikáciu do zoznamu povolených.
     */
    fun addAllowedApp(packageName: String) {
        val current = allowedApps.toMutableSet()
        current.add(packageName)
        allowedApps = current
    }
    
    /**
     * Odstráni aplikáciu zo zoznamu povolených.
     */
    fun removeAllowedApp(packageName: String) {
        val current = allowedApps.toMutableSet()
        current.remove(packageName)
        allowedApps = current
    }
    
    /**
     * Vymaže celý zoznam povolených aplikácií.
     */
    fun clearAllowedApps() {
        allowedApps = emptySet()
    }
}
