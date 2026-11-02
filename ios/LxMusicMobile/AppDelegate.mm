#import "AppDelegate.h"

#import <React/RCTBridge.h>
#import <React/RCTBundleURLProvider.h>
#import <ReactNativeNavigation/ReactNativeNavigation.h>

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
  // 场景模式（Info.plist 声明了 UIApplicationSceneManifest）：
  // 窗口创建 + RNN 启动移到 SceneDelegate.willConnectToSession 执行，
  // 这里只负责创建 bridge（SceneDelegate 需要它）
  RCTBridge *bridge = [[RCTBridge alloc] initWithDelegate:self launchOptions:launchOptions];
  self.bridge = bridge;

  // 关键修复：Info.plist 中 UIApplicationSupportsMultipleScenes=true（CarPlay 场景必需），
  // 此时 iOS 不会自动创建 iPhone 主场景，必须主动请求创建场景，
  // 否则 SceneDelegate.willConnectToSession 永远不被调用 → 无窗口 → 白屏停在 LaunchScreen。
  [UIApplication.sharedApplication requestSceneSessionActivation:nil
                                                    userActivity:nil
                                                     options:nil
                                                    errorHandler:^(NSError *error) {
    NSLog(@"[AppDelegate] requestSceneSessionActivation 失败: %@", error);
  }];

  return YES;
}

- (NSArray<id<RCTBridgeModule>> *)extraModulesForBridge:(RCTBridge *)bridge
{
  return [ReactNativeNavigation extraModulesForBridge:bridge];
}

- (NSURL *)sourceURLForBridge:(RCTBridge *)bridge
{
#if DEBUG
  return [[RCTBundleURLProvider sharedSettings] jsBundleURLForBundleRoot:@"index"];
#else
  return [[NSBundle mainBundle] URLForResource:@"main" withExtension:@"jsbundle"];
#endif
}

@end
