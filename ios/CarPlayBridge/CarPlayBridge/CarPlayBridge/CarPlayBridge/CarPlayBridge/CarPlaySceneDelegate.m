#import "CarPlaySceneDelegate.h"

// 与 RNCarPlayBridge.m 中监听的通知名一致
NSString * const CarPlayConnectionChangedNotification = @"CarPlayConnectionChanged";

@implementation CarPlaySceneDelegate

- (void)templateApplicationScene:(CPTemplateApplicationScene *)templateApplicationScene
     didConnectInterfaceController:(CPInterfaceController *)interfaceController
{
  self.interfaceController = interfaceController;

  // 使用系统共享的 Now Playing 模板：封面/歌名/进度自动读取 MPNowPlayingInfoCenter
  // 播放/暂停/上一曲/下一曲按钮由系统路由到 MPRemoteCommandCenter，
  // 落雪 src/plugins/player/service.ts 已监听这些事件，无需额外处理
  CPNowPlayingTemplate *nowPlaying = [CPNowPlayingTemplate sharedTemplate];

  __weak typeof(self) weakSelf = self;
  [interfaceController setRootTemplate:nowPlaying
                              animated:YES
                            completion:^(BOOL success, NSError *error) {
    if (!success && error != nil) {
      NSLog(@"[CarPlayBridge] setRootTemplate failed: %@", error);
    }
    __strong typeof(self) strongSelf = weakSelf;
    if (strongSelf != nil && strongSelf.interfaceController != nil) {
      [[NSNotificationCenter defaultCenter]
          postNotificationName:CarPlayConnectionChangedNotification
                        object:nil
                      userInfo:@{ @"connected": @YES }];
    }
  }];
}

- (void)templateApplicationScene:(CPTemplateApplicationScene *)templateApplicationScene
     didDisconnectInterfaceController:(CPInterfaceController *)interfaceController
{
  self.interfaceController = nil;
  [[NSNotificationCenter defaultCenter]
      postNotificationName:CarPlayConnectionChangedNotification
                    object:nil
                  userInfo:@{ @"connected": @NO }];
}

@end
