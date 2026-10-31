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

  // RNN 接管导航（此时它拿到的就是我们已绑定场景的窗口）
  [ReactNativeNavigation bootstrapWithBridge:bridge];
  [window makeKeyAndVisible];
}

@end
