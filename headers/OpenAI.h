#import <Foundation/Foundation.h>
#import "ChatQuery.h"
#import "Config.h"
#import "Digest/DigestPrefsManager.h"
#import "Digest/DigestLogger.h"

@interface OpenAI : NSObject
@property(nonatomic, strong, readonly) NSURLSession *session;
@property(nonatomic, strong) Config *configuration;
@property(nonatomic, strong) NSString *prompt;
@property(nonatomic, strong) NSString *systemPrompt;
@property(nonatomic, strong) DigestPrefsManager *manager;
@property(nonatomic, strong) DigestLogger *logger;
- (instancetype)initWithConfiguration:(Config *)configuration;
- (void)summarize:(ChatQuery *)query completion:(void (^)(NSString *response))completion;
- (void)check:(void (^)(BOOL response))completion;
@end
