#import <Foundation/Foundation.h>

@interface DigestLogger : NSObject
@property(nonatomic, assign) int level;
- (instancetype)initWithLevel:(int)level;
+ (instancetype)sharedInstance;
- (void)log:(NSString *)message level:(int)level;
- (NSDictionary *)levels;
@end