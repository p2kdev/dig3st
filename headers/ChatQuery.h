#import <Foundation/Foundation.h>

@interface ChatQuery : NSObject
@property(nonatomic, strong) NSString *prompt;
@property(nonatomic, strong) NSString *model;
-(instancetype)initWithPrompt:(NSString *)prompt model:(NSString *)model;
@end