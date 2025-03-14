#import <Foundation/Foundation.h>
#import <Preferences/PSSpecifier.h>
#import <AudioToolbox/AudioServices.h>
#import <rootless.h>

#import "Log.h"
#import "Alert.h"
#import "CheckApiKey.h"
#import "Preferences.h"
#import "CoreServices.h"
#import "UIImage+Private.h"
#import "UIView+Private.h"
#import "UIColor+Private.h"
#import "Digest/DigestAppSelectController.h"
#import "Digest/DigestButton.h"
#import "Digest/DigestPrefsManager.h"
#import "Digest/DigestRootListController.h"
#import "Digest/DigestSettingsController.h"
#import "Digest/DigestSubtitleLinkCell.h"
#import "Digest/DigestEndpointSettingsController.h"
#import "Digest/DigestEndpointsController.h"
#import "Digest/DigestTestingController.h"
#import "Digest/DigestSwitch.h"
#import "Digest/UIColor+Digest.h"
#import "Digest/DigestEditTextCell.h"

#define kDigestColor [UIColor colorWithRed:1 green:0 blue:0 alpha:1.0]