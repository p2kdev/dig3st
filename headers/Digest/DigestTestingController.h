#import <Preferences/PSListController.h>
#import "DigestPrefsManager.h"
#import "DigestLogger.h"

@interface DigestTestingController : PSListController
@property(nonatomic, strong) DigestPrefsManager *manager;
@property(nonatomic, strong) DigestLogger *logger;
@end