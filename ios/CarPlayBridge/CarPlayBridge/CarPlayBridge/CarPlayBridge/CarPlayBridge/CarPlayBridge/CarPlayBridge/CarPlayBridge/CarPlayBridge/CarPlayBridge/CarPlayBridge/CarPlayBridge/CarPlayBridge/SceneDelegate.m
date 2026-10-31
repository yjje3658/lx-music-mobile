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

  // ReactNativeNavigation 接管窗口与根视图
  [ReactNativeNavigation bootstrapWithBridge:bridge];

  // 修复黑屏：RNN 创建的主窗口没有绑定 windowScene（多场景模式下不绑定就黑屏）
  // 把它创建的窗口绑定到当前场景并显示
  for (UIWindow *w in UIApplication.sharedApplication.windows) {
    if (w.windowScene == nil) {
      w.windowScene = (UIWindowScene *)scene;
      [w makeKeyAndVisible];
    }
  }
}

@end
