#import <Preferences/PSListController.h>
#import "DigestPrefsManager.h"

@interface DigestEndPointSettingsController : PSListController
@property(nonatomic, copy) NSString *titleKey;
@property(nonatomic, copy) NSDictionary *endpoint;
@property(nonatomic, strong) DigestPrefsManager *manager;
- (NSMutableArray *)visibleSpecifiersFromPlist:(NSString *)plist;
@end