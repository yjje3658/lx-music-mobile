#import "SceneDelegate.h"
#import "AppDelegate.h"
#import <React/RCTBridge.h>
#import <ReactNativeNavigation/ReactNativeNavigation.h>

@implementation SceneDelegate

- (void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session
      options:(UISceneConnectionOptions *)connectionOptions
{
  AppDelegate *appDelegate = (AppDelegate *)UIApplication.sharedApplication.delegate;
  RCTBridge *bridge = appDelegate.bridge;
  NSAssert(bridge != nil, @"bridge 必须在 didFinishLaunching 中创建完成");

  // 创建绑定当前场景的窗口，交给 AppDelegate（RNN 从 delegate.window 取主窗口）
  UIWindow *window = [[UIWindow alloc] initWithWindowScene:(UIWindowScene *)scene];
  self.window = window;

  @try {
    [appDelegate setValue:window forKey:@"window"];
  } @catch (NSException *e) {
    appDelegate.window = window;
  }

  // 关键①：立即显示窗口（先不管 RNN）——覆盖 LaunchScreen，
  // 如果这里都没效果，说明场景根本没创建（SceneDelegate 没被调用）。
  [window makeKeyAndVisible];

  // 关键②：轮询等 JS bundle 加载完成后再让 RNN 接管。
  // 不用通知监听（通知 object 不匹配会永远等不到 → 白屏），
  // 每 0.1 秒查一次 bridge.isLoading，最长等 10 秒。
  __weak typeof(self) weakSelf = self;
  __block int tries = 0;
  void (^waitAndBootstrap)(void) = ^{
    __strong typeof(self) strongSelf = weakSelf;
    if (strongSelf == nil) return;
    if (bridge.isLoading && tries < 100) {
      tries++;
      dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)),
                     dispatch_get_main_queue(), waitAndBootstrap);
    } else {
      [ReactNativeNavigation bootstrapWithBridge:bridge];
      [strongSelf.window makeKeyAndVisible];
    }
  };
  waitAndBootstrap();
}

@end
