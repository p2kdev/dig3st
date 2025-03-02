#import <Foundation/Foundation.h>
#import "ChatQuery.h"
#import "Config.h"
#import "Digest/DigestPrefsManager.h"

@interface OpenAI : NSObject
@property(nonatomic, strong, readonly) NSURLSession *session;
@property(nonatomic, strong) Config *configuration;
@property(nonatomic, strong) NSString *prompt;
@property(nonatomic, strong) DigestPrefsManager *manager;
- (instancetype)initWithConfiguration:(Config *)configuration;
- (void)summarize:(ChatQuery *)query completion:(void (^)(NSString *response))completion;
- (void)check:(void (^)(BOOL response))completion;
@end
