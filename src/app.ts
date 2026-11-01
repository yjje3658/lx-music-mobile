import '@/utils/errorHandle'
import { Alert } from 'react-native'
import { init as initLog } from '@/utils/log'
import { bootLog, getBootLog } from '@/utils/bootLog'
import '@/config/globalData'
import { getFontSize } from '@/utils/data'
import { exitApp } from './utils/nativeModules/utils'
import { windowSizeTools } from './utils/windowSizeTools'
import { listenLaunchEvent } from './navigation/regLaunchedEvent'
import { tipDialog } from './utils/tools'

const diag = (msg: string) => Alert.alert('启动诊断', msg)

console.log('starting app...')
diag('1. JS已启动，正在注册RNN监听')
listenLaunchEvent()

void Promise.all([getFontSize(), windowSizeTools.init()]).then(async([fontSize]) => {
  global.lx.fontSize = fontSize
  bootLog('Font size setting loaded.')
  diag('2. 字体初始化完成，开始注册导航')

  let isInited = false
  let handlePushedHomeScreen: () => void | Promise<void>

  const tryGetBootLog = () => {
    try {
      return getBootLog()
    } catch (err) {
      return 'Get boot log failed.'
    }
  }

  const handleInit = async() => {
    if (isInited) return
    void initLog()
    const { default: init } = await import('@/core/init')
    try {
      handlePushedHomeScreen = await init()
    } catch (err: any) {
      void tipDialog({
        title: '初始化失败 (Init Failed)',
        message: `Boot Log:\n${tryGetBootLog()}\n\n${(err.stack ?? err.message) as string}`,
        btnText: 'Exit',
        bgClose: false,
      }).then(() => {
        exitApp()
      })
      return
    }
    isInited ||= true
  }

  diag('2.6 开始加载导航模块...')
  const { init: initNavigation, navigations } = await import('@/navigation')
  diag('2.7 导航模块已加载')

  initNavigation(async() => {
    diag('3. 初始化回调执行')
    await handleInit()
    if (!isInited) return
    // import('@/utils/nativeModules/cryptoTest')

    await navigations.pushHomeScreen().then(() => {
      diag('4. setRoot完成，等待渲染')
      void handlePushedHomeScreen()
    }).catch((err: any) => {
      void tipDialog({
        title: 'Error',
        message: err.message,
        btnText: 'Exit',
        bgClose: false,
      }).then(() => {
        exitApp()
      })
    })
  })
}).catch((err) => {
  void tipDialog({
    title: '初始化失败 (Init Failed)',
    message: `Boot Log:\n\n${(err.stack ?? err.message) as string}`,
    btnText: 'Exit',
    bgClose: false,
  }).then(() => {
    exitApp()
  })
})
