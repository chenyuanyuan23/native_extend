import Flutter
import UIKit
import SystemConfiguration
import AudioToolbox
import VideoToolbox
import AVFoundation
import Foundation
import CoreTelephony
import NetworkExtension
import CFNetwork
import AdSupport
import Security
import native_extend.ResolvWrapper


public class NativeExtendPlugin: NSObject, FlutterPlugin, UIDocumentPickerDelegate {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "native_extend", binaryMessenger: registrar.messenger())
        let instance = NativeExtendPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    var imageDict: NSDictionary?
    var isLandscape: Int = 0
    var orientationsResult: FlutterResult?
    var documentPicker: UIDocumentPickerViewController?
    var documentResult: FlutterResult?
    
    // 获取HomeIndicatorAwareFlutterViewController实例的方法
    private func controller() -> HomeIndicatorAwareFlutterViewController? {
        guard let window = UIApplication.shared.keyWindow else { return nil }
        guard let rvc = window.rootViewController else { return nil }
        
        if let rvc = rvc as? HomeIndicatorAwareFlutterViewController {
            return rvc
        }
        
        guard let fvc = rvc as? FlutterViewController else { return nil }
        
        object_setClass(fvc, HomeIndicatorAwareFlutterViewController.self)
        let newController = fvc as! HomeIndicatorAwareFlutterViewController
        window.rootViewController = newController as UIViewController?
        return newController
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let noController = FlutterError(code: "NO_CONTROLLER", message: "Error fetching HomeIndicatorAwareFlutterViewController", details: nil)
        let noArgument = FlutterError(code: "NO_ARGUMENT", message: "Expected an argument to \(call.method) but didn't get any", details: nil)
        let argumentError = FlutterError(code: "ARGUMENT_ERROR", message: "Argument to \(call.method) has the wrong type", details: nil)
        
        switch call.method {
        case "getPlatformVersion":
            result("iOS " + UIDevice.current.systemVersion)
        case "getLastShareFilePath":
            self.getLastShareFilePath(result: result)
        case "clearLastShareFilePath":
            self.clearLastShareFilePath(result: result)
        case "getSonChannel":
            let infoDict = Bundle.main.infoDictionary
            result(infoDict?["flutter_son_channel"] as? String ?? NSNull())
        case "ShareFilePath":
            result(nil)
        case "openDocument":
            self.documentResult = result;
            self.documentPicker = UIDocumentPickerViewController.init(documentTypes: ["public.item"], in: .open)
            //            TODO
            //            self.documentPicker?.delegate = self
            //            self.documentPicker?.modalPresentationStyle = .formSheet
            //            controller.present(self.documentPicker!, animated: true)
        case "pushToken":
            let defaults = UserDefaults.init(suiteName: "group.xxx.xxx.xxx")
            defaults?.set(call.arguments, forKey: "my_token")
            result(true)
        case "pushUrl":
            let defaults = UserDefaults.init(suiteName: "group.xxx.xxx.xxx")
            defaults?.set(call.arguments, forKey: "my_url")
            result(true)
        case "pushUserId":
            let defaults = UserDefaults.init(suiteName: "group.xxx.xxx.xxx")
            defaults?.set(call.arguments, forKey: "current_user_id")
            //            Bugly.setUserIdentifier((call.arguments as! String))
            result(true)
        case "iosIsEnterHome":
            let defaults = UserDefaults.init(suiteName: "group.xxx.xxx.xxx")
            defaults?.set(call.arguments, forKey: "is_enter_home")
            result(true)
        case "changeMovToMp4":
            self.movToMp4Url(result: result, oldPath: call.arguments as! String)
        case "changeHeicToPng":
            self.changeHeicToPng(result: result, oldPath: call.arguments as! String)
        case "get_system_volume":
            result("iOS " + UIDevice.current.systemVersion)
        case "jump_location_center":
            result("iOS " + UIDevice.current.systemVersion)
        case "switchFullScreen":
            self.isLandscape = 1
            //            _ = self.application(application, supportedInterfaceOrientationsFor: self.window)
            result(true)
            self.orientationsResult = result
        case "switchAllScreen":
            self.isLandscape = 2
            //            _ =  self.application(application, supportedInterfaceOrientationsFor: self.window)
            result(true)
            self.orientationsResult = result
        case "switchPortraitScreen":
            self.isLandscape = 0
            //            _ =  self.application(application, supportedInterfaceOrientationsFor: self.window)
            result(true)
            self.orientationsResult = result
        case "focus_other_music":
            self.focusOtherMusic(result: result, close: (call.arguments as! Bool))
        case "end_carplay":
            let audioSession = AVAudioSession.sharedInstance()
            try? audioSession.setCategory(.playAndRecord, mode: .default, options: .duckOthers)
            try? audioSession.setActive(true)
            result(true)
        case "resume_carplay":
            let audioSession = AVAudioSession.sharedInstance()
            try? audioSession.setCategory(.playAndRecord, mode: .default, options: .duckOthers)
            result(true)
        case "HomeIndicator.hide":
            guard let controller = controller() else { result(noController); return }
            controller.setHidingHomeIndicator(newValue: true)
            result(nil)
        case "HomeIndicator.show":
            guard let controller = controller() else { result(noController); return }
            controller.setHidingHomeIndicator(newValue: false)
            result(nil)
        case "HomeIndicator.isHidden":
            result(HomeIndicatorAwareFlutterViewController.hidingHomeIndicator)
        case "HomeIndicator.deferScreenEdges":
            guard let controller = controller() else { result(noController); return }
            guard let arg = call.arguments else { result(noArgument); return }
            guard let num = arg as? UInt else { result(argumentError); return }
            controller.setDeferredEdges(newValue: UIRectEdge(rawValue: num))
        case "HomeIndicator.removeTopLevelFlutterClippingMaskView":
            // 实现removeTopLevelFlutterClippingMaskView的代码逻辑
            result(nil)
        case "HomeIndicator.autoRemoveTopLevelFlutterClippingMaskView":
            // 实现autoRemoveTopLevelFlutterClippingMaskView的代码逻辑
            result(nil)
        case "getCpuInfo":
            result(self.getDeviceInfo())
        case "getDeviceDnsServers":
            result(getDeviceDnsServers())
        case "getDeviceMccMnc":
            result(getDeviceMccMnc())
        case "checkVpnProxyStatus":
            checkVpnProxyStatus(result: result)
        case "getDeviceNatType":
            result(getDeviceNatType())
        // ========== 从 device_info 插件迁移的接口 ==========
        case "getUUID":
            let appName = (call.arguments as? [String: Any])?["appName"] as? String ?? ""
            result(getUUID(appName: appName))
        case "isHEVCSupported":
            result(isHEVCSupported())
        case "getTotalSpace":
            result(getTotalSpace())
        case "getFreeSpace":
            result(getFreeSpace())
        case "requestAudioFocus":
            result(requestAudioFocus())
        case "abandonAudioFocus":
            result(abandonAudioFocus())
        case "setMixWithOthers":
            result(setMixWithOthers(v: (call.arguments != nil)))
        case "getAudioFocusState":
            result(0) // iOS 不需要状态管理，直接返回0
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func getDeviceDnsServers() -> [String] {
        let data = ResolvWrapper.outPutDNSServers()
        return data as! [String]
    }
    
    // 验证是否为有效的IP地址
    private func isValidIpAddress(_ address: String) -> Bool {
        // 简单的IP地址验证
        let components = address.components(separatedBy: ".")
        
        // 必须有4个部分
        guard components.count == 4 else {
            return false
        }
        
        // 每部分必须是0-255之间的数字
        for component in components {
            guard let num = Int(component), num >= 0, num <= 255 else {
                return false
            }
        }
        
        // 排除特殊的情况，如"*.local"和网络范围表示
        if address.contains("*") || address.contains("/") {
            return false
        }
        
        return true
    }
    private func getDeviceMccMnc() -> [String: String] {
        var info: [String: String] = [
            "mcc": "",
            "mnc": "",
            "carrierName": ""
        ]
        
        let networkInfo = CTTelephonyNetworkInfo()
        
        if #available(iOS 12.0, *) {
            if let carriers = networkInfo.serviceSubscriberCellularProviders, let carrier = carriers.values.first {
                info["mcc"] = carrier.mobileCountryCode ?? ""
                info["mnc"] = carrier.mobileNetworkCode ?? ""
                info["carrierName"] = carrier.carrierName ?? ""
            }
        } else {
            if let carrier = networkInfo.subscriberCellularProvider {
                info["mcc"] = carrier.mobileCountryCode ?? ""
                info["mnc"] = carrier.mobileNetworkCode ?? ""
                info["carrierName"] = carrier.carrierName ?? ""
            }
        }
        
        return info
    }
    
    private func checkVpnProxyStatus(result: @escaping FlutterResult) -> Void {
        let status: [String: Bool] = [
            "isVpnActive": NativeExtendPlugin.sta_isVPNOn,
            "isProxyEnabled": false
        ]
        
        result(status)
    }
    
    /// 判断VPN是否打开
    @objc static var sta_isVPNOn: Bool {
        
        guard let cfDict = CFNetworkCopySystemProxySettings() else {
            return false
        }
        
        let nsDict = cfDict.takeRetainedValue() as NSDictionary
        
        guard let keys = nsDict["__SCOPED__"] as? [String:Any] else {
            return false
        }
        
        let keyValues: [String] = [
            "tap",
            "tun",
            "ppp",
            "ipsec",
            "ipsec0",
        ]
        
        var result: Bool = false
        for key in keys.keys {
            keyValues.forEach { (value) in
                if key.contains(value) {
                    result = true
                }
            }
        }
        
        return result
    }
    
    private func getDeviceNatType() -> String {
        // 检查本机IP地址
        var address: String?
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        var natType = "Unknown NAT"
        
        guard getifaddrs(&ifaddr) == 0 else {
            return "Unknown NAT"
        }
        defer { freeifaddrs(ifaddr) }
        
        var hasPrivateIP = false
        var hasPublicIP = false
        var interfaces = 0
        
        var ptr = ifaddr
        while ptr != nil {
            let interface = ptr!.pointee
            let addrFamily = interface.ifa_addr.pointee.sa_family
            
            if addrFamily == UInt8(AF_INET) || addrFamily == UInt8(AF_INET6) {
                // 排除本地回环接口
                let name = String(cString: interface.ifa_name)
                if name == "en0" || name == "en1" || name == "pdp_ip0" {
                    interfaces += 1
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    getnameinfo(interface.ifa_addr, socklen_t(interface.ifa_addr.pointee.sa_len),
                                &hostname, socklen_t(hostname.count),
                                nil, socklen_t(0), NI_NUMERICHOST)
                    address = String(cString: hostname)
                    
                    if let ipAddress = address {
                        if isPrivateIp(ipAddress) {
                            hasPrivateIP = true
                        } else if !ipAddress.hasPrefix("169.254") { // 排除链路本地地址
                            hasPublicIP = true
                        }
                    }
                }
            }
            ptr = ptr!.pointee.ifa_next
        }
        
        // 由于无法通过本地信息真正确定NAT类型，这里使用启发式方法
        if hasPublicIP && !hasPrivateIP {
            natType = "No NAT"
        } else if hasPrivateIP {
            // 这里使用一些启发式判断来区分不同类型的NAT
            // 实际上需要STUN服务器测试才能准确判断
            
            // 获取上次记录的网络活动情况（此处为模拟代码，实际应用中应使用持久化存储）
            let lastNetworkActivity = UserDefaults.standard.integer(forKey: "lastNetworkActivity")
            let currentTime = Int(Date().timeIntervalSince1970)
            
            if interfaces > 1 {
                // 多个接口可能表明更复杂的网络配置，假设为对称型NAT
                natType = "Symmetric NAT"
            } else if let gatewayAddress = getDefaultGateway(), gatewayAddress.hasPrefix("192.168.") {
                // 常见家庭路由器地址，通常实现端口限制型NAT
                natType = "Port Restricted Cone NAT"
            } else if currentTime - lastNetworkActivity > 3600 { // 一小时以上
                // 如果长时间未活动，假设会话可能已超时，这是限制型NAT的特征
                natType = "Restricted Cone NAT"
            } else {
                // 默认情况下，假设为完全圆锥型NAT
                natType = "Full Cone NAT"
            }
            
            // 更新上次网络活动时间
            UserDefaults.standard.set(currentTime, forKey: "lastNetworkActivity")
        }
        
        return natType
    }
    
    // 获取默认网关地址的辅助函数
    private func getDefaultGateway() -> String? {
        var address: String?
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        
        guard getifaddrs(&ifaddr) == 0 else { return nil }
        defer { freeifaddrs(ifaddr) }
        
        var ptr = ifaddr
        while ptr != nil {
            let interface = ptr!.pointee
            let addrFamily = interface.ifa_addr.pointee.sa_family
            
            if addrFamily == UInt8(AF_INET) {
                let name = String(cString: interface.ifa_name)
                if name == "en0" { // Wi-Fi接口
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    getnameinfo(interface.ifa_addr, socklen_t(interface.ifa_addr.pointee.sa_len),
                                &hostname, socklen_t(hostname.count),
                                nil, socklen_t(0), NI_NUMERICHOST)
                    address = String(cString: hostname)
                    
                    if let ipAddress = address {
                        let components = ipAddress.split(separator: ".")
                        if components.count >= 3 {
                            return "\(components[0]).\(components[1]).\(components[2]).1"
                        }
                    }
                    break
                }
            }
            ptr = ptr!.pointee.ifa_next
        }
        
        return "192.168.1.1" // 默认网关
    }
    
    private func isPrivateIp(_ ipAddress: String) -> Bool {
        // 检查是否为私有IP地址
        return ipAddress.hasPrefix("10.") ||
        ipAddress.hasPrefix("172.16.") || ipAddress.hasPrefix("172.17.") ||
        ipAddress.hasPrefix("172.18.") || ipAddress.hasPrefix("172.19.") ||
        ipAddress.hasPrefix("172.20.") || ipAddress.hasPrefix("172.21.") ||
        ipAddress.hasPrefix("172.22.") || ipAddress.hasPrefix("172.23.") ||
        ipAddress.hasPrefix("172.24.") || ipAddress.hasPrefix("172.25.") ||
        ipAddress.hasPrefix("172.26.") || ipAddress.hasPrefix("172.27.") ||
        ipAddress.hasPrefix("172.28.") || ipAddress.hasPrefix("172.29.") ||
        ipAddress.hasPrefix("172.30.") || ipAddress.hasPrefix("172.31.") ||
        ipAddress.hasPrefix("192.168.") ||
        ipAddress.hasPrefix("169.254.")
    }
    // 获取 CPU 名称
    private func getCPUName() -> String {
#if targetEnvironment(simulator)
        return "Simulator CPU"
#else
        let deviceName = self.getDeviceIdentifier()
        
        // 芯片名称映射
        let chipNameMap: [String: String] = [
            // A-series
            "iPhone8,1": "A9",
            "iPhone8,2": "A9",
            "iPhone8,4": "A9",
            "iPhone9,1": "A10 Fusion",
            "iPhone9,2": "A10 Fusion",
            "iPhone9,3": "A10 Fusion",
            "iPhone9,4": "A10 Fusion",
            "iPhone10,1": "A11 Bionic",
            "iPhone10,2": "A11 Bionic",
            "iPhone10,3": "A11 Bionic",
            "iPhone10,4": "A11 Bionic",
            "iPhone10,5": "A11 Bionic",
            "iPhone10,6": "A11 Bionic",
            "iPhone11,2": "A12 Bionic",
            "iPhone11,4": "A12 Bionic",
            "iPhone11,6": "A12 Bionic",
            "iPhone11,8": "A12 Bionic",
            "iPhone12,1": "A13 Bionic",
            "iPhone12,3": "A13 Bionic",
            "iPhone12,5": "A13 Bionic",
            "iPhone12,8": "A13 Bionic",
            "iPhone13,1": "A14 Bionic",
            "iPhone13,2": "A14 Bionic",
            "iPhone13,3": "A14 Bionic",
            "iPhone13,4": "A14 Bionic",
            "iPhone14,2": "A15 Bionic",
            "iPhone14,3": "A15 Bionic",
            "iPhone14,4": "A15 Bionic",
            "iPhone14,5": "A15 Bionic",
            "iPhone14,6": "A15 Bionic",
            "iPhone14,7": "A15 Bionic",
            "iPhone14,8": "A15 Bionic",
            "iPhone15,2": "A16 Bionic",
            "iPhone15,3": "A16 Bionic",
            "iPhone15,4": "A16 Bionic",
            "iPhone15,5": "A16 Bionic",
            "iPhone16,1": "A17 Pro",
            "iPhone16,2": "A17 Pro",
            "iPhone17,3": "A18",        // Corrected based on your list (Assuming 16,3 is standard)
            "iPhone17,4": "A18",   // Corrected based on your list (Assuming 16,4 is plus)
            "iPhone17,1": "A18 Pro",    // Corrected based on your list (Assuming 17,1 is pro)
            "iPhone17,2": "A18 Pro" // Corrected based on your list (Assuming 17,2 is pro max)
            
        ]
        
        return chipNameMap[deviceName] ?? "Unknown Apple Chip"
#endif
    }
    
    // 获取设备标识符
    private func getDeviceIdentifier() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier
    }
    // 获取设备详细信息
    private func getDeviceInfo() -> [String: Any] {
        let device = UIDevice.current
        
        var deviceInfo: [String: Any] = [
            "model": device.model,
            "systemName": device.systemName,
            "systemVersion": device.systemVersion,
            "modelName": getDeviceModelName(),
            "deviceName": device.name,
            "CPUName": getCPUName(),
            "cpuFrequency": getMaxCPUFrequency(),
            "architecture": getArchitecture(),
            "isJailbroken": isJailbroken()
        ]
        
        return deviceInfo
    }
    
    // 检测设备是否越狱
    private func isJailbroken() -> Bool {
        // 1. 检查常见越狱文件路径
        let jailbreakPaths = [
            "/Applications/Cydia.app",
            "/Library/MobileSubstrate/MobileSubstrate.dylib",
            "/bin/bash",
            "/usr/sbin/sshd",
            "/etc/apt",
            "/usr/bin/ssh",
            "/private/var/lib/apt/",
            "/private/var/lib/cydia",
            "/private/var/stash",
            "/private/var/mobile/Library/SBSettings/Themes",
            "/Library/PreferenceBundles/LibertySB.bundle",
            "/Library/PreferenceBundles/ShadowPreferences.bundle",
            "/Library/PreferenceBundles/FlyJBPrefs.bundle",
            "/Library/PreferenceBundles/ABypassPrefs.bundle",
            "/usr/lib/TweakInject",
            "/var/checkra1n.dmg"
        ]
        
        for path in jailbreakPaths {
            if FileManager.default.fileExists(atPath: path) {
                return true
            }
        }
        
        // 2. 检查是否可以写入私有目录（非越狱设备无法写入）
        let privateWriteTest = "/private/jailbreak_test.txt"
        do {
            try "jailbreak test".write(toFile: privateWriteTest, atomically: true, encoding: .utf8)
            try FileManager.default.removeItem(atPath: privateWriteTest)
            return true // 可以写入私有目录，说明已越狱
        } catch {
            // 无法写入，符合正常设备表现
        }
        
        // 3. 检查是否可以通过URL scheme打开越狱应用
        let urlSchemes = [
            "cydia://",
            "sileo://",
            "zbra://",
            "filza://",
            "activator://"
        ]
        
        for scheme in urlSchemes {
            if let url = URL(string: scheme), UIApplication.shared.canOpenURL(url) {
                return true
            }
        }
        
        // 4. 检查环境变量
        if getenv("DYLD_INSERT_LIBRARIES") != nil {
            return true
        }
        // 判断是否能访问系统所有应用
        let appPath = "/Applications/"
        if FileManager.default.fileExists(atPath: appPath){
            do{
                let appList = try FileManager.default.contentsOfDirectory(atPath: appPath)
                if appList.count >  0{
                    return true
                }
            }catch let error as NSError{
                print(error)
            }
        }
        return false
    }
    
    // 获取设备型号名称（如"iPhone 15 Pro"）
    // 获取设备型号名称（如"iPhone 15 Pro"）
    private func getDeviceModelName() -> String {
        let identifier = getDeviceIdentifier() // Assuming getDeviceIdentifier() exists and works
        
        // Updated deviceNameMap based on the provided list
        let deviceNameMap: [String: String] = [
            // iPhones based on your provided list
            "iPhone1,1": "iPhone (1st generation)",
            "iPhone1,2": "iPhone 3G",
            "iPhone2,1": "iPhone 3GS",
            "iPhone3,1": "iPhone 4 (GSM)",
            "iPhone3,2": "iPhone 4 (GSM Rev A)",
            "iPhone3,3": "iPhone 4 (CDMA)",
            "iPhone4,1": "iPhone 4S",
            "iPhone5,1": "iPhone 5 (GSM/LTE)",
            "iPhone5,2": "iPhone 5 (CDMA/LTE)",
            "iPhone5,3": "iPhone 5c (GSM/LTE)",
            "iPhone5,4": "iPhone 5c (CDMA/LTE)",
            "iPhone6,1": "iPhone 5s (GSM/LTE)",
            "iPhone6,2": "iPhone 5s (CDMA/LTE)",
            "iPhone7,1": "iPhone 6 Plus", // Note: Identifier from your list
            "iPhone7,2": "iPhone 6",      // Note: Identifier from your list
            "iPhone8,1": "iPhone 6s",
            "iPhone8,2": "iPhone 6s Plus",
            "iPhone8,4": "iPhone SE (1st generation)", // Combined name for simplicity, list had "iPhone SE"
            "iPhone9,1": "iPhone 7 (CDMA+GSM/LTE)", // Specific name from list
            "iPhone9,3": "iPhone 7 (GSM/LTE)",        // Specific name from list
            "iPhone9,2": "iPhone 7 Plus (CDMA+GSM/LTE)", // Specific name from list
            "iPhone9,4": "iPhone 7 Plus (GSM/LTE)",    // Specific name from list
            "iPhone10,1": "iPhone 8 (CDMA+GSM/LTE)",  // Specific name from list
            "iPhone10,4": "iPhone 8 (GSM/LTE)",        // Specific name from list
            "iPhone10,2": "iPhone 8 Plus (CDMA+GSM/LTE)",// Specific name from list
            "iPhone10,5": "iPhone 8 Plus (GSM/LTE)",    // Specific name from list
            "iPhone10,3": "iPhone X (CDMA+GSM/LTE)",   // Specific name from list
            "iPhone10,6": "iPhone X (GSM/LTE)",        // Specific name from list
            "iPhone11,2": "iPhone XS",
            "iPhone11,6": "iPhone XS Max", // Your list map for XS Max; Note: iPhone11,4 also exists sometimes
            "iPhone11,8": "iPhone XR",
            "iPhone12,1": "iPhone 11",
            "iPhone12,3": "iPhone 11 Pro",
            "iPhone12,5": "iPhone 11 Pro Max",
            "iPhone12,8": "iPhone SE (2nd generation)", // Combined name for simplicity
            "iPhone13,1": "iPhone 12 mini",
            "iPhone13,2": "iPhone 12",
            "iPhone13,3": "iPhone 12 Pro",
            "iPhone13,4": "iPhone 12 Pro Max",
            "iPhone14,4": "iPhone 13 mini", // Note identifier order
            "iPhone14,5": "iPhone 13",      // Note identifier order
            "iPhone14,2": "iPhone 13 Pro",   // Note identifier order
            "iPhone14,3": "iPhone 13 Pro Max",// Note identifier order
            "iPhone14,6": "iPhone SE (3rd generation)", // Combined name for simplicity
            "iPhone14,7": "iPhone 14",
            "iPhone14,8": "iPhone 14 Plus",
            "iPhone15,2": "iPhone 14 Pro",
            "iPhone15,3": "iPhone 14 Pro Max",
            "iPhone15,4": "iPhone 15",
            "iPhone15,5": "iPhone 15 Plus",
            "iPhone16,1": "iPhone 15 Pro",  // Corrected based on your list
            "iPhone16,2": "iPhone 15 Pro Max", // Corrected based on your list
            "iPhone17,3": "iPhone 16",        // Corrected based on your list (Assuming 16,3 is standard)
            "iPhone17,4": "iPhone 16 Plus",   // Corrected based on your list (Assuming 16,4 is plus)
            "iPhone17,1": "iPhone 16 Pro",    // Corrected based on your list (Assuming 17,1 is pro)
            "iPhone17,2": "iPhone 16 Pro Max" // Corrected based on your list (Assuming 17,2 is pro max)
            
            // Note: Your original code had iPhone11,4 mapped to XS Max, I've used 11,6 based on the list.
            // Note: Your original code had different identifiers for iPhone 16 models, I've used the ones from your list.
            // Note: Added older models and more specific names (like GSM/CDMA) from your list.
        ]
        
        return deviceNameMap[identifier] ?? "Unknown (\(identifier))" // Changed fallback slightly for clarity
    }
    
    
    
    // 获取最大 CPU 频率（MHz）
    private func getMaxCPUFrequency() -> Double {
        // 尝试多种系统调用
        var freq: UInt64 = 0
        var size = MemoryLayout<UInt64>.size
        
        // 方法1：尝试 hw.cpufrequency
        if sysctlbyname("hw.cpufrequency", &freq, &size, nil, 0) == 0 {
            let result = Double(freq) / 1_000_000.0
            // 验证结果是否在合理范围内
            if result > 0 && result < 5000 {
                NSLog("CPU DEBUG - 方法1 hw.cpufrequency: 原始值=%llu, 转换后=%.2f MHz", freq, result)
                return result
            } else {
                NSLog("CPU DEBUG - 方法1 hw.cpufrequency: 值超出合理范围: %.2f MHz", result)
            }
        }
        
        // 方法2：尝试 hw.cpumaxfrequency
        if sysctlbyname("hw.cpumaxfrequency", &freq, &size, nil, 0) == 0 {
            let result = Double(freq) / 1_000_000.0
            // 验证结果是否在合理范围内
            if result > 0 && result < 5000 {
                NSLog("CPU DEBUG - 方法2 hw.cpumaxfrequency: 原始值=%llu, 转换后=%.2f MHz", freq, result)
                return result
            } else {
                NSLog("CPU DEBUG - 方法2 hw.cpumaxfrequency: 值超出合理范围: %.2f MHz", result)
            }
        }
        
        // 方法3：根据设备型号提供合理的默认值
        let deviceIdentifier = getDeviceIdentifier()
        NSLog("CPU DEBUG - 方法3: 设备识别符=%@", deviceIdentifier)
        
        // 为常见的iOS设备提供CPU频率映射
        let chipFrequencyMap: [String: Double] = [
            // iPhone
            "iPhone8,1": 1850,  // iPhone 6s (A9)
            "iPhone8,2": 1850,  // iPhone 6s Plus (A9)
            "iPhone8,4": 1850,  // iPhone SE 1st gen (A9)
            "iPhone9,1": 2340,  // iPhone 7 (A10 Fusion)
            "iPhone9,2": 2340,  // iPhone 7 Plus (A10 Fusion)
            "iPhone9,3": 2340,  // iPhone 7 (A10 Fusion)
            "iPhone9,4": 2340,  // iPhone 7 Plus (A10 Fusion)
            "iPhone10,1": 2390, // iPhone 8 (A11 Bionic)
            "iPhone10,2": 2390, // iPhone 8 Plus (A11 Bionic)
            "iPhone10,3": 2390, // iPhone X (A11 Bionic)
            "iPhone10,4": 2390, // iPhone 8 (A11 Bionic)
            "iPhone10,5": 2390, // iPhone 8 Plus (A11 Bionic)
            "iPhone10,6": 2390, // iPhone X (A11 Bionic)
            "iPhone11,2": 2490, // iPhone XS (A12 Bionic)
            "iPhone11,4": 2490, // iPhone XS Max (A12 Bionic)
            "iPhone11,6": 2490, // iPhone XS Max (A12 Bionic)
            "iPhone11,8": 2490, // iPhone XR (A12 Bionic)
            "iPhone12,1": 2650, // iPhone 11 (A13 Bionic)
            "iPhone12,3": 2650, // iPhone 11 Pro (A13 Bionic)
            "iPhone12,5": 2650, // iPhone 11 Pro Max (A13 Bionic)
            "iPhone12,8": 2650, // iPhone SE 2nd gen (A13 Bionic)
            "iPhone13,1": 2990, // iPhone 12 mini (A14 Bionic)
            "iPhone13,2": 2990, // iPhone 12 (A14 Bionic)
            "iPhone13,3": 2990, // iPhone 12 Pro (A14 Bionic)
            "iPhone13,4": 2990, // iPhone 12 Pro Max (A14 Bionic)
            "iPhone14,2": 3230, // iPhone 13 Pro (A15 Bionic)
            "iPhone14,3": 3230, // iPhone 13 Pro Max (A15 Bionic)
            "iPhone14,4": 3230, // iPhone 13 mini (A15 Bionic)
            "iPhone14,5": 3230, // iPhone 13 (A15 Bionic)
            "iPhone14,6": 3230, // iPhone SE 3rd gen (A15 Bionic)
            "iPhone14,7": 3230, // iPhone 14 (A15 Bionic)
            "iPhone14,8": 3230, // iPhone 14 Plus (A15 Bionic)
            "iPhone15,2": 3460, // iPhone 14 Pro (A16 Bionic)
            "iPhone15,3": 3460, // iPhone 14 Pro Max (A16 Bionic)
            "iPhone15,4": 3460, // iPhone 15 (A16 Bionic) - 修正频率
            "iPhone15,5": 3460, // iPhone 15 Plus (A16 Bionic) - 修正频率
             // iPhone 16系列更准确的频率  
            "iPhone16,1": 3780, // iPhone 15 Pro (A17 Pro) - 已正确
            "iPhone16,2": 3780, // iPhone 15 Pro Max (A17 Pro) - 已正确
            "iPhone16,3": 3780, // iPhone 16 (A18) - 建议从3900调整为3780
            "iPhone16,4": 3780, // iPhone 16 Plus (A18) - 建议从3900调整为3780  
            "iPhone16,5": 3780, // iPhone 16 Pro (A18 Pro) - 建议从4000调整为3780
            "iPhone16,6": 3780, // iPhone 16 Pro Max (A18 Pro) - 建议从4000调整为3780
            "iPhone16,7": 3900, // 可能的其他变体
            "iPhone16,8": 4000, // 可能的其他变体
            
            
        ]
        
        // 如果找到设备特定频率，使用它
        if let frequency = chipFrequencyMap[deviceIdentifier] {
            NSLog("CPU DEBUG - 方法3: 根据设备型号估算频率=%.2f MHz", frequency)
            return frequency
        }
        
        // 如果找不到特定设备，使用处理器数量提供合理默认值
        let processorCount = ProcessInfo.processInfo.processorCount
        var defaultFreq: Double
        
        if processorCount >= 6 {
            defaultFreq = 3000.0  // 较新设备默认3GHz
        } else if processorCount >= 4 {
            defaultFreq = 2500.0  // 中等设备默认2.5GHz
        } else {
            defaultFreq = 2000.0  // 较旧设备默认2GHz
        }
        
        NSLog("CPU DEBUG - 方法3: 使用默认频率估计, 核心数=%d, 估算频率=%.2f MHz", processorCount, defaultFreq)
        return defaultFreq
    }
    // 获取设备架构
    private func getArchitecture() -> String {
#if arch(arm64)
        return "ARM64"
#elseif arch(x86_64)
        return "x86_64 (模拟器)"
#else
        return "未知架构"
#endif
    }
    
    private func focusOtherMusic(result: @escaping FlutterResult, close: Bool) {
        if (close) {
            do {
                let audioSession = AVAudioSession.sharedInstance()
                try? audioSession.setCategory(.playAndRecord, mode: .default, options: .allowAirPlay)
                try? audioSession.setActive(true)
                result(true)
            } catch {
                result(false)
            }
        } else {
            do {
                let audioSession = AVAudioSession.sharedInstance()
                try? audioSession.setCategory(.playback, mode: .default, options: .mixWithOthers)
                try? audioSession.setActive(false, options: .notifyOthersOnDeactivation)
                result(true)
            } catch {
                result(false)
            }
        }
    }
    
    private func getLastShareFilePath(result: FlutterResult) {
        let defaults = UserDefaults.init(suiteName: "group.com.xxx.xxx.ImagePublish")
        if let dict = defaults?.object(forKey: "share_image") {
            defaults?.setValue(nil, forKey: "share_image")
            imageDict = dict as? NSDictionary
            result(dict)
        }
        if let dict = defaults?.object(forKey: "share_image") {
            defaults?.setValue(nil, forKey: "share_image")//清空
            imageDict = (dict as! NSDictionary);
        }
    }
    
    private func clearLastShareFilePath(result: FlutterResult) {
        imageDict = nil
        result(true)
    }
    
    public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        if (urls.first == nil) {
            documentResult!(["result" : "result_fail"])
            return
        }
        let fileUrlAuthozied = urls.first?.startAccessingSecurityScopedResource()
        if (fileUrlAuthozied == nil) {
            documentResult!(["result" : "result_fail"])
            return
        }
        if (fileUrlAuthozied!) {
            
            let fileCoordinator = NSFileCoordinator.init()
            let err = NSErrorPointer.init(nilLiteral: ())
            fileCoordinator.coordinate(readingItemAt: urls.first!, options: NSFileCoordinator.ReadingOptions.init(), error: err) { newUrl in
                let fileName = newUrl.lastPathComponent
                let suffix = newUrl.pathExtension
                let fileData = try? NSData.init(contentsOf: newUrl, options: NSData.ReadingOptions.mappedIfSafe)
                urls.first?.stopAccessingSecurityScopedResource()
                self.documentPicker!.dismiss(animated: true)
                if (fileData != nil) {
                    if (self.documentResult != nil) {
                        self.documentResult!([
                            "result" : "result_ok",
                            "file_name" : fileName,
                            "suffix": suffix,
                            "length": fileData!.count,
                            "file_data" : fileData!,
                        ] as [String : Any])
                    }
                } else {
                    if (documentResult != nil) {
                        documentResult!(["result" : "result_invalid"])
                    }
                }
            }
        } else {
            if (documentResult != nil) {
                documentResult!(["result" : "result_fail"])
            }
        }
        
    }
    
    public func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        if (documentResult != nil) {
            documentResult!(["result" : "result_cancel"])
        }
        
    }
    
    
    
    
    ///视频mov转mp4格式
    func movToMp4Url(result: @escaping FlutterResult, oldPath: String) {
        DispatchQueue.global().async {
            let avAsset = AVURLAsset.init(url: URL(fileURLWithPath: oldPath), options: nil)
            
            let sufix: String = oldPath.components(separatedBy: ".").last!
            let filePath: String = oldPath.components(separatedBy: "/").last!
            var fileName = filePath.replacingOccurrences(of: sufix, with: "mp4")
            fileName = "change_" + String(Int(Date().timeIntervalSince1970)) + "_" + fileName
            let destinationPath = NSTemporaryDirectory() + fileName
            let newVideoPath: URL = URL(fileURLWithPath: destinationPath as String)
            
            let exporter = AVAssetExportSession(asset: avAsset,  presetName: AVAssetExportPreset1920x1080)!
            exporter.outputURL = newVideoPath
            exporter.outputFileType = AVFileType.mp4
            exporter.shouldOptimizeForNetworkUse = true
            exporter.exportAsynchronously(completionHandler: {
                if (exporter.status == AVAssetExportSession.Status.completed) {
                    DispatchQueue.main.async {
                        result(newVideoPath.path)
                    }
                } else {
                    do {
                        try FileManager.default.removeItem(at: newVideoPath)
                    } catch {
                        
                    }
                    DispatchQueue.main.async {
                        result("")
                    }
                }
            })
        }
        
    }
    
    ///图片HEIC转PNG格式
    func changeHeicToPng(result: @escaping FlutterResult, oldPath: String) {
        let oldUrl: URL = URL(fileURLWithPath: oldPath as String)
        guard let source = CGImageSourceCreateWithURL(oldUrl as CFURL, nil) else {
            result("")
            return
        }
        
        let props : NSDictionary? = CGImageSourceCopyPropertiesAtIndex(source, 0, nil)
        
        guard let cgImage = CGImageSourceCreateImageAtIndex(source, 0, props) else {
            result("")
            return
        }
        
        var orientation = 0;
        if (props != nil) {
            orientation = props!["Orientation"] as! Int
        }
        
        var image = UIImage(cgImage: cgImage, scale: 1.0, orientation: getImageOrientation(ori: orientation))
        
        if (image.imageOrientation != .up) {
            UIGraphicsBeginImageContext(image.size)
            image.draw(in: CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height))
            image = UIGraphicsGetImageFromCurrentImageContext()!
            UIGraphicsEndImageContext()
        }
        
        guard let imageData = image.jpegData(compressionQuality: 0.9) else {
            result("")
            return
        }
        
        let sufix: String = oldPath.components(separatedBy: ".").last!
        let filePath: String = oldPath.components(separatedBy: "/").last!
        let fileName = filePath.replacingOccurrences(of: sufix, with: "png")
        let destinationPath = NSTemporaryDirectory() + fileName
        let newImageUrl: URL = URL(fileURLWithPath: destinationPath as String)
        
        do {
            try imageData.write(to: newImageUrl)
            result(destinationPath)
        } catch {
            result("")
        }
    }
    
    func getImageOrientation(ori: Int) -> UIImage.Orientation {
        switch (ori) {
        case 0:
            return .up
        case 1:
            return .up //(完成)
        case 2:
            return .upMirrored //(完成)
        case 3:
            return .down //(完成)
        case 4:
            return .downMirrored //(完成)
        case 5:
            return .leftMirrored //(完成)
        case 6:
            return .right //(完成)
        case 7:
            return .rightMirrored //(完成)
        case 8:
            return .left //(完成)
        default:
            return .up
        }
    }
    
    // ========== 从 device_info 插件迁移的实现方法 ==========
    
    private func getUUID(appName: String) -> String {
        let adId = getContentFromKeyChain(appName: appName)
        if !adId.isEmpty {
            return adId
        }
        
        // 生成新的 UUID
        var newId = ""
        if #available(iOS 6.0, *) {
            let advertisingId = ASIdentifierManager.shared().advertisingIdentifier.uuidString
            if advertisingId != "00000000-0000-0000-0000-000000000000" {
                newId = advertisingId
            }
        }
        
        if newId.isEmpty {
            if let identifierForVendor = UIDevice.current.identifierForVendor?.uuidString {
                newId = identifierForVendor
            }
        }
        
        if newId.isEmpty {
            newId = UUID().uuidString
        }
        
        // 保存到 Keychain
        saveContentToKeyChain(content: newId, appName: appName)
        return newId
    }
    
    private func getContentFromKeyChain(appName: String) -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: appName,
            kSecAttrAccount as String: "zhibo_ipfv",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        if status == errSecSuccess {
            if let data = dataTypeRef as? Data,
               let password = String(data: data, encoding: .utf8) {
                return password
            }
        }
        
        return ""
    }
    
    private func saveContentToKeyChain(content: String, appName: String) -> Bool {
        let data = content.data(using: .utf8)!
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: appName,
            kSecAttrAccount as String: "zhibo_ipfv",
            kSecValueData as String: data
        ]
        
        // 先删除已存在的项
        SecItemDelete(query as CFDictionary)
        
        // 添加新项
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    private func isHEVCSupported() -> Bool {
        if #available(iOS 11.0, *) {
            let asset = AVAsset(url: URL(fileURLWithPath: "/dev/null"))
            let compatiblePresets = AVAssetExportSession.exportPresets(compatibleWith: asset)
            return compatiblePresets.contains(AVAssetExportPresetHEVCHighestQuality)
        }
        return false
    }
    
    private func getTotalSpace() -> Int64 {
        do {
            let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
            if let path = paths.last {
                let attributes = try FileManager.default.attributesOfFileSystem(forPath: path)
                if let totalSpace = attributes[.systemSize] as? NSNumber {
                    return totalSpace.int64Value
                }
            }
        } catch {
            print("Error getting total space: \(error)")
        }
        return 0
    }
    
    private func getFreeSpace() -> Int64 {
        do {
            let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
            if let path = paths.last {
                let attributes = try FileManager.default.attributesOfFileSystem(forPath: path)
                if let freeSpace = attributes[.systemFreeSize] as? NSNumber {
                    return freeSpace.int64Value
                }
            }
        } catch {
            print("Error getting free space: \(error)")
        }
        return 0
    }
    
    func requestAudioFocus() -> Bool{
        try? AVAudioSession.sharedInstance().setActive(true)
        return true;
    }

    func abandonAudioFocus() -> Bool{
        // try AVAudioSession.sharedInstance().setActive(true)
        return true;
    }
    
    func setMixWithOthers(v:Bool) -> Bool{
        do{
            
            if(v == true){
                try? AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback,options: AVAudioSession.CategoryOptions.mixWithOthers);
            }
            else{
                try? AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback,options: []);
            }
        }
        return true;
    }
}

/// 继承自FlutterViewController，通过全局静态变量来控制小横杠的显示和系统手势的延迟边缘
class HomeIndicatorAwareFlutterViewController : FlutterViewController {
    // 静态变量用于控制Home Indicator的显示状态
    static var hidingHomeIndicator: Bool = false
    
    // 用于iOS 11及更高版本，用于控制小横杠的自动隐藏
    @available(iOS 11.0, *)
    override var prefersHomeIndicatorAutoHidden: Bool {
        return HomeIndicatorAwareFlutterViewController.hidingHomeIndicator
    }
    
    // 方法用于设置Home Indicator的显示状态
    func setHidingHomeIndicator(newValue: Bool) {
        if #available(iOS 11.0, *) {
            if (newValue != HomeIndicatorAwareFlutterViewController.hidingHomeIndicator) {
                HomeIndicatorAwareFlutterViewController.hidingHomeIndicator = newValue
                setNeedsUpdateOfHomeIndicatorAutoHidden()
            }
        }
    }
    
    // 静态变量用于存储延迟系统手势的边缘
    static var deferredEdges: UIRectEdge = []
    
    // 用于iOS 11及更高版本，控制延迟系统手势的边缘
    @available(iOS 11.0, *)
    override var preferredScreenEdgesDeferringSystemGestures: UIRectEdge {
        return HomeIndicatorAwareFlutterViewController.deferredEdges
    }
    
    // 方法用于设置延迟系统手势的边缘
    func setDeferredEdges(newValue: UIRectEdge) {
        if #available(iOS 11.0, *) {
            if (newValue != HomeIndicatorAwareFlutterViewController.deferredEdges) {
                HomeIndicatorAwareFlutterViewController.deferredEdges = newValue
                setNeedsUpdateOfScreenEdgesDeferringSystemGestures()
            }
        }
    }
    
    // 控制是否允许自动旋转
    override public var shouldAutorotate: Bool {
        return false
    }
}
