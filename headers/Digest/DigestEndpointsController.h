#import <Preferences/PSListController.h>
#import "DigestPrefsManager.h"
#import "DigestLogger.h"

@interface PSEditableListController : PSListController
@end
@interface DigestEndpointsController : PSEditableListController
@property (nonatomic, strong) DigestPrefsManager *manager;
@property(nonatomic, strong) DigestLogger *logger;
@end