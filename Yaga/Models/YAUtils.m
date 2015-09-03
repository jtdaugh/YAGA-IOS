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
#import "YABubbleView.h"

#define FORCED_FOLLOWING_COMPLETED @"forceFollowComplete"
#define STREAM_VISITED @"streamVisited"
#define PUBLIC_GROUP_VISITED @"publicGroupVisited"
#define PRIVATE_GROUP_VISITED @"privateGroupVisited"
#define HAS_CREATED_HOSTED_GROUP @"createdPublicGroup"
#define HAS_CREATED_PRIVATE_GROUP @"createdPrivateGroup"
#define PENDING_APPROVAL_SEEN @"pendingApprovalSeen"
#define SEEN_CAMERA @"seenCamera"
#define TAPPED_RECORD @"tappedRecord"
#define SEEN_TRIM_VIEW @"seenTrimView"


@interface YAUtils ()
@property (copy) void (^acceptAction)();
@property (copy) void (^dismissAction)();

@end

static NSMutableDictionary *bubblesDictionary;

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
        [result addObject:@{YA_RESPONSE_ID : groupData[YA_RESPONSE_ID], YA_RESPONSE_PRIVATE : groupData[YA_RESPONSE_PRIVATE], YA_RESPONSE_FEATURED : groupData[YA_RESPONSE_FEATURED], YA_RESPONSE_FOLLOWER_COUNT : groupData[YA_RESPONSE_FOLLOWER_COUNT], YA_RESPONSE_NAME : groupData[YA_RESPONSE_NAME], YA_RESPONSE_MEMBERS : membersString, YA_RESPONSE_PENDING_MEMBERS : [NSNumber numberWithBool:isPending]}];
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

+ (BOOL)defaultsBoolForKey:(NSString *)key {
    return [[NSUserDefaults standardUserDefaults] boolForKey:key];
}

+ (void)setDefaultsForKey:(NSString *)key {
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:key];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (BOOL)hasSeenFollowingScreen {
    return [self defaultsBoolForKey:FORCED_FOLLOWING_COMPLETED];
}
+ (void)setSeenFollowingScreen {
    [self setDefaultsForKey:FORCED_FOLLOWING_COMPLETED];
}

+ (BOOL)hasVisitedStream {
    return [self defaultsBoolForKey:STREAM_VISITED];
}
+ (void)setVisitedStream {
    [self setDefaultsForKey:STREAM_VISITED];
}

+ (BOOL)hasVisitedPublicGroup {
    return [self defaultsBoolForKey:PUBLIC_GROUP_VISITED];
}
+ (void)setVisitedPublicGroup {
    [self setDefaultsForKey:PUBLIC_GROUP_VISITED];
}

+ (BOOL)hasCreatedPublicGroup {
    return [self defaultsBoolForKey:HAS_CREATED_HOSTED_GROUP];
}
+ (void)setCreatedPublicGroup {
    [self setDefaultsForKey:HAS_CREATED_HOSTED_GROUP];
}

+ (BOOL)hasVisitedPrivateGroup {
    return [self defaultsBoolForKey:PRIVATE_GROUP_VISITED];
}
+ (void)setVisitedPrivateGroup {
    [self setDefaultsForKey:PRIVATE_GROUP_VISITED];
}

+ (BOOL)hasSeenPendingApprovalMessage {
    return [self defaultsBoolForKey:PENDING_APPROVAL_SEEN];
}
+ (void)setSeenPendingApprovalMessage {
    [self setDefaultsForKey:PENDING_APPROVAL_SEEN];
}

+ (BOOL)hasTappedRecord {
    return [self defaultsBoolForKey:TAPPED_RECORD];
}
+ (void)setTappedRecord {
    [self setDefaultsForKey:TAPPED_RECORD];
}

+ (BOOL)hasSeenCamera {
    return [self defaultsBoolForKey:SEEN_CAMERA];
}
+ (void)setSeenCamera {
    [self setDefaultsForKey:SEEN_CAMERA];
}

+ (BOOL)hasSeenTrimView {
    return [self defaultsBoolForKey:SEEN_TRIM_VIEW];
}

+ (void)setSeenTrimView {
    [self setDefaultsForKey:SEEN_TRIM_VIEW];
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

+ (void)showBubbleWithText:(NSString*)text bubbleWidth:(CGFloat)width forView:(UIView*)view arrowDirection:(BOOL)arrowUp{
    UIFont *bubbleFont = [UIFont fontWithName:BIG_FONT size:14];
    CGRect boundingRect = [text boundingRectWithSize:CGSizeMake(width - 20, NSIntegerMax)
                                             options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                                          attributes:@{NSFontAttributeName:bubbleFont} context:nil];
    
    CGRect viewFrame = view.frame;
    
    CGFloat x = viewFrame.origin.x + viewFrame.size.width/2 - width/2;
    if(x < 0)
        x = 5;
    if(x + width + 5 >= VIEW_WIDTH)
        x = VIEW_WIDTH - width - 5;
    
    CGFloat y = arrowUp ? viewFrame.origin.y + viewFrame.size.height + 5 : viewFrame.origin.y - boundingRect.size.height - 25;
    
    YABubbleView *bubbleView = [[YABubbleView alloc] initWithFrame:CGRectMake(x, y, width, boundingRect.size.height + 20)];
    bubbleView.arrowXPosition = view.center.x - x;
    bubbleView.arrowDirectionUp = arrowUp;
    bubbleView.backgroundColor = [UIColor clearColor];
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(10, arrowUp ? 15 : 5, boundingRect.size.width, boundingRect.size.height)];
    label.font = bubbleFont;
    label.textColor = [UIColor whiteColor];
    label.numberOfLines = 0;
    label.text = text;
    label.textAlignment = NSTextAlignmentCenter;
    [bubbleView addSubview:label];
    bubbleView.alpha = 0;
    [view.superview addSubview:bubbleView];
    
    [UIView animateWithDuration:2.0 delay:0.0f usingSpringWithDamping:0.4f initialSpringVelocity:1.0f options:UIViewAnimationOptionCurveEaseIn animations:^{
        bubbleView.alpha = 1;
    } completion:^(BOOL finished) {
        
    }];
    if(!bubblesDictionary)
        bubblesDictionary = [NSMutableDictionary new];
    
    [bubblesDictionary setObject:bubbleView forKey:text];
    
}

+ (void)showBubbleWithText:(NSString*)text bubbleWidth:(CGFloat)width forView:(UIView*)view {
    UIFont *bubbleFont = [UIFont fontWithName:BIG_FONT size:14];
    CGRect boundingRect = [text boundingRectWithSize:CGSizeMake(width - 20, NSIntegerMax)
                                             options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                                          attributes:@{NSFontAttributeName:bubbleFont} context:nil];
    
    CGRect viewFrame = view.frame;
    BOOL arrowUp = viewFrame.origin.y + viewFrame.size.height + boundingRect.size.height + 20 < view.superview.frame.size.height;
    
    [self showBubbleWithText:text bubbleWidth:width forView:view arrowDirection:arrowUp];
}

+ (void)showBubbleWithTextOnce:(NSString*)text bubbleWidth:(CGFloat)width arrowDirectionUp:(BOOL)arrowUp forView:(UIView*)view {
    NSMutableSet *popupTextsShown = [NSMutableSet setWithArray:[[NSUserDefaults standardUserDefaults] objectForKey:kPopupsShown]];
    if(![popupTextsShown containsObject:text]) {
        [popupTextsShown addObject:text];
        [[NSUserDefaults standardUserDefaults] setObject:[popupTextsShown allObjects] forKey:kPopupsShown];
    }
}

+ (void)hideBubbleWithText:(NSString*)text {
    if(!text)
        return;
    
    UIView *bubbleView = [bubblesDictionary objectForKey:text];
    if (!bubbleView) return;
    [UIView animateWithDuration:.8 delay:0.0f usingSpringWithDamping:0.4f initialSpringVelocity:3.0f options:UIViewAnimationOptionCurveEaseIn animations:^{
        bubbleView.alpha = 0;
    } completion:^(BOOL finished) {
        [bubbleView removeFromSuperview];
        [bubblesDictionary removeObjectForKey:text];
    }];
}

@end
