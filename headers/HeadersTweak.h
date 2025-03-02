#import <UIKit/UIKit.h>
#import <UserNotifications/UserNotifications.h>
#import <Foundation/Foundation.h>

#import "Log.h"
#import "Alert.h"
#import "CheckApiKey.h"
#import "Digest/UIColor+Digest.h"
#import "Digest/DigestPrefsManager.h"
#import "Digest/DigestLogger.h"
#import "Summarize.h"
#import "Notification.h"
#import "OpenAI.h"
#import "Config.h"
#import "ChatQuery.h"
#import <rootless.h>

#define SYSTEM_VERSION_LESS_THAN(v) ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)