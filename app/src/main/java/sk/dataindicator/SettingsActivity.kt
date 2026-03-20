/**
 * Obrazovka s nastaveniami overlay indikátora.
 *
 * Používateľ tu vie meniť farby, veľkosť a zarovnanie indikátora,
 * zvoliť jazyk aplikácie a otestovať zobrazovanie pásika.
 */
package sk.dataindicator

import android.content.Intent
import android.graphics.Color
import android.os.Bundle
import android.text.Editable
import android.text.TextWatcher
import android.view.View
import android.widget.*
import androidx.appcompat.app.AppCompatActivity
import androidx.appcompat.app.AppCompatDelegate
import androidx.core.os.LocaleListCompat
import sk.dataindicator.config.ConfigManager
import sk.dataindicator.service.NetworkStateService

/**
 * UI pre nastavenia vzhľadu a správania overlay indikátora.
 */
class SettingsActivity : BaseActivity() {

    private lateinit var configManager: ConfigManager
    
    // UI komponenty
    private lateinit var wifiColorEdit: EditText
    private lateinit var wifiColorPreview: View
    private lateinit var mobileColorEdit: EditText
    private lateinit var mobileColorPreview: View
    private lateinit var noInternetColorEdit: EditText
    private lateinit var noInternetColorPreview: View
    
    private lateinit var heightSlider: SeekBar
    private lateinit var heightValue: TextView
    private lateinit var widthSlider: SeekBar
    private lateinit var widthValue: TextView
    
    private lateinit var alignmentSpinner: Spinner
    private lateinit var languageSpinner: Spinner
    
    private lateinit var previewIndicator: View
    private lateinit var autoStartSwitch: Switch
    
    /**
     * Inicializuje obrazovku a načíta uložené nastavenia.
     */
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_settings)
        setupBottomNavigation()
        
        configManager = ConfigManager.getInstance(this)
        
        initViews()
        setupListeners()
        loadCurrentSettings()
        updatePreview()
        
        // Nastavenie ActionBar
        supportActionBar?.title = getString(R.string.settings_title)
        supportActionBar?.setDisplayHomeAsUpEnabled(true)
    }
    
    /**
     * Nájde UI prvky a nastaví základné ovládače.
     */
    private fun initViews() {
        // Farby
        wifiColorEdit = findViewById(R.id.wifiColorEdit)
        wifiColorPreview = findViewById(R.id.wifiColorPreview)
        mobileColorEdit = findViewById(R.id.mobileColorEdit)
        mobileColorPreview = findViewById(R.id.mobileColorPreview)
        noInternetColorEdit = findViewById(R.id.noInternetColorEdit)
        noInternetColorPreview = findViewById(R.id.noInternetColorPreview)
        
        // Rozmery
        heightSlider = findViewById(R.id.heightSlider)
        heightValue = findViewById(R.id.heightValue)
        widthSlider = findViewById(R.id.widthSlider)
        widthValue = findViewById(R.id.widthValue)
        
        // Zarovnanie
        alignmentSpinner = findViewById(R.id.alignmentSpinner)
        
        // Jazyk
        languageSpinner = findViewById(R.id.languageSpinner)
        
        // Preview
        previewIndicator = findViewById(R.id.previewIndicator)

        // Auto-štart
        autoStartSwitch = findViewById(R.id.autoStartSwitch)
        autoStartSwitch.isChecked = configManager.isAutoStartEnabled
        autoStartSwitch.setOnCheckedChangeListener { _, isChecked ->
            configManager.isAutoStartEnabled = isChecked
        }
        
        // Spinners setup
        setupAlignmentSpinner()
        setupLanguageSpinner()
        
        // Tlačidlá
        findViewById<Button>(R.id.saveButton).setOnClickListener { saveSettings() }
        findViewById<Button>(R.id.resetButton).setOnClickListener { resetSettings() }
    }
    
    /**
     * Pridá listener-y pre zmeny v UI a aktualizuje preview.
     */
    private fun setupListeners() {
        // Color watchers
        wifiColorEdit.addTextChangedListener(createColorWatcher(wifiColorPreview))
        mobileColorEdit.addTextChangedListener(createColorWatcher(mobileColorPreview))
        noInternetColorEdit.addTextChangedListener(createColorWatcher(noInternetColorPreview))
        
        // Height slider
        heightSlider.setOnSeekBarChangeListener(object : SeekBar.OnSeekBarChangeListener {
            override fun onProgressChanged(seekBar: SeekBar?, progress: Int, fromUser: Boolean) {
                val height = progress + 1 // 1-20 dp
                heightValue.text = "${height} dp"
                updatePreview()
            }
            override fun onStartTrackingTouch(seekBar: SeekBar?) {}
            override fun onStopTrackingTouch(seekBar: SeekBar?) {}
        })
        
        // Width slider
        widthSlider.setOnSeekBarChangeListener(object : SeekBar.OnSeekBarChangeListener {
            override fun onProgressChanged(seekBar: SeekBar?, progress: Int, fromUser: Boolean) {
                val width = (progress + 1) * 5 // 5-100% (krok 5%)
                widthValue.text = "${width}%"
                updatePreview()
                
                // Povoliť/zakázať alignment spinner
                alignmentSpinner.isEnabled = width < 100
            }
            override fun onStartTrackingTouch(seekBar: SeekBar?) {}
            override fun onStopTrackingTouch(seekBar: SeekBar?) {}
        })
        
        // Alignment spinner
        val alignmentAdapter = ArrayAdapter.createFromResource(
            this,
            R.array.alignment_options,
            android.R.layout.simple_spinner_item
        )
        alignmentAdapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item)
        alignmentSpinner.adapter = alignmentAdapter
        
        alignmentSpinner.onItemSelectedListener = object : AdapterView.OnItemSelectedListener {
            override fun onItemSelected(parent: AdapterView<*>?, view: View?, position: Int, id: Long) {
                updatePreview()
            }
            override fun onNothingSelected(parent: AdapterView<*>?) {}
        }
    }
    
    /**
     * Vytvorí TextWatcher, ktorý validuje farbu a aktualizuje preview.
     */
    private fun createColorWatcher(preview: View): TextWatcher {
        return object : TextWatcher {
            override fun beforeTextChanged(s: CharSequence?, start: Int, count: Int, after: Int) {}
            override fun onTextChanged(s: CharSequence?, start: Int, before: Int, count: Int) {}
            override fun afterTextChanged(s: Editable?) {
                val colorString = s.toString()
                if (configManager.isValidColor(colorString)) {
                    try {
                        preview.setBackgroundColor(Color.parseColor(colorString))
                        updatePreview()
                    } catch (e: Exception) {
                        preview.setBackgroundColor(Color.GRAY)
                    }
                } else {
                    preview.setBackgroundColor(Color.GRAY)
                }
            }
        }
    }
    
    /**
     * Načíta aktuálne nastavenia z ConfigManagera do UI.
     */
    private fun loadCurrentSettings() {
        // Farby
        wifiColorEdit.setText(configManager.wifiColor)
        mobileColorEdit.setText(configManager.mobileColor)
        noInternetColorEdit.setText(configManager.noInternetColor)
        
        // Rozmery
        heightSlider.progress = configManager.indicatorHeight - 1
        heightValue.text = "${configManager.indicatorHeight} dp"
        
        val widthProgress = (configManager.indicatorWidthPercent / 5) - 1
        widthSlider.progress = widthProgress
        widthValue.text = "${configManager.indicatorWidthPercent}%"
        
        // Zarovnanie
        val alignmentPosition = when (configManager.alignment) {
            "left" -> 0
            "center" -> 1
            "right" -> 2
            else -> 1
        }
        alignmentSpinner.setSelection(alignmentPosition)
        alignmentSpinner.isEnabled = configManager.indicatorWidthPercent < 100
        
        // Jazyk
        val languagePosition = when (configManager.language) {
            "en" -> 0
            "sk" -> 1
            else -> 0 // default to English
        }
        languageSpinner.setSelection(languagePosition)
    }
    
    /**
     * Aktualizuje vizuálny preview pásika podľa aktuálnych hodnôt.
     */
    private fun updatePreview() {
        val height = (heightSlider.progress + 1) * resources.displayMetrics.density
        val widthPercent = (widthSlider.progress + 1) * 5
        val screenWidth = resources.displayMetrics.widthPixels
        val width = (screenWidth * widthPercent / 100f).toInt()
        
        val layoutParams = previewIndicator.layoutParams
        layoutParams.height = height.toInt()
        layoutParams.width = width
        previewIndicator.layoutParams = layoutParams
        
        // Farba preview (použije WiFi farbu)
        val wifiColor = wifiColorEdit.text.toString()
        if (configManager.isValidColor(wifiColor)) {
            previewIndicator.setBackgroundColor(Color.parseColor(wifiColor))
        }
        
        // Zarovnanie preview
        val parentLayout = previewIndicator.parent as? LinearLayout
        parentLayout?.let { _ ->
            val alignment = when (alignmentSpinner.selectedItemPosition) {
                0 -> android.view.Gravity.START  // left
                2 -> android.view.Gravity.END    // right
                else -> android.view.Gravity.CENTER_HORIZONTAL // center
            }
            val params = previewIndicator.layoutParams as LinearLayout.LayoutParams
            params.gravity = alignment
            previewIndicator.layoutParams = params
        }
    }
    
    /**
     * Uloží nastavenia do ConfigManagera a reštartuje službu.
     */
    private fun saveSettings() {
        // Uloženie farieb
        if (configManager.isValidColor(wifiColorEdit.text.toString())) {
            configManager.wifiColor = wifiColorEdit.text.toString()
        }
        if (configManager.isValidColor(mobileColorEdit.text.toString())) {
            configManager.mobileColor = mobileColorEdit.text.toString()
        }
        if (configManager.isValidColor(noInternetColorEdit.text.toString())) {
            configManager.noInternetColor = noInternetColorEdit.text.toString()
        }
        
        // Uloženie rozmerov
        configManager.indicatorHeight = heightSlider.progress + 1
        configManager.indicatorWidthPercent = (widthSlider.progress + 1) * 5
        
        // Uloženie zarovnania
        configManager.alignment = when (alignmentSpinner.selectedItemPosition) {
            0 -> "left"
            2 -> "right"
            else -> "center"
        }
        
        // Uloženie jazyka
        configManager.language = when (languageSpinner.selectedItemPosition) {
            0 -> "en"
            1 -> "sk"
            else -> "en"
        }
        
        Toast.makeText(this, getString(R.string.settings_saved), Toast.LENGTH_SHORT).show()
        
        // Restart služby ak beží
        restartServiceIfRunning()
        
        finish()
    }
    
    /**
     * Obnoví predvolené nastavenia a obnoví UI.
     */
    private fun resetSettings() {
        configManager.resetToDefaults()
        loadCurrentSettings()
        updatePreview()
        Toast.makeText(this, getString(R.string.settings_reset), Toast.LENGTH_SHORT).show()
    }
    
    /**
     * Spustí krátky test indikátora na 5 sekúnd.
     */
    /**
     * Reštartuje službu, aby sa nové nastavenia prejavili.
     */
    private fun restartServiceIfRunning() {
        // Restart služby ak beží (implementácia závisí od toho, ako sledujeme stav služby)
        val stopIntent = Intent(this, NetworkStateService::class.java).apply {
            action = NetworkStateService.ACTION_STOP
        }
        startService(stopIntent)
        
        // Krátka pauza pred reštartom
        android.os.Handler(mainLooper).postDelayed({
            val startIntent = Intent(this, NetworkStateService::class.java).apply {
                action = NetworkStateService.ACTION_START
            }
            startForegroundService(startIntent)
        }, 500)
    }
    
    /**
     * Pripraví spinner pre výber zarovnania pásika.
     */
    private fun setupAlignmentSpinner() {
        val alignmentAdapter = ArrayAdapter.createFromResource(
            this,
            R.array.alignment_options,
            android.R.layout.simple_spinner_item
        )
        alignmentAdapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item)
        alignmentSpinner.adapter = alignmentAdapter
    }
    
    /**
     * Pripraví spinner pre výber jazyka a spracuje zmenu.
     */
    private fun setupLanguageSpinner() {
        val languageAdapter = ArrayAdapter.createFromResource(
            this,
            R.array.language_options,
            android.R.layout.simple_spinner_item
        )
        languageAdapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item)
        languageSpinner.adapter = languageAdapter
        
        languageSpinner.onItemSelectedListener = object : AdapterView.OnItemSelectedListener {
            override fun onItemSelected(parent: AdapterView<*>?, view: View?, position: Int, id: Long) {
                val newLanguage = when (position) {
                    0 -> "en"
                    1 -> "sk"
                    else -> "en"
                }
                
                // Ak sa jazyk zmenil, okamžite ho aplikuj
                if (newLanguage != configManager.language) {
                    configManager.language = newLanguage
                    applyLanguage(newLanguage)
                }
            }
            override fun onNothingSelected(parent: AdapterView<*>?) {}
        }
    }
    
    /**
     * Aplikuje nový jazyk a znovu vytvorí aktivitu.
     */
    private fun applyLanguage(languageCode: String) {
        // Nastaví jazyk pre celú aplikáciu pomocou AppCompatDelegate.
        // Systém potom znovu vytvorí aktivity, aby sa načítali nové texty.
        val locales = if (languageCode == "system") {
            LocaleListCompat.getEmptyLocaleList()
        } else {
            LocaleListCompat.forLanguageTags(languageCode)
        }
        AppCompatDelegate.setApplicationLocales(locales)
    }

    /**
     * Navigácia späť v ActionBar.
     */
    override fun onSupportNavigateUp(): Boolean {
        onBackPressedDispatcher.onBackPressed()
        return true
    }
}
