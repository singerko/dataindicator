/**
 * Utility funkcie pre prácu s nainštalovanými aplikáciami.
 *
 * Slúži na načítanie aplikácií, informácií o nich a základné kontroly.
 */
package sk.dataindicator.utils

import android.app.ActivityManager
import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.graphics.drawable.Drawable
import android.os.Build

/**
 * Základné informácie o aplikácii potrebné pre zobrazenie v UI.
 */
data class AppInfo(
    val packageName: String,
    val appName: String,
    val icon: Drawable,
    val isSystemApp: Boolean
)

/**
 * Utility pre získavanie aplikácií a ich metadát.
 */
object AppUtils {
    
    /**
     * Získa zoznam všetkých nainštalovaných aplikácií.
     */
    fun getInstalledApps(context: Context): List<AppInfo> {
        val packageManager = context.packageManager
        val launcherIntent = Intent(Intent.ACTION_MAIN).apply {
            addCategory(Intent.CATEGORY_LAUNCHER)
        }

        // Použijeme launcher query namiesto QUERY_ALL_PACKAGES (Play policy compliant).
        val resolveInfos = packageManager.queryIntentActivities(launcherIntent, 0)
        val uniquePackages = resolveInfos.mapNotNull { it.activityInfo?.packageName }.toSet()

        return uniquePackages.mapNotNull { packageName ->
            try {
                val appInfo = packageManager.getApplicationInfo(packageName, 0)
                val appName = packageManager.getApplicationLabel(appInfo).toString()
                val icon = packageManager.getApplicationIcon(appInfo)
                val isSystemApp = (appInfo.flags and ApplicationInfo.FLAG_SYSTEM) != 0
                
                AppInfo(
                    packageName = appInfo.packageName,
                    appName = appName,
                    icon = icon,
                    isSystemApp = isSystemApp
                )
            } catch (e: Exception) {
                null
            }
        }.sortedBy { it.appName.lowercase() }
    }
    
    /**
     * Získa zoznam len používateľských aplikácií (nie systémových).
     */
    fun getUserApps(context: Context): List<AppInfo> {
        return getInstalledApps(context).filter { !it.isSystemApp }
    }
    
    /**
     * Získa aktuálnu aplikáciu na popredí (ak je dostupné).
     */
    fun getCurrentForegroundApp(context: Context): String? {
        val activityManager = context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            // Pre novšie Android verzie
            try {
                val usageStats = activityManager.appTasks
                if (usageStats.isNotEmpty()) {
                    val topTask = usageStats[0]
                    topTask.taskInfo.topActivity?.packageName
                } else {
                    null
                }
            } catch (e: Exception) {
                null
            }
        } else {
            // Pre staršie verzie (nie je podporované)
            null
        }
    }
    
    /**
     * Získa informácie o aplikácii na základe package názvu.
     */
    fun getAppInfo(context: Context, packageName: String): AppInfo? {
        return try {
            val packageManager = context.packageManager
            val appInfo = packageManager.getApplicationInfo(packageName, 0)
            val appName = packageManager.getApplicationLabel(appInfo).toString()
            val icon = packageManager.getApplicationIcon(appInfo)
            val isSystemApp = (appInfo.flags and ApplicationInfo.FLAG_SYSTEM) != 0
            
            AppInfo(
                packageName = packageName,
                appName = appName,
                icon = icon,
                isSystemApp = isSystemApp
            )
        } catch (e: Exception) {
            null
        }
    }
    
    /**
     * Skontroluje, či je aplikácia nainštalovaná.
     */
    fun isAppInstalled(context: Context, packageName: String): Boolean {
        return try {
            context.packageManager.getPackageInfo(packageName, 0)
            true
        } catch (e: PackageManager.NameNotFoundException) {
            false
        }
    }
}
