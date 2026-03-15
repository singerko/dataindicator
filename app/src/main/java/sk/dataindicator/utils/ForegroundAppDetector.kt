/**
 * Pomocná trieda na zistenie aplikácie v popredí.
 *
 * Na novších Androidoch používa UsageStats, na starších ActivityManager.
 */
package sk.dataindicator.utils

import android.app.ActivityManager
import android.app.usage.UsageStats
import android.app.usage.UsageStatsManager
import android.content.Context
import android.os.Build
import android.os.Handler
import android.os.Looper
import java.util.*

/**
 * Periodicky zisťuje aktuálnu aplikáciu a volá callback pri zmene.
 */
class ForegroundAppDetector(
    private val context: Context,
    private val onAppChanged: (String?) -> Unit
) {
    
    private val handler = Handler(Looper.getMainLooper())
    private var isRunning = false
    private var lastForegroundApp: String? = null
    
    private val checkRunnable = object : Runnable {
        override fun run() {
            if (isRunning) {
                val currentApp = getCurrentForegroundApp()
                android.util.Log.d("ForegroundAppDetector", "Checking app: $currentApp (last: $lastForegroundApp)")
                if (currentApp != lastForegroundApp) {
                    lastForegroundApp = currentApp
                    android.util.Log.d("ForegroundAppDetector", "App changed to: $currentApp")
                    onAppChanged(currentApp)
                }
                handler.postDelayed(this, CHECK_INTERVAL)
            }
        }
    }
    
    companion object {
        /** Interval kontroly (ms). */
        private const val CHECK_INTERVAL = 5000L // 5 sekúnd - optimalizácia batérie
    }
    
    /**
     * Spustí periodické zisťovanie foreground aplikácie.
     */
    fun start() {
        if (!isRunning) {
            isRunning = true
            handler.post(checkRunnable)
        }
    }
    
    /**
     * Zastaví periodické zisťovanie.
     */
    fun stop() {
        isRunning = false
        handler.removeCallbacks(checkRunnable)
    }
    
    /**
     * Vráti aktuálnu aplikáciu v popredí podľa verzie Androidu.
     */
    private fun getCurrentForegroundApp(): String? {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            getForegroundAppWithUsageStats()
        } else {
            getForegroundAppLegacy()
        }
    }
    
    /**
     * Získa aplikáciu v popredí cez UsageStats (Android 5+).
     */
    private fun getForegroundAppWithUsageStats(): String? {
        return try {
            val usageStatsManager = context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
            val endTime = System.currentTimeMillis()
            val beginTime = endTime - 10000 // Posledných 10 sekúnd
            
            val usageStatsList = usageStatsManager.queryUsageStats(
                UsageStatsManager.INTERVAL_DAILY,
                beginTime,
                endTime
            )
            
            android.util.Log.d("ForegroundAppDetector", "UsageStats found ${usageStatsList.size} apps")
            
            if (usageStatsList.isEmpty()) {
                android.util.Log.d("ForegroundAppDetector", "No usage stats available - may need USAGE_STATS permission")
                return null
            }
            
            // Nájdeme aplikáciu s najnovším lastTimeUsed
            val recentApp = usageStatsList.maxByOrNull { it.lastTimeUsed }
            android.util.Log.d("ForegroundAppDetector", "Most recent app: ${recentApp?.packageName} at ${recentApp?.lastTimeUsed}")
            recentApp?.packageName
        } catch (e: Exception) {
            android.util.Log.e("ForegroundAppDetector", "Error getting usage stats", e)
            null
        }
    }
    
    /**
     * Získa aplikáciu v popredí cez ActivityManager (staršie Androidy).
     */
    private fun getForegroundAppLegacy(): String? {
        return try {
            val activityManager = context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
            @Suppress("DEPRECATION")
            val runningTasks = activityManager.getRunningTasks(1)
            
            if (runningTasks.isNotEmpty()) {
                runningTasks[0].topActivity?.packageName
            } else {
                null
            }
        } catch (e: Exception) {
            null
        }
    }
}
