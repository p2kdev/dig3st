#import "../headers/HeadersTweak.h"

static NSString * nsNotificationString = @"com.uncore.dig3st/preferences.changed";
static void notificationCallback(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"com.uncore.dig3st/update" object:nil];
}

@implementation DigestPrefsManager
+ (instancetype)sharedInstance {
    static DigestPrefsManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[DigestPrefsManager alloc] initWithSuiteName:@"com.uncore.dig3st"];
    });
    return sharedInstance;
}

- (instancetype)initWithSuiteName:(NSString *)suitename {
    DigestPrefsManager *prefs = [super initWithSuiteName:suitename];

    [prefs registerDefaults:@{
        @"enabled": @NO,
        @"apiChecks": @NO,
        @"sanityChecks": @YES,
        @"logLevel": @"1",
        @"prompt" : @"Summarize this text as sort as possible only mention about the content do not go in detail,super simple shorten anything you can (urls,numbers),compromise understandability in favor of keeping it short,only keep keywords,if possible fit it in a max a sentence of 5 words",
        @"systemPrompt": @"You are an assistant that summarizes notifications.",
        @"minChars": @"15",
        @"timeout": @"30",
        //some enabled defaults
        @"com.apple.MobileSMS" : @YES,
        @"com.apple.news" : @YES,
        @"ph.telegra.Telegraph" : @YES,
        @"com.apple.mobilemail" : @YES,
        @"activeEndpoint" : @"131931923291414342342",
        @"endpoints" : @[
            @{@"apiKey": @"AIzaSyDKxKADDHENhe3IcdofAP7ljc6ZolbuinQ", @"uuid": @"131931923291414342342",@"label":@"main", @"model": @"gemini-1.5-flash", @"url": @"https://generativelanguage.googleapis.com/v1beta/openai"},
            @{@"apiKey": @"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", @"uuid": @"123141241432423413132", @"label":@"main",@"model": @"gpt-4o", @"url": @"https://api.openai.com/v1"},
        ],
    }];
    
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, notificationCallback, (CFStringRef)nsNotificationString, NULL, CFNotificationSuspensionBehaviorCoalesce);

    return prefs;
}
@end