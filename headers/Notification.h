@interface NCNotificationRequest : NSObject
@property (nonatomic, assign) BOOL dig3st;
@property (nonatomic, retain) NSString * actualMessage;
@property (nonatomic, retain) NSString *sectionIdentifier;
@property (nonatomic, retain) NSObject *content;
@end

@interface NCNotificationShortLookView : UIView
@property (nonatomic,readonly) UIView * viewForPreview;
@end

@interface NCNotificationShortLookViewController : UIViewController
@property (nonatomic,readonly) NCNotificationShortLookView * viewForPreview;
@property (nonatomic,readonly) NCNotificationRequest  * notificationRequest;
@property (nonatomic, retain) UIImage *image;
@end

@interface NCNotificationSeamlessContentView : UIView
- (NCNotificationShortLookViewController *)_viewControllerForAncestor;
@end

@interface NCNotificationShortLookViewController (Digest)
@property (nonatomic, retain) id delegate;
@end
