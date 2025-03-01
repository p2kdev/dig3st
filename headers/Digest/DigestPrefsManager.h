#import <UIKit/UIKit.h>

@interface DigestPrefsManager : NSUserDefaults
+ (instancetype)sharedInstance;
- (instancetype)initWithSuiteName:(NSString *)suitename;
@end