#import <CoreFoundation/CoreFoundation.h>
#include <substrate.h>
#import "../headers/HeadersTweak.h"

NSData *imgData;
DigestPrefsManager *prefsManager;
OpenAI *openai;

%hook NCNotificationRequest
    %property (nonatomic, retain) NSString * summarizedMessage;
    %property (nonatomic, retain) NSString * summarizationError;
%end

%hook NCNotificationSeamlessContentView

    -(void)setSecondaryText:(NSString *)arg1 {
        %orig(arg1);
        [self updateSummarizedText];
    }

    -(void)_updateTextAttributesForSecondaryTextElement {
        %orig;
        [self updateSummarizedText];
    }

    // -(void)_configureSecondaryLabelIfNecessary {
    //     %orig;
    //     [self updateSummarizedText];
    // }

    // -(void)_configureSecondaryTextViewIfNecessary {
    //     %orig;
    //     [self updateSummarizedText];
    // }     

    // -(void)_configureSecondaryTextElementIfNecessary {
    //     %orig;
    //     [self updateSummarizedText];
    // }    

    %new
    -(void)updateSummarizedText {
        UILabel *secondaryTextElement = [self valueForKey:@"secondaryTextElement"];
        if (!secondaryTextElement) {
            return;
        } 

        NCNotificationShortLookViewController *controller = [self _viewControllerForAncestor];
        NCNotificationRequest *req = controller.notificationRequest;        

        if ([[self _viewControllerForAncestor] isKindOfClass:NSClassFromString(@"NCNotificationShortLookViewController")]) {
            if (req.summarizedMessage) {
                UIImage *image = [[[UIImage alloc] initWithData:imgData scale:[[UIScreen mainScreen] scale]] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];

                NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
                attachment.image = image;
                attachment.bounds = CGRectMake(0, 0, 19, 12);
                    
                NSAttributedString *attachmentString = [NSAttributedString attributedStringWithAttachment:attachment];
                NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:@" "];
                
                [attributedString appendAttributedString:attachmentString];

                //space between image and text
                [attributedString appendAttributedString:[[NSAttributedString alloc] initWithString:@"  "]];

                NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
                NSDictionary *attributes = @{NSParagraphStyleAttributeName: paragraphStyle};
                NSAttributedString *messageString = [[NSAttributedString alloc] initWithString:req.summarizedMessage attributes:attributes];
                
                [attributedString appendAttributedString:messageString];
                secondaryTextElement.text = nil;
                secondaryTextElement.attributedText = attributedString;   
                secondaryTextElement.font = [UIFont italicSystemFontOfSize:secondaryTextElement.font.pointSize];                
                return;
            }
        }

        // secondaryTextElement.attributedText = nil;
        // secondaryTextElement.text = [req.content valueForKey:@"message"];
        // secondaryTextElement.font = [UIFont systemFontOfSize:secondaryTextElement.font.pointSize];                                    
    }
%end

%hook NCNotificationDispatcher
    -(void)postNotificationWithRequest:(NCNotificationRequest*)req {
        @try {
            DigestLogger *logger = [NSClassFromString(@"DigestLogger") sharedInstance];
            [logger log:[NSString stringWithFormat:@"Notification received bundle identifier is %@",req.sectionIdentifier] level:LOGLEVEL_VERBOSE];
            NSString *textContent = [req.content valueForKey:@"message"];
            [req setValue:nil forKey:@"summarizedMessage"];
            [req setValue:nil forKey:@"summarizationError"];
            NSInteger minChars = [[prefsManager objectForKey:@"minChars"] integerValue];

            BOOL contentTooShort = textContent ? textContent.length < minChars  : YES;
            if (contentTooShort) {
                [req setValue:@"Content short" forKey:@"summarizationError"];
                [logger log:@"Skipping summarization, content is too short" level:LOGLEVEL_WARNING];
                return %orig;        
            }

            //checks if user set anything for this bundle identifier
            id _enabled = [prefsManager objectForKey:req.sectionIdentifier];
            //if not then use isOkToSummarize else use the user setting
            BOOL enabled = _enabled == nil ? YES : [_enabled boolValue];

            [logger log:[NSString stringWithFormat:@"Will summarize notification with bundle identifier %@ ? %@",req.sectionIdentifier,enabled ? @"yes" : @"no"] level:LOGLEVEL_INFO];

            if (enabled) {
                ChatQuery *query = [[ChatQuery alloc] initWithPrompt:textContent];
                [logger log:[NSString stringWithFormat:@"ChatQuery has been created with prompt %@",textContent] level:LOGLEVEL_VERBOSE];
                [openai summarize:query completion:^(NSString *summary) {
                    if (summary.length > 0) {
                        [logger log:[NSString stringWithFormat:@"Summary: %@",summary] level:LOGLEVEL_INFO];
                        [req setValue:summary forKey:@"summarizedMessage"];                                                
                    }
                    else
                        [req setValue:@"Summary response empty" forKey:@"summarizationError"];
                    %orig(req);
                }];
            } else {
                [req setValue:@"Summarized not Enabled" forKey:@"summarizationError"];
                [logger log:@"Skipping summarization" level:LOGLEVEL_INFO];
                %orig(req);
            }
        } @catch (NSException *e) { 
            [req setValue:@"AI Response Error" forKey:@"summarizationError"];
            NSLog(@"exception while fetching ai response : %@", e);
            %orig;
        }
    }
%end

%ctor {
    @try{    
        NSLog(@"init");
        prefsManager = [NSClassFromString(@"DigestPrefsManager") sharedInstance];
        BOOL enabled = [[prefsManager objectForKey:@"enabled"] boolValue];
        BOOL apiChecks = [[prefsManager objectForKey:@"apiChecks"] boolValue];
        BOOL sanityChecks = [[prefsManager objectForKey:@"sanityChecks"] boolValue];
        DigestLogger *logger = [NSClassFromString(@"DigestLogger") sharedInstance];
		//maybe register it only if enabled
        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)postDebugNotificationWithInfo, CFSTR("com.uncore.dig3st/push"), NULL, CFNotificationSuspensionBehaviorCoalesce);
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

            NSBundle *bundle = [[NSBundle alloc] initWithPath:ROOT_PATH_NS(@"/Library/PreferenceBundles/dig3st.bundle")];
            NSString *imgFile = [bundle pathForResource:@"arrow" ofType:@"png"];

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


