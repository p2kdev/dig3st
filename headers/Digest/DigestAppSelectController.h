#import <Preferences/PSListController.h>
#import "DigestPrefsManager.h"

@interface DigestAppSelectController : PSListController
@property(nonatomic, copy) DigestPrefsManager *manager;
@end
