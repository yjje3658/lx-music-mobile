import { NativeModules } from 'react-native'

global.Buffer = require('buffer').Buffer

// iOS 兜底：UtilsModule 是 Android 原生模块，iOS 未实现。
// polyfill 成 JS 实现，避免 getWindowSize 等调用炸掉初始化链。
if (!NativeModules.UtilsModule) {
  NativeModules.UtilsModule = {
    exitApp: () => {},
    getSupportedAbis: () => [],
    installApk: () => Promise.resolve(),
    screenkeepAwake: () => {},
    screenUnkeepAwake: () => {},
    getWIFIIPV4Address: () => Promise.resolve(''),
    getDeviceName: () => Promise.resolve('iPhone'),
    isNotificationsEnabled: () => Promise.resolve(true),
    requestNotificationPermission: () => Promise.resolve(true),
    shareText: () => Promise.resolve(),
    getSystemLocales: () => Promise.resolve('zh-CN'),
    getWindowSize: () => Promise.resolve({ width: 0, height: 0 }),
    isIgnoringBatteryOptimization: () => Promise.resolve(true),
    requestIgnoreBatteryOptimization: () => Promise.resolve(),
    onWindowSizeChange: () => Promise.resolve(),
    onScreenStateChange: () => Promise.resolve(),
    openNotificationPermissionActivity: () => Promise.resolve(true),
  }
}
