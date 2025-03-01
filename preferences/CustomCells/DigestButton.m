// https://github.com/NoisyFlake/Velvet2/blob/master/preferences/CustomCells/Velvet2Button.m
#import "../../headers/HeadersPreferences.h"

@implementation DigestButton
- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier specifier:(PSSpecifier *)specifier {
	self = [super initWithStyle:style reuseIdentifier:reuseIdentifier specifier:specifier];

	if (self) {
		if (specifier.properties[@"systemIcon"]) {
            UIImageSymbolConfiguration *config = [UIImageSymbolConfiguration configurationWithFont:[UIFont systemFontOfSize:25]];
            UIImage *image = [UIImage systemImageNamed:specifier.properties[@"systemIcon"] withConfiguration:config];
            [specifier setProperty:image forKey:@"iconImage"];

            self.imageView.tintColor = kDigestColor;
        }
	}

	return self;
}

-(void)layoutSubviews {
    [super layoutSubviews];

    self.textLabel.textColor = UIColor.labelColor;
    self.textLabel.highlightedTextColor = UIColor.labelColor;

    if (self.specifier.properties[@"systemIcon"]) {
        self.textLabel.frame = CGRectMake(60, self.textLabel.frame.origin.y, self.textLabel.frame.size.width, self.textLabel.frame.size.height);
    }
}
@end