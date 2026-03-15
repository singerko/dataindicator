/**
 * Receiver pre systémové udalosti po boote alebo aktualizácii aplikácie.
 *
 * Ak je zapnutý auto‑štart, spustí službu monitorovania siete.
 */
package sk.dataindicator.receiver

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import sk.dataindicator.config.ConfigManager
import sk.dataindicator.service.NetworkStateService
import sk.dataindicator.utils.PermissionUtils

/**
 * Reaguje na BOOT_COMPLETED a podobné systémové akcie.
 */
class BootReceiver : BroadcastReceiver() {

    companion object {
        /** Tag pre logovanie. */
        private const val TAG = "BootReceiver"
    }
    
    /**
     * Spracuje boot/upgrade udalosti a spustí auto‑štart, ak je povolený.
     */
    override fun onReceive(context: Context?, intent: Intent?) {
        if (context == null || intent == null) return
        
        val action = intent.action
        Log.d(TAG, "Received action: $action")
        
        when (action) {
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_MY_PACKAGE_REPLACED,
            Intent.ACTION_PACKAGE_REPLACED -> {
                handleBootCompleted(context)
            }
        }
    }
    
    /**
     * Spustí službu po boote, ak sú splnené podmienky.
     */
    private fun handleBootCompleted(context: Context) {
        Log.d(TAG, "Handling boot completed")
        
        val configManager = ConfigManager.getInstance(context)
        
        // Kontrola, či je auto-štart povolený
        if (!configManager.isAutoStartEnabled) {
            Log.d(TAG, "Auto-start is disabled")
            return
        }
        
        // Kontrola potrebných povolení (len overlay je nevyhnutné)
        if (!PermissionUtils.hasEssentialPermissions(context)) {
            Log.w(TAG, "Missing essential permissions for auto-start")
            return
        }
        
        try {
            // Spustenie služby
            val serviceIntent = Intent(context, NetworkStateService::class.java).apply {
                action = NetworkStateService.ACTION_START
            }
            context.startForegroundService(serviceIntent)
            
            Log.i(TAG, "Network monitoring service started on boot")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start service on boot", e)
        }
    }
}
