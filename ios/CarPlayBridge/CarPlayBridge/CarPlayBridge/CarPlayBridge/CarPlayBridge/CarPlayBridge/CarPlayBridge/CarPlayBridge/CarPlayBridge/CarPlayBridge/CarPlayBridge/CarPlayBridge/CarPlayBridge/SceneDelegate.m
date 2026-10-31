#import "SceneDelegate.h"
#import "AppDelegate.h"
#import <React/RCTBridge.h>
#import <ReactNativeNavigation/ReactNativeNavigation.h>

@implementation SceneDelegate

- (void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session
      options:(UISceneConnectionOptions *)connectionOptions
{
  UIWindow *window = [[UIWindow alloc] initWithWindowScene:(UIWindowScene *)scene];
  self.window = window;

  AppDelegate *appDelegate = (AppDelegate *)UIApplication.sharedApplication.delegate;
  RCTBridge *bridge = appDelegate.bridge;
  NSAssert(bridge != nil, @"bridge 必须在 didFinishLaunching 中创建完成");

  // ReactNativeNavigation 在此接管窗口与根视图
  // 注：RNN 7.39 的 bootstrap 会创建并显示自己的窗口；
  // 若真机上白屏（RNN 窗口未绑定 windowScene），把日志贴回来，
  // 改法：改为 [ReactNativeNavigation bootstrapWithBridge:bridge] 后把 RNN 窗口手动关联 windowScene
  [ReactNativeNavigation bootstrapWithBridge:bridge];
  [window makeKeyAndVisible];
}

@end
