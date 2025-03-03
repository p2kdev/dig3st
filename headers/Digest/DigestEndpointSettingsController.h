#import <Preferences/PSListController.h>
#import "DigestPrefsManager.h"
#import "DigestLogger.h"

@interface DigestEndpointSettingsController : PSListController
@property(nonatomic, copy) NSString *titleKey;
@property(nonatomic, copy) NSDictionary *endpoint;
@property(nonatomic, strong) DigestPrefsManager *manager;
@property(nonatomic, strong) DigestLogger *logger;
- (NSMutableArray *)visibleSpecifiersFromPlist:(NSString *)plist;
@end