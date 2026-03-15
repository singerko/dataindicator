/**
 * Základná aktivita pre celú aplikáciu.
 *
 * Slúži ako spoločný základ pre všetky obrazovky.
 * Lokalizáciu riadi AppCompatDelegate na úrovni aplikácie.
 */
package sk.dataindicator

import android.os.Bundle
import androidx.appcompat.app.AppCompatActivity

/**
 * Spoločný základ pre aktivity.
 */
open class BaseActivity : AppCompatActivity() {

    /**
     * Inicializácia aktivity.
     */
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
    }
}
