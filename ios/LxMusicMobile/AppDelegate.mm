#import "AppDelegate.h"
#import <ReactNativeNavigation/ReactNativeNavigation.h>

#import <React/RCTBundleURLProvider.h>
#import <CarPlay/CarPlay.h>

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
  // Scene 模式下不再在此创建窗口/启动 RNN（窗口与 RNN 启动移到 SceneDelegate），
  // 这里只创建 bridge，供 SceneDelegate 使用
  RCTBridge *bridge = [[RCTBridge alloc] initWithDelegate:self launchOptions:launchOptions];
  self.bridge = bridge;
  self.initialProps = @{};
  return YES;
}

// 新增：场景分发——CarPlay 场景返回 CarPlay 配置，主界面场景返回 Default 配置
- (UISceneConfiguration *)application:(UIApplication *)application
    configurationForConnectingSceneSession:(UISceneSession *)connectingSceneSession
                                   options:(UISceneConnectionOptions *)options
{
  UISceneConfiguration *config =
      [[UISceneConfiguration alloc] initWithName:@"Default"
                                     sessionRole:connectingSceneSession.role];
  if ([connectingSceneSession.role isEqualToString:CPTemplateApplicationSceneSessionRoleApplication]) {
    config.name = @"CarPlay";
  }
  return config;
}

- (NSArray<id<RCTBridgeModule>> *)extraModulesForBridge:(RCTBridge *)bridge {
  return [ReactNativeNavigation extraModulesForBridge:bridge];
}

- (NSURL *)sourceURLForBridge:(RCTBridge *)bridge
{
  return [self getBundleURL];
}
- (NSURL *)getBundleURL
{
#if DEBUG
  return [[RCTBundleURLProvider sharedSettings] jsBundleURLForBundleRoot:@"index"];
#else
  return [[NSBundle mainBundle] URLForResource:@"main" withExtension:@"jsbundle"];
#endif
}

@end
