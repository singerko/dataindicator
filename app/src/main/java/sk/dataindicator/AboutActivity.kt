/**
 * Obrazovka "O aplikácii".
 * Zobrazuje logo, názov aplikácie a aktuálnu verziu.
 */
package sk.dataindicator

import android.os.Build
import android.os.Bundle
import android.widget.TextView
import android.content.pm.PackageInfo

class AboutActivity : BaseActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_about)
        setupBottomNavigation()

        val versionText = findViewById<TextView>(R.id.aboutVersionText)
        versionText.text = getVersionLabel()
    }

    private fun getVersionLabel(): String {
        val packageInfo: PackageInfo = packageManager.getPackageInfo(packageName, 0)
        val versionName = packageInfo.versionName ?: "?"
        val versionCode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            packageInfo.longVersionCode
        } else {
            @Suppress("DEPRECATION")
            packageInfo.versionCode.toLong()
        }
        return getString(R.string.app_version_format, versionName, versionCode)
    }
}
