// https://github.com/NoisyFlake/Velvet2/blob/master/preferences/Velvet2AppSelectController.m
#import "../headers/HeadersPreferences.h"

@interface DigestEndpointsSelectController : PSListItemsController
@end

@implementation DigestEndpointsSelectController : PSListItemsController

- (NSArray *)specifiers {
    if (!_specifiers) {
        NSMutableArray *mutableSpecifiers = [NSMutableArray new];
        DigestPrefsManager *manager = [NSClassFromString(@"DigestPrefsManager") sharedInstance];
        NSMutableArray *endpoints = [manager objectForKey:@"endpoints"];
        // NSString *activeEndpoint = [manager objectForKey:@"activeEndpoint"];
        for (int i = 0; i < endpoints.count; i++) {
            NSString *name = [endpoints[i] objectForKey:@"model"];
            // NSString *uuid = [endpoints[i] objectForKey:@"uuid"];
            PSSpecifier *specifier = [PSSpecifier preferenceSpecifierNamed:name
                                        target:self
                                        set:@selector(setPreferenceValue:specifier:)
                                        get:@selector(readPreferenceValue:)
                                        detail:NSClassFromString(@"PSListItemsController")
                                        cell:PSListItemCell
                                        edit:Nil];

            // [specifier setProperty:uuid forKey:@"uuid"];
            [specifier setProperty:@"activeEndpoint" forKey:@"key"];
            [mutableSpecifiers addObject:specifier];
        }
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
    Alert(@"readPreferenceValue", @"readPreferenceValue",self);
        NSLog(@"Reading value for key: ");
    @try {
        NSString *uuid = [specifier propertyForKey:@"uuid"];
        NSLog(@"Reading value for key: %@ ; specifier %@", uuid, specifier);
        // DigestPrefsManager *manager = [NSClassFromString(@"DigestPrefsManager") sharedInstance];
            // NSMutableArray *endpoints = [manager objectForKey:@"endpoints"];
            // NSString *activeEndpoint = [manager objectForKey:@"activeEndpoint"];
        // NSLog(@"Reading value for key: %@", key);
        return uuid;
    } @catch (NSException *exception) {
        NSLog(@"Reading value for %@", exception);

        return nil;
    }
}

@end
