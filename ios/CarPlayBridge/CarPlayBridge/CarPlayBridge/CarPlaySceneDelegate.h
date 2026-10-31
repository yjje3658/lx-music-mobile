#import <UIKit/UIKit.h>
#import <CarPlay/CarPlay.h>

NS_ASSUME_NONNULL_BEGIN

@interface CarPlaySceneDelegate : UIResponder <CPTemplateApplicationSceneDelegate, CPInterfaceControllerDelegate>

@property (nonatomic, strong, nullable) CPInterfaceController *interfaceController;

@end

NS_ASSUME_NONNULL_END
