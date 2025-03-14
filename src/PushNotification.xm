//https://github.com/aydenp/iNDT/blob/master/Tweak.mm
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "../headers/Digest/DigestPrefsManager.h"


@interface TLAlertConfiguration : NSObject
- (id)initWithType:(long long)arg1 ;
@end

@interface NCNotificationSound : NSObject
@end

@interface NCNotificationOptions : NSObject
@property (nonatomic,readonly) BOOL canTurnOnDisplay;
@property (nonatomic,readonly) BOOL canPlaySound;
@end

@interface NCNotificationRequest : NSObject
@property (nonatomic,copy,readonly) NSString * notificationIdentifier;
@property (nonatomic, retain, readonly) NSObject *content;
@property (nonatomic, readonly) NCNotificationOptions * options;
@property (nonatomic, readonly) NCNotificationSound *sound;
+(id)notificationRequestWithSectionId:(id)arg1 notificationId:(id)arg2 threadId:(id)arg3 title:(id)arg4 message:(id)arg5 timestamp:(id)arg6 destinations:(id)arg7;
@end

@interface NCNotificationDispatcher : NSObject
- (void)postNotificationWithRequest:(NCNotificationRequest *)request;
- (void)withdrawNotificationWithRequest:(NCNotificationRequest *)request;
@end

@interface SBNCNotificationDispatcher : NSObject
@property (nonatomic,retain) NCNotificationDispatcher *dispatcher;
@end

@interface SpringBoard : UIApplication
@property (nonatomic,readonly) SBNCNotificationDispatcher * notificationDispatcher;
- (void)_relaunchSpringBoardNow;
@end


@interface NSObject (SafeKVC)
- (void)safelySetValue:(id)value forKey:(NSString *)key;
- (id)safeValueForKey:(NSString *)key;
@end

@interface SBApplication : NSObject
- (NSString *)displayName;
- (NSString *)bundleIdentifier;
@end

@interface SBApplicationController : NSObject
+ (instancetype)sharedInstance;
- (SBApplication *)applicationWithBundleIdentifier:(NSString *)bundleIdentifier;
@end

@interface UIImage (Private)
+ (UIImage *)_applicationIconImageForBundleIdentifier:(NSString *)bundle format:(int)format scale:(CGFloat)scale;
@end

@implementation NSObject (SafeKVC)

- (void)safelySetValue:(id)value forKey:(NSString *)key {
    @try {
        [self setValue:value forKey:key];
    }
    @catch (NSException *exception) {}
}

- (id)safeValueForKey:(NSString *)key {
    @try {
        return [self valueForKey:key];
    }
    @catch (NSException *exception) {
        return nil;
    }
}
@end


extern "C" void postDebugNotificationWithInfo () {
    DigestPrefsManager *manager = [NSClassFromString(@"DigestPrefsManager") sharedInstance];
    NSDictionary *info = [manager objectForKey:@"testNotif"];
    NSString *bundleIdentifier = info[@"bundleIdentifier"];
    NSString *title = info[@"title"];
    NSString *content = info[@"content"];
    
    NCNotificationRequest *request = [%c(NCNotificationRequest) notificationRequestWithSectionId:bundleIdentifier
        notificationId:[NSString stringWithFormat:@"debug-notif-req-%@", [NSUUID UUID].UUIDString]
        threadId:[NSString stringWithFormat:@"debug-thread-req-%@", [NSUUID UUID].UUIDString]
        title:title
        message:content
        timestamp:[NSDate date]
        destinations:[NSSet setWithObjects:@"BulletinDestinationCoverSheet", @"BulletinDestinationBanner", @"BulletinDestinationNotificationCenter", @"BulletinDestinationLockScreen", nil]];
    
    SBApplication *app = [[%c(SBApplicationController) sharedInstance] applicationWithBundleIdentifier:bundleIdentifier];
    if (app) {
        [request.content safelySetValue:app.displayName forKey:@"header"];
        UIImage *iconImage = [UIImage _applicationIconImageForBundleIdentifier:app.bundleIdentifier format:5 scale:[UIScreen mainScreen].scale];
        if (iconImage) {
            [request.content safelySetValue:iconImage forKey:@"_icon"];
            [request.content safelySetValue:@[iconImage] forKey:@"_icons"];
        }
    } else {
        [request.content safelySetValue:bundleIdentifier forKey:@"header"];
    }
    
    [request.content safelySetValue:[NSDate date] forKey:@"_date"];
    [request.options safelySetValue:@(1) forKey:@"_canPlaySound"];
    [request.options safelySetValue:@(1) forKey:@"_canTurnOnDisplay"];
    [request.options safelySetValue:@(1) forKey:@"_alertsWhenLocked"];
    
    [request safelySetValue:[[%c(NCNotificationSound) alloc] init] forKey:@"_sound"];
    [request.sound safelySetValue:@(2) forKey:@"_soundType"];
    [request.sound safelySetValue:[(TLAlertConfiguration *)[%c(TLAlertConfiguration) alloc] initWithType:17] forKey:@"_alertConfiguration"];
    NSLog(@"Notiification dispatcher %@", ((SpringBoard *)[UIApplication sharedApplication]));
    [((SpringBoard *)[UIApplication sharedApplication]).notificationDispatcher.dispatcher postNotificationWithRequest:request];
}
