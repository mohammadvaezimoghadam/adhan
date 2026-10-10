package com.qurantafakor.app

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.os.Process
import android.util.Log

/**
 * Lightweight helper Activity running in a separate process (:restart).
 *
 * Designed based on the proven ProcessPhoenix pattern to reliably restart
 * Flutter/Android apps across all Android versions (including Android 10-15)
 * without triggering Background Activity Launch (BAL) restrictions.
 */
class RestartActivity : Activity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Kill the old main process if still lingering
        val mainPid = intent.getIntExtra(KEY_MAIN_PID, -1)
        if (mainPid > 0) {
            try {
                Process.killProcess(mainPid)
            } catch (e: Exception) {
                Log.w("RestartActivity", "Could not kill main process: $e")
            }
        }

        // Retrieve the launch intent for the main application
        val restartIntent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            intent.getParcelableExtra(KEY_RESTART_INTENT, Intent::class.java)
        } else {
            @Suppress("DEPRECATION")
            intent.getParcelableExtra(KEY_RESTART_INTENT)
        }

        if (restartIntent != null) {
            restartIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK)
            startActivity(restartIntent)
        } else {
            // Fallback: lookup launch intent dynamically
            val fallback = packageManager.getLaunchIntentForPackage(packageName)
            if (fallback != null) {
                fallback.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK)
                startActivity(fallback)
            }
        }

        // Finish self and terminate the helper process
        finish()
        Runtime.getRuntime().exit(0)
    }

    companion object {
        private const val KEY_RESTART_INTENT = "restart_intent"
        private const val KEY_MAIN_PID = "main_pid"

        @JvmStatic
        fun restartApp(context: Context) {
            val packageName = context.packageName
            val launchIntent = context.packageManager.getLaunchIntentForPackage(packageName)

            val intent = Intent(context, RestartActivity::class.java).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                if (launchIntent != null) {
                    launchIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK)
                    putExtra(KEY_RESTART_INTENT, launchIntent)
                }
                putExtra(KEY_MAIN_PID, Process.myPid())
            }

            context.startActivity(intent)

            if (context is Activity) {
                context.finishAffinity()
            }
            Runtime.getRuntime().exit(0)
        }
    }
}
