#import "../headers/HeadersTweak.h"


@implementation DigestLogger
- (NSDictionary *)levels {
    return @{
        @10: @"Verbose",
        @6: @"Info",
        @4: @"Warning",
        @1: @"Disable Output"
    };
}

-(instancetype)initWithLevel:(int)level {
    self = [super init];
    if (self) {
        self.level = level;
    }
    return self;
}
+(instancetype)sharedInstance {
    static DigestLogger *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[DigestLogger alloc] initWithLevel:10];
    });
    return sharedInstance;
}
-(void)log:(NSString *)message level:(int)level;
{
    if (level != LOGLEVEL_DISABLED && self.level >= level) {
        NSLog(@"[%@] %@", self.levels[@(level)], message);
    }
}
@end
