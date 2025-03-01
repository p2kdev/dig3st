#import "../../headers/HeadersTweak.h"

@implementation Config 
- (instancetype)initWithEndpoint:(NSDictionary*)endpoint timeoutInterval:(NSNumber *)timeoutInterval {
    self = [super init];
    if (self) {
        self.token = endpoint[@"apiKey"];
        self.host = endpoint[@"url"];
        self.model = endpoint[@"model"];
        // self.port = port;
        // self.scheme = scheme;
        // self.basePath = basePath;
        self.timeoutInterval = timeoutInterval;
    }
    return self;
}

@end