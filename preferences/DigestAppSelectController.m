// https://github.com/NoisyFlake/Velvet2/blob/master/preferences/Velvet2AppSelectController.m
#import "../headers/HeadersPreferences.h"

@implementation DigestAppSelectController

- (NSArray *)specifiers {
	if (!_specifiers) {
        NSMutableArray *mutableSpecifiers = [NSMutableArray new];
		
        LSApplicationWorkspace *workspace = [NSClassFromString(@"LSApplicationWorkspace") defaultWorkspace];
		NSArray *apps = [workspace allInstalledApplications];

        for (LSApplicationProxy *app in apps) {
            if ([app.applicationType isEqual:@"User"] || ([app.applicationType isEqual:@"System"] && ![app.appTags containsObject:@"hidden"] && !app.launchProhibited && !app.placeholder && !app.removedSystemApp)) {

				if ([app.applicationIdentifier isEqual:@"com.apple.webapp"]) continue;

				PSSpecifier* specifier = [PSSpecifier preferenceSpecifierNamed:app.localizedName
										target:self
										set:@selector(setPreferenceValue:specifier:)
										get:@selector(readPreferenceValue:)
										detail:Nil
										cell:PSSwitchCell
										edit:Nil];

				[specifier setProperty:app.applicationIdentifier forKey:@"digestKey"];
				// [specifier setProperty:app.applicationIdentifier forKey:@"key"];
				[specifier setProperty:app.localizedName forKey:@"label"];
				// [specifier setProperty:isOkToSummarize(app.applicationIdentifier) forKey:@"default"];
				[specifier setProperty:NSClassFromString(@"DigestSwitch") forKey:@"cellClass"];
				[mutableSpecifiers addObject:specifier];
				
				UIImage *icon = [UIImage _applicationIconImageForBundleIdentifier:app.applicationIdentifier format:0 scale:UIScreen.mainScreen.scale];

				CGImageRef cgIcon = icon.CGImage;
				CGFloat scale = (CGImageGetWidth(cgIcon) + CGImageGetHeight(cgIcon)) / (CGFloat)(29 + 29);
				UIImage *iconResized = [UIImage imageWithCGImage:cgIcon scale:scale orientation:0];

				if (iconResized) {
					[specifier setProperty:iconResized forKey:@"iconImage"];
				}
				
            }
        }
        [mutableSpecifiers sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES selector:@selector(caseInsensitiveCompare:)]]];
 
        _specifiers = mutableSpecifiers;
	}

	return _specifiers;
}
- (void)setPreferenceValue:(id)value specifier:(PSSpecifier *)specifier {
	DigestPrefsManager *manager = [NSClassFromString(@"DigestPrefsManager") sharedInstance];
	[manager setObject:value forKey:specifier.properties[@"digestKey"]];
	// [self.manager save];
	// [self.manager notify:@"com.uncore.dig3st/update"];
}
- (id)readPreferenceValue:(PSSpecifier *)specifier {
	DigestPrefsManager *manager = [NSClassFromString(@"DigestPrefsManager") sharedInstance];
	NSString *value = [manager objectForKey:specifier.properties[@"digestKey"]];
	if (value == nil) {
		value = @"1";
	}
	return value;
}
@end
