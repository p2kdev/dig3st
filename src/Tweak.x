#import <CoreFoundation/CoreFoundation.h>
#include <substrate.h>
#import "../headers/HeadersTweak.h"

//just 500bytes
//much more efficient than reading from disk every time
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
                // self.image = image;

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
        BOOL contentToShort = textContent ? textContent.length < minChars  : YES;
        if (contentToShort || !textContent) {
            [req setValue:@(NO) forKey:@"dig3st"];
            return %orig;        
        }
        NSLog(@"uncor3: en %@", [prefsManager objectForKey:req.sectionIdentifier]);

        //checks if user set anything for this bundle identifier
        id _enabled = [prefsManager objectForKey:req.sectionIdentifier];
        //if not then use isOkToSummarize else use the user setting
        BOOL enabled = _enabled != nil ? [_enabled boolValue] : isOkToSummarize(req.sectionIdentifier);
        NSLog(@"uncor3: enabled %d", enabled);
        ChatQuery *query = [[ChatQuery alloc] initWithPrompt:textContent model:@"gpt-3.5-turbo"];
        if (enabled) {
            [openai summarize:query completion:^(NSString *summary) {
                if (summary.length > 0) {
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
    if ([[prefsManager objectForKey:@"enabled"] boolValue]) {

        // BOOL runChecks = [prefsManager objectForKey:@"runChecks"];
 
    

        NSString *uuid = [prefsManager objectForKey:@"activeEndpoint"];
        NSArray *endpoints = [prefsManager objectForKey:@"endpoints"];
        __block NSDictionary *endpoint;
        [endpoints enumerateObjectsUsingBlock:^(NSDictionary *p, NSUInteger idx, BOOL *stop) {
            if ([p[@"uuid"] isEqualToString:uuid]) {
                endpoint = p;
                *stop = YES;
            }
        }];

        if (endpoint == nil) {
            NSLog(@"Endpoint is missing");
            //instantly showing the alert results in a crash so delay it
            return dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                Alert(@"Endpoint is missing", @"Tweak is enabled but the endpoint could not be found. Try resetting the settings and then respring.",nil);
            });
        }
        // NSString *apiKey = endpoint[@"apiKey"];


        

        // NSString *apiKey = @"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";

        // if (uuid == nil || [uuid isEqualToString:@""]) {
        //     NSLog(@"");
        //     //instantly showing the alert results in a crash so delay it
        //     return dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        //         Alert(@"API Key is missing", @"Tweak is enabled but API Key is missing. Please enter the API Key in the settings and then respring.",nil);
        //     });
        // }
        Config *config = [[Config alloc] initWithEndpoint:endpoint timeoutInterval:@10];
        // Config *config = [[Config alloc] initWithToken:apiKey host:@"api.openai.com/v1" port:@443 scheme:@"https" basePath:@"/v1" timeoutInterval:@60];
        openai = [[OpenAI alloc] initWithConfiguration:config];
        NSBundle *bundle = [[NSBundle alloc] initWithPath:ROOT_PATH_NS(@"/Library/PreferenceBundles/dig3st.bundle")];
        NSString *imgFile = [bundle pathForResource:@"arrow" ofType:@"png"];
        imgData = [[NSData alloc] initWithContentsOfFile:imgFile];
        %init;
    }
        }@catch(NSException *e) {
        NSLog(@"error: %@", e);
    }
}


