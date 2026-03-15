/**
 * Základný instrumented test pre overenie Android kontextu.
 */
package sk.dataindicator

import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import org.junit.Assert.assertEquals
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class SimpleInstrumentedTest {
    /**
     * Overí, že packageName aplikácie je správny.
     */
    @Test
    fun appContext_isCorrect() {
        val appContext = InstrumentationRegistry.getInstrumentation().targetContext
        assertEquals("sk.dataindicator", appContext.packageName)
    }
}
