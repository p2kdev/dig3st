#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
void Alert(NSString *_title, NSString *message,id self) {
    @try{
        NSString *title = [NSString stringWithFormat:@"Digest: %@", _title];

        UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
        [alert addAction:okAction];

        if (!self) {
            #pragma clang diagnostic push
            #pragma clang diagnostic ignored "-Wdeprecated-declarations"
            return [[[UIApplication sharedApplication] keyWindow].rootViewController presentViewController:alert animated:YES completion:nil];
            #pragma clang diagnostic pop
        }

        [(UIViewController *)self presentViewController:alert animated:YES completion:nil];
    }@catch(NSException *e){
        NSLog(@"error while trying to alert: %@", e);
    }
}
