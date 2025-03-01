// https://github.com/NoisyFlake/Velvet2/blob/master/preferences/Velvet2AppSelectController.m
#import "../headers/HeadersPreferences.h"

@interface DigestEndpointsSelectController : PSListItemsController
@end

@implementation DigestEndpointsSelectController : PSListItemsController

- (NSArray *)specifiers {
    if (!_specifiers) {
        NSMutableArray *mutableSpecifiers = [NSMutableArray new];

        PSSpecifier *specifier = [PSSpecifier preferenceSpecifierNamed:@"Log Level"
                                    target:self
                                    set:@selector(setPreferenceValue:specifier:)
                                    get:@selector(readPreferenceValue:)
                                    detail:NSClassFromString(@"PSListItemsController")
                                    cell:PSListItemCell
                                    edit:Nil];

        [specifier setProperty:@"logLevel" forKey:@"key"];
        // [specifier setProperty:@"com.nablac0d3.SSLKillSwitchSettings" forKey:@"defaults"];
        [specifier setProperty:@10 forKey:@"default"];
        // [specifier setProperty:@[@"Verbose /n wtf", @"Info /n wtf", @"Warning /n wtf", @"Disable Output /n wtf"] forKey:@"validTitles"];
        // [specifier setProperty:@[@10, @6, @4, @1] forKey:@"validValues"];
        PSSpecifier *specifier2 = [PSSpecifier preferenceSpecifierNamed:@"WTF"
                                    target:self
                                    set:@selector(setPreferenceValue:specifier:)
                                    get:@selector(readPreferenceValue:)
                                    detail:NSClassFromString(@"PSListItemsController")
                                    cell:PSListItemCell
                                    edit:Nil];

        [specifier setProperty:@"logLevel" forKey:@"key"];
        PSSpecifier *specifier3 = [PSSpecifier preferenceSpecifierNamed:@"HELLO WROLD"
                                    target:self
                                    set:@selector(setPreferenceValue:specifier:)
                                    get:@selector(readPreferenceValue:)
                                    detail:NSClassFromString(@"PSListItemsController")
                                    cell:PSListItemCell
                                    edit:Nil];

        [specifier setProperty:@"logLevel" forKey:@"key"];


        [mutableSpecifiers addObject:specifier];
		[mutableSpecifiers addObject:specifier2];
		[mutableSpecifiers addObject:specifier3];

        _specifiers = mutableSpecifiers;
    }

    return _specifiers;
}

- (void)setPreferenceValue:(id)value specifier:(PSSpecifier *)specifier {
    NSString *key = [specifier propertyForKey:@"key"];
    NSLog(@"Setting value for key: %@", key);
    [super setPreferenceValue:value specifier:specifier];
}

- (id)readPreferenceValue:(PSSpecifier *)specifier {
    NSString *key = [specifier propertyForKey:@"key"];
    NSLog(@"Reading value for key: %@", key);
    return [super readPreferenceValue:specifier];
}

@end
