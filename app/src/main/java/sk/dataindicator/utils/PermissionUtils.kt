/**
 * Pomocné funkcie pre prácu s povoleniami.
 *
 * Zjednodušuje kontrolu a žiadosť o overlay a notifikačné povolenia.
 */
package sk.dataindicator.utils

import android.Manifest
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.core.content.ContextCompat

/**
 * Utility pre kontrolu a žiadanie povolení.
 */
object PermissionUtils {
    
    /**
     * Zistí, či aplikácia môže zobrazovať overlay.
     */
    fun hasOverlayPermission(context: Context): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            Settings.canDrawOverlays(context)
        } else {
            true
        }
    }
    
    /** Vytvorí intent pre systémovú obrazovku overlay povolenia. */
    fun createOverlayPermissionIntent(context: Context): Intent {
        return Intent(
            Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
            Uri.parse("package:${context.packageName}")
        )
    }
    
    /**
     * Zistí, či aplikácia má povolenie na notifikácie (Android 13+).
     */
    fun hasNotificationPermission(context: Context): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            ContextCompat.checkSelfPermission(
                context,
                Manifest.permission.POST_NOTIFICATIONS
            ) == PackageManager.PERMISSION_GRANTED
        } else {
            true
        }
    }
    
    /** Názov runtime povolenia pre notifikácie (Android 13+). */
    fun notificationPermissionName(): String = Manifest.permission.POST_NOTIFICATIONS
    
    /**
     * Zistí, či sú udelené „nevyhnutné“ povolenia (overlay).
     */
    fun hasEssentialPermissions(context: Context): Boolean {
        return hasOverlayPermission(context)
    }
}
