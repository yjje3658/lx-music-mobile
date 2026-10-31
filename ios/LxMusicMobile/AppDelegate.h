#import <RCTAppDelegate.h>
#import <UIKit/UIKit.h>

@class RCTBridge;

@interface AppDelegate : RCTAppDelegate

// 新增：bridge 暴露给 SceneDelegate 使用
@property (nonatomic, strong) RCTBridge *bridge;

@end
