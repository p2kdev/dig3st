#import "../../headers/ChatQuery.h"
@implementation ChatQuery
- (instancetype)initWithPrompt:(NSString *)prompt model:(NSString *)model {
    self = [super init];
    if (self) {
        self.prompt = prompt;
        self.model = model;
    }
    return self;
}
@end