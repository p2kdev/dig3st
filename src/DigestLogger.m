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
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(update) name:@"com.uncore.dig3st/update" object:nil];
    }
    return self;
}
+(instancetype)sharedInstance {
    static DigestLogger *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSInteger level = [[[NSClassFromString(@"DigestPrefsManager") sharedInstance] objectForKey:@"logLevel"] integerValue];
        sharedInstance = [[DigestLogger alloc] initWithLevel:(int)level];
    });
    return sharedInstance;
}
-(void)update {
    NSInteger level = [[[NSClassFromString(@"DigestPrefsManager") sharedInstance] objectForKey:@"logLevel"] integerValue];
    NSLog(@"Log level updated to %ld", (long)level);
    self.level = (int)level;
}

-(void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"com.uncore.dig3st/update" object:nil];
}

-(void)log:(NSString *)message level:(int)level;
{
    if (level != LOGLEVEL_DISABLED && self.level >= level) {
        NSLog(@"[%@] %@", self.levels[@(level)], message);
    }
}
@end
