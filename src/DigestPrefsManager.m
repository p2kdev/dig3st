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
        @"prompt" : @"Summarize this text as short as possible only mention about the content do not go in detail,super simple shorten anything you can (urls,numbers),compromise understandability in favor of keeping it short,only keep keywords,if possible fit it in a max a sentence of 5 words",
        @"systemPrompt": @"You are an assistant that summarizes notifications.",
        @"minChars": @"15",
        @"timeout": @"30",
        //some enabled defaults
        @"activeEndpoint" : @"3FAC24B8-6EBF-40CC-818B-8BBC64410EF4",
        @"endpoints" : @[
            @{@"apiKey": @"your gemini api key", @"uuid": @"3FAC24B8-6EBF-40CC-818B-8BBC64410EF4",@"label":@"main", @"model": @"gemini-2.0-flash", @"url": @"https://generativelanguage.googleapis.com/v1beta/openai"},
            @{@"apiKey": @"your openai api key", @"uuid": @"792BBF8B-A0EF-477D-B5AE-D105D0D2B340", @"label":@"main",@"model": @"gpt-4o", @"url": @"https://api.openai.com/v1"},
            @{@"apiKey": @"key may not be required", @"uuid": @"E7C57337-EA07-4EF6-AEB7-D5148B7E856E", @"label":@"ollama",@"model": @"qwen2.5:7b", @"url": @"http://192.168.1.152:11434/v1"},
        ],
        @"testNotif":@{
            @"title": @"Google",
            @"content": @"We noticed a new sign-in to your Google Account on a Linux device. If this was you, you don’t need to do anything. If not, we’ll help you secure your account.",
            @"bundleIdentifier": @"com.apple.mobilemail",
        }
    }];
    
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, notificationCallback, (CFStringRef)nsNotificationString, NULL, CFNotificationSuspensionBehaviorCoalesce);

    return prefs;
}
@end