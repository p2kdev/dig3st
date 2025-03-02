#import "../../headers/HeadersTweak.h"

@implementation OpenAI
- (instancetype)initWithConfiguration:(Config *)configuration {
    self = [super init];
    if (self) {
        _configuration = configuration;
        _session = [NSURLSession sharedSession];
        self.manager = [NSClassFromString(@"DigestPrefsManager") sharedInstance];
        self.prompt = [self.manager objectForKey:@"prompt"];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(update) name:@"com.uncore.dig3st/update" object:nil];
    }
    return self;
}

- (void)update {
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

    if (endpoint == nil) {
        NSLog(@"Tried to update endpoint with UUID %@ but it was not found", uuid);
        return dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            Alert(@"Endpoint is missing", @"Tweak is enabled but the endpoint could not be found. Try resetting the settings and then respring.",nil);
        });
    }
    self.prompt = [self.manager objectForKey:@"prompt"];
    self.configuration = [[Config alloc] initWithEndpoint:endpoint timeoutInterval:@10];

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
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(NO);
            });
        } else {
            @try {
                NSDictionary *result = jsonResponse[@"error"];
                BOOL isValid = (result == nil);
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(isValid);
                });
            } @catch (NSException *e) {
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
        NSLog(@"url: %@", url);

            // @"model": @"gemini-2.0-flash",
        NSDictionary *body = @{
            @"model": self.configuration.model,
            @"messages" : @[
                @{
                    @"role": @"user",
                    @"content": [NSString stringWithFormat:@"%@ %@",self.prompt, query.prompt]
                },
            ]
        };
        NSLog(@"body: %@", body);
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:body options:0 error:nil];
        
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
        [request setHTTPMethod:@"POST"];
        [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        [request setValue:[NSString stringWithFormat:@"Bearer %@",self.configuration.token] forHTTPHeaderField:@"Authorization"];
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
            NSLog(@"result: %@", jsonResponse);

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
