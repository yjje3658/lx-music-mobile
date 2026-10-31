import { NativeModules, NativeEventEmitter } from 'react-native'
import TrackPlayer from 'react-native-track-player'

// CarPlay 连接时兜底刷新 Now Playing 信息。
// 正常情况下 track-player 会自动维护 MPNowPlayingInfoCenter，
// 这里只在连接瞬间强制刷一次，防止车机刚连上时信息未同步。
const CarPlayBridge = NativeModules.CarPlayBridge as any

if (CarPlayBridge) {
  const emitter = new NativeEventEmitter(CarPlayBridge)
  emitter.addListener('onCarPlayConnectionChanged', async (e: { connected: boolean }) => {
    if (!e.connected) return
    try {
      const anyPlayer = TrackPlayer as any
      if (typeof anyPlayer.updateNowPlayingForCurrentTrack === 'function') {
        await anyPlayer.updateNowPlayingForCurrentTrack()
      }
    } catch (_e) {
      // 忽略：刷新失败不影响播放，track-player 会自行维护
    }
  })
}
