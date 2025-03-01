// https://github.com/NoisyFlake/Velvet2/blob/master/preferences/Velvet2SettingsController.m
#import "../headers/HeadersPreferences.h"

@implementation DigestEndPointSettingsController

- (instancetype)init {
    self = [super init];
    if (self) {
        self.manager = [NSClassFromString(@"DigestPrefsManager") sharedInstance];
    }
    return self;
}

- (NSArray *)specifiers {
	if (!_specifiers) {
	    _specifiers = [self visibleSpecifiersFromPlist:@"Endpoint"];
		if (self.titleKey) {
			self.title = self.titleKey;
		}
	}

	return _specifiers;
}

-(void)showController:(id)controller {
	return [super showController:controller]; 
}

-(void)checkApiKey:(id)value specifier:(PSSpecifier *)specifier {
	[self setPreferenceValue:value specifier:specifier];

	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Check key" style:UIBarButtonItemStylePlain target:self action:@selector(checkApiKeyAction)];
}

-(void)viewDidLayoutSubviews {
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Save" style:UIBarButtonItemStylePlain target:self action:@selector(save)];
	[super viewDidLayoutSubviews];
}
-(void)save {
	@try {
		BOOL isOkayToSave = YES;
		NSMutableDictionary *endpoint = [NSMutableDictionary new];
		for (PSSpecifier *specifier in self.specifiers) {
			//skip group cell
			if ([[specifier.properties valueForKey:@"cell"] isEqual:@"PSGroupCell"] ) continue;
			
			NSLog(@"specifier: %@", specifier.properties);
			PSEditableTableCell *cell = [specifier.properties valueForKey:@"cellObject"];
			UITextField *textField = [cell valueForKey:@"textField"]; 
			if (textField) {
				NSString *inputText = textField.text;
				if (!inputText || inputText.length == 0) {
					isOkayToSave = NO;
					break;
				}

				endpoint[specifier.properties[@"key"]] = inputText;
				NSLog(@"TextField Text: %@", inputText);
			} else {
				NSLog(@"Failed to access textField.");
			}
		}
		if (!isOkayToSave) return Alert(@"Error", @"Please fill in all fields.",self);
		//generate a uuid
		DigestPrefsManager *manager = [NSClassFromString(@"DigestPrefsManager") sharedInstance];
		if (self.endpoint) {
			endpoint[@"uuid"] = self.endpoint[@"uuid"];
			//find the endpoint and update it
			NSMutableArray *mutableEndpoints = [[manager objectForKey:@"endpoints"] mutableCopy];
			for (int i = 0; i < mutableEndpoints.count; i++) {
				if ([mutableEndpoints[i][@"uuid"] isEqualToString:endpoint[@"uuid"]]) {
					[mutableEndpoints replaceObjectAtIndex:i withObject:endpoint];
					[manager setObject:mutableEndpoints forKey:@"endpoints"];
					break;
				}
			}
			[[NSNotificationCenter defaultCenter] postNotificationName:@"com.uncore.dig3st/endpointUpdate" object:nil];
		    [self.navigationController popViewControllerAnimated:YES];
			return;
		}
		NSString *uuid = [[NSUUID UUID] UUIDString];
		endpoint[@"uuid"] = uuid;
        NSMutableArray *endpoints = [[manager objectForKey:@"endpoints"] mutableCopy];

		//push to dictionary
		[endpoints addObject:endpoint];
		[manager setObject:endpoints forKey:@"endpoints"];
		[[NSNotificationCenter defaultCenter] postNotificationName:@"com.uncore.dig3st/endpointUpdate" object:nil];

		NSLog(@"endpoint: %@", endpoint);
    	[self.navigationController popViewControllerAnimated:YES];
	}@catch(NSException *e) {
		NSLog(@"Error: %@", e);
		Alert(@"Error", @"An error occurred while saving.",self);
	}
}

-(void)checkApiKeyAction {
	DigestPrefsManager *manager = [NSClassFromString(@"DigestPrefsManager") sharedInstance];
	
    NSString *apiKey = [manager objectForKey:@"apiKey"];
    checkApiKeyImp(apiKey, ^(BOOL valid) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (valid) {
				Alert(@"API Key", @"API Key is valid.",self);
			} else {
				Alert(@"API Key", @"API Key is invalid.",self);
            }
        });
    });
}

-(id)readPreferenceValue:(PSSpecifier*)specifier {
	if (!self.endpoint) return nil;

	return self.endpoint[specifier.properties[@"key"]];
}

- (NSMutableArray*)visibleSpecifiersFromPlist:(NSString*)plist {
	return [self loadSpecifiersFromPlistName:plist target:self];
}
@end