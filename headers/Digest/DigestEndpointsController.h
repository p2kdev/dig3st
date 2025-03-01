#import <Preferences/PSListController.h>
#import "DigestPrefsManager.h"

@interface PSEditableListController : PSListController
@end
@interface DigestEndpointsController : PSEditableListController
@property (nonatomic, strong) DigestPrefsManager *manager;
@end