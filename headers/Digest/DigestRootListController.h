#import <Preferences/PSListController.h>
#import <spawn.h>

@interface DigestRootListController : PSListController
// -(void)setupHeader;
- (void)setupFooterVersion;
- (void)resetSettings;
- (void)twitter;
- (void)setTweakEnabled:(id)value specifier:(PSSpecifier *)specifier;
- (void)respring;
@end
