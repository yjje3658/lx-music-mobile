#import <UIKit/UIKit.h>
#import <React/RCTBridgeDelegate.h>

@class RCTBridge;

@interface AppDelegate : UIResponder <UIApplicationDelegate, RCTBridgeDelegate>

@property (nonatomic, strong) UIWindow *window;
@property (nonatomic, strong) RCTBridge *bridge;

@end
