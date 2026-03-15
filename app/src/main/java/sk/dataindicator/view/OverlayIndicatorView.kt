/**
 * Vizuálny komponent, ktorý kreslí farebný pásik na obrazovku.
 *
 * Farba a šírka sa menia podľa typu siete a nastavení používateľa.
 */
package sk.dataindicator.view

import android.content.Context
import android.graphics.Canvas
import android.graphics.Paint
import android.view.View
import sk.dataindicator.config.ConfigManager
import sk.dataindicator.service.NetworkStateService

/**
 * Jednoduché View, ktoré kreslí horizontálny pásik.
 */
class OverlayIndicatorView(context: Context) : View(context) {

    private val paint = Paint().apply {
        style = Paint.Style.FILL
        isAntiAlias = true
    }
    
    private val configManager = ConfigManager.getInstance(context)
    private var currentNetworkType: NetworkStateService.NetworkType = NetworkStateService.NetworkType.NO_INTERNET
    
    init {
        setBackgroundColor(android.graphics.Color.TRANSPARENT)
        updateColor(currentNetworkType)
    }
    
    /**
     * Vykreslí pásik podľa aktuálneho typu siete a nastavení.
     */
    override fun onDraw(canvas: Canvas) {
        super.onDraw(canvas)
        
        val color = configManager.getColorForState(currentNetworkType)
        paint.color = color
        
        // Vypočítanie skutočnej šírky na základe percenta
        val screenWidth = resources.displayMetrics.widthPixels
        val indicatorWidth = (screenWidth * configManager.indicatorWidthPercent / 100f).toInt()
        
        // Vypočítanie X pozície na základe zarovnania
        val startX = when (configManager.alignment) {
            "left" -> 0f
            "right" -> (screenWidth - indicatorWidth).toFloat()
            else -> ((screenWidth - indicatorWidth) / 2f) // center
        }
        
        val endX = startX + indicatorWidth
        
        // Kreslenie pásika
        canvas.drawRect(startX, 0f, endX, height.toFloat(), paint)
    }
    
    /**
     * Aktualizuje farbu indikátora podľa typu siete.
     */
    fun updateColor(networkType: NetworkStateService.NetworkType) {
        if (currentNetworkType != networkType) {
            currentNetworkType = networkType
            post {
                invalidate()
            }
        }
    }
    
    /**
     * Vynúti prekreslenie po zmene konfigurácie.
     */
    fun refreshConfig() {
        // Obnoviť konfiguráciu a prekresliť
        post {
            invalidate()
        }
    }
}
