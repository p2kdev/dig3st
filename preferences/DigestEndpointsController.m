#import "../headers/HeadersPreferences.h"

@implementation DigestEndpointsController
- (instancetype)init {
    self = [super init];
    if (self) {
        self.manager = [NSClassFromString(@"DigestPrefsManager") sharedInstance];
        self.logger = [NSClassFromString(@"DigestLogger") sharedInstance];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(update) name:@"com.uncore.dig3st/endpointUpdate" object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"com.uncore.dig3st/endpointUpdate" object:nil];
}

- (NSArray *)specifiers {
    if (!_specifiers) {
        _specifiers = [self getSpecifiers];
    }

    return _specifiers;
}

-(void)update {
    [self reloadSpecifiers];
}

-(NSMutableArray*)getSpecifiers{
    NSMutableArray *mutableSpecifiers = [NSMutableArray new];
    DigestPrefsManager *manager = self.manager;
    NSMutableArray *endpoints = [manager objectForKey:@"endpoints"];
    for (NSDictionary *endpoint in endpoints) {
        NSString *name = [endpoint objectForKey:@"model"];
        NSString *label = [endpoint objectForKey:@"label"];

        PSSpecifier* specifier = [PSSpecifier preferenceSpecifierNamed:[NSString  stringWithFormat:@"%@/%@",label,name] 
                                target:self
                                set:@selector(setPreferenceValue:specifier:)
                                get:@selector(readPreferenceValue:)
                                detail:Nil
                                cell:PSListItemCell
                                edit:Nil];

        [specifier setProperty:Nil forKey:@"default"];
        [specifier setProperty:name forKey:@"titleKey"];
        [specifier setProperty:endpoint forKey:@"endpoint"];
        [specifier setProperty:NSStringFromSelector(@selector(removedSpecifier:)) forKey:PSDeletionActionKey];
        [mutableSpecifiers addObject:specifier];
        specifier.detailControllerClass = NSClassFromString(@"DigestEndpointSettingsController");
    }
    
    [self.logger log:[NSString stringWithFormat:@"getSpecifiers: %@",mutableSpecifiers] level:LOGLEVEL_VERBOSE];

    return mutableSpecifiers;
}

-(void)setPreferenceValue:(id)value specifier:(PSSpecifier *)specifier {
    [self.logger log:[NSString stringWithFormat:@"setPreferenceValue: %@",value] level:LOGLEVEL_VERBOSE];
    [super setPreferenceValue:value specifier:specifier];
}

-(id)readPreferenceValue:(PSSpecifier *)specifier {
    [self.logger log:[NSString stringWithFormat:@"readPreferenceValue: %@",specifier.properties] level:LOGLEVEL_VERBOSE];
    return [specifier valueForKey:@"endpoint"][@"uuid"];
}

-(void)removedSpecifier:(PSSpecifier*)specifier{
    @try {
        [self.logger log:[NSString stringWithFormat:@"removedSpecifier: %@",specifier.properties] level:LOGLEVEL_VERBOSE];
        NSString *uuid = specifier.properties[@"endpoint"][@"uuid"];
        DigestPrefsManager *manager = self.manager;
        //find the endpoint and update it
        [self.logger log:[NSString stringWithFormat:@"updating endpoint with uuid: %@",uuid] level:LOGLEVEL_VERBOSE];
        NSMutableArray *mutableEndpoints = [[manager objectForKey:@"endpoints"] mutableCopy];

        [mutableEndpoints enumerateObjectsUsingBlock:^(NSDictionary *mutEndpoint, NSUInteger idx, BOOL *stop) {
            if ([mutEndpoint[@"uuid"] isEqualToString:uuid]) {
                *stop = YES;
                [mutableEndpoints removeObjectAtIndex:idx];
                [self.logger log:[NSString stringWithFormat:@"removed endpoint: %@",mutEndpoint] level:LOGLEVEL_VERBOSE];
                [manager setObject:mutableEndpoints forKey:@"endpoints"];
            }
        }];

        [[NSNotificationCenter defaultCenter] postNotificationName:@"com.uncore.dig3st/endpointUpdate" object:nil];
    }@catch(NSException *e) {
        NSLog(@"Error: %@", e);
        Alert(@"Error", @"An error occurred while saving.",self);
    }
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *uuid = [self.specifiers[indexPath.row + 1] properties][@"endpoint"][@"uuid"];

    NSString *activeEndpoint = [self.manager objectForKey:@"activeEndpoint"];
    BOOL isDeletable = ![uuid isEqualToString:activeEndpoint];
    [self.logger log:[NSString stringWithFormat:@"isDeletable: %d uuid: %@ activeEndpoint: %@",isDeletable,uuid,activeEndpoint] level:LOGLEVEL_VERBOSE];
    if (!isDeletable) return UITableViewCellEditingStyleNone;
	return UITableViewCellEditingStyleDelete;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    PSSpecifier *specifier = [self specifierAtIndexPath:indexPath];
    DigestPrefsManager *manager = self.manager;
    NSDictionary *endpoint = [[specifier properties] objectForKey:@"endpoint"];
    NSString *uuid = [endpoint objectForKey:@"uuid"];
    NSString *activeEndpoint = [manager objectForKey:@"activeEndpoint"];
    NSString *url = [endpoint objectForKey:@"url"];

    // Set the textLabel to the endpoint label
    cell.textLabel.text = [NSString stringWithFormat:@"%@/%@", [endpoint objectForKey:@"label"], [endpoint objectForKey:@"model"]];
    
    // Set the detailTextLabel to the URL
    cell.detailTextLabel.text = url;

    // Set the accessory type to checkmark if the endpoint is active
     if ([uuid isEqualToString:activeEndpoint]) {
        UIImage *checkmarkImage = [UIImage systemImageNamed:@"checkmark.circle.fill"];
        UIImageView *checkmarkImageView = [[UIImageView alloc] initWithImage:[checkmarkImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
        checkmarkImageView.tintColor = kDigestColor;
        cell.accessoryView = checkmarkImageView;
    } else {
        cell.accessoryView = nil;
    }

    // Add long press gesture recognizer
    UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    [cell addGestureRecognizer:longPressGesture];

    // Add tap gesture recognizer
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    [cell addGestureRecognizer:tapGesture];

    return cell;
}

 -(void)viewDidLoad {
    [super viewDidLoad];

    // Create and configure the footer label
    UILabel *footerLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    footerLabel.text = @"Long press on an endpoint to change its settings.";
    footerLabel.textAlignment = NSTextAlignmentCenter;
    footerLabel.textColor = [UIColor grayColor];
    footerLabel.numberOfLines = 0;
    footerLabel.font = [UIFont systemFontOfSize:11];

    // Adjust the size of the label to fit the text
    [footerLabel sizeToFit];

    // Set the footer label as the table footer view
    self.table.tableFooterView = footerLabel;
}


- (void)handleLongPress:(UILongPressGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        CGPoint point = [gestureRecognizer locationInView:self.table];
        NSIndexPath *indexPath = [self.table indexPathForRowAtPoint:point];
        if (indexPath) {
            PSSpecifier *specifier = [self specifierAtIndexPath:indexPath];
            Class detailControllerClass = specifier.detailControllerClass;
            if (detailControllerClass) {
                id detailController = [[detailControllerClass alloc] init];
                ((DigestEndpointSettingsController *)detailController).titleKey = specifier.properties[@"titleKey"];
                ((DigestEndpointSettingsController *)detailController).endpoint = specifier.properties[@"endpoint"];
                [self.navigationController pushViewController:detailController animated:YES];
            }
        }
    }
}

- (void)handleTap:(UITapGestureRecognizer *)gestureRecognizer {
    if (self.table.isEditing) return;
    if (gestureRecognizer.state == UIGestureRecognizerStateEnded) {
        CGPoint point = [gestureRecognizer locationInView:self.table];
        NSIndexPath *indexPath = [self.table indexPathForRowAtPoint:point];
        if (indexPath) {
            DigestPrefsManager *manager = self.manager;
            PSSpecifier *specifier = [self specifierAtIndexPath:indexPath];
            NSDictionary *endpoint = [[specifier properties] objectForKey:@"endpoint"];

            NSString *uuid = [endpoint objectForKey:@"uuid"];
            [self.logger log:[NSString stringWithFormat:@"Activating endpoint: %@",endpoint] level:LOGLEVEL_INFO];
            // Update the active endpoint
            [manager setObject:uuid forKey:@"activeEndpoint"];
            CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), (CFStringRef)@"com.uncore.dig3st/preferences.changed", NULL, NULL, true);
            // Reload the table view to update the checkmarks
            [self.table reloadData];
        }
    }
}
 
-(void)showController:(id)controller {
    [self.logger log:[NSString stringWithFormat:@"showController: %@",controller] level:LOGLEVEL_VERBOSE];
	if ([controller isKindOfClass:NSClassFromString(@"DigestEndpointSettingsController")]) {
        NSIndexPath *selectedPath = self.table.indexPathForSelectedRow;
        PSTableCell *selectedCell = [self.table cellForRowAtIndexPath:selectedPath];
        PSSpecifier *specifier = selectedCell.specifier;

        ((DigestEndpointSettingsController *)controller).titleKey = specifier.properties[@"titleKey"];
        ((DigestEndpointSettingsController *)controller).endpoint = specifier.properties[@"endpoint"];
	}

	return [super showController:controller]; 
}
@end
