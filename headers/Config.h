#import <Foundation/Foundation.h>

@interface Config : NSObject
@property(nonatomic, strong) NSString *token;
@property(nonatomic, strong) NSString *host;
@property(nonatomic, strong) NSNumber *port;
@property(nonatomic, strong) NSString *scheme;
@property(nonatomic, strong) NSString *basePath;
@property(nonatomic, strong) NSString *model;
@property(nonatomic, strong) NSNumber *timeoutInterval;
- (instancetype)initWithEndpoint:(NSDictionary *)endpoint timeoutInterval:(NSNumber *)timeoutInterval;
@end
