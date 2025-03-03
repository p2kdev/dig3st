#import "../../headers/HeadersTweak.h"

@implementation OpenAI
- (instancetype)initWithConfiguration:(Config *)configuration {
    self = [super init];
    if (self) {
        _configuration = configuration;
        _session = [NSURLSession sharedSession];
        self.manager = [NSClassFromString(@"DigestPrefsManager") sharedInstance];
        self.prompt = [self.manager objectForKey:@"prompt"];
        self.systemPrompt = [self.manager objectForKey:@"systemPrompt"];
        self.logger = [NSClassFromString(@"DigestLogger") sharedInstance];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(update) name:@"com.uncore.dig3st/update" object:nil];
    }
    return self;
}

- (void)update {
    [self.logger log:@"Updating OpenAI instance" level:LOGLEVEL_INFO];
    DigestPrefsManager *manager = [DigestPrefsManager sharedInstance];
    NSString *uuid = [manager objectForKey:@"activeEndpoint"];
    NSArray *endpoints = [manager objectForKey:@"endpoints"];
    __block NSDictionary *endpoint;
    [endpoints enumerateObjectsUsingBlock:^(NSDictionary *p, NSUInteger idx, BOOL *stop) {
        if ([p[@"uuid"] isEqualToString:uuid]) {
            endpoint = p;
            *stop = YES;
        }
    }];
    [self.logger log:[NSString stringWithFormat:@"Updating endpoint with UUID %@", uuid] level:LOGLEVEL_INFO];
    [self.logger log:[NSString stringWithFormat:@"New endpoint %@", endpoint] level:LOGLEVEL_INFO];
    if (endpoint == nil) {
        NSLog(@"Tried to update endpoint with UUID %@ but it was not found", uuid);

        return dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            Alert(@"Endpoint is missing", @"Tweak is enabled but the endpoint could not be found. Try resetting the settings and then respring.",nil);
        });
    }
    self.prompt = [self.manager objectForKey:@"prompt"];
    [self.logger log:[NSString stringWithFormat:@"New Prompt: %@", self.prompt] level:LOGLEVEL_VERBOSE];
    
    self.systemPrompt = [self.manager objectForKey:@"systemPrompt"];
    [self.logger log:[NSString stringWithFormat:@"New System Prompt: %@", self.systemPrompt] level:LOGLEVEL_VERBOSE];

    NSInteger timeout = [[self.manager objectForKey:@"timeout"] integerValue];
    self.configuration = [[Config alloc] initWithEndpoint:endpoint timeoutInterval:[NSNumber numberWithInteger:timeout]];
    [self.logger log:[NSString stringWithFormat:@"New Configuration: %@", self.configuration] level:LOGLEVEL_VERBOSE];
}

-(void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"com.uncore.dig3st/update" object:nil];
}

-(NSURL*)urlWithPath:(NSString *)path {
    //maybe follow this implementation in the future
    // NSString *url = [NSString stringWithFormat:@"%@://%@", self.configuration.scheme, self.configuration.host];
    NSString *url = self.configuration.host;
    return (NSURL *)[NSURL URLWithString:[url stringByAppendingString:path]];
}

-(void)check:(void (^)(BOOL response))completion {
    NSURL *url = [self urlWithPath:@"/chat/completions"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"GET"];
    [request setValue:[NSString stringWithFormat:@"Bearer %@",self.configuration.token] forHTTPHeaderField:@"Authorization"];
    
    NSURLSessionDataTask *task = [self.session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            NSLog(@"Request failed: %@", error.localizedDescription);
            completion(NO);
            return;
        }
        
        NSError *jsonError;
        NSDictionary *jsonResponse = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
        if (jsonError) {
            [self.logger log:[NSString stringWithFormat:@"JSON error while checking the endpoint: %@", jsonError.localizedDescription] level:LOGLEVEL_WARNING];
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(NO);
            });
        } else {
            @try {
                NSDictionary *result = jsonResponse[@"error"];
                BOOL isValid = (result == nil);
                [self.logger log:[NSString stringWithFormat:@"Endpoint is valid: %@", isValid ? @"YES" : @"NO"] level:LOGLEVEL_INFO];
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(isValid);
                });
            } @catch (NSException *e) {
                NSLog(@"Exception: %@", e);
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(NO);
                });
            }
        }
    }];
    
    [task resume];
}

-(void)summarize:(ChatQuery*)query completion:(void (^)(NSString *response))completion {
    @try { 
        NSURL *url = [self urlWithPath:@"/chat/completions"];
        [self.logger log:[NSString stringWithFormat:@"Endpoint url: %@",url] level:LOGLEVEL_VERBOSE];
        NSMutableArray *messages = [NSMutableArray array];
        
        if (self.systemPrompt) {
            [messages addObject:@{
                @"role": @"system",
                @"content": self.systemPrompt
            }];
        }
        
        [messages addObject:@{
            @"role": @"user",
            @"content": [NSString stringWithFormat:@"%@ %@", self.prompt, query.prompt]
        }];

        NSDictionary *body = @{
            @"model": self.configuration.model,
            @"messages" : messages,
        };
        [self.logger log:[NSString stringWithFormat:@"Making a post req with body: %@", body] level:LOGLEVEL_VERBOSE];
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:body options:0 error:nil];
        
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
        [request setHTTPMethod:@"POST"];
        [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        [request setValue:[NSString stringWithFormat:@"Bearer %@",self.configuration.token] forHTTPHeaderField:@"Authorization"];
        [request setTimeoutInterval:[self.configuration.timeoutInterval doubleValue]];
        [request setHTTPBody:jsonData];
        
        NSURLSessionDataTask *task = [self.session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            if (error) {
                    NSLog(@"Request failed: %@", error.localizedDescription);
                    return dispatch_async(dispatch_get_main_queue(), ^{
                        completion(@"");
                    });                
            }
            
            NSError *jsonError;
            id jsonResponse = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
            [self.logger log:[NSString stringWithFormat:@"Response body: %@", jsonResponse] level:LOGLEVEL_VERBOSE];

            if (jsonError) {
                    NSLog(@"JSON error: %@", jsonError.localizedDescription);
                    return dispatch_async(dispatch_get_main_queue(), ^{
                        completion(@"");
                    });
            }  
            @try {
                NSString *result = jsonResponse[@"choices"][0][@"message"][@"content"];
                // Sometimes the result contains newlines, which we want to remove
                NSString *cleanedResult = [result stringByReplacingOccurrencesOfString:@"\n" withString:@""];
                return dispatch_async(dispatch_get_main_queue(), ^{
                    completion(cleanedResult);
                });
            } @catch (NSException *e) {
                NSLog(@"Exception: %@", e);
                return dispatch_async(dispatch_get_main_queue(), ^{
                    completion(@"");
                });
            }
        }];

        
        [task resume];
    } @catch (NSException *e) { 
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(@"");
        });
    }
}  
@end
