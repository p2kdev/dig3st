// Tweak file for simulator
#import <CoreFoundation/CoreFoundation.h>
#include <substrate.h>
#import "../headers/HeadersTweak.h"

NSData *imgData;
DigestPrefsManager *prefsManager;
OpenAI *openai;

%hook NCNotificationRequest
%property (nonatomic, assign) BOOL dig3st;
%property (nonatomic, retain) NSString * actualMessage;
%end

BOOL isOkToSummarize(NSString *sectionIdentifier) {
    //ios has a lot of different types of notifications
    //for example unlock notification for usb connection, etc
    //the bundle identifier for that is com.apple.springboard.alert.SBUserNotificationAlert
    //so skip those
    if ([sectionIdentifier hasPrefix:@"com.apple"]) {
        return NO;
    }
    return YES;
}


%hook NCNotificationSeamlessContentView
%property (nonatomic, retain) UIImageView *imageView;
-(void)setSecondaryText:(NSString *)arg1 {
    @try {
        NCNotificationShortLookViewController *controller = [self _viewControllerForAncestor];
        NCNotificationRequest *req = controller.notificationRequest;
        //long view
        if ([controller isKindOfClass:NSClassFromString(@"NCExpandedPlatterViewController")] && req.dig3st) {
            %orig([req valueForKey:@"actualMessage"]);
        }else{
            %orig(arg1);
        }
    } @catch(NSException *e) {
        NSLog(@"error: setting long view text %@", e) ;
    }
}
%end

%hook NCNotificationShortLookViewController
%property (nonatomic, retain) UIImage *image;
-(void)viewDidLayoutSubviews  {
    %orig;
    @try{
        NCNotificationShortLookView *view  = (NCNotificationShortLookView *)self.viewForPreview;
        if (self.notificationRequest.dig3st) {
            UIView *seamlessContentView =  [view valueForKey:@"notificationContentView"];
            if (seamlessContentView) {
                UIImage *image = [[UIImage alloc] initWithData:imgData];
                self.image = image;

                NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
                attachment.image = image;
                attachment.bounds = CGRectMake(0, 0, 20, 15);
                
                NSAttributedString *attachmentString = [NSAttributedString attributedStringWithAttachment:attachment];
                NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:@" "];
                
                [attributedString appendAttributedString:attachmentString];

                //space between image and text
                [attributedString appendAttributedString:[[NSAttributedString alloc] initWithString:@"  "]];

                NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
                NSDictionary *attributes = @{NSParagraphStyleAttributeName: paragraphStyle};
                NSAttributedString *messageString = [[NSAttributedString alloc] initWithString:[self.notificationRequest.content valueForKey:@"message"] attributes:attributes];
                
                [attributedString appendAttributedString:messageString];
                UILabel *message = [seamlessContentView valueForKey:@"secondaryTextElement"];
                message.attributedText = attributedString;
            }
        } 
    } @catch(NSException *e) {
        NSLog(@"error: %@", e);
    }
}
%end

%hook NCNotificationDispatcher
-(void)postNotificationWithRequest:(NCNotificationRequest*)req {
    @try {
        NSString *textContent = [req.content valueForKey:@"message"];
        NSInteger minChars = [[prefsManager objectForKey:@"minChars"] integerValue];
        DigestLogger *logger = [NSClassFromString(@"DigestLogger") sharedInstance];

        BOOL contentToShort = textContent ? textContent.length < minChars  : YES;
        if (contentToShort || !textContent) {
            [logger log:@"Skipping summarization, content is too short" level:LOGLEVEL_WARNING];
            [req setValue:@(NO) forKey:@"dig3st"];
            return %orig;        
        }
        [logger log:[NSString stringWithFormat:@"Notification received bundle identifier is %@",req.sectionIdentifier] level:LOGLEVEL_VERBOSE];

        //checks if user set anything for this bundle identifier
        id _enabled = [prefsManager objectForKey:req.sectionIdentifier];
        //if not then use isOkToSummarize else use the user setting
        BOOL enabled = _enabled != nil ? [_enabled boolValue] : isOkToSummarize(req.sectionIdentifier);

        [logger log:[NSString stringWithFormat:@"Will summarize notification with bundle identifier %@ ? %@",req.sectionIdentifier,enabled ? @"yes" : @"no"] level:LOGLEVEL_INFO];
        ChatQuery *query = [[ChatQuery alloc] initWithPrompt:textContent];
        [logger log:[NSString stringWithFormat:@"ChatQuery has been created with prompt %@",textContent] level:LOGLEVEL_VERBOSE];

        if (enabled) {
            [openai summarize:query completion:^(NSString *summary) {
                if (summary.length > 0) {
                    [logger log:[NSString stringWithFormat:@"Summary: %@",summary] level:LOGLEVEL_INFO];
                    [req setValue:@(YES) forKey:@"dig3st"];
                    [req setValue:[req.content valueForKey:@"message"] forKey:@"actualMessage"];
                    [req.content setValue:summary forKey:@"message"];
                    %orig(req);
                } else {
                    [req setValue:@(NO) forKey:@"dig3st"];
                    %orig(req);
                }
            }];
        } else {
            [logger log:@"Skipping summarization" level:LOGLEVEL_INFO];
            [req setValue:@(NO) forKey:@"dig3st"];
            %orig(req);
        }
    } @catch (NSException *e) { 
        [req setValue:@(NO) forKey:@"dig3st"];
        NSLog(@"exception while fetching ai response : %@", e);
        %orig;
    }
}
%end

%ctor {
    @try{    
        NSLog(@"init");
        prefsManager = [NSClassFromString(@"DigestPrefsManager") sharedInstance];
        NSDictionary *prefsDict = [prefsManager dictionaryRepresentation];
                for (NSString *key in prefsDict) {
                    NSLog(@"NSUserDefaults key: %@, value: %@ class: %@", key, prefsDict[key],[prefsDict[key] class]);
                }
        BOOL enabled = [[prefsManager objectForKey:@"enabled"] boolValue];
        BOOL apiChecks = [[prefsManager objectForKey:@"apiChecks"] boolValue];
        BOOL sanityChecks = [[prefsManager objectForKey:@"sanityChecks"] boolValue];
        DigestLogger *logger = [NSClassFromString(@"DigestLogger") sharedInstance];
        if (enabled) {

            NSString *uuid = [prefsManager objectForKey:@"activeEndpoint"];
            NSArray *endpoints = [prefsManager objectForKey:@"endpoints"];
            __block NSDictionary *endpoint;

            if (sanityChecks) {
                [logger log:@"Running Sanity Checks" level:LOGLEVEL_INFO];

                if (uuid == nil || [uuid isEqualToString:@""]) {
                    [logger log:@"UUID was empty please try resetting your settings" level:LOGLEVEL_WARNING];
                    //instantly showing the alert results in a crash so delay it
                    return dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(20 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        Alert(@"Internal Error", @"UUID was empty please try resetting your settings and then respring",nil);
                    });
                }

                [logger log:@"Identifying the endpoint to use" level:LOGLEVEL_INFO];
                [endpoints enumerateObjectsUsingBlock:^(NSDictionary *p, NSUInteger idx, BOOL *stop) {
                    if ([p[@"uuid"] isEqualToString:uuid]) {
                        endpoint = p;
                        *stop = YES;
                    }
                }];

                [logger log:[NSString stringWithFormat:@"Chosen endpoint is %@",endpoint] level:LOGLEVEL_INFO];

                if (endpoint == nil) {
                    [logger log:@"Endpoint could not be found" level:LOGLEVEL_WARNING];

                    //instantly showing the alert results in a crash so delay it
                    return dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(20 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        Alert(@"Endpoint could not be found", @"Tweak is enabled but the endpoint could not be found. Try resetting the settings and then respring.",nil);
                    });
                }
            }
            Config *config = [[Config alloc] initWithEndpoint:endpoint timeoutInterval:@10];
            [logger log:@"Config has been created" level:LOGLEVEL_VERBOSE];

            openai = [[OpenAI alloc] initWithConfiguration:config];
            [logger log:@"Openai instance has been created" level:LOGLEVEL_VERBOSE];

            //check if bundle exists at /Library/PreferenceBundles/dig3st.bundle
            NSFileManager *fileManager = [NSFileManager defaultManager];

            //it turns out MacOS is mounted at /Volumes/MacOS
            NSString *path = @"/Volumes/MacOS/Users/uncore/Desktop/dig3st.bundle";
            if (![fileManager fileExistsAtPath:path]) {
                [logger log:[NSString stringWithFormat:@"Bundle not found at %@",path] level:LOGLEVEL_WARNING];
            }

            NSBundle *bundle = [[NSBundle alloc] initWithPath:path];
            NSString *imgFile = [bundle pathForResource:@"arrow" ofType:@"png"];

            // NSError *error = nil;
            // NSArray *contents = [fileManager contentsOfDirectoryAtPath:@"/Volumes/MacOS/Users/uncore/Desktop" error:&error];

            // if (error) {
            //     NSLog(@"Error reading root directory: %@", error.localizedDescription);
            // } else {
            //     for (NSString *item in contents) {
            //         NSString *fullPath = [@"/Volumes/MacOS/Users/uncore/Desktop" stringByAppendingPathComponent:item];
            //         BOOL isDirectory;
            //         [fileManager fileExistsAtPath:fullPath isDirectory:&isDirectory];
                    
            //         if (isDirectory) {
            //             NSLog(@"Directory: %@", fullPath);
            //         } else {
            //             NSLog(@"File: %@", fullPath);
            //         }
            //     }
            // }

            if (apiChecks) {
                [logger log:@"Running API Check" level:LOGLEVEL_INFO];
                [openai check:^(BOOL success) {
                    if (!success) {
                        [logger log:@"API request failed disable Check Api in the settings to skip this check and then respring" level:LOGLEVEL_WARNING];
                        //instantly showing the alert results in a crash so delay it
                        return dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(20 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                            Alert(@"API Error", @"API request failed this means the current endpoint might be invalid,disable Check Api in the settings to skip this check and then respring",nil);
                        });
                    }
                }];
            }
            
            imgData = [[NSData alloc] initWithContentsOfFile:imgFile];
            [logger log:@"End of ctor block" level:LOGLEVEL_VERBOSE];
            %init;
        }else {
            [logger log:@"End of ctor block, not running (tweak is disabled)" level:LOGLEVEL_WARNING];
        }
    }@catch(NSException *e) {
        NSLog(@"error: %@", e);
    }
}


