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

  // RNN 启动时主窗口取自 UIApplication.delegate.window。
  // 若它是 nil，RNN 会自己新建一个没绑定场景的窗口 → iOS 13+ 场景模式下不显示 → 黑屏。
  // 所以必须先创建并绑定当前场景的窗口，再交给 AppDelegate。
  UIWindow *window = [[UIWindow alloc] initWithWindowScene:(UIWindowScene *)scene];
  self.window = window;

  // 把窗口交给 AppDelegate（RNN 从 delegate.window 取主窗口）
  @try {
    [appDelegate setValue:window forKey:@"window"];
  } @catch (NSException *e) {
    appDelegate.window = window;
  }

  // 关键修复：等 JS bundle 加载完成后再让 RNN 接管。
  // didFinishLaunching 创建 bridge 后 JS 是异步加载的，若立刻 bootstrap，
  // RNN 拿不到就绪的 bridge → 不初始化 → 白屏（只停 LaunchScreen）。
  if (bridge.isLoading) {
    __weak typeof(self) weakSelf = self;
    [[NSNotificationCenter defaultCenter] addObserverForName:RCTJavaScriptDidLoadNotification
                                                      object:bridge
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification *note) {
      __strong typeof(self) strongSelf = weakSelf;
      if (strongSelf != nil) {
        [ReactNativeNavigation bootstrapWithBridge:bridge];
        [strongSelf.window makeKeyAndVisible];
      }
    }];
  } else {
    [ReactNativeNavigation bootstrapWithBridge:bridge];
    [window makeKeyAndVisible];
  }
}

@end
