#import <Foundation/Foundation.h>

@interface ChatQuery : NSObject
@property(nonatomic, strong) NSString *prompt;
- (instancetype)initWithPrompt:(NSString *)prompt;
@end