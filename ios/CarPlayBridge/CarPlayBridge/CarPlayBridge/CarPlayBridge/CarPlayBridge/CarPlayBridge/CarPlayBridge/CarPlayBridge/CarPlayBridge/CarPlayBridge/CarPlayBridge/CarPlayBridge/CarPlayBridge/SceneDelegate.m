#import "SceneDelegate.h"
#import "AppDelegate.h"
#import <React/RCTBridge.h>
#import <ReactNativeNavigation/ReactNativeNavigation.h>

// 【关键修复】ReactNativeNavigation.h（7.39.2）没有公开 sharedInstance，
// 直接调用产生 warning，Release 构建把 warning 当 error（-Werror）→ 编译失败。
// 补类扩展声明消除该 warning。
@interface ReactNativeNavigation (Private)
+ (instancetype)sharedInstance;
@end

@implementation SceneDelegate

// 关键修复：RNN 在 didFinishLaunching 时自己创建了"无场景"窗口（_mainWindow），
// iOS 13+ 无场景窗口不显示 → 白屏。用 KVC 把 RNN 的 _mainWindow 换成场景窗口，
// 并把已挂上的 rootViewController 迁移过来。
// 【注意】此方法必须先于 willConnectToSession 定义。
- (void)repointRNNWindowToSceneWindow:(UIWindow *)sceneWindow
{
  @try {
    id nav = [ReactNativeNavigation sharedInstance];
    id bridgeManager = [nav valueForKey:@"bridgeManager"];
    id commandsHandler = [bridgeManager valueForKey:@"commandsHandler"];
    UIWindow *oldWindow = [commandsHandler valueForKey:@"mainWindow"];
    if (oldWindow != nil && oldWindow != sceneWindow) {
      UIViewController *rootVC = oldWindow.rootViewController;
      [commandsHandler setValue:sceneWindow forKey:@"mainWindow"];
      if (rootVC != nil) {
        sceneWindow.rootViewController = rootVC;
        oldWindow.rootViewController = nil;
      }
      NSLog(@"[SceneDelegate] RNN window repointed to scene window");
    }
  } @catch (NSException *e) {
    NSLog(@"[SceneDelegate] repoint RNN window failed: %@", e);
  }
}

- (void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session
      options:(UISceneConnectionOptions *)connectionOptions
{
  AppDelegate *appDelegate = (AppDelegate *)UIApplication.sharedApplication.delegate;
  RCTBridge *bridge = appDelegate.bridge;
  NSAssert(bridge != nil, @"bridge 必须在 didFinishLaunching 中创建完成");

  // 创建绑定当前场景的窗口
  UIWindow *window = [[UIWindow alloc] initWithWindowScene:(UIWindowScene *)scene];
  self.window = window;

  // 交给 AppDelegate（RNN 从 delegate.window 取主窗口）
  @try {
    [appDelegate setValue:window forKey:@"window"];
  } @catch (NSException *e) {
    appDelegate.window = window;
  }

  // 立即显示窗口（覆盖 LaunchScreen）
  [window makeKeyAndVisible];

  // 轮询等 JS bundle 加载完成（不依赖通知 object，最稳）
  // 【闪退修复】递归 block 必须用 __block 修饰，
  // 否则栈上 block 自引用在 dispatch_after 异步拷贝时拿到 NULL → SIGTRAP 崩溃
  __weak typeof(self) weakSelf = self;
  __block int tries = 0;
  __block void (^waitAndBootstrap)(void);
  waitAndBootstrap = ^{
    __strong typeof(self) strongSelf = weakSelf;
    if (strongSelf == nil) return;
    if (bridge.isLoading && tries < 100) {
      tries++;
      dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)),
                     dispatch_get_main_queue(), waitAndBootstrap);
    } else {
      [ReactNativeNavigation bootstrapWithBridge:bridge];
      [strongSelf repointRNNWindowToSceneWindow:window];
      [strongSelf.window makeKeyAndVisible];
    }
  };
  waitAndBootstrap();
}

@end
