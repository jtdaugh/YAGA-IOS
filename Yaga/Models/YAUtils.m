//
//  YAUtils.m
//  Yaga
//
//  Created by valentinkovalski on 12/16/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import "YAUtils.h"
#import "NBPhoneNumberUtil.h"
#import <CommonCrypto/CommonDigest.h>
#import "YAUser.h"
#import "YAAssetsCreator.h"
#import <Social/Social.h>
#import "MBProgressHUD.h"
#import "YAGifCreationOperation.h"

@interface YAUtils ()
@property (copy) void (^acceptAction)();
@property (copy) void (^dismissAction)();
@end

@implementation YAUtils

+ (YAUtils*)instance {
    static dispatch_once_t _singletonPredicate;
    static YAUtils *_singleton = nil;
    
    dispatch_once(&_singletonPredicate, ^{
        _singleton = [[super allocWithZone:nil] init];
    });
    
    return _singleton;
}

+ (id)allocWithZone:(NSZone *)zone {
    return [self instance];
}

+ (NSString *)readableNumberFromString:(NSString*)input {
    NBPhoneNumberUtil *phoneUtil = [NBPhoneNumberUtil sharedInstance];
    NSError *aError = nil;
    NBPhoneNumber *myNumber = [phoneUtil parse:input defaultRegion:@"US" error:&aError];
    NSString *num = [phoneUtil format:myNumber numberFormat:NBEPhoneNumberFormatNATIONAL error:&aError];
    return num;
}

+ (UIColor*)inverseColor:(UIColor*)color {
    CGFloat r,g,b,a;
    [color getRed:&r green:&g blue:&b alpha:&a];
    return [UIColor colorWithRed:1.-r green:1.-g blue:1.-b alpha:a];
}

+ (NSString*)cachesDirectory {
    NSArray *cachePaths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    return cachePaths[0];
}

+ (NSString *)uniqueId {
    NSString *input = [[NSUUID UUID] UUIDString];
    const char *cstr = [input cStringUsingEncoding:NSUTF8StringEncoding];
    NSData *data = [NSData dataWithBytes:cstr length:input.length];
    uint8_t digest[CC_SHA256_DIGEST_LENGTH];
    
    // This is an iOS5-specific method.
    // It takes in the data, how much data, and then output format, which in this case is an int array.
    CC_SHA256(data.bytes, (CC_LONG)data.length, digest);
    
    NSMutableString* output = [NSMutableString stringWithCapacity:CC_SHA256_DIGEST_LENGTH * 2];
    
    // Parse through the CC_SHA256 results (stored inside of digest[]).
    for(int i = 0; i < CC_SHA256_DIGEST_LENGTH; i++) {
        [output appendFormat:@"%02x", digest[i]];
    }
    
    return output;
}

+ (NSURL*)urlFromFileName:(NSString*)fileName {
    if(!fileName.length)
        return nil;
    
    NSString *path = [[YAUtils cachesDirectory] stringByAppendingPathComponent:fileName];
    return [NSURL fileURLWithPath:path];
}

+ (void)showNotification:(NSString*)message type:(YANotificationType)type {
    [YANotificationView showMessage:message viewType:type];
}

+ (BOOL)validatePhoneNumber:(NSString*)value error:(NSError **)error {
    NBPhoneNumberUtil *phoneUtil = [NBPhoneNumberUtil sharedInstance];
    
    NBPhoneNumber *myNumber = [phoneUtil parse:value
                                 defaultRegion:[YAUser currentUser].countryCode error:error];
    
    if(error && *error)
        return NO;
    //
    //
    //    [phoneUtil format:myNumber numberFormat:NBEPhoneNumberFormatE164 error:error];
    //
    //    if(*error)
    //        return NO;
    
    
    return [phoneUtil isValidNumber:myNumber];
}

+ (UIView*)createBackgroundViewWithFrame:(CGRect)frame alpha:(CGFloat)alpha {
    UIView *bkgView = [[UIView alloc] initWithFrame:frame];
    bkgView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    bkgView.backgroundColor = [PRIMARY_COLOR colorWithAlphaComponent:alpha];
    return bkgView;
}


+ (UIImage *)imageWithColor:(UIColor *)color {
    CGRect rect = CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

#pragma mark - Video actions
+ (void)showVideoOptionsForVideo:(YAVideo*)video {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Choose action", @"") message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    if([SLComposeViewController isAvailableForServiceType:SLServiceTypeFacebook]) {
        [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Share on Facebook", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [YAUtils shareVideoOnFacebook:video];
        }]];
    }
    if([SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter]) {
        [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Share on Twitter", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [YAUtils shareVideoOnTwitter:video];
        }]];
    }
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Save to Camera Roll", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [YAUtils saveVideoToCameraRoll:video];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Copy Gif", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        if (![video.highQualityGifFilename length]) {
            YAGifCreationOperation *gifCreationOperation = [[YAGifCreationOperation alloc] initWithVideo:video quality:YAGifCreationHighQuality];
            gifCreationOperation.completionBlock = ^{
                [YAUtils copyVideoToClipboard:video];
            };
            [gifCreationOperation start];
        } else {
            [YAUtils copyVideoToClipboard:video];
        }
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Delete", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [YAUtils deleteVideo:video];
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"") style:UIAlertActionStyleCancel handler:nil]];
    
    UIViewController *vc = [UIApplication sharedApplication].keyWindow.rootViewController;
    vc = [vc presentedViewController] ? [vc presentedViewController] : vc;
    
    [vc presentViewController:alert animated:YES completion:nil];
}

+ (void)saveVideoToCameraRoll:(YAVideo*)video {
    
    MBProgressHUD *hud = [[MBProgressHUD alloc] initWithWindow:[UIApplication sharedApplication].keyWindow];
    [[UIApplication sharedApplication].keyWindow addSubview:hud];
    hud.labelText = NSLocalizedString(@"Saving", nil);
    [hud show:YES];
    
    [[YAAssetsCreator sharedCreator] addBumberToVideoAtURLAndSaveToCameraRoll:[YAUtils urlFromFileName:video.movFilename] completion:^(NSError *error) {
        
        [hud hide:YES];
        
        if (error) {
            [YAUtils showNotification:NSLocalizedString(@"Can't save video", @"") type:YANotificationTypeError];
        }
        else {
            [YAUtils showNotification:NSLocalizedString(@"Video saved to the camera roll", @"") type:YANotificationTypeMessage];
        }
    }];
}

+ (void)copyVideoToClipboard:(YAVideo*)video {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSURL *gifURL = [NSURL fileURLWithPath:[[YAUtils cachesDirectory] stringByAppendingPathComponent:video.highQualityGifFilename]];
        
        MBProgressHUD *hud = [[MBProgressHUD alloc] initWithWindow:[UIApplication sharedApplication].keyWindow];
        [[UIApplication sharedApplication].keyWindow addSubview:hud];
        hud.labelText = NSLocalizedString(@"Saving", nil);
        [hud show:YES];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
            [pasteboard setData:[[NSData alloc] initWithContentsOfURL:gifURL] forPasteboardType:@"com.compuserve.gif"];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [hud hide:YES];
                [YAUtils showNotification:NSLocalizedString(@"Copied to clipboard", @"") type:YANotificationTypeMessage];
            });
        });
    });
}

+ (void)deleteVideo:(YAVideo*)video {
    NSString *alertMessageText = [NSString stringWithFormat:NSLocalizedString(@"Are you sure you want to delete this video from '%@'?", @""), [YAUser currentUser].currentGroup.name];
    
    NSString *alertMessage = NSLocalizedString(alertMessageText, nil);
    UIAlertController *confirmAlert = [UIAlertController
                                       alertControllerWithTitle:NSLocalizedString(@"Delete video", nil)
                                       message:alertMessage
                                       preferredStyle:UIAlertControllerStyleAlert];
    
    [confirmAlert addAction:[UIAlertAction
                             actionWithTitle:NSLocalizedString(@"Cancel", nil)
                             style:UIAlertActionStyleCancel
                             handler:^(UIAlertAction *action) {
                                 
                             }]];
    
    [confirmAlert addAction:[UIAlertAction
                             actionWithTitle:NSLocalizedString(@"Delete", nil)
                             style:UIAlertActionStyleDestructive
                             handler:^(UIAlertAction *action) {
                                 [video removeFromCurrentGroup];
                             }]];
    
    UIViewController *vc = [UIApplication sharedApplication].keyWindow.rootViewController;
    vc = [vc presentedViewController] ? [vc presentedViewController] : vc;
    
    [vc presentViewController:confirmAlert animated:YES completion:nil];
}

+ (void)shareVideoOnFacebook:(YAVideo*)video {
    SLComposeViewController *controller = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeFacebook];
    
    [controller setInitialText:NSLocalizedString(@"Check out my new Yaga video", nil)];
    [controller addURL:[NSURL URLWithString:video.url]];
    [controller addImage:[UIImage imageWithContentsOfFile:[YAUtils urlFromFileName:video.jpgFilename].path]];
    
    UIViewController *vc = [UIApplication sharedApplication].keyWindow.rootViewController;
    vc = [vc presentedViewController] ? [vc presentedViewController] : vc;
    
    [vc presentViewController:controller animated:YES completion:Nil];
}

+ (void)shareVideoOnTwitter:(YAVideo*)video {
    SLComposeViewController *tweetSheet = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeTwitter];
    [tweetSheet setInitialText:NSLocalizedString(@"Check out my new Yaga video", nil)];
    [tweetSheet addURL:[NSURL URLWithString:video.url]];
    [tweetSheet addImage:[UIImage imageWithContentsOfFile:[YAUtils urlFromFileName:video.jpgFilename].path]];
    
    UIViewController *vc = [UIApplication sharedApplication].keyWindow.rootViewController;
    vc = [vc presentedViewController] ? [vc presentedViewController] : vc;
    
    [vc presentViewController:tweetSheet animated:YES completion:nil];
}

+ (void)showAlertViewWithTitle:(NSString*)title
                       message:(NSString*)message
             forViewController:(UIViewController*)vc
                 accepthButton:(NSString*)okButtonTitle
                  cancelButton:(NSString*)cancelButtonTitle
                  acceptAction:(void (^)())acceptAction
                  cancelAction:(void (^)())cancelAction
{
    
    YAUtils *sharedUtils = [self instance];
    sharedUtils.acceptAction = acceptAction;
    sharedUtils.dismissAction = cancelAction;
    
    if ([UIAlertController class]) {
        
        UIAlertController *alertController =
        [UIAlertController alertControllerWithTitle:title
                                            message:message
                                     preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* ok = [UIAlertAction actionWithTitle:okButtonTitle
                                                     style:UIAlertActionStyleDefault
                                                   handler:sharedUtils.acceptAction];
        [alertController addAction:ok];
        
        [vc   presentViewController:alertController
                           animated:YES
                         completion:nil];
    }
    else
    {
        UIAlertView *alertView =
        [[UIAlertView alloc] initWithTitle:title
                                   message:message
                                  delegate:sharedUtils
                         cancelButtonTitle:okButtonTitle
                         otherButtonTitles:nil];
        [alertView show];
    }

}

#pragma mark - UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    switch (buttonIndex) {
        case 0:
        {
            self.acceptAction();
        }
            break;
        case 1:
        {
            self.dismissAction();
        }
            break;
            
        default:
            break;
    }
}

@end
