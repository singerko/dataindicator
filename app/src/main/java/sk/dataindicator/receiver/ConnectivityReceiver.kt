/**
 * BroadcastReceiver pre zmeny sieťového pripojenia.
 *
 * Používa sa ako doplnkový mechanizmus na spustenie služby pri zmene siete.
 */
package sk.dataindicator.receiver

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.os.Build
import sk.dataindicator.service.NetworkStateService

/**
 * Reaguje na zmeny pripojenia a spúšťa foreground službu.
 */
class ConnectivityReceiver : BroadcastReceiver() {

    /**
     * Spracuje systémový broadcast o zmene siete.
     */
    override fun onReceive(context: Context, intent: Intent) {
        @Suppress("DEPRECATION")
        if (intent.action == ConnectivityManager.CONNECTIVITY_ACTION) {
            val connectivityManager = context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
            
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                val activeNetwork = connectivityManager.activeNetwork
                val capabilities = connectivityManager.getNetworkCapabilities(activeNetwork)
                
                val hasInternet = capabilities?.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET) ?: false
                
                if (hasInternet) {
                    // Služba je už spustená, len sa aktualizuje stav
                    val serviceIntent = Intent(context, NetworkStateService::class.java).apply {
                        action = NetworkStateService.ACTION_START
                    }
                    context.startForegroundService(serviceIntent)
                }
            }
        }
    }
}
