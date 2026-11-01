import { Navigation } from 'react-native-navigation'
import * as screenNames from './screenNames'
import * as navigations from './navigation'
import { Alert } from 'react-native'

import registerScreens from './registerScreens'
import { removeComponentId } from '@/core/common'
import { onAppLaunched } from './regLaunchedEvent'

let unRegisterEvent: ReturnType<ReturnType<typeof Navigation.events>['registerScreenPoppedListener']>

const init = (callback: () => void | Promise<void>) => {
  Alert.alert('启动诊断', '2.8 init开始执行')
  // Register all screens on launch
  registerScreens()

  if (unRegisterEvent) unRegisterEvent.remove()

  Navigation.setDefaultOptions({
    // animations: {
    //   setRoot: {
    //     waitForRender: true,
    //   },
    // },
  })
  unRegisterEvent = Navigation.events().registerScreenPoppedListener(({ componentId }) => {
    removeComponentId(componentId)
  })
  Alert.alert('启动诊断', '2.9 导航回调已注册')
  onAppLaunched(() => {
    console.log('Register app launched listener')
    void callback()
  })
}

export * from './utils'
export * from './event'
export * from './hooks'

export {
  init,
  screenNames,
  navigations,
}
