#import <Foundation/Foundation.h>

void checkApiKeyImp(NSString *apiKey, void (^completion)(BOOL response)) {
    // "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash?key=12314"
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash?key=%@", apiKey]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"GET"];

    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request
                                                completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            NSLog(@"Request failed: %@", error.localizedDescription);
            completion(NO);
            return;
        }

        // Handle the response
        NSError *jsonError;
        NSDictionary *jsonResponse = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
        if (jsonError) {
            completion(NO);
        } else {
            @try {
                NSDictionary *result = jsonResponse[@"error"];
                BOOL isValid = (result == nil);
                completion(isValid);
            } @catch (NSException *e) {
                completion(NO);
            }
        }
    }];

    [task resume];
}