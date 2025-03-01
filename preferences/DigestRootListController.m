// https://github.com/NoisyFlake/Velvet2/blob/master/preferences/Velvet2RootListController.m
#import "../headers/HeadersPreferences.h"

@implementation DigestRootListController

- (NSArray *)specifiers {
	if (!_specifiers) {
		_specifiers = [self loadSpecifiersFromPlistName:@"Root" target:self];
	}

	return _specifiers;
}

-(void)viewDidLayoutSubviews {
	[super viewDidLayoutSubviews];

	[self setupHeader];
	[self setupFooterVersion];
}

-(void)setupHeader {
	UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 140)];
	NSString *imageToLoad;

	if (UITraitCollection.currentTraitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
		imageToLoad = @"d3-header-dark.png";
	} else {
		imageToLoad = @"d3-header.png";
	}

    UIImage *image = [UIImage imageNamed:imageToLoad inBundle:[NSBundle bundleForClass:NSClassFromString(@"DigestRootListController")] compatibleWithTraitCollection:nil];
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 30 - 4, self.view.bounds.size.width, 80)];
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    [imageView setImage:image];
 
    [header addSubview:imageView];
	self.table.tableHeaderView = header;
}

-(void)setupFooterVersion {
	NSString *firstLine = [NSString stringWithFormat:@"dig3st %@ v%@", PACKAGE_SCHEME,PACKAGE_VERSION];
	BOOL isDebugBuild = [THEOS_SCHEMA isEqualToString:@"DEFAULT DEBUG"];

	if (isDebugBuild) {
		firstLine = [firstLine stringByAppendingString:@" (Debug)"];
	}
	NSMutableAttributedString *fullFooter =  [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@\n UI forked from Velvet2\n made by uncore", firstLine]];

	[fullFooter beginEditing];
	[fullFooter addAttribute:NSFontAttributeName value:[UIFont boldSystemFontOfSize:18] range:NSMakeRange(0, [firstLine length])];
	[fullFooter endEditing];
	
	UILabel *footerLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 100)];
	footerLabel.font = [UIFont systemFontOfSize:13];
	footerLabel.textColor = UIColor.systemGrayColor;
	footerLabel.numberOfLines = 3;
	footerLabel.attributedText = fullFooter;
	footerLabel.textAlignment = NSTextAlignmentCenter;
	self.table.tableFooterView = footerLabel;
}

-(void)resetSettings {
 	[[NSUserDefaults standardUserDefaults] removePersistentDomainForName:@"com.uncore.dig3st"];
	NSString *prefsPath = @"/var/mobile/Library/Preferences/com.uncore.dig3st.plist";

    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    if ([fileManager fileExistsAtPath:prefsPath]) {
        NSError *error = nil;
        [fileManager removeItemAtPath:prefsPath error:&error];
        
        if (error) {
            NSLog(@"Error deleting preferences: %@", error.localizedDescription);
        } else {
            NSLog(@"Preferences reset successfully.");
        }
    } else {
        NSLog(@"Preferences file does not exist.");
    }
	[self reload];
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Respring" style:UIBarButtonItemStylePlain target:self action:@selector(respring)];

	CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), (CFStringRef)@"com.uncore.dig3st/preferences.changed", NULL, NULL, YES);
}

-(void)twitter {
	NSURL *tweetbot = [NSURL URLWithString:@"tweetbot://NoisyFlake/user_profile/NoisyFlake"];
	NSURL *twitterrific = [NSURL URLWithString:@"twitterrific://profile?screen_name=NoisyFlake"];
	NSURL *twitter = [NSURL URLWithString:@"twitter://user?screen_name=NoisyFlake"];
	NSURL *web = [NSURL URLWithString:@"http://www.twitter.com/NoisyFlake"];
	
	if ([[UIApplication sharedApplication] canOpenURL:tweetbot]) {
        [[UIApplication sharedApplication] openURL:tweetbot options:@{} completionHandler:nil];
    } else if ([[UIApplication sharedApplication] canOpenURL:twitterrific]) {
        [[UIApplication sharedApplication] openURL:twitterrific options:@{} completionHandler:nil];
    } else if ([[UIApplication sharedApplication] canOpenURL:twitter]) {
        [[UIApplication sharedApplication] openURL:twitter options:@{} completionHandler:nil];
    } else {
        [[UIApplication sharedApplication] openURL:web options:@{} completionHandler:nil];
    }
}

-(void)github {
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.github.com/NoisyFlake"] options:@{} completionHandler:nil];
}

-(void)yt {
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.youtube.com/NoisyFlake"] options:@{} completionHandler:nil];
}

-(void)setTweakEnabled:(id)value specifier:(PSSpecifier *)specifier {
	[self setPreferenceValue:value specifier:specifier];

	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Respring" style:UIBarButtonItemStylePlain target:self action:@selector(respring)];
}

-(void)donate {
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://uncore.me/donate"] options:@{} completionHandler:nil];
}

-(void)respring {
	pid_t pid;
	const char* args[] = {"sbreload", NULL};
	posix_spawn(&pid, ROOT_PATH("/usr/bin/sbreload"), NULL, NULL, (char* const*)args, NULL);
}
@end
