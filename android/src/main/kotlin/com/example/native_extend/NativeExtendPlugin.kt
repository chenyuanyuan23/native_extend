package com.example.native_extend

import android.content.Context
import android.os.PowerManager
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.io.File
import java.io.FileOutputStream
import java.io.IOException
import java.io.BufferedReader
import java.io.InputStreamReader
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.telephony.TelephonyManager
import java.net.InetAddress
import java.net.NetworkInterface
import java.net.Inet4Address
import android.media.AudioManager

/** NativeExtendPlugin */
class NativeExtendPlugin : FlutterPlugin, MethodCallHandler {
  private lateinit var channel: MethodChannel
  private lateinit var context: Context
  private lateinit var audioManager: AudioManager
  private var audioFocusState = 0

  //注册OnAudioFocusChangeListener监听
  private val afChangeListener = AudioManager.OnAudioFocusChangeListener { focusChange ->
    when (focusChange) {
      AudioManager.AUDIOFOCUS_LOSS_TRANSIENT -> {
        // 暂时失去焦点
      }
      AudioManager.AUDIOFOCUS_GAIN -> {
        // 重新获得焦点
      }
      AudioManager.AUDIOFOCUS_LOSS -> {
        // 永久失去焦点
        abandonAudioFocus()
      }
    }
  }

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "native_extend")
    channel.setMethodCallHandler(this)
    context = flutterPluginBinding.applicationContext
    audioManager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    when (call.method) {
      "getPlatformVersion" -> {
        result.success("Android ${android.os.Build.VERSION.RELEASE}")
      }
      "getDeviceDnsServers" -> {
        result.success(getDeviceDnsServers())
      }
      "getDeviceMccMnc" -> {
        result.success(getDeviceMccMnc())
      }
      "checkVpnProxyStatus" -> {
        result.success(checkVpnProxyStatus())
      }
      "getDeviceNatType" -> {
        result.success(getDeviceNatType())
      }
      "setBrightness" -> {
        val brightnessLevel = call.argument<Int>("brightness") ?: 128
        setBrightness(brightnessLevel, result)
      }
      "setBrightnessMode" -> {
        val mode = call.argument<Int>("mode") ?: Settings.System.SCREEN_BRIGHTNESS_MODE_MANUAL
        setBrightnessMode(mode, result)
      }
      "openWriteSettingsPermissionPage" -> {
        openWriteSettingsPermissionPage(result)
      }
      "hasWriteSettingsPermission" -> {
        hasWriteSettingsPermission(result)
      }
      "checkBatteryOptimization" -> {
          checkBatteryOptimization(result)
      }
      "openBatteryOptimizationSettings" -> {
          openBatteryOptimizationSettings(result)
      }
      "openAppSettings" -> {
          openAppSettings(result)
      }
      "changeHeicToPng" -> {
        val oldPath = call.arguments as String
        changeHeicToPng(oldPath, result)
      }
      // ========== 从 device_info 插件迁移的接口 ==========
      "getAndroidId" -> {
        getAndroidId(result)
      }
      "isHEVCSupported" -> {
        isHEVCSupported(result)
      }
      "getTotalSpace" -> {
        getTotalSpace(result)
      }
      "getFreeSpace" -> {
        getFreeSpace(result)
      }
      "requestAudioFocus" -> {
        result.success(requestAudioFocus())
      }
      "abandonAudioFocus" -> {
        result.success(abandonAudioFocus())
      }
      "setMixWithOthers" -> {
        result.success(setMixWithOthers(call.arguments != null))
      }
      "getAudioFocusState" -> {
        result.success(audioFocusState)
      }
      else -> {
        result.notImplemented()
      }
    }
  }
// 实现getDeviceDnsServers方法
private fun getDeviceDnsServers(): List<String> {
    val dnsServers = ArrayList<String>()
    
    try {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val connectivityManager = context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
            val network = connectivityManager.activeNetwork
            val linkProperties = connectivityManager.getLinkProperties(network)
            
            if (linkProperties != null && Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                for (server in linkProperties.dnsServers) {
                    dnsServers.add(server.hostAddress)
                }
            }
        }
        
        // 如果上面的方法没有获取到DNS或者SDK版本较低，尝试系统属性
        if (dnsServers.isEmpty()) {
            try {
                val process = Runtime.getRuntime().exec("getprop net.dns1")
                val reader = BufferedReader(InputStreamReader(process.inputStream))
                val dns1 = reader.readLine()
                if (!dns1.isNullOrEmpty()) {
                    dnsServers.add(dns1)
                }
                reader.close()
                
                val process2 = Runtime.getRuntime().exec("getprop net.dns2")
                val reader2 = BufferedReader(InputStreamReader(process2.inputStream))
                val dns2 = reader2.readLine()
                if (!dns2.isNullOrEmpty()) {
                    dnsServers.add(dns2)
                }
                reader2.close()
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    } catch (e: Exception) {
        e.printStackTrace()
    }
    
    return dnsServers
}
// 实现getDeviceMccMnc方法
private fun getDeviceMccMnc(): Map<String, String> {
    val result = HashMap<String, String>()
    
    try {
        val telephonyManager = context.getSystemService(Context.TELEPHONY_SERVICE) as TelephonyManager
        
        var networkOperator = telephonyManager.networkOperator
        if (networkOperator.isNotEmpty() && networkOperator.length >= 5) {
            result["mcc"] = networkOperator.substring(0, 3)
            result["mnc"] = networkOperator.substring(3)
        } else {
            result["mcc"] = ""
            result["mnc"] = ""
        }
        
        result["carrierName"] = telephonyManager.networkOperatorName ?: ""
    } catch (e: Exception) {
        e.printStackTrace()
        result["mcc"] = ""
        result["mnc"] = ""
        result["carrierName"] = ""
    }
    
    return result
}

// 实现checkVpnProxyStatus方法
private fun checkVpnProxyStatus(): Map<String, Boolean> {
    val result = HashMap<String, Boolean>()
    
    try {
        // 检查VPN连接
        val connectivityManager = context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
        var isVpnActive = false
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val network = connectivityManager.activeNetwork
            val capabilities = connectivityManager.getNetworkCapabilities(network)
            isVpnActive = capabilities?.hasTransport(NetworkCapabilities.TRANSPORT_VPN) ?: false
        } else {
            try {
                @Suppress("DEPRECATION")
                val networks = connectivityManager.allNetworks
                for (network in networks) {
                    @Suppress("DEPRECATION")
                    val networkInfo = connectivityManager.getNetworkInfo(network)
                    if (networkInfo != null && networkInfo.type == ConnectivityManager.TYPE_VPN && networkInfo.isConnected) {
                        isVpnActive = true
                        break
                    }
                }
            } catch (e: Exception) {
                // 忽略旧版API中的异常
            }
        }
        
        // 检查代理设置
        var isProxyEnabled = false
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val network = connectivityManager.activeNetwork
            val linkProperties = connectivityManager.getLinkProperties(network)
            isProxyEnabled = linkProperties?.httpProxy != null
        } else {
            val proxyHost = System.getProperty("http.proxyHost")
            val proxyPort = System.getProperty("http.proxyPort")
            isProxyEnabled = !proxyHost.isNullOrEmpty() && !proxyPort.isNullOrEmpty()
        }
        
        result["isVpnActive"] = isVpnActive
        result["isProxyEnabled"] = isProxyEnabled
    } catch (e: Exception) {
        e.printStackTrace()
        result["isVpnActive"] = false
        result["isProxyEnabled"] = false
    }
    
    return result
}

// 实现getDeviceNatType方法
private fun getDeviceNatType(): String {
    // 简化版NAT类型检测，基于网络类型和IP地址
    try {
        val connectivityManager = context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
        
        // 检查网络类型
        var isWifi = false
        var isMobile = false
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val network = connectivityManager.activeNetwork
            val capabilities = connectivityManager.getNetworkCapabilities(network)
            isWifi = capabilities?.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) ?: false
            isMobile = capabilities?.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR) ?: false
        } else {
            @Suppress("DEPRECATION")
            val networkInfo = connectivityManager.activeNetworkInfo
            if (networkInfo != null) {
                isWifi = networkInfo.type == ConnectivityManager.TYPE_WIFI
                isMobile = networkInfo.type == ConnectivityManager.TYPE_MOBILE
            }
        }
        
        // 获取本地IP
        val localIp = getLocalIpAddress()
        val isPrivateIp = isPrivateIpAddress(localIp)
        
        // 基于启发式规则推断NAT类型
        if (!isPrivateIp) {
            return "Public IP (No NAT)"
        } else if (isWifi) {
            return "Symmetric NAT (WiFi)"
        } else if (isMobile) {
            return "Carrier-grade NAT (Mobile)"
        } else {
            return "Unknown NAT type"
        }
    } catch (e: Exception) {
        e.printStackTrace()
        return "Unknown NAT type"
    }
}

// 获取本地IP地址的辅助方法
private fun getLocalIpAddress(): String {
    try {
        val interfaces = NetworkInterface.getNetworkInterfaces()
        while (interfaces.hasMoreElements()) {
            val networkInterface = interfaces.nextElement()
            val addresses = networkInterface.inetAddresses
            
            while (addresses.hasMoreElements()) {
                val address = addresses.nextElement()
                
                // 过滤IPv6和回环地址
                if (!address.isLoopbackAddress && address is Inet4Address) {
                    return address.hostAddress
                }
            }
        }
    } catch (e: Exception) {
        e.printStackTrace()
    }
    
    return "127.0.0.1" // 默认回环地址
}

// 检查IP是否为私有地址的辅助方法
private fun isPrivateIpAddress(ipAddress: String): Boolean {
    return try {
        val addr = InetAddress.getByName(ipAddress)
        addr.isSiteLocalAddress || 
        addr.isLinkLocalAddress || 
        addr.isLoopbackAddress ||
        ipAddress.startsWith("10.") ||
        ipAddress.startsWith("192.168.") ||
        (ipAddress.startsWith("172.") && 
         ipAddress.split(".").getOrNull(1)?.toIntOrNull() in 16..31)
    } catch (e: Exception) {
        e.printStackTrace()
        false
    }
}
  // Method to set screen brightness
  private fun setBrightness(brightnessLevel: Int, result: Result) {
    try {
      if (brightnessLevel < 0 || brightnessLevel > 255) {
        result.error("INVALID_BRIGHTNESS", "Brightness level must be between 0 and 255", null)
        return
      }

      Settings.System.putInt(context.contentResolver, Settings.System.SCREEN_BRIGHTNESS, brightnessLevel)
      result.success("Brightness set to $brightnessLevel")
    } catch (e: Exception) {
      result.error("ERROR", "Could not set brightness: ${e.message}", null)
    }
  }

  // Method to set brightness mode (automatic/manual)
  private fun setBrightnessMode(mode: Int, result: Result) {
    try {
      if (mode != Settings.System.SCREEN_BRIGHTNESS_MODE_AUTOMATIC &&
          mode != Settings.System.SCREEN_BRIGHTNESS_MODE_MANUAL) {
        result.error("INVALID_MODE", "Mode must be 0 (manual) or 1 (automatic)", null)
        return
      }

      Settings.System.putInt(context.contentResolver, Settings.System.SCREEN_BRIGHTNESS_MODE, mode)
      result.success("Brightness mode set to $mode")
    } catch (e: Exception) {
      result.error("ERROR", "Could not set brightness mode: ${e.message}", null)
    }
  }

  // Method to open the "Write System Settings" permission page
  private fun openWriteSettingsPermissionPage(result: Result) {
    try {
      if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
        val intent = Intent(Settings.ACTION_MANAGE_WRITE_SETTINGS)
        intent.data = Uri.parse("package:" + context.packageName)
        intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
        context.startActivity(intent)
        result.success("Permission page opened")
      } else {
        result.error("UNSUPPORTED_VERSION", "This feature is only available on Android 6.0 (API 23) or later", null)
      }
    } catch (e: Exception) {
      result.error("ERROR", "Could not open permission page: ${e.message}", null)
    }
  }

  // Method to check if the "Write System Settings" permission has been granted
  private fun hasWriteSettingsPermission(result: Result) {
    try {
      if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
        val permissionGranted = Settings.System.canWrite(context)
        result.success(permissionGranted)
      } else {
        result.success(true) // Permission is automatically granted on versions below Android 6.0
      }
    } catch (e: Exception) {
      result.error("ERROR", "Could not check permission: ${e.message}", null)
    }
  }

  private fun checkBatteryOptimization(result: Result) {
    try {
      val powerManager = context?.getSystemService(Context.POWER_SERVICE) as PowerManager
      val isIgnoringBatteryOptimizations = powerManager.isIgnoringBatteryOptimizations(context?.packageName)
      result.success(isIgnoringBatteryOptimizations)
    } catch (e: Exception) {
      result.error("ERROR", "Could not check battery optimization status: ${e.message}", null)
    }
  }


  private fun openBatteryOptimizationSettings(result: Result) {
    try {
      val intent = Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)
      intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK) // Required for starting an activity from non-activity context
      context?.startActivity(intent)
    } catch (e: Exception) {
      // Handle the error, or notify the result if applicable
      result.error("ERROR", "Could not open battery optimization settings: ${e.message}", null)
    }
  }

  private fun openAppSettings(result: Result) {
    try {
      val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
      val uri = Uri.fromParts("package", context?.packageName, null)
      intent.data = uri
      intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK) // Required for non-activity context
      context?.startActivity(intent)
    } catch (e: Exception) {
      result.error("ERROR", "Failed to open app settings: ${e.message}", null)
    }
  }

  private fun changeHeicToPng(oldPath: String, result: Result) {
    val oldFile = File(oldPath)
    if (!oldFile.exists()) {
        result.error("ERROR", "File is not exists", null)
        return
    }

    // Load the HEIC image as a Bitmap
    val bitmap: Bitmap? = BitmapFactory.decodeFile(oldPath)
    if (bitmap == null) {
        result.error("ERROR", "Load the HEIC image as a Bitmap fail", null)
        return
    }

    // Create a new file path for the PNG image
    val fileName = oldFile.nameWithoutExtension + ".png"
    val destinationPath = File(oldFile.parent, fileName).absolutePath

    // Save the bitmap as a PNG file
    try {
        val outputStream = FileOutputStream(destinationPath)
        bitmap.compress(Bitmap.CompressFormat.PNG, 100, outputStream)
        outputStream.flush()
        outputStream.close()
        result.success(destinationPath)  // Return the path of the new PNG file
    } catch (e: IOException) {
        e.printStackTrace()
        result.error("ERROR", "change to png fail", null)  // Return an empty string in case of an error
    }
  }

  // ========== 从 device_info 插件迁移的实现方法 ==========
  
  // DeviceUuidFactory 实例
  private var deviceUuidFactory: DeviceUuidFactory? = null

  private fun getAndroidId(result: Result) {
    try {
      // 使用原始的 DeviceUuidFactory Java 类
      if (deviceUuidFactory == null) {
        deviceUuidFactory = DeviceUuidFactory(context)
      }
      val deviceId = DeviceUuidFactory.getUuid().toString()
      result.success(deviceId)
    } catch (e: Exception) {
      result.error("ERROR", "Could not get Android ID: ${e.message}", null)
    }
  }

  private fun isHEVCSupported(result: Result) {
    try {
      var isHaveH265 = false
      if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
        val codecList = android.media.MediaCodecList(android.media.MediaCodecList.ALL_CODECS)
        for (codecInfo in codecList.codecInfos) {
          val types = codecInfo.supportedTypes
          for (type in types) {
            if (type.equals("video/hevc", ignoreCase = true)) {
              isHaveH265 = true
              break
            }
          }
          if (isHaveH265) break
        }
      }
      result.success(isHaveH265)
    } catch (e: Exception) {
      result.error("ERROR", "Could not check HEVC support: ${e.message}", null)
    }
  }

  private fun getTotalSpace(result: Result) {
    try {
      val stat = android.os.StatFs(android.os.Environment.getDataDirectory().path)
      val blockSize = stat.blockSizeLong
      val totalBlocks = stat.blockCountLong
      val totalSpace = blockSize * totalBlocks
      result.success(totalSpace)
    } catch (e: Exception) {
      result.error("ERROR", "Could not get total space: ${e.message}", null)
    }
  }

  private fun getFreeSpace(result: Result) {
    try {
      val stat = android.os.StatFs(android.os.Environment.getDataDirectory().path)
      val blockSize = stat.blockSizeLong
      val availableBlocks = stat.availableBlocksLong
      val freeSpace = blockSize * availableBlocks
      result.success(freeSpace)
    } catch (e: Exception) {
      result.error("ERROR", "Could not get free space: ${e.message}", null)
    }
  }
  
  private fun requestAudioFocus(): Boolean {
    audioFocusState = 1
    //在播放的时候为AudioManager添加获取焦点的监听
    val result = audioManager.requestAudioFocus(afChangeListener,
            AudioManager.STREAM_MUSIC,
            AudioManager.AUDIOFOCUS_GAIN)
    return true
  }

  private fun abandonAudioFocus(): Boolean {
    audioManager.abandonAudioFocus(afChangeListener)
    audioFocusState = 0
    return true
  }

  private fun setMixWithOthers(v: Boolean): Boolean {
    if (!v) {
      requestAudioFocus()
    } else {
      abandonAudioFocus()
    }
    return true
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }
}
