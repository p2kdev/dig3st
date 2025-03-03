#import "../../headers/ChatQuery.h"
@implementation ChatQuery
- (instancetype)initWithPrompt:(NSString *)prompt {
    self = [super init];
    if (self) {
        self.prompt = prompt;
    }
    return self;
}
@end