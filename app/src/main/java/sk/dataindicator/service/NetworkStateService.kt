/**
 * Foreground služba, ktorá sleduje stav siete a zobrazuje overlay indikátor.
 *
 * Beží na pozadí, počúva zmeny pripojenia a upravuje farbu pásika podľa typu siete.
 */
package sk.dataindicator.service

import android.app.*
import android.content.Context
import android.content.Intent
import android.graphics.PixelFormat
import android.net.ConnectivityManager
import android.net.Network
import android.net.NetworkCapabilities
import android.net.NetworkRequest
import android.os.Build
import android.os.IBinder
import android.view.WindowManager
import androidx.core.app.NotificationCompat
import sk.dataindicator.MainActivity
import sk.dataindicator.R
import sk.dataindicator.config.ConfigManager
import sk.dataindicator.view.OverlayIndicatorView

/**
 * Služba pre monitoring siete a zobrazenie overlay indikátora.
 */
class NetworkStateService : Service() {

    companion object {
        /** ID notifikačného kanála pre foreground službu. */
        const val CHANNEL_ID = "NetworkStateChannel"
        /** ID notifikácie. */
        const val NOTIFICATION_ID = 1

        /** Akcia pre spustenie služby. */
        const val ACTION_START = "sk.dataindicator.action.START"
        /** Akcia pre zastavenie služby. */
        const val ACTION_STOP = "sk.dataindicator.action.STOP"
        /** Akcia pre znovu načítanie konfigurácie overlay. */
        const val ACTION_REFRESH_CONFIG = "sk.dataindicator.action.REFRESH_CONFIG"
    }
    
    private lateinit var windowManager: WindowManager
    private lateinit var overlayView: OverlayIndicatorView
    private lateinit var connectivityManager: ConnectivityManager
    private lateinit var networkCallback: ConnectivityManager.NetworkCallback
    private lateinit var configManager: ConfigManager
    private lateinit var handler: android.os.Handler
    
    private var isOverlayAdded = false
    private var isMonitoringActive = false
    private var isNetworkCallbackRegistered = false
    
    /**
     * Inicializácia služieb a overlay prvku.
     */
    override fun onCreate() {
        super.onCreate()
        
        windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager
        connectivityManager = getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
        configManager = ConfigManager.getInstance(this)
        handler = android.os.Handler(android.os.Looper.getMainLooper())
        
        createNotificationChannel()
        setupNetworkCallback()
        createOverlay()
    }
    
    /**
     * Spracuje príkazy na spustenie, zastavenie alebo refresh konfigurácie.
     */
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START -> {
                startForeground(NOTIFICATION_ID, createNotification())
                if (!isMonitoringActive) {
                    registerNetworkCallback()
                    showOverlay()
                    isMonitoringActive = true
                } else {
                    // Idempotent start: iba obnov stav bez ďalšej registrácie callbackov.
                    showOverlay()
                    updateOverlayColor()
                }
            }
            ACTION_STOP -> {
                stopForeground(STOP_FOREGROUND_REMOVE)
                isMonitoringActive = false
                hideOverlay()
                stopSelf()
            }
            ACTION_REFRESH_CONFIG -> {
                refreshOverlayConfig()
            }
        }
        
        return START_STICKY
    }
    
    /**
     * Uvoľní zdroje pri zničení služby.
     */
    override fun onDestroy() {
        super.onDestroy()
        unregisterNetworkCallback()
        hideOverlay()
    }
    
    /**
     * Služba nepodporuje bindovanie.
     */
    override fun onBind(intent: Intent?): IBinder? = null
    
    /**
     * Vytvorí notifikačný kanál pre Android 8+.
     */
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                getString(R.string.notification_channel_name),
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = getString(R.string.notification_text)
            }
            
            val notificationManager = getSystemService(NotificationManager::class.java)
            notificationManager.createNotificationChannel(channel)
        }
    }
    
    /**
     * Vytvorí notifikáciu pre foreground službu.
     */
    private fun createNotification(): Notification {
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            Intent(this, MainActivity::class.java),
            PendingIntent.FLAG_IMMUTABLE
        )
        
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle(getString(R.string.notification_title))
            .setContentText(getString(R.string.notification_text))
            .setSmallIcon(R.drawable.ic_notification)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .build()
    }
    
    /**
     * Inicializuje overlay view.
     */
    private fun createOverlay() {
        overlayView = OverlayIndicatorView(this)
    }
    
    /**
     * Zobrazí overlay na obrazovke, ak sú splnené podmienky.
     */
    private fun showOverlay() {
        if (!isOverlayAdded && android.provider.Settings.canDrawOverlays(this)) {
            // Použitie konfigurovateľnej výšky
            val heightInPx = (configManager.indicatorHeight * resources.displayMetrics.density).toInt()
            
            val params = WindowManager.LayoutParams(
                WindowManager.LayoutParams.MATCH_PARENT,
                heightInPx,
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
                WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                        WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE or
                        WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
                PixelFormat.TRANSLUCENT
            ).apply {
                // Použitie konfigurovateľného zarovnania
                gravity = configManager.getGravityForAlignment()
                y = 0
            }
            
            try {
                windowManager.addView(overlayView, params)
                isOverlayAdded = true
            } catch (_: Exception) {
                return
            }
            
            updateOverlayColor()
        }
    }
    
    /**
     * Skryje overlay, ak je zobrazený.
     */
    private fun hideOverlay() {
        if (isOverlayAdded) {
            try {
                windowManager.removeView(overlayView)
            } catch (_: Exception) {
                // ignore window detach race
            }
            isOverlayAdded = false
        }
    }
    
    /**
     * Pripraví callback na zmeny sieťových možností.
     */
    private fun setupNetworkCallback() {
        networkCallback = object : ConnectivityManager.NetworkCallback() {
            override fun onAvailable(network: Network) {
                updateOverlayColor()
            }
            
            override fun onLost(network: Network) {
                // Oneskorená kontrola, aby sme zachytili stav keď stratíme poslednú sieť
                handler.postDelayed({
                    updateOverlayColor()
                }, 100)
            }
            
            override fun onCapabilitiesChanged(network: Network, capabilities: NetworkCapabilities) {
                updateOverlayColor()
            }
        }
    }
    
    /**
     * Zaregistruje callback pre zmeny siete.
     */
    private fun registerNetworkCallback() {
        if (isNetworkCallbackRegistered) return
        val networkRequest = NetworkRequest.Builder()
            .addCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)
            .build()
            
        try {
            connectivityManager.registerNetworkCallback(networkRequest, networkCallback)
            isNetworkCallbackRegistered = true
        } catch (_: Exception) {
            isNetworkCallbackRegistered = false
        }
    }
    
    /**
     * Odregistruje callback pre zmeny siete.
     */
    private fun unregisterNetworkCallback() {
        if (!isNetworkCallbackRegistered) return
        try {
            connectivityManager.unregisterNetworkCallback(networkCallback)
            isNetworkCallbackRegistered = false
        } catch (e: Exception) {
            // Ignore if already unregistered
            isNetworkCallbackRegistered = false
        }
    }
    
    /**
     * Aktualizuje farbu overlay podľa aktuálneho typu siete.
     */
    private fun updateOverlayColor() {
        val networkType = getNetworkType()
        overlayView.updateColor(networkType)
    }
    
    /**
     * Znovu načíta konfiguráciu overlay (výška, zarovnanie, farby).
     */
    private fun refreshOverlayConfig() {
        if (isOverlayAdded) {
            // Znovu vytvoriť overlay s novou konfiguráciou
            hideOverlay()
            showOverlay()
        }
    }
    
    /**
     * Zistí typ pripojenia (Wi‑Fi, mobilné dáta, alebo bez internetu).
     */
    private fun getNetworkType(): NetworkType {
        val activeNetwork = connectivityManager.activeNetwork ?: return NetworkType.NO_INTERNET
        val capabilities = connectivityManager.getNetworkCapabilities(activeNetwork) ?: return NetworkType.NO_INTERNET
        
        return when {
            !capabilities.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET) -> NetworkType.NO_INTERNET
            capabilities.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) -> NetworkType.WIFI
            capabilities.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR) -> NetworkType.MOBILE_DATA
            else -> NetworkType.NO_INTERNET
        }
    }
    
    /**
     * Typy pripojenia, ktoré ovplyvňujú farbu indikátora.
     */
    enum class NetworkType {
        WIFI,
        MOBILE_DATA,
        NO_INTERNET
    }
}
