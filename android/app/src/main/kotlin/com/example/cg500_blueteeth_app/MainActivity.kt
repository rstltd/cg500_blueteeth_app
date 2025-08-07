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
                        val installResult = installApkDirect(filePath)
                        result.success(installResult)
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

    // Direct APK installation without complex permission checks
    private fun installApkDirect(filePath: String): Map<String, Any> {
        val result = mutableMapOf<String, Any>()
        
        try {
            Log.d(TAG, "=== Direct APK Installation Start ===")
            Log.d(TAG, "installApkDirect called with filePath: $filePath")
            Log.d(TAG, "Android version: ${Build.VERSION.SDK_INT}")
            Log.d(TAG, "Package name: $packageName")
            
            result["success"] = false
            result["androidVersion"] = Build.VERSION.SDK_INT
            result["packageName"] = packageName
            result["filePath"] = filePath
            result["method"] = "direct"
            
            val file = File(filePath)
            Log.d(TAG, "Checking APK file: ${file.absolutePath}")
            result["absolutePath"] = file.absolutePath
            
            if (!file.exists()) {
                val errorMsg = "APK file does not exist: $filePath"
                Log.e(TAG, errorMsg)
                result["error"] = errorMsg
                result["errorType"] = "FILE_NOT_FOUND"
                return result
            }
            
            Log.d(TAG, "APK file exists, size: ${file.length()} bytes")
            Log.d(TAG, "APK file readable: ${file.canRead()}")
            result["fileSize"] = file.length()
            result["fileReadable"] = file.canRead()

            val intent = Intent(Intent.ACTION_VIEW)
            intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_GRANT_READ_URI_PERMISSION

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                // Use FileProvider for Android N and above
                Log.d(TAG, "Using FileProvider for Android N+")
                result["useFileProvider"] = true
                
                try {
                    val authority = "${packageName}.fileprovider"
                    Log.d(TAG, "FileProvider authority: $authority")
                    result["fileProviderAuthority"] = authority
                    
                    val uri = FileProvider.getUriForFile(this, authority, file)
                    Log.d(TAG, "FileProvider URI: $uri")
                    result["fileProviderUri"] = uri.toString()
                    
                    intent.setDataAndType(uri, "application/vnd.android.package-archive")
                    
                    // Grant permission to package installer
                    val resolveInfos = packageManager.queryIntentActivities(intent, PackageManager.MATCH_DEFAULT_ONLY)
                    Log.d(TAG, "Found ${resolveInfos.size} activities that can handle APK install")
                    result["resolvedActivitiesCount"] = resolveInfos.size
                    
                    val resolvedActivities = mutableListOf<String>()
                    for (resolveInfo in resolveInfos) {
                        val packageName = resolveInfo.activityInfo.packageName
                        grantUriPermission(packageName, uri, Intent.FLAG_GRANT_READ_URI_PERMISSION)
                        Log.d(TAG, "Granted URI permission to: $packageName")
                        resolvedActivities.add(packageName)
                    }
                    result["resolvedActivities"] = resolvedActivities
                    
                    if (resolveInfos.isEmpty()) {
                        val errorMsg = "No activities found that can handle APK installation!"
                        Log.e(TAG, errorMsg)
                        result["error"] = errorMsg
                        result["errorType"] = "NO_RESOLVER"
                        return result
                    }
                } catch (e: Exception) {
                    val errorMsg = "FileProvider error: ${e.message}"
                    Log.e(TAG, errorMsg, e)
                    Log.e(TAG, "FileProvider error class: ${e.javaClass.simpleName}")
                    e.printStackTrace()
                    result["error"] = errorMsg
                    result["errorType"] = "FILEPROVIDER_ERROR"
                    result["errorClass"] = e.javaClass.simpleName
                    return result
                }
            } else {
                // Direct file URI for older Android versions
                Log.d(TAG, "Using direct file URI for older Android")
                result["useFileProvider"] = false
                intent.setDataAndType(Uri.fromFile(file), "application/vnd.android.package-archive")
            }

            Log.d(TAG, "Intent data: ${intent.data}")
            Log.d(TAG, "Intent type: ${intent.type}")
            Log.d(TAG, "Intent flags: ${intent.flags}")
            result["intentData"] = intent.data?.toString() ?: "null"
            result["intentType"] = intent.type ?: "null"
            result["intentFlags"] = intent.flags
            
            Log.d(TAG, "Starting install activity...")
            startActivity(intent)
            Log.d(TAG, "Install activity started successfully - system will handle permission prompts")
            Log.d(TAG, "=== Direct APK Installation End ===")
            
            result["success"] = true
            result["message"] = "Install activity started successfully - system will handle permission prompts"
            return result
            
        } catch (e: Exception) {
            Log.e(TAG, "=== Direct APK Installation Failed ===")
            Log.e(TAG, "installApkDirect failed: ${e.message}", e)
            Log.e(TAG, "Exception class: ${e.javaClass.simpleName}")
            e.printStackTrace()
            
            result["success"] = false
            result["error"] = e.message ?: "Unknown error"
            result["errorType"] = "EXCEPTION"
            result["errorClass"] = e.javaClass.simpleName
            return result
        }
    }

    private fun installApkWithDetails(filePath: String): Map<String, Any> {
        val result = mutableMapOf<String, Any>()
        
        try {
            Log.d(TAG, "=== APK Installation Start ===")
            Log.d(TAG, "installApk called with filePath: $filePath")
            Log.d(TAG, "Android version: ${Build.VERSION.SDK_INT}")
            Log.d(TAG, "Package name: $packageName")
            
            result["success"] = false
            result["androidVersion"] = Build.VERSION.SDK_INT
            result["packageName"] = packageName
            result["filePath"] = filePath
            
            // Check if we have permission to install unknown apps
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val canInstall = canInstallApks()
                Log.d(TAG, "Can install APKs: $canInstall")
                result["canInstallApks"] = canInstall
                
                // Even if canInstall is false, we'll still attempt installation
                // The system will handle permission prompts if needed
                if (!canInstall) {
                    Log.w(TAG, "Permission check indicates install not allowed, but proceeding anyway")
                    Log.w(TAG, "System will show permission prompt if needed")
                    result["permissionWarning"] = "May require user permission during installation"
                }
            } else {
                result["canInstallApks"] = true
            }
            
            val file = File(filePath)
            Log.d(TAG, "Checking APK file: ${file.absolutePath}")
            result["absolutePath"] = file.absolutePath
            
            if (!file.exists()) {
                val errorMsg = "APK file does not exist: $filePath"
                Log.e(TAG, errorMsg)
                result["error"] = errorMsg
                result["errorType"] = "FILE_NOT_FOUND"
                return result
            }
            
            Log.d(TAG, "APK file exists, size: ${file.length()} bytes")
            Log.d(TAG, "APK file readable: ${file.canRead()}")
            result["fileSize"] = file.length()
            result["fileReadable"] = file.canRead()

            val intent = Intent(Intent.ACTION_VIEW)
            intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_GRANT_READ_URI_PERMISSION

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                // Use FileProvider for Android N and above
                Log.d(TAG, "Using FileProvider for Android N+")
                result["useFileProvider"] = true
                
                try {
                    val authority = "${packageName}.fileprovider"
                    Log.d(TAG, "FileProvider authority: $authority")
                    result["fileProviderAuthority"] = authority
                    
                    val uri = FileProvider.getUriForFile(this, authority, file)
                    Log.d(TAG, "FileProvider URI: $uri")
                    result["fileProviderUri"] = uri.toString()
                    
                    intent.setDataAndType(uri, "application/vnd.android.package-archive")
                    
                    // Grant permission to package installer
                    val resolveInfos = packageManager.queryIntentActivities(intent, PackageManager.MATCH_DEFAULT_ONLY)
                    Log.d(TAG, "Found ${resolveInfos.size} activities that can handle APK install")
                    result["resolvedActivitiesCount"] = resolveInfos.size
                    
                    val resolvedActivities = mutableListOf<String>()
                    for (resolveInfo in resolveInfos) {
                        val packageName = resolveInfo.activityInfo.packageName
                        grantUriPermission(packageName, uri, Intent.FLAG_GRANT_READ_URI_PERMISSION)
                        Log.d(TAG, "Granted URI permission to: $packageName")
                        resolvedActivities.add(packageName)
                    }
                    result["resolvedActivities"] = resolvedActivities
                    
                    if (resolveInfos.isEmpty()) {
                        val errorMsg = "No activities found that can handle APK installation!"
                        Log.e(TAG, errorMsg)
                        result["error"] = errorMsg
                        result["errorType"] = "NO_RESOLVER"
                        return result
                    }
                } catch (e: Exception) {
                    val errorMsg = "FileProvider error: ${e.message}"
                    Log.e(TAG, errorMsg, e)
                    Log.e(TAG, "FileProvider error class: ${e.javaClass.simpleName}")
                    e.printStackTrace()
                    result["error"] = errorMsg
                    result["errorType"] = "FILEPROVIDER_ERROR"
                    result["errorClass"] = e.javaClass.simpleName
                    return result
                }
            } else {
                // Direct file URI for older Android versions
                Log.d(TAG, "Using direct file URI for older Android")
                result["useFileProvider"] = false
                intent.setDataAndType(Uri.fromFile(file), "application/vnd.android.package-archive")
            }

            Log.d(TAG, "Intent data: ${intent.data}")
            Log.d(TAG, "Intent type: ${intent.type}")
            Log.d(TAG, "Intent flags: ${intent.flags}")
            result["intentData"] = intent.data?.toString() ?: "null"
            result["intentType"] = intent.type ?: "null"
            result["intentFlags"] = intent.flags
            
            Log.d(TAG, "Starting install activity...")
            startActivity(intent)
            Log.d(TAG, "Install activity started successfully")
            Log.d(TAG, "=== APK Installation End ===")
            
            result["success"] = true
            result["message"] = "Install activity started successfully"
            return result
            
        } catch (e: Exception) {
            Log.e(TAG, "=== APK Installation Failed ===")
            Log.e(TAG, "installApk failed: ${e.message}", e)
            Log.e(TAG, "Exception class: ${e.javaClass.simpleName}")
            e.printStackTrace()
            
            result["success"] = false
            result["error"] = e.message ?: "Unknown error"
            result["errorType"] = "EXCEPTION"
            result["errorClass"] = e.javaClass.simpleName
            return result
        }
    }

    private fun installApk(filePath: String): Boolean {
        return try {
            Log.d(TAG, "=== APK Installation Start ===")
            Log.d(TAG, "installApk called with filePath: $filePath")
            Log.d(TAG, "Android version: ${Build.VERSION.SDK_INT}")
            Log.d(TAG, "Package name: $packageName")
            
            // Check if we have permission to install unknown apps
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val canInstall = canInstallApks()
                Log.d(TAG, "Can install APKs: $canInstall")
                if (!canInstall) {
                    Log.w(TAG, "Permission check indicates install not allowed, but proceeding anyway")
                    Log.w(TAG, "System will show permission prompt if needed")
                }
            }
            
            val file = File(filePath)
            Log.d(TAG, "Checking APK file: ${file.absolutePath}")
            if (!file.exists()) {
                Log.e(TAG, "APK file does not exist: $filePath")
                return false
            }
            
            Log.d(TAG, "APK file exists, size: ${file.length()} bytes")
            Log.d(TAG, "APK file readable: ${file.canRead()}")

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
                    Log.d(TAG, "Found ${resolveInfos.size} activities that can handle APK install")
                    
                    for (resolveInfo in resolveInfos) {
                        val packageName = resolveInfo.activityInfo.packageName
                        grantUriPermission(packageName, uri, Intent.FLAG_GRANT_READ_URI_PERMISSION)
                        Log.d(TAG, "Granted URI permission to: $packageName")
                    }
                    
                    if (resolveInfos.isEmpty()) {
                        Log.e(TAG, "No activities found that can handle APK installation!")
                        return false
                    }
                } catch (e: Exception) {
                    Log.e(TAG, "FileProvider error: ${e.message}", e)
                    Log.e(TAG, "FileProvider error class: ${e.javaClass.simpleName}")
                    e.printStackTrace()
                    return false
                }
            } else {
                // Direct file URI for older Android versions
                Log.d(TAG, "Using direct file URI for older Android")
                intent.setDataAndType(Uri.fromFile(file), "application/vnd.android.package-archive")
            }

            Log.d(TAG, "Intent data: ${intent.data}")
            Log.d(TAG, "Intent type: ${intent.type}")
            Log.d(TAG, "Intent flags: ${intent.flags}")
            
            Log.d(TAG, "Starting install activity...")
            startActivity(intent)
            Log.d(TAG, "Install activity started successfully")
            Log.d(TAG, "=== APK Installation End ===")
            true
        } catch (e: Exception) {
            Log.e(TAG, "=== APK Installation Failed ===")
            Log.e(TAG, "installApk failed: ${e.message}", e)
            Log.e(TAG, "Exception class: ${e.javaClass.simpleName}")
            e.printStackTrace()
            false
        }
    }

    private fun canInstallApks(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            try {
                val canInstall = packageManager.canRequestPackageInstalls()
                Log.d(TAG, "canRequestPackageInstalls() returned: $canInstall")
                canInstall
            } catch (e: SecurityException) {
                // This shouldn't happen with proper permissions, but as a fallback
                Log.e(TAG, "SecurityException in canRequestPackageInstalls(): ${e.message}")
                // Return false to trigger permission request flow
                false
            } catch (e: Exception) {
                Log.e(TAG, "Unexpected error in canRequestPackageInstalls(): ${e.message}", e)
                false
            }
        } else {
            Log.d(TAG, "Android version < O, no special permission needed")
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
