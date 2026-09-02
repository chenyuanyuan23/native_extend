package com.example.native_extend

import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlin.test.Test
import org.mockito.Mockito

/*
 * This demonstrates a simple unit test of the Kotlin portion of this plugin's implementation.
 *
 * Once you have built the plugin's example app, you can run these tests from the command
 * line by running `./gradlew testDebugUnitTest` in the `example/android/` directory, or
 * you can run them directly from IDEs that support JUnit such as Android Studio.
 */

internal class NativeExtendPluginTest {
  @Test
  fun onMethodCall_getPlatformVersion_returnsExpectedValue() {
    val plugin = NativeExtendPlugin()

    val call = MethodCall("getPlatformVersion", null)
    val mockResult: MethodChannel.Result = Mockito.mock(MethodChannel.Result::class.java)
    plugin.onMethodCall(call, mockResult)

    Mockito.verify(mockResult).success("Android " + android.os.Build.VERSION.RELEASE)
  }

  // 无 Activity 时无缝旋转声明必须安全返回 false（activity 判空先于任何窗口/版本访问，
  // 这也是该分支能在纯 JVM 下运行的前提）。守住 channel 契约：方法存在且不抛。
  @Test
  fun onMethodCall_setRotationCrossfade_withoutActivity_returnsFalse() {
    val plugin = NativeExtendPlugin()

    val call = MethodCall("setRotationCrossfade", true)
    val mockResult: MethodChannel.Result = Mockito.mock(MethodChannel.Result::class.java)
    plugin.onMethodCall(call, mockResult)

    Mockito.verify(mockResult).success(false)
  }
}
