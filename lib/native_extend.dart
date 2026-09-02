import 'dart:async';
import 'dart:io';

import 'package:events_widget/events_widget.dart';
import 'package:sync/semaphore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:universal_platform/universal_platform.dart';

/// An edge of the device screen.
enum ScreenEdge {
  top,
  left,
  bottom,
  right,
}

class NativeExtend {
  static const orientationChange = "orientationChange";
  static const devicePixelRatioChange = "devicePixelRatioChange";
  static EventDispatcher eventDispatcher = EventDispatcher();

  static const methodChannel = MethodChannel('native_extend');

  static Future<String?> getPlatformVersion() async {
    final version =
        await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }

  static Future<String> get sonChannel async {
    return UniversalPlatform.isAndroid
        ? ""
        : (await methodChannel.invokeMethod('getSonChannel')) ?? "";
  }

  static Future<Map<String, dynamic>?> get lastShareFilePath async {
    return await methodChannel.invokeMethod('getLastShareFilePath');
  }

  static Future<bool> get clearLastShareFilePath async {
    return await methodChannel.invokeMethod('clearLastShareFilePath');
  }

  static Future<Map<String, dynamic>?> get androidShareFile async {
    return await methodChannel.invokeMethod('ShareFilePath');
  }

  static Future<Map<String, dynamic>?> get openIosDocument async {
    return await methodChannel.invokeMethod('openDocument');
  }

  /// 获取设备的DNS服务器信息
  static Future<List<String>> getDeviceDnsServers() async {
    try {
      final List<dynamic> dnsServers =
          await methodChannel.invokeMethod('getDeviceDnsServers');
      return dnsServers.map((e) => e.toString()).toList();
    } on PlatformException catch (e) {
      debugPrint('获取设备DNS服务器失败: ${e.message}');
      return [];
    }
  }

  /// 获取设备的MCC/MNC信息
  static Future<Map<String, String>> getDeviceMccMnc() async {
    try {
      final Map<dynamic, dynamic> result =
          await methodChannel.invokeMethod('getDeviceMccMnc');
      return {
        'mcc': result['mcc'] ?? '',
        'mnc': result['mnc'] ?? '',
        'carrierName': result['carrierName'] ?? '',
      };
    } on PlatformException catch (e) {
      debugPrint('获取设备MCC/MNC失败: ${e.message}');
      return {'mcc': '', 'mnc': '', 'carrierName': ''};
    }
  }

  /// 检查设备是否使用VPN或代理
  static Future<Map<String, bool>> checkVpnProxyStatus() async {
    try {
      final Map<dynamic, dynamic> result =
          await methodChannel.invokeMethod('checkVpnProxyStatus');
      return {
        'isVpnActive': result['isVpnActive'] ?? false,
        'isProxyEnabled': result['isProxyEnabled'] ?? false,
      };
    } on PlatformException catch (e) {
      debugPrint('检查VPN/代理状态失败: ${e.message}');
      return {'isVpnActive': false, 'isProxyEnabled': false};
    }
  }

  /// 获取设备的NAT类型
  static Future<String> getDeviceNatType() async {
    try {
      final String natType =
          await methodChannel.invokeMethod('getDeviceNatType');
      return natType;
    } on PlatformException catch (e) {
      debugPrint('获取设备NAT类型失败: ${e.message}');
      return 'Unknown';
    }
  }

  ///传token给ios
  static Future<bool> pushTokenToIos(String token) async {
    return false;
    // return await methodChannel.invokeMethod('pushToken', token);
  }

  ///传url给ios
  static Future<bool> pushUrlToIos(String url) async {
    return await methodChannel.invokeMethod('pushUrl', url);
  }

  ///传user_id给原生
  static Future<bool> pushUserId(String userId) async {
    return false;
    // return await methodChannel.invokeMethod('pushUserId', userId);
  }

  ///是否进入home主界面
  static Future<bool> iosIsEnterHome() async {
    return await methodChannel.invokeMethod('iosIsEnterHome', 'home');
  }

  ///获取安卓系统音量
  static Future<int> getSystemVolume() async {
    return await methodChannel.invokeMethod('get_system_volume');
  }

  static Future<Map<Object?, Object?>?> getIosCpuInfo() async {
    return await methodChannel.invokeMethod('getCpuInfo');
  }

  ///图片Heic转Png
  static Future<String> changeHeicToPng(String filePath) async {
    String newPath =
        await methodChannel.invokeMethod('changeHeicToPng', filePath);
    return newPath;
  }

  ///跳转定位服务中心
  static Future<void> jumpLocationCenter() async {
    methodChannel.invokeMethod('jump_location_center');
  }

  static Future<String> get environment async {
    return await methodChannel.invokeMethod('getEnvironment');
  }

  static Future<bool?> get isSandbox async {
    return await methodChannel.invokeMethod('getISSandbox');
  }

  //当前屏幕方向
  static Orientation _curOrientation = Orientation.portrait;

  static Orientation get curOrientation => _curOrientation;

  static set curOrientation(Orientation v) {
    if (_curOrientation != v) {
      _curOrientation = v;
      eventDispatcher.event(eventDispatcher, orientationChange,
          data: _curOrientation);
    }
  }

  static bool get isLandscape => curOrientation == Orientation.landscape;
  static final Semaphore _orientationSemaphore = Semaphore(1);

  // ========== 自动旋转监听机制 ==========
  static _OrientationObserver? _orientationObserver;
  static bool _isAutoRotationMode = false;

  /// 是否处于自动旋转模式
  static bool get isAutoRotationMode => _isAutoRotationMode;

  /// 开启自动旋转监听（用于 setOrientationAuto 模式）
  static void startOrientationListener() {
    if (_orientationObserver != null) return; // 防止重复注册
    _orientationObserver = _OrientationObserver();
    WidgetsBinding.instance.addObserver(_orientationObserver!);
    _isAutoRotationMode = true;
  }

  /// 停止自动旋转监听
  static void stopOrientationListener() {
    if (_orientationObserver != null) {
      WidgetsBinding.instance.removeObserver(_orientationObserver!);
      _orientationObserver = null;
    }
    _isAutoRotationMode = false;
  }

  /// 根据实际屏幕尺寸更新方向（供监听器调用）
  static void updateOrientationFromSize(Size size) {
    if (!_isAutoRotationMode) return;
    final orientation =
        size.width > size.height ? Orientation.landscape : Orientation.portrait;
    curOrientation = orientation; // 会自动触发 orientationChange 事件
  }

  // ========== 恢复前台方向重申（port from live3 stable_0814）==========
  // iOS16+ 锁屏-解锁过渡会丢掉 setPreferredOrientations 的横屏声明：解锁后
  // 窗口被系统转回竖屏（resumed 之前即可观测到竖屏 metrics），且不自行恢复。
  // 恢复前台时若显式意图（curOrientation）与窗口真实几何不一致，重申一次意图。
  // auto 跟随模式没有显式意图，不重申；转向在途（rotationing）自会收敛，不重申。
  static _ResumeReassertObserver? _resumeReassertObserver;

  static void _ensureResumeReassertObserver() {
    if (_resumeReassertObserver != null) return;
    _resumeReassertObserver = _ResumeReassertObserver();
    WidgetsBinding.instance.addObserver(_resumeReassertObserver!);
    debugPrint('[NativeExtend] 方向重申观察者已注册');
  }

  /// 恢复前台时应重申的方向；null 表示无需重申。纯判定，供测试直调。
  @visibleForTesting
  static Orientation? reassertTargetOnResume({
    required bool isAutoRotationMode,
    required bool rotationing,
    required Orientation intent,
    required Size physicalSize,
  }) {
    if (isAutoRotationMode) return null;
    if (rotationing) return null;
    if (physicalSize.width <= 0 || physicalSize.height <= 0) return null;
    final actual = physicalSize.width > physicalSize.height
        ? Orientation.landscape
        : Orientation.portrait;
    if (actual == intent) return null;
    return intent;
  }

  static void _onResumedReassert() {
    final view = WidgetsBinding.instance.platformDispatcher.views.first;
    final size = view.physicalSize;
    final target = reassertTargetOnResume(
      isAutoRotationMode: _isAutoRotationMode,
      rotationing: rotationing,
      intent: _curOrientation,
      physicalSize: size,
    );
    debugPrint('[NativeExtend] 恢复前台方向检查: intent=$_curOrientation '
        'auto=$_isAutoRotationMode rotationing=$rotationing '
        'size=${size.width.toInt()}x${size.height.toInt()} → '
        '${target == null ? '一致,不重申' : '不一致,重申 $target'}');
    if (target == null) return;
    unawaited(_reassertOrientation(target));
  }

  // 强制重申:引擎端 performOrientationUpdate 对相同 mask 直接短路——锁屏丢声明后
  // 引擎存值仍是旧 mask,重发同值到不了 UIKit。先发全集过渡 mask 改变引擎存值,
  // 再发目标 mask 强制 requestGeometryUpdate 转回。
  static Future<void> _reassertOrientation(Orientation target) async {
    await _orientationSemaphore.acquire();
    await _setRotationing(true);
    try {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
        DeviceOrientation.portraitUp,
      ]);
      if (target == Orientation.landscape) {
        if (Platform.isIOS) {
          await SystemChrome.setPreferredOrientations(
              [DeviceOrientation.landscapeRight]);
        } else {
          await SystemChrome.setPreferredOrientations([
            DeviceOrientation.landscapeLeft,
            DeviceOrientation.landscapeRight,
          ]);
        }
      } else {
        await SystemChrome.setPreferredOrientations(
            [DeviceOrientation.portraitUp]);
      }
      curOrientation = target;
    } finally {
      _orientationSemaphore.release();
      await _setRotationing(false);
    }
  }

  static bool _rotationing = false;

  static bool get rotationing =>
      _rotationing || DateTime.now().millisecondsSinceEpoch < _unRotationTime;
  static int _unRotationTime = 0;

  static Future<void> _setRotationing(bool v) async {
    _rotationing = v;
    _unRotationTime = DateTime.now().millisecondsSinceEpoch + 500;
  }

  /// Android：声明/撤销窗口转屏的交叉淡化过渡（CROSSFADE，API 26+）。
  /// enable 期间的转向走系统截图冻结管线：冻结帧几何正确、保持到 app 画完
  /// 新方向首帧才淡化揭开——无旋转动画、无变形、无黑屏。
  /// 必须在转向发生前至少一帧声明并保持（窗口属性回写要等下一次 relayout 才同步到 WMS）。
  /// 返回是否生效（非 Android / 无 Activity / 低于 API 26 返回 false）。port from live3 stable_0814。
  static Future<bool> setRotationCrossfade(bool enable) async {
    if (!Platform.isAndroid) return false;
    final ok =
        await methodChannel.invokeMethod<bool>('setRotationCrossfade', enable);
    return ok ?? false;
  }

  //设置竖向旋转
  static Future<void> setOrientationPortrait() async {
    _ensureResumeReassertObserver();
    // print("@@@@@@@@@@ setOrientationPortrait");
    await _orientationSemaphore.acquire();
    await _setRotationing(true);
    try {
      await SystemChrome.setPreferredOrientations(
          [DeviceOrientation.portraitUp]);
      curOrientation = Orientation.portrait;
      await SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: SystemUiOverlay.values,
      );
    } finally {
      _orientationSemaphore.release();
      await _setRotationing(false);
    }
  }

  //设置横向旋转
  static Future<void> setOrientationLandscape() async {
    _ensureResumeReassertObserver();
    // print("@@@@@@@@@@ setOrientationLandscape");
    await _orientationSemaphore.acquire();
    await _setRotationing(true);
    try {
      if (Platform.isIOS) {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeRight,
          // DeviceOrientation.landscapeLeft,
        ]);
      } else {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
      }
      curOrientation = Orientation.landscape;
    } finally {
      _orientationSemaphore.release();
      await _setRotationing(false);
    }
  }

  //设置自动跟随手机方向
  static Future<void> setOrientationAuto({bool startListener = false}) async {
    _ensureResumeReassertObserver();
    // print("@@@@@@@@@@ setOrientationAuto");
    await _orientationSemaphore.acquire();
    await _setRotationing(true);
    try {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
        DeviceOrientation.portraitUp
      ]);
      // 不再固定设为 portrait，保持当前方向或由监听器更新
      if (startListener) {
        startOrientationListener();
      }
    } finally {
      _orientationSemaphore.release();
      await _setRotationing(false);
    }
  }

  static void setOrientation(Orientation ori) {
    if (ori == Orientation.portrait) {
      setOrientationPortrait();
    } else {
      setOrientationLandscape();
    }
  }

  //音频焦点控制器
  static Future<bool> controlAudioFocus(bool focus) async {
    if (UniversalPlatform.isAndroid) {
      if (focus) {
        await requestAudioFocus();
      } else {
        await abandonAudioFocus();
      }
      return true;
    }
    var rep = await methodChannel.invokeMethod('focus_other_music', focus);
    return rep;
  }

  //恢复carplay播放
  static Future resumeCarplay() async {
    if (!UniversalPlatform.isIOS) {
      return;
    }
    await methodChannel.invokeMethod('resume_carplay');
    return;
  }

  //停止carplay播放
  static Future endCarplay() async {
    if (!UniversalPlatform.isIOS) {
      await controlAudioFocus(true);
      return;
    }
    await requestAudioFocus();
    // await channel.invokeMethod('resume_carplay');
    return;
  }

  /// 请求音频焦点
  static Future<bool> requestAudioFocus() async {
    try {
      final bool result = await methodChannel.invokeMethod('requestAudioFocus');
      return result;
    } on PlatformException catch (e) {
      debugPrint("Failed to request audio focus: ${e.message}");
      return false;
    }
  }

  /// 释放音频焦点
  static Future<bool> abandonAudioFocus() async {
    try {
      final bool result = await methodChannel.invokeMethod('abandonAudioFocus');
      return result;
    } on PlatformException catch (e) {
      debugPrint("Failed to abandon audio focus: ${e.message}");
      return false;
    }
  }

  /// 设置是否与其他音频混合播放
  static Future<bool> setMixWithOthers(bool mixWithOthers) async {
    try {
      final bool result = await methodChannel.invokeMethod(
          'setMixWithOthers', mixWithOthers ? "1" : null);
      return result;
    } on PlatformException catch (e) {
      debugPrint("Failed to set mix with others: ${e.message}");
      return false;
    }
  }

  /// 获取音频焦点状态
  static Future<int> getAudioFocusState() async {
    try {
      final int state = await methodChannel.invokeMethod('getAudioFocusState');
      return state;
    } on PlatformException catch (e) {
      debugPrint("Failed to get audio focus state: ${e.message}");
      return 0;
    }
  }

  static Future<void> homeIndicatorHide() async {
    if (Platform.isIOS) {
      await methodChannel.invokeMethod('HomeIndicator.hide');
    }
  }

  /// Ask iOS to show the iPhone X home indicator (bar at bottom of screen).
  /// It will then always be visible, as is the default setting.
  static Future<void> homeIndicatorShow() async {
    if (Platform.isIOS) {
      await methodChannel.invokeMethod('HomeIndicator.show');
    }
  }

  /// Query whether the home indicator is currently instructed to be hidden.
  static Future<bool> homeIndicatorIsHidden() async {
    if (Platform.isIOS) {
      return await methodChannel.invokeMethod('HomeIndicator.isHidden');
    }
    return true;
  }

  /// Ask iOS to defer system gestures on the given edges of the screen.
  ///
  /// **Warning:** It appears "deferring" the bottom screen edge does _not_ successfully
  /// prevent a "home swipe" when the home indicator is also hidden. That is: if you need
  /// the behavior of `HomeIndicator.deferScreenEdges([ScreenEdge.bottom])`, then
  /// don't also call `HomeIndicator.hide()`.
  static Future<void> homeIndicatorDeferScreenEdges(
      List<ScreenEdge> edges) async {
    var mask = 0;
    for (final e in edges) {
      mask |= 1 << e.index;
    }
    if (Platform.isIOS) {
      try {
        await methodChannel.invokeMethod(
            'HomeIndicator.deferScreenEdges', mask);
      } catch (e) {
        debugPrint('HomeIndicator.deferScreenEdges error: $e');
      }
    }
  }

  static bool _isAutoAemoveTopLevelFlutterClippingMaskView = true;

  static Future<void> autoAemoveTopLevelFlutterClippingMaskView() async {
    if (Platform.isIOS) {
      //防止重复注册事件
      if (_isAutoAemoveTopLevelFlutterClippingMaskView) return;
      _isAutoAemoveTopLevelFlutterClippingMaskView = true;
      await methodChannel.invokeMethod(
          'HomeIndicator.autoAemoveTopLevelFlutterClippingMaskView');
    }
  }

  static Future<dynamic> removeTopLevelFlutterClippingMaskView(
      {int? ms = 1000}) async {
    if (_isAutoAemoveTopLevelFlutterClippingMaskView) return false;
    if (_isAutoAemoveTopLevelFlutterClippingMaskView && Platform.isIOS) {
      if (ms == null) {
        return methodChannel.invokeMethod(
            'HomeIndicator.removeTopLevelFlutterClippingMaskView');
      } else {
        Completer<bool> comm = Completer();
        Timer(Duration(milliseconds: ms), () async {
          comm.complete(await methodChannel.invokeMethod(
              'HomeIndicator.removeTopLevelFlutterClippingMaskView'));
        });
        return comm.future;
      }
    }
    return Future.value(false);
  }

  // Set brightness level (0-255)
  static Future<void> setBrightness(int brightness) async {
    try {
      await methodChannel
          .invokeMethod('setBrightness', {"brightness": brightness});
    } on PlatformException catch (e) {
      debugPrint("Failed to set brightness: ${e.message}");
      rethrow;
    }
  }

  /// 读当前窗口/页面亮度（0-255），失败回退 128。port from live3 stable_0814。
  static Future<int> getBrightness() async {
    try {
      return await methodChannel.invokeMethod<int>('getBrightness') ?? 128;
    } on PlatformException catch (e) {
      debugPrint("Failed to get brightness: ${e.message}");
      return 128;
    }
  }

  // Restore the page/window brightness that was active before playback.
  static Future<void> restoreBrightness() async {
    try {
      await methodChannel.invokeMethod('restoreBrightness');
    } on PlatformException catch (e) {
      debugPrint("Failed to restore brightness: ${e.message}");
      rethrow;
    }
  }

  // Set brightness mode (0 for manual, 1 for automatic)
  static Future<void> setBrightnessMode(int mode) async {
    if (!Platform.isAndroid) return;
    try {
      await methodChannel.invokeMethod('setBrightnessMode', {"mode": mode});
    } on PlatformException catch (e) {
      debugPrint("Failed to set brightness mode: ${e.message}");
    }
  }

  // Open the system settings permission page
  static Future<void> openWriteSettingsPermissionPage() async {
    if (!Platform.isAndroid) return;
    try {
      await methodChannel.invokeMethod('openWriteSettingsPermissionPage');
    } on PlatformException catch (e) {
      debugPrint("Failed to open permission page: ${e.message}");
    }
  }

  // Check if the "Write System Settings" permission is granted
  static Future<bool> hasWriteSettingsPermission() async {
    if (!Platform.isAndroid) return false;
    try {
      final bool permissionGranted =
          await methodChannel.invokeMethod('hasWriteSettingsPermission');
      return permissionGranted;
    } on PlatformException catch (e) {
      debugPrint("Failed to check permission: ${e.message}");
      return false;
    }
  }

  static Future<void> openBatteryOptimizationSettingsPage() async {
    if (!Platform.isAndroid) return;
    try {
      await methodChannel.invokeMethod('openBatteryOptimizationSettings');
    } on PlatformException catch (e) {
      debugPrint("Failed to open battery optimization settings page: ${e.message}");
    }
  }

  static Future<bool> isBatteryOptimizationIgnored() async {
    if (!Platform.isAndroid) return false;
    try {
      final bool isIgnored =
          await methodChannel.invokeMethod('checkBatteryOptimization');
      return isIgnored;
    } on PlatformException catch (e) {
      debugPrint("Failed to check battery optimization status: ${e.message}");
      return false;
    }
  }

  static Future<void> openAppSettingsPage() async {
    if (!Platform.isAndroid) return;
    try {
      await methodChannel.invokeMethod('openAppSettings');
    } on PlatformException catch (e) {
      debugPrint("Failed to open app settings page: ${e.message}");
    }
  }

  // ========== 从 device_info 插件迁移的接口 ==========

  /// 获取 Android 设备 ID
  static Future<String> getAndroidId() async {
    if (!Platform.isAndroid) return '';
    try {
      final String androidId = await methodChannel.invokeMethod('getAndroidId');
      return androidId;
    } on PlatformException catch (e) {
      debugPrint("Failed to get Android ID: ${e.message}");
      return '';
    }
  }

  /// 获取 iOS 设备 UUID
  static Future<String> getUUID(String appName) async {
    if (!Platform.isIOS) return '';
    try {
      final String uuid =
          await methodChannel.invokeMethod('getUUID', {'appName': appName});
      return uuid;
    } on PlatformException catch (e) {
      debugPrint("Failed to get UUID: ${e.message}");
      return '';
    }
  }

  /// 检测设备是否支持 HEVC/H.265 编码
  static Future<bool> isHEVCSupported() async {
    try {
      final bool isSupported =
          await methodChannel.invokeMethod('isHEVCSupported');
      return isSupported;
    } on PlatformException catch (e) {
      debugPrint("Failed to check HEVC support: ${e.message}");
      return false;
    }
  }

  /// 获取设备存储总空间（字节）
  static Future<int> getTotalSpace() async {
    try {
      final int totalSpace = await methodChannel.invokeMethod('getTotalSpace');
      return totalSpace;
    } on PlatformException catch (e) {
      debugPrint("Failed to get total space: ${e.message}");
      return 0;
    }
  }

  /// 获取设备剩余存储空间（字节）
  static Future<int> getFreeSpace() async {
    try {
      final int freeSpace = await methodChannel.invokeMethod('getFreeSpace');
      return freeSpace;
    } on PlatformException catch (e) {
      debugPrint("Failed to get free space: ${e.message}");
      return 0;
    }
  }
}

/// 屏幕方向变化监听器
class _OrientationObserver extends WidgetsBindingObserver {
  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    // 获取当前窗口尺寸
    final view = WidgetsBinding.instance.platformDispatcher.views.first;
    final size = view.physicalSize / view.devicePixelRatio;
    if (size.width > 0 && size.height > 0) {
      NativeExtend.updateOrientationFromSize(size);
    }
  }
}

/// 恢复前台方向重申观察者（见 NativeExtend._onResumedReassert 注释）
class _ResumeReassertObserver extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      NativeExtend._onResumedReassert();
    }
  }
}
