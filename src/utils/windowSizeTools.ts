import { Dimensions, StatusBar } from 'react-native'
import { getWindowSize as getWindowSizeRaw } from './nativeModules/utils'

export type SizeHandler = (size: { width: number, height: number }) => void

// 原生模块超时兜底：iOS 端可能没有 getWindowSize 原生实现，超时后用 Dimensions 兜底
const withTimeout = <T>(p: Promise<T>, ms: number, name: string): Promise<T | undefined> =>
  Promise.race([
    p,
    new Promise<T | undefined>((resolve) => {
      setTimeout(() => {
        console.log(`[diag] ${name} 超时${ms}ms，使用 Dimensions 兜底`)
        resolve(undefined)
      }, ms)
    }),
  ])

export const getWindowSize = async() => {
  // 【修复】getWindowSizeRaw() 加 .catch(() => undefined)：
  // iOS 没有 UtilsModule 原生模块，调用会 reject 直接炸掉 Promise 链。
  // reject 转成 undefined 后走 Dimensions 兜底，初始化不再中断。
  const raw = await withTimeout(getWindowSizeRaw().catch(() => undefined), 3000, 'getWindowSizeRaw')
  if (!raw || !raw.width) {
    const window = Dimensions.get('window')
    return {
      width: Math.round(window.width),
      height: Math.round(window.height) + (StatusBar.currentHeight ?? 0),
    }
  }
  const scale = Dimensions.get('window').scale
  raw.width = raw.width / scale
  raw.height = raw.height / scale
  return raw
}

export const windowSizeTools = {
  size: {
    width: 0,
    height: 0,
  },
  listeners: [] as SizeHandler[],
  getSize() {
    return this.size
  },
  onSizeChanged(handler: SizeHandler) {
    this.listeners.push(handler)

    return () => {
      this.listeners.splice(this.listeners.indexOf(handler), 1)
    }
  },
  async init() {
    const size = await getWindowSize()
    if (size.width) {
      this.size = size
    } else {
      const window = Dimensions.get('window')
      this.size = {
        width: Math.round(window.width),
        height: Math.round(window.height) + (StatusBar.currentHeight ?? 0),
      }
    }
    return size
  },
  setWindowSize(width: number, height: number) {
    this.size = {
      width: Math.round(width),
      height: Math.round(height),
    }
    for (const handler of this.listeners) handler(this.size)
  },
}
