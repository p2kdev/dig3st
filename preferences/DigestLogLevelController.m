#import "../headers/HeadersPreferences.h"

@interface DigestLogLevelController : PSListController
@property (nonatomic, strong) DigestPrefsManager *manager;
@property (nonatomic, strong) DigestLogger *logger;
@end

@implementation DigestLogLevelController
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
    NSDictionary *logLevels = @{
        @"Verbose": @10,
        @"Info": @6,
        @"Warning": @4,
        @"Disable Output": @10
    };

    for (NSString *key in logLevels) {
        NSNumber *value = logLevels[key];
        PSSpecifier* specifier = [PSSpecifier preferenceSpecifierNamed:key
                                target:self
                                set:@selector(setPreferenceValue:specifier:)
                                get:@selector(readPreferenceValue:)
                                detail:Nil
                                cell:PSListItemCell
                                edit:Nil];

        [specifier setProperty:value forKey:@"val"];
		[specifier setProperty:key forKey:@"label"];
        [mutableSpecifiers addObject:specifier];
    }
    
    return mutableSpecifiers;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }

    DigestPrefsManager *manager = self.manager;
    NSInteger logLevel = [[manager objectForKey:@"logLevel"] integerValue];
    //+1 because of group cell
    NSInteger normalizedIndex = indexPath.row + 1;
    //get cell properties
    NSDictionary *cellProperties = [self.specifiers[normalizedIndex] properties];
    BOOL enabled = [cellProperties[@"val"] isEqualToNumber:@(logLevel)];

    cell.textLabel.text = cellProperties[@"label"];

    // Set the accessory type to checkmark if the endpoint is active
     if (enabled) {
        UIImage *checkmarkImage = [UIImage systemImageNamed:@"checkmark.circle.fill"];
        UIImageView *checkmarkImageView = [[UIImageView alloc] initWithImage:[checkmarkImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
        checkmarkImageView.tintColor = kDigestColor;
        cell.accessoryView = checkmarkImageView;
    } else {
        cell.accessoryView = nil;
    }

    // Add tap gesture recognizer
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    [cell addGestureRecognizer:tapGesture];

    return cell;
}

-(void)viewDidLoad {
    [super viewDidLoad];

    // Create and configure the footer label
    UILabel *footerLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    footerLabel.text = @"Check out my youtube video if you need help with debugging";
    footerLabel.textAlignment = NSTextAlignmentCenter;
    footerLabel.textColor = [UIColor grayColor];
    footerLabel.numberOfLines = 0;
    footerLabel.font = [UIFont systemFontOfSize:11];

    // Adjust the size of the label to fit the text
    [footerLabel sizeToFit];

    // Set the footer label as the table footer view
    self.table.tableFooterView = footerLabel;
}

- (void)handleTap:(UITapGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer.state == UIGestureRecognizerStateEnded) {
        UITableViewCell *cell = (UITableViewCell *)gestureRecognizer.view;
        NSIndexPath *indexPath = [self.table indexPathForCell:cell];
        if (indexPath) {
            PSSpecifier *specifier = self.specifiers[indexPath.row];
            NSNumber *logLevel = [specifier propertyForKey:@"val"];
            [self.logger log:[NSString stringWithFormat:@"Setting log level to %@", logLevel] level:LOGLEVEL_INFO];
            // [self.logger setLogLevel:logLevel.integerValue];
            DigestPrefsManager *manager = self.manager;
            [manager setObject:logLevel forKey:@"logLevel"];
            // CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), (CFStringRef)@"com.uncore.dig3st/preferences.changed", NULL, NULL, true);
            [self.table reloadData];
        }
    }
}
@end
