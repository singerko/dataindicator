/**
 * RecyclerView adapter pre výber aplikácií, nad ktorými sa zobrazuje overlay.
 *
 * Zobrazuje hlavičku "všetky aplikácie" a zoznam nainštalovaných aplikácií.
 */
package sk.dataindicator.adapter

import android.content.Context
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.CheckBox
import android.widget.ImageView
import android.widget.TextView
import androidx.recyclerview.widget.RecyclerView
import sk.dataindicator.R
import sk.dataindicator.utils.AppInfo

/**
 * Adapter pre zoznam aplikácií s checkboxmi.
 */
class AppSelectionAdapter(
    private val context: Context,
    private val onAppSelected: (String, Boolean) -> Unit,
    private val onSelectAllApps: (Boolean) -> Unit
) : RecyclerView.Adapter<RecyclerView.ViewHolder>() {
    
    private var apps: List<AppInfo> = emptyList()
    private var allowedApps: Set<String> = emptySet()
    
    companion object {
        /** View type pre hlavičku. */
        private const val TYPE_HEADER = 0
        /** View type pre položku aplikácie. */
        private const val TYPE_APP = 1
    }
    
    /**
     * Vráti typ položky podľa pozície.
     */
    override fun getItemViewType(position: Int): Int {
        return if (position == 0) TYPE_HEADER else TYPE_APP
    }
    
    /**
     * Počet položiek vrátane hlavičky.
     */
    override fun getItemCount(): Int = apps.size + 1 // +1 pre header
    
    /**
     * Vytvorí ViewHolder podľa typu položky.
     */
    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): RecyclerView.ViewHolder {
        return when (viewType) {
            TYPE_HEADER -> {
                val view = LayoutInflater.from(parent.context)
                    .inflate(R.layout.item_app_selection_header, parent, false)
                HeaderViewHolder(view)
            }
            else -> {
                val view = LayoutInflater.from(parent.context)
                    .inflate(R.layout.item_app_selection, parent, false)
                AppViewHolder(view)
            }
        }
    }
    
    /**
     * Naplní ViewHolder dátami podľa pozície.
     */
    override fun onBindViewHolder(holder: RecyclerView.ViewHolder, position: Int) {
        when (holder) {
            is HeaderViewHolder -> holder.bind()
            is AppViewHolder -> {
                val app = apps[position - 1] // -1 kvôli header
                holder.bind(app)
            }
        }
    }
    
    /**
     * Aktualizuje celý zoznam aplikácií a povolené položky.
     */
    fun updateApps(newApps: List<AppInfo>, newAllowedApps: Set<String>) {
        this.apps = newApps
        this.allowedApps = newAllowedApps
        notifyDataSetChanged()
    }
    
    /**
     * Aktualizuje iba množinu povolených aplikácií.
     */
    fun updateAllowedApps(newAllowedApps: Set<String>) {
        this.allowedApps = newAllowedApps
        notifyDataSetChanged()
    }
    
    /**
     * Vráti zoznam všetkých package názvov.
     */
    fun getAllPackageNames(): List<String> {
        return apps.map { it.packageName }
    }
    
    /**
     * ViewHolder pre hlavičku s "všetky aplikácie".
     */
    inner class HeaderViewHolder(itemView: View) : RecyclerView.ViewHolder(itemView) {
        private val selectAllCheckbox: CheckBox = itemView.findViewById(R.id.selectAllCheckbox)
        private val headerText: TextView = itemView.findViewById(R.id.headerText)
        
        /**
         * Nastaví text a stav checkboxu v hlavičke.
         */
        fun bind() {
            headerText.text = context.getString(R.string.select_apps_overlay)
            
            // Nastavenie stavu checkbox na základe počtu vybraných aplikácií
            val allSelected = allowedApps.isEmpty() // Prázdny zoznam znamená "všetky aplikácie"
            selectAllCheckbox.isChecked = allSelected
            
            selectAllCheckbox.setOnCheckedChangeListener { _, isChecked ->
                onSelectAllApps(isChecked)
            }
        }
    }
    
    /**
     * ViewHolder pre jednu aplikáciu v zozname.
     */
    inner class AppViewHolder(itemView: View) : RecyclerView.ViewHolder(itemView) {
        private val appIcon: ImageView = itemView.findViewById(R.id.appIcon)
        private val appName: TextView = itemView.findViewById(R.id.appName)
        private val packageName: TextView = itemView.findViewById(R.id.packageName)
        private val appCheckbox: CheckBox = itemView.findViewById(R.id.appCheckbox)
        
        /**
         * Naplní položku dátami o aplikácii a nastaví správanie checkboxu.
         */
        fun bind(app: AppInfo) {
            appIcon.setImageDrawable(app.icon)
            appName.text = app.appName
            packageName.text = app.packageName
            
            // Checkbox je zaškrtnutý ak:
            // - allowedApps je prázdne (všetky aplikácie povolené) ALEBO
            // - aplikácia je v zozname povolených
            val isSelected = allowedApps.isEmpty() || allowedApps.contains(app.packageName)
            appCheckbox.isChecked = isSelected
            
            // Zablokuj checkbox ak sú povolené všetky aplikácie
            appCheckbox.isEnabled = allowedApps.isNotEmpty()
            
            appCheckbox.setOnCheckedChangeListener { _, isChecked ->
                if (allowedApps.isNotEmpty()) { // Len ak nie sú povolené všetky aplikácie
                    onAppSelected(app.packageName, isChecked)
                }
            }
            
            itemView.setOnClickListener {
                if (allowedApps.isNotEmpty()) {
                    appCheckbox.isChecked = !appCheckbox.isChecked
                }
            }
        }
    }
}
