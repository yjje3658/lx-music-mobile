#import "RNCarPlayBridge.h"

extern NSString * const CarPlayConnectionChangedNotification;

@implementation RNCarPlayBridge

RCT_EXPORT_MODULE(CarPlayBridge);

+ (BOOL)requiresMainQueueSetup
{
  return YES;
}

- (NSArray<NSString *> *)supportedEvents
{
  return @[ @"onCarPlayConnectionChanged" ];
}

- (instancetype)init
{
  if (self = [super init]) {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleConnectionChanged:)
                                                 name:CarPlayConnectionChangedNotification
                                               object:nil];
  }
  return self;
}

- (void)handleConnectionChanged:(NSNotification *)notification
{
  [self sendEventWithName:@"onCarPlayConnectionChanged" body:notification.userInfo];
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
