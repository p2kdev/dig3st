@interface NCNotificationRequest : NSObject
@property (nonatomic, retain) NSString * summarizedMessage;
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
- (void)updateSummarizedText;
@end

@interface NCNotificationShortLookViewController (Digest)
@property (nonatomic, retain) id delegate;
@end
