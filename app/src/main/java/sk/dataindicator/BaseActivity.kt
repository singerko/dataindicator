/**
 * Základná aktivita pre celú aplikáciu.
 *
 * Zabezpečuje spoločnú spodnú navigačnú lištu na všetkých obrazovkách.
 */
package sk.dataindicator

import android.content.Intent
import androidx.appcompat.app.AppCompatActivity
import android.os.Bundle
import com.google.android.material.bottomnavigation.BottomNavigationView

open class BaseActivity : AppCompatActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
    }

    /**
     * Nastaví spodnú navigačnú lištu – volá sa po setContentView() v každej aktivite.
     * Automaticky vyberie správnu záložku podľa aktuálnej aktivity.
     */
    protected fun setupBottomNavigation() {
        val bottomNav = findViewById<BottomNavigationView>(R.id.bottomNavigation) ?: return

        bottomNav.selectedItemId = when (this) {
            is SettingsActivity -> R.id.nav_settings
            is AboutActivity    -> R.id.nav_about
            else                -> R.id.nav_home
        }

        bottomNav.setOnItemSelectedListener { item ->
            if (item.itemId == bottomNav.selectedItemId) return@setOnItemSelectedListener true

            val intent = when (item.itemId) {
                R.id.nav_home     -> Intent(this, MainActivity::class.java)
                R.id.nav_settings -> Intent(this, SettingsActivity::class.java)
                R.id.nav_about    -> Intent(this, AboutActivity::class.java)
                else              -> return@setOnItemSelectedListener false
            }
            intent.flags = Intent.FLAG_ACTIVITY_REORDER_TO_FRONT
            startActivity(intent)
            false
        }
    }
}
