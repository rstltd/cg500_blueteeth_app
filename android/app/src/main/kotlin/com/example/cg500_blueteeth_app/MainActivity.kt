package com.example.cg500_blueteeth_app

import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.util.Log
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.cg500.ble_app/update"
    private val TAG = "MainActivity"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "installApk" -> {
                    val filePath = call.argument<String>("filePath")
                    if (filePath != null) {
                        val success = installApk(filePath)
                        result.success(success)
                    } else {
                        result.error("INVALID_ARGUMENT", "File path is required", null)
                    }
                }
                "canInstallApks" -> {
                    val canInstall = canInstallApks()
                    Log.d(TAG, "canInstallApks result: $canInstall")
                    result.success(canInstall)
                }
                "requestInstallPermission" -> {
                    Log.d(TAG, "requestInstallPermission called")
                    requestInstallPermission()
                    result.success(true)
                }
                "diagnosePermissions" -> {
                    val diagnosis = diagnosePermissions()
                    Log.d(TAG, "diagnosePermissions result: $diagnosis")
                    result.success(diagnosis)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun installApk(filePath: String): Boolean {
        return try {
            Log.d(TAG, "installApk called with filePath: $filePath")
            
            // Check if we have permission to install unknown apps
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && !canInstallApks()) {
                Log.w(TAG, "Cannot install APKs - permission not granted")
                return false
            }
            
            val file = File(filePath)
            if (!file.exists()) {
                Log.e(TAG, "APK file does not exist: $filePath")
                return false
            }
            
            Log.d(TAG, "APK file exists, size: ${file.length()} bytes")

            val intent = Intent(Intent.ACTION_VIEW)
            intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_GRANT_READ_URI_PERMISSION

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                // Use FileProvider for Android N and above
                Log.d(TAG, "Using FileProvider for Android N+")
                try {
                    val authority = "${packageName}.fileprovider"
                    Log.d(TAG, "FileProvider authority: $authority")
                    
                    val uri = FileProvider.getUriForFile(this, authority, file)
                    Log.d(TAG, "FileProvider URI: $uri")
                    
                    intent.setDataAndType(uri, "application/vnd.android.package-archive")
                    
                    // Grant permission to package installer
                    val resolveInfos = packageManager.queryIntentActivities(intent, PackageManager.MATCH_DEFAULT_ONLY)
                    for (resolveInfo in resolveInfos) {
                        val packageName = resolveInfo.activityInfo.packageName
                        grantUriPermission(packageName, uri, Intent.FLAG_GRANT_READ_URI_PERMISSION)
                        Log.d(TAG, "Granted URI permission to: $packageName")
                    }
                } catch (e: Exception) {
                    Log.e(TAG, "FileProvider error: ${e.message}", e)
                    return false
                }
            } else {
                // Direct file URI for older Android versions
                Log.d(TAG, "Using direct file URI for older Android")
                intent.setDataAndType(Uri.fromFile(file), "application/vnd.android.package-archive")
            }

            Log.d(TAG, "Starting install activity...")
            startActivity(intent)
            Log.d(TAG, "Install activity started successfully")
            true
        } catch (e: Exception) {
            Log.e(TAG, "installApk failed: ${e.message}", e)
            e.printStackTrace()
            false
        }
    }

    private fun canInstallApks(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            packageManager.canRequestPackageInstalls()
        } else {
            true // No special permission needed for older Android versions
        }
    }

    private fun requestInstallPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && !canInstallApks()) {
            Log.d(TAG, "Requesting install permission via settings")
            val intent = Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES)
            intent.data = Uri.parse("package:${packageName}")
            startActivity(intent)
        } else {
            Log.d(TAG, "Install permission already granted or not required")
        }
    }
    
    private fun diagnosePermissions(): Map<String, Any> {
        val diagnosis = mutableMapOf<String, Any>()
        
        // Basic info
        diagnosis["androidVersion"] = Build.VERSION.SDK_INT
        diagnosis["packageName"] = packageName
        
        // Install permission
        val canInstall = canInstallApks()
        diagnosis["canInstallApks"] = canInstall
        
        // FileProvider test
        try {
            val authority = "${packageName}.fileprovider"
            diagnosis["fileProviderAuthority"] = authority
            
            // Test FileProvider with a dummy file path (common app documents path)
            val testPath = "/data/data/${packageName}/app_flutter/Documents/test.apk"
            diagnosis["testFilePath"] = testPath
            
            val testFile = File(testPath)
            diagnosis["testFilePathExists"] = testFile.exists()
            
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                try {
                    // This will throw an exception if FileProvider config is wrong
                    FileProvider.getUriForFile(this, authority, File("/data/data/${packageName}/files/dummy.apk"))
                    diagnosis["fileProviderConfigValid"] = true
                } catch (e: Exception) {
                    diagnosis["fileProviderConfigValid"] = false
                    diagnosis["fileProviderError"] = e.message ?: "Unknown error"
                    Log.w(TAG, "FileProvider config test failed: ${e.message}")
                }
            }
            
            // Check what paths are actually accessible
            val documentsDir = File("/data/data/${packageName}/app_flutter")
            diagnosis["documentsDirectoryExists"] = documentsDir.exists()
            
            val filesDir = filesDir
            diagnosis["filesDirectoryPath"] = filesDir.absolutePath
            diagnosis["filesDirectoryExists"] = filesDir.exists()
            
        } catch (e: Exception) {
            diagnosis["diagnosisError"] = e.message ?: "Unknown error"
            Log.e(TAG, "Diagnosis failed: ${e.message}", e)
        }
        
        return diagnosis
    }
}
