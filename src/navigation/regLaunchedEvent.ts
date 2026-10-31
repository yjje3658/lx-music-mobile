import { Alert } from 'react-native'
import { Navigation } from 'react-native-navigation'

let launched = false
const handlers: Array<() => void> = []

export const listenLaunchEvent = () => {
  Navigation.events().registerAppLaunchedListener(() => {
    launched = true
    Alert.alert('启动诊断', '2.5 RNN启动事件已触发')
    setImmediate(() => {
      for (const handler of handlers) handler()
    })
  })
}

export const onAppLaunched = (handler: () => void) => {
  handlers.push(handler)
  if (launched) {
    setImmediate(() => {
      handler()
    })
  }
}
