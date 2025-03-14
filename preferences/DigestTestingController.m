// https://github.com/NoisyFlake/Velvet2/blob/master/preferences/Velvet2SettingsController.m
#import "../headers/HeadersPreferences.h"


@implementation DigestTestingController

- (instancetype)init {
    self = [super init];
    if (self) {
        self.manager = [NSClassFromString(@"DigestPrefsManager") sharedInstance];
		self.logger =[NSClassFromString(@"DigestLogger") sharedInstance];
    }
    return self;
}

- (NSArray *)specifiers {
	if (!_specifiers) {
	    _specifiers = [self visibleSpecifiersFromPlist:@"Testing"];
	}

	return _specifiers;
}

-(void)showController:(id)controller {
	return [super showController:controller]; 
}

-(void)viewDidLayoutSubviews {
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Push" style:UIBarButtonItemStylePlain target:self action:@selector(push)];
	[super viewDidLayoutSubviews];
}
-(void)push {
	@try {
		BOOL isOkToPush = YES;
		NSMutableDictionary *not = [NSMutableDictionary new];
		for (PSSpecifier *specifier in self.specifiers) {
			//skip group cell
			if ([[specifier.properties valueForKey:@"cell"] isEqual:@"PSGroupCell"] ) continue;
			
			[self.logger log:[NSString stringWithFormat:@"specifier: %@", specifier.properties] level:LOGLEVEL_VERBOSE];
			PSEditableTableCell *cell = [specifier.properties valueForKey:@"cellObject"];
			UITextField *textField = [cell valueForKey:@"textField"]; 
			if (textField) {
				NSString *inputText = textField.text;
				if (!inputText || inputText.length == 0) {
					isOkToPush = NO;
					break;
				}

				not[specifier.properties[@"key"]] = inputText;
				[self.logger log:[NSString stringWithFormat:@"TextField Text: %@", inputText] level:LOGLEVEL_VERBOSE];
			} else {
				NSLog(@"Failed to access textField.");
			}
		}
		if (!isOkToPush) return Alert(@"Error", @"Please fill in all fields.",self);
			[self.manager setObject:not forKey:@"testNotif"];
			[self.logger log:[NSString stringWithFormat:@"Pushing notification: %@", not] level:LOGLEVEL_INFO];
			CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), (__bridge CFStringRef)@"com.uncore.dig3st/push", NULL, NULL, YES);
	}	@catch(NSException *e) {
		NSLog(@"Error: %@", e);
		Alert(@"Error", @"An error occurred.",self);
	}
}

-(id)readPreferenceValue:(PSSpecifier*)specifier {
	NSDictionary *dict = [self.manager objectForKey:@"testNotif"];
	return dict[specifier.properties[@"key"]];
}

- (NSMutableArray*)visibleSpecifiersFromPlist:(NSString*)plist {
	return [self loadSpecifiersFromPlistName:plist target:self];
}
@end