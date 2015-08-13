//
//  YAUtils.m
//  Yaga
//
//  Created by valentinkovalski on 12/16/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import "YAUtils.h"
#import <CommonCrypto/CommonDigest.h>
#import "YAUser.h"
#import "YAAssetsCreator.h"
#import <Social/Social.h>
#import "YAGifCreationOperation.h"
#import "NSString+Hash.h"
#import "NBNumberFormat.h"
#import "YAServer.h"
#import "Constants.h"
#import <AFNetworking/AFHTTPRequestOperationManager.h>

#define HUMANITY_VISITED @"humanityVisited"
#define PRIVATE_GROUP_VISITED @"groupVisited"
#define HAS_RECORDED_PUBLIC_VIDEO @"publicRecorded"
#define HAS_RECORDED_PRIVATE_VIDEO @"privateRecorded"
#define HAS_RECORDED_UNGROUPED_VIDEO @"ungroupedRecorded"


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
    NBPhoneNumberUtil *phoneUtil = [NBPhoneNumberUtil new];
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

+ (void)showHudWithText:(NSString*)text{
    MBProgressHUD *hud = [[MBProgressHUD alloc] initWithWindow:[UIApplication sharedApplication].keyWindow];
    [[UIApplication sharedApplication].keyWindow addSubview:hud];
    hud.labelText = text;
    hud.mode = MBProgressHUDModeText;
    
    [hud showAnimated:YES whileExecutingBlock:^{
        [NSThread sleepForTimeInterval:1.0];
    }];
}

+ (MBProgressHUD*)showIndeterminateHudWithText:(NSString*)text {
    MBProgressHUD *hud = [[MBProgressHUD alloc] initWithWindow:[UIApplication sharedApplication].keyWindow];
    [[UIApplication sharedApplication].keyWindow addSubview:hud];
    hud.labelText = text;
    hud.mode = MBProgressHUDModeIndeterminate;
    [hud show:YES];
    return hud;
}

+ (BOOL)validatePhoneNumber:(NSString*)value {
    NBPhoneNumberUtil *phoneUtil = [NBPhoneNumberUtil new];
    
    NSError *error;
    NBPhoneNumber *myNumber = [phoneUtil parse:value
                                 defaultRegion:[YAUser currentUser].countryCode error:&error];
    
    if(error)
        return NO;
    
    
    [phoneUtil format:myNumber numberFormat:NBEPhoneNumberFormatE164 error:&error];
    
    if(error)
        return NO;
    
    
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

+ (void)copyGIFToClipboard:(YAVideo*)video {
    if (![video.highQualityGifFilename length]) {
        MBProgressHUD *hud = [[MBProgressHUD alloc] initWithWindow:[UIApplication sharedApplication].keyWindow];
        [[UIApplication sharedApplication].keyWindow addSubview:hud];
        hud.labelText = NSLocalizedString(@"Copying to clipboard", nil);
        [hud show:YES];
        YAGifCreationOperation *gifCreationOperation = [[YAGifCreationOperation alloc] initWithVideo:video quality:YAGifCreationHighQuality];
        gifCreationOperation.completionBlock = ^{
            dispatch_async(dispatch_get_main_queue(), ^{
                NSURL *gifURL = [NSURL fileURLWithPath:[[YAUtils cachesDirectory] stringByAppendingPathComponent:video.highQualityGifFilename]];
                
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
                    [pasteboard setData:[[NSData alloc] initWithContentsOfURL:gifURL] forPasteboardType:@"com.compuserve.gif"];
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [YAUtils showNotification:NSLocalizedString(@"GIF copied to clipboard", @"") type:YANotificationTypeMessage];
                    });
                });
            });
            dispatch_async(dispatch_get_main_queue(), ^{
                [hud hide:YES];
            });
        };
        [gifCreationOperation start];
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSURL *gifURL = [NSURL fileURLWithPath:[[YAUtils cachesDirectory] stringByAppendingPathComponent:video.highQualityGifFilename]];
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
                [pasteboard setData:[[NSData alloc] initWithContentsOfURL:gifURL] forPasteboardType:@"com.compuserve.gif"];
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    [YAUtils showNotification:NSLocalizedString(@"GIF copied to clipboard", @"") type:YANotificationTypeMessage];
                });
            });
        });
    }
}

+ (void)confirmDeleteVideo:(YAVideo*)video withConfirmationBlock:(confirmationBlock)block {
    NSString *alertMessageText = video.group ? [NSString stringWithFormat:NSLocalizedString(@"Are you sure you want to delete this video from '%@'?", @""), video.group.name] : NSLocalizedString(@"Are you sure you want to delete this video?", @"");
    
    NSString *alertMessage = NSLocalizedString(alertMessageText, nil);
    MSAlertController*confirmAlert = [MSAlertController
                                       alertControllerWithTitle:NSLocalizedString(@"Delete video", nil)
                                       message:alertMessage
                                       preferredStyle:MSAlertControllerStyleAlert];
    
    [confirmAlert addAction:[MSAlertAction
                             actionWithTitle:NSLocalizedString(@"Cancel", nil)
                             style:MSAlertActionStyleCancel
                             handler:^(MSAlertAction *action) {
                                 
                             }]];
    
    [confirmAlert addAction:[MSAlertAction
                             actionWithTitle:NSLocalizedString(@"Delete", nil)
                             style:MSAlertActionStyleDestructive
                             handler:^(MSAlertAction *action) {
                                 if(block)
                                     block();
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
    
//    if ([MSAlertController class]) {
//        
        MSAlertController *alertController =
        [MSAlertController alertControllerWithTitle:title
                                            message:message
                                     preferredStyle:MSAlertControllerStyleAlert];
        
        MSAlertAction* ok = [MSAlertAction actionWithTitle:okButtonTitle
                                                     style:MSAlertActionStyleDefault
                                                   handler:sharedUtils.acceptAction];
        [alertController addAction:ok];
        
        [vc   presentViewController:alertController
                           animated:YES
                         completion:nil];
//    }
//    else
//    {
//        UIAlertView *alertView =
//        [[UIAlertView alloc] initWithTitle:title
//                                   message:message
//                                  delegate:sharedUtils
//                         cancelButtonTitle:okButtonTitle
//                         otherButtonTitles:nil];
//        [alertView show];
//    }

}

+ (UIColor *)UIColorFromUsernameString:(NSString *)username {
    
    NSString *rgb = [[username md5] substringToIndex:6];
    
    return [self colorFromHexString:rgb];
}

+ (UIColor *)colorFromHexString:(NSString *)hexString {
    unsigned rgbValue = 0;
    NSScanner *scanner = [NSScanner scannerWithString:hexString];
    [scanner setScanLocation:1]; // bypass '#' character
    [scanner scanHexInt:&rgbValue];
    return [UIColor colorWithRed:((rgbValue & 0xFF0000) >> 16)/255.0 green:((rgbValue & 0xFF00) >> 8)/255.0 blue:(rgbValue & 0xFF)/255.0 alpha:1.0];
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

+ (NSString*)phoneNumberFromText:(NSString *)text numberFormat:(NBEPhoneNumberFormat)format {
    if([text length] > 6){
        NBPhoneNumberUtil *phoneUtil = [NBPhoneNumberUtil new];
    
        
        NSError *error = nil;
        NBPhoneNumber *myNumber = [phoneUtil parse:text
                                     defaultRegion:[YAUser currentUser].countryCode error:&error];
        
        if(error)
            return nil;
        
        error = nil;
        
        NSString *text;
        
        if(format == NBEPhoneNumberFormatNATIONAL) {
            NBNumberFormat *newNumFormat = [[NBNumberFormat alloc] init];
            [newNumFormat setPattern:@"(\\d{2})(\\d{3})(\\d{4})"];
            [newNumFormat setFormat:@"($1) $2-$3"];
            
            text = [phoneUtil formatByPattern:myNumber numberFormat:NBEPhoneNumberFormatNATIONAL userDefinedFormats:@[newNumFormat] error:&error];
        }
        else {
            text = [phoneUtil format:myNumber numberFormat:format error:&error];
        }
        
        if(!error && text.length)
            return text;
        
    }
    return nil;
}

+ (UIButton *)circleButtonWithImage:(NSString *)imageName diameter:(CGFloat)diameter center:(CGPoint)center {
    UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, diameter, diameter)];
    button.center = center;
    //    button.backgroundColor = [UIColor colorWithWhite:0.9f alpha:0.2f];
    //    button.layer.borderColor = [[UIColor whiteColor] CGColor];
    //    button.layer.borderWidth = 1.f;
    //    button.layer.cornerRadius = diameter/2.f;
    //    button.layer.masksToBounds = YES;
    [button setBackgroundImage:[UIImage imageNamed:imageName] forState:UIControlStateNormal];
    return button;
}

#pragma mark - Find Groups helper methods
+ (NSArray*)readableGroupsArrayFromResponse:(NSArray *)response {
    NSMutableArray *result = [NSMutableArray new];
    for (NSDictionary *groupData in response) {
        NSArray *members = groupData[YA_RESPONSE_MEMBERS];
        NSString *membersString = [self membersStringFromMembersArray:members];
        
        BOOL isPending = [self alreadyRequestedAccessToGroup:groupData];
        [result addObject:@{YA_RESPONSE_ID : groupData[YA_RESPONSE_ID], YA_RESPONSE_NAME : groupData[YA_RESPONSE_NAME], YA_RESPONSE_MEMBERS : membersString, YA_RESPONSE_PENDING_MEMBERS : [NSNumber numberWithBool:isPending]}];
    }
    return result;
}

+ (BOOL)alreadyRequestedAccessToGroup:(NSDictionary*)groupData {
    for (NSDictionary *pending_member in groupData[YA_RESPONSE_PENDING_MEMBERS]) {
        NSString *phoneNumber = pending_member[YA_RESPONSE_USER][YA_RESPONSE_MEMBER_PHONE];
        if([phoneNumber isEqualToString:[YAUser currentUser].phoneNumber])
            return YES;
    }
    return NO;
}

+ (NSString*)contactDisplayNameFromDictionary:(NSDictionary*)contactDictionary {
    NSString *phoneNumber = contactDictionary[YA_RESPONSE_USER][YA_RESPONSE_MEMBER_PHONE];
    NSString *name = contactDictionary[YA_RESPONSE_USER][YA_RESPONSE_NAME];
    name = [name isKindOfClass:[NSNull class]] ? @"" : name;
    
    if(!name.length) {
        if([[YAUser currentUser].phonebook objectForKey:phoneNumber]) {
            name = [[YAUser currentUser].phonebook objectForKey:phoneNumber][nCompositeName];
        }
        else {
            name = kDefaultUsername;
        }
    }
    return name;
}

+ (NSString*)membersStringFromMembersArray:(NSArray*)members {
    if(!members.count) {
        return NSLocalizedString(@"No members", @"");
    }
    
    NSString *results = @"";
    
    NSUInteger andMoreCount = 0;
    for(int i = 0; i < members.count; i++) {
        NSDictionary *contatDictionary = [members objectAtIndex:i];
        
        NSString *displayName = [self contactDisplayNameFromDictionary:contatDictionary];
        
        if([displayName isEqualToString:kDefaultUsername] || ! displayName)
            andMoreCount++;
        else {
            if(!results.length)
                results = displayName;
            else
                results = [results stringByAppendingFormat:@", %@", displayName];
        }
        if (i >= kMaxUsersShownInList) {
            andMoreCount += members.count - kMaxUsersShownInList;
            break;
        }
    }
    
    if(andMoreCount == 1) {
        if(results.length)
            results = [results stringByAppendingString:NSLocalizedString(@" and 1 more", @"")];
        else
            results = NSLocalizedString(@"ONE_UNKOWN_USER", @"");
    }
    else if(andMoreCount > 1) {
        if(!results.length) {
            results = [results stringByAppendingFormat:NSLocalizedString(@"N_UNKOWN_USERS_TEMPLATE", @""), andMoreCount];
        }
        else {
            results = [results stringByAppendingFormat:NSLocalizedString(@"OTHER_CONTACTS_TEMPLATE", @""), andMoreCount];
        }
        
    }
    return results;
}

#pragma mark - Tooltip and userdefaults helpers

+ (BOOL)hasVisitedGifGrid {
    return ![[[NSUserDefaults alloc] initWithSuiteName:@"group.com.yaga.yagaapp"] boolForKey:GIF_GRID_UNSEEN];
}

+ (void)setVisitedGifGrid {
    [[[NSUserDefaults alloc] initWithSuiteName:@"group.com.yaga.yagaapp"] setBool:NO forKey:GIF_GRID_UNSEEN];
    [[[NSUserDefaults alloc] initWithSuiteName:@"group.com.yaga.yagaapp"] synchronize];
}

+ (BOOL)hasVisitedHumanity {
    return [[[NSUserDefaults alloc] initWithSuiteName:@"group.com.yaga.yagaapp"] boolForKey:HUMANITY_VISITED];
}

+ (void)setVisitedHumanity {
    [[[NSUserDefaults alloc] initWithSuiteName:@"group.com.yaga.yagaapp"] setBool:YES forKey:HUMANITY_VISITED];
    [[[NSUserDefaults alloc] initWithSuiteName:@"group.com.yaga.yagaapp"] synchronize];
}

+ (BOOL)hasVisitedPrivateGroup {
    return [[[NSUserDefaults alloc] initWithSuiteName:@"group.com.yaga.yagaapp"] boolForKey:PRIVATE_GROUP_VISITED];
}

+ (void)setVisitedPrivateGroup {
    [[[NSUserDefaults alloc] initWithSuiteName:@"group.com.yaga.yagaapp"] setBool:YES forKey:PRIVATE_GROUP_VISITED];
    [[[NSUserDefaults alloc] initWithSuiteName:@"group.com.yaga.yagaapp"] synchronize];
}

+ (BOOL)hasRecordedPrivateVideo {
    return [[[NSUserDefaults alloc] initWithSuiteName:@"group.com.yaga.yagaapp"] boolForKey:HAS_RECORDED_PRIVATE_VIDEO];
}

+ (void)setRecordedPrivateVideo {
    [[[NSUserDefaults alloc] initWithSuiteName:@"group.com.yaga.yagaapp"] setBool:YES forKey:HAS_RECORDED_PRIVATE_VIDEO];
    [[[NSUserDefaults alloc] initWithSuiteName:@"group.com.yaga.yagaapp"] synchronize];
}

+ (BOOL)hasRecordedPublicVideo {
    return [[[NSUserDefaults alloc] initWithSuiteName:@"group.com.yaga.yagaapp"] boolForKey:HAS_RECORDED_PUBLIC_VIDEO];
}

+ (void)setRecordedPublicVideo {
    [[[NSUserDefaults alloc] initWithSuiteName:@"group.com.yaga.yagaapp"] setBool:YES forKey:HAS_RECORDED_PUBLIC_VIDEO];
    [[[NSUserDefaults alloc] initWithSuiteName:@"group.com.yaga.yagaapp"] synchronize];
}

+ (BOOL)hasRecordedUngroupedVideo {
    return [[[NSUserDefaults alloc] initWithSuiteName:@"group.com.yaga.yagaapp"] boolForKey:HAS_RECORDED_UNGROUPED_VIDEO];
}

+ (void)setRecordedUngroupedVideo {
    [[[NSUserDefaults alloc] initWithSuiteName:@"group.com.yaga.yagaapp"] setBool:YES forKey:HAS_RECORDED_UNGROUPED_VIDEO];
    [[[NSUserDefaults alloc] initWithSuiteName:@"group.com.yaga.yagaapp"] synchronize];
}

+ (void)randomQuoteWithCompletion:(stringCompletionBlock)completion {
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    [manager.requestSerializer setValue:@"ezBtcvH4HEmshaP4mANK8ZCvBA2ip1gpoHPjsnZ3p0o42PLQw1" forHTTPHeaderField:@"X-Mashape-Key"];
        [manager.requestSerializer setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    
    
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObject:@"text/html"];
//    NSDictionary *headers = @{@"X-Mashape-Key": @"ezBtcvH4HEmshaP4mANK8ZCvBA2ip1gpoHPjsnZ3p0o42PLQw1", @"Content-Type": @"application/x-www-form-urlencoded", @"Accept": @"application/json"};

    
    
    [manager POST:@"https://andruxnet-random-famous-quotes.p.mashape.com/cat=movies" parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSString *quote = [responseObject objectForKey:@"quote"];
        if(completion)
            completion(quote, nil);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if(completion)
            completion(nil, error);
    }];
}

+ (NSDictionary*)urlParametersFromString:(NSString*)urlString {
    NSArray *urlComponents = [urlString componentsSeparatedByString:@"&"];
    
    NSMutableDictionary *result = [NSMutableDictionary new];
    
    for (NSString *keyValuePair in urlComponents)
    {
        NSArray *pairComponents = [keyValuePair componentsSeparatedByString:@"="];
        NSString *key = [[pairComponents firstObject] stringByRemovingPercentEncoding];
        NSString *value = [[pairComponents lastObject] stringByRemovingPercentEncoding];
        
        [result setObject:value forKey:key];
    }
    return result;
}

@end
