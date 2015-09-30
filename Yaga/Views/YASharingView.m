//
//  YAShareViewController.m
//  Yaga
//
//  Created by valentinkovalski on 6/12/15.
//  Copyright (c) 2015 Raj Vir. All rights reserved.
//

#import "YASharingView.h"
#import "YACenterImageButton.h"

#import "YAGroup.h"
#import "YAUser.h"

#import "YACrosspostCell.h"
#import "YAServer.h"
#import "YAAssetsCreator.h"
#import "UIImage+Color.h"

#import "YASwipingViewController.h"

#import "FBSDKShareKit.h"

#import "SocialVideoHelper.h"

#import <AssetsLibrary/AssetsLibrary.h>
#import "YAAssetsCreator.h"
#import "YaPostToGroupsViewController.h"

#define SHARING_VIEW_PROPORTION 0.55
#define kNewGroupCellId @"postToNewGroupCell"
#define kCrosspostCellId @"crossPostCell"

@interface YASharingView () <FBSDKSharingDelegate, MFMessageComposeViewControllerDelegate, UIActionSheetDelegate>

@property (nonatomic, strong) YAVideo *video;

@property (strong, nonatomic) UILabel *crossPostPrompt;
@property (strong, nonatomic) UIButton *externalShareButton;
@property (strong, nonatomic) UIButton *saveButton;
@property (strong, nonatomic) UIButton *crosspostButton;
@property (strong, nonatomic) UIButton *collapseCrosspostButton;
@property (strong, nonatomic) MBProgressHUD *hud;

@property (nonatomic, copy) void (^completionBlock)(ACAccount *account);
@property (nonatomic, strong) NSArray *accounts;
@property (strong, nonatomic) UIView *shareBar;
@end

@implementation YASharingView

- (id)initWithFrame:(CGRect)frame video:(YAVideo *)video {
    
    self = [super initWithFrame:frame];
    if (self) {
        _video = video;

        CGFloat copyHeight = 60;
        CGFloat shareBarHeight = 80;
        
        BOOL myVideo = [self.video.creator isEqualToString:[[YAUser currentUser] username]];
        if (!myVideo) copyHeight = 0;

        CGFloat gradientHeight = shareBarHeight + copyHeight;

        UIView *bgGradient = [[UIView alloc] initWithFrame:CGRectMake(0, VIEW_HEIGHT - gradientHeight, VIEW_WIDTH, gradientHeight)];
        CAGradientLayer *gradient = [CAGradientLayer layer];
        gradient.frame = bgGradient.bounds;
        ;
        gradient.colors = [NSArray arrayWithObjects:
                           (id)[[UIColor colorWithWhite:0.0 alpha:.0] CGColor],
                           (id)[[UIColor colorWithWhite:0.0 alpha:.6] CGColor],
                           (id)[[UIColor colorWithWhite:0.0 alpha:.7] CGColor],
                           (id)[[UIColor colorWithWhite:0.0 alpha:.7] CGColor],
                           (id)[[UIColor colorWithWhite:0.0 alpha:.8] CGColor],
                           nil];
        
        [bgGradient.layer insertSublayer:gradient atIndex:0];
        [self addSubview:bgGradient];

        
        self.shareBar = [[UIView alloc] initWithFrame:CGRectMake(0, frame.size.height - shareBarHeight - copyHeight, VIEW_WIDTH, shareBarHeight)];
        [self addSubview:self.shareBar];
        
        CGFloat count = 4;
        CGFloat buttonWidth = VIEW_WIDTH/count - VIEW_WIDTH/(count*2 + 1);
        
        NSArray *files = @[@"Message", @"FB", @"Twitter", @"CameraRoll"];
        
        UIView *tapOutView = [[UIView alloc] initWithFrame:CGRectMake(0, 60, VIEW_WIDTH, VIEW_HEIGHT - shareBarHeight - 60)];
        tapOutView.backgroundColor = [UIColor clearColor];
        [self addSubview:tapOutView];
        self.crosspostTapOutRecognizer = [[UITapGestureRecognizer alloc] init];
        [tapOutView addGestureRecognizer:self.crosspostTapOutRecognizer];
        
        for(float i = 0.0f; i < [files count]; i++){
            UIButton *externalShareButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, buttonWidth, buttonWidth)];
            CGFloat centerRatio = (i*2+1)/(count*2);
            externalShareButton.center = CGPointMake(centerRatio*VIEW_WIDTH, shareBarHeight/2);
            //        [externalShareButton setBackgroundColor:[UIColor greenColor]];
            externalShareButton.tag = (int)i;
            [externalShareButton setImage:[UIImage imageNamed:files[(int)i]] forState:UIControlStateNormal];
            [externalShareButton addTarget:self action:@selector(externalShareAction:) forControlEvents:UIControlEventTouchUpInside];
            [self.shareBar addSubview:externalShareButton];
        }
        
        self.crosspostButton = [[UIButton alloc] initWithFrame:CGRectMake(0, frame.size.height - copyHeight , VIEW_WIDTH, copyHeight)];
        self.crosspostButton.backgroundColor = PRIMARY_COLOR;
        self.crosspostButton.titleLabel.font = [UIFont fontWithName:BOLD_FONT size:22];
        self.crosspostButton.titleLabel.textColor = [UIColor whiteColor];
        [self.crosspostButton setContentHorizontalAlignment:UIControlContentHorizontalAlignmentLeft];
        [self.crosspostButton setImage:[UIImage imageNamed:@"Disclosure"] forState:UIControlStateNormal];
        self.crosspostButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
        [self.crosspostButton setContentEdgeInsets:UIEdgeInsetsZero];
        [self.crosspostButton setImageEdgeInsets:UIEdgeInsetsMake(-4, self.crosspostButton.frame.size.width - 20 - 30, -4, 20)];
        [self.crosspostButton setTitleEdgeInsets:UIEdgeInsetsMake(0, 8, 0, 48 - 16)];
        [self.crosspostButton addTarget:self action:@selector(crosspostPressed) forControlEvents:UIControlEventTouchUpInside];
        [self.crosspostButton setTitle:@"Copy to other chats" forState:UIControlStateNormal];
        if (myVideo) {
            [self addSubview:self.crosspostButton];
        }
        
        CGFloat buttonRadius = 22.f, padding = 4.f;
        self.collapseCrosspostButton = [YAUtils circleButtonWithImage:@"X" diameter:buttonRadius*2 center:CGPointMake(VIEW_WIDTH - buttonRadius - padding, padding + buttonRadius)];
        [self.collapseCrosspostButton addTarget:self action:@selector(collapseCrosspost) forControlEvents:UIControlEventTouchUpInside];
        self.collapseCrosspostButton.alpha = 0.0;
        [self addSubview:self.collapseCrosspostButton];
        
    }
    return self;
}

- (void)crosspostPressed {
    YAPostToGroupsViewController *vc = [YAPostToGroupsViewController new];
    vc.video = self.video;
    [((UIViewController *)self.page.presentingVC).navigationController pushViewController:vc animated:YES];
}

- (void)setTopButtonsHidden:(BOOL)hidden animated:(BOOL)animated {
    [UIView animateWithDuration:animated ? 0.2 : 0.0 animations:^{
        self.collapseCrosspostButton.alpha = hidden ? 0.0 : 1.0;
    }];
}

- (void)collapseCrosspost {
    if (self.video.group) {
        [self.page collapseShareSheet];
    } else {
        [self.page.presentingVC dismissAnimated];
    }
}

- (void)externalShareAction:(UIButton *)sender {
    NSLog(@"%li", (long)sender.tag);
    
    NSURL *url = [YAUtils urlFromFileName:self.video.mp4Filename];
    self.hud = [MBProgressHUD showHUDAddedTo:self.page animated:YES];
    self.hud.mode = MBProgressHUDModeIndeterminate;
    self.hud.labelText = @"Exporting";
    
    [[YAAssetsCreator sharedCreator] addBumberToVideoAtURL:url completion:^(NSURL *filePath, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.hud hide:NO];
            
            if (error) {
                DLog(@"error");
            } else {
                [self shareVideoWithActionType:sender.tag fileUrl:filePath];
            }
        });
        
    }];

}

- (void)shareVideoWithActionType:(NSUInteger)type fileUrl:(NSURL *)fileUrl {
    switch (type) {
        case 0: {
            //iMessage
            
            NSString *caption = ![self.video.caption isEqualToString:@""] ? self.video.caption : @"Yaga";
            NSString *detailText = [NSString stringWithFormat:@"%@ — http://getyaga.com", caption];

            MFMessageComposeViewController *messageController = [[MFMessageComposeViewController alloc] init];
            messageController.messageComposeDelegate = self;
            [messageController setBody:detailText];
            [messageController setSubject:@"Yaga"];
            [messageController addAttachmentURL:fileUrl withAlternateFilename:@"GET_YAGA.mov"];
            //            [messageController setSubject:@"Yaga"];
            
            // Present message view controller on screen
            [(UIViewController *) self.page.presentingVC presentViewController:messageController animated:YES completion:^{
                //                [self.hud hide:NO];
                [self.hud hide:YES];
//                [self showSuccessHud];
            }];
            
            break;
        } case 1: {
            
            ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
            ALAssetsLibraryWriteVideoCompletionBlock videoWriteCompletionBlock =
            ^(NSURL *newURL, NSError *error) {
                if (error) {
                    [self.hud hide:YES];
                } else {
                    FBSDKShareVideo *video = [[FBSDKShareVideo alloc] init];
                    [video setVideoURL:newURL];
                    
                    FBSDKShareVideoContent *content = [[FBSDKShareVideoContent alloc] init];
                    content.video = video;
                    
                    [FBSDKShareDialog showFromViewController:(UIViewController *) self.page.presentingVC
                                                 withContent:content
                                                    delegate:self];
                    [self.hud hide:YES];


                }
            };
            
            if ([library videoAtPathIsCompatibleWithSavedPhotosAlbum:fileUrl])
            {
                [library writeVideoAtPathToSavedPhotosAlbum:fileUrl
                                            completionBlock:videoWriteCompletionBlock];
            }
            
//            dialog.delegate = self;
//            [dialog show];
//            [self showSuccessHud];
            
            break;
        } case 2: {
            // Twitter
            [self.hud hide:YES];

            [self getTwitterAccount:^(ACAccount *account) {
                
                if (account) {
                    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                        //
                        NSURL *videoUrl = [YAUtils urlFromFileName:self.video.mp4Filename];
    //                    [NSURL URLWithString:self.video.mp4Filename];
                        
                        NSData *data = [NSData dataWithContentsOfURL: videoUrl];
                        self.hud = [MBProgressHUD showHUDAddedTo:self.page animated:YES];
                        self.hud.labelText = @"Posting";
                        self.hud.mode = MBProgressHUDModeIndeterminate;
                        
                        NSString *caption = ![self.video.caption isEqualToString:@""] ? [NSString stringWithFormat:@"%@ ", self.video.caption] : @"";
                        NSString *detailText = [NSString stringWithFormat:@"%@#yaga http://getyaga.com", caption];

                        [SocialVideoHelper uploadTwitterVideo:data account:account text:detailText withCompletion:^{
                            
                            [self showSuccessHud];
                            
                        }];
                    }];
                }
                
            }];

            break;
        } case 3: {
            // save
            ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
            [library writeVideoAtPathToSavedPhotosAlbum:fileUrl completionBlock:^(NSURL *assetURL, NSError *error){
                if(error) {
                    NSLog(@"CameraViewController: Error on saving movie : %@ {imagePickerController}", error);
                }
                else {
                    NSLog(@"URL: %@", assetURL);
                }
                
                [self showSuccessHud];
            }];
            
            break;
        } default:
            break;
    }
    
}

- (void)showSuccessHud {
    [self.hud hide:YES];
    
    self.hud = [MBProgressHUD showHUDAddedTo:self.page animated:YES];
    self.hud.mode = MBProgressHUDModeText;
    self.hud.labelText = @"Success!";
    
    [self.hud hide:YES afterDelay:1.0];
}

- (void)hideHud {
    [self.hud hide:YES];
}

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult) result
{
    [(UIViewController *)self.page.presentingVC dismissViewControllerAnimated:YES completion:nil];
    switch (result) {
        case MessageComposeResultCancelled: {
            [[Mixpanel sharedInstance] track:@"iMessage cancelled"];
            break;
        }
        case MessageComposeResultFailed:
        {
            [[Mixpanel sharedInstance] track:@"iMessage failed"];
            [YAUtils showNotification:@"failed to send message" type:YANotificationTypeError];
//            [self popToGridViewController];
            break;
        }
            
        case MessageComposeResultSent:
            [[Mixpanel sharedInstance] track:@"iMessage sent"];
            //            [YAUtils showNotification:@"message sent" type:YANotificationTypeSuccess];
//            [self popToGridViewController];
            
            break;
    }
}

- (void)getTwitterAccount:(void (^)(ACAccount *account))block {
    
    
    ACAccountStore *accountStore = [[ACAccountStore alloc] init];
    ACAccountType *accountType = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    
    [accountStore requestAccessToAccountsWithType:accountType options:nil completion:^(BOOL granted, NSError *error){
        if (granted) {
            
            NSArray *accounts = [accountStore accountsWithAccountType:accountType];
            
            // Check if the users has setup at least one Twitter account
            
            if (accounts.count > 0){
                
                if(accounts.count > 1){
                
                    [self accountSelector:accounts withBlock:block];
                } else {
                    ACAccount *twitterAccount = [accounts objectAtIndex:0];
                    //                [twitterAccount username]
                    block(twitterAccount);
                }
            
                
                // Creating a request to get the info about a user on Twitter
            }
        } else {
            NSLog(@"No access granted");
        }
    }];
}

- (void) accountSelector:(NSArray *)accounts withBlock:(void (^)(ACAccount *account))block {
    
    self.accounts = accounts;
    self.completionBlock = block;
    
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:@"Select Account" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:nil];
    
    for(ACAccount *account in accounts){
        [sheet addButtonWithTitle:[NSString stringWithFormat:@"@%@", account.username]];
    }
    
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [sheet showInView:self.page];
    }];
    
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0)  {
        // Cancel pressed
        self.completionBlock(nil);
        return;
    }
    ACAccount *twitterAccount = [self.accounts objectAtIndex:buttonIndex-1];
    self.completionBlock(twitterAccount);
}

#pragma mark - FBSDKSharingDelegate
- (void)sharer:(id<FBSDKSharing>)sharer didCompleteWithResults :(NSDictionary *)results {
    NSLog(@"FB: SHARE RESULTS=%@\n",[results debugDescription]);
}

- (void)sharer:(id<FBSDKSharing>)sharer didFailWithError:(NSError *)error {
    NSLog(@"FB: ERROR=%@\n",[error debugDescription]);
}

- (void)sharerDidCancel:(id<FBSDKSharing>)sharer {
    NSLog(@"FB: CANCELED SHARER=%@\n",[sharer debugDescription]);
}

- (void)externalShareButtonPressed {
    //    [self animateButton:self.shareButton withImageName:@"Share" completion:nil];
    NSString *caption = ![self.video.caption isEqualToString:@""] ? self.video.caption : @"Yaga";
    NSString *detailText = [NSString stringWithFormat:@"%@ — http://getyaga.com", caption];
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];
    hud.labelText = NSLocalizedString(@"Exporting", @"");
    hud.mode = MBProgressHUDModeIndeterminate;
    
    [[YAAssetsCreator sharedCreator] addBumberToVideoAtURL:[YAUtils urlFromFileName:self.video.mp4Filename]
                                                completion:^(NSURL *filePath, NSError *error) {
                                                    if (error) {
                                                        DLog(@"Error: can't add bumber");
                                                    } else {
                                                        
                                                        NSURL *videoFile = filePath;
                                                        //            YACopyVideoToClipboardActivity *copyActivity = [YACopyVideoToClipboardActivity new];
                                                        UIActivityViewController *activityViewController =
                                                        [[UIActivityViewController alloc] initWithActivityItems:@[detailText, videoFile]
                                                                                          applicationActivities:@[]];
                                                        
                                                        UIViewController *presentingVC = (UIViewController *) self.page.presentingVC;
                                                        [presentingVC presentViewController:activityViewController
                                                                                                                   animated:YES
                                                                                                                 completion:^{
                                                                                                                     [hud hide:YES];
                                                                                                                 }];
                                                        
                                                        [activityViewController setCompletionWithItemsHandler:^(NSString *activityType, BOOL completed, NSArray *returnedItems, NSError *activityError) {
                                                            if([activityType isEqualToString:@"com.apple.UIKit.activity.SaveToCameraRoll"]) {
                                                                NSString *message = completed ? NSLocalizedString(@"Video saved to camera roll", @"") : NSLocalizedString(@"Video failed to save to camera roll", @"");
                                                                [YAUtils showHudWithText:message];
                                                            }
                                                            else if ([activityType isEqualToString:@"yaga.copy.video"]) {
                                                                NSString *message = completed ? NSLocalizedString(@"Video copied to clipboard", @"") : NSLocalizedString(@"Video failed to copy to clipboard", @"");
                                                                [YAUtils showHudWithText:message];
                                                            }
                                                            if(completed){
                                                                [self.page collapseShareSheet];
                                                            }
                                                        }];
                                                    }
                                                }];
}


#pragma mark - Sharing
- (void)saveToCameraRollPressed {
    /*
     if (UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(path)) {
     UISaveVideoAtPathToSavedPhotosAlbum(path, self, @selector(video:didFinishSavingWithError:contextInfo:), nil);
     }
     */
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];
    hud.labelText = NSLocalizedString(@"Saving", @"");
    hud.mode = MBProgressHUDModeIndeterminate;
    
    [[YAAssetsCreator sharedCreator] addBumberToVideoAtURL:[YAUtils urlFromFileName:self.video.mp4Filename]
                                                completion:^(NSURL *filePath, NSError *error) {
                                                    [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
                                                        
                                                        [hud hide:YES];
                                                        [self.page collapseShareSheet];
                                                        //Your code goes in here
                                                        DLog(@"Main Thread Code");
                                                        
                                                    }];
                                                    if (error) {
                                                        DLog(@"Error: can't add bumber");
                                                    } else {
                                                        
                                                        if(UIVideoAtPathIsCompatibleWithSavedPhotosAlbum([filePath path])) {
                                                            UISaveVideoAtPathToSavedPhotosAlbum([filePath path], self, @selector(video:didFinishSavingWithError:contextInfo:), nil);
                                                        }
                                                        
                                                    }
                                                }];
}

- (void)video:(NSString*)videoPath didFinishSavingWithError:(NSError*)error contextInfo:(void*)contextInfo {
    if (error) {
        NSString *message = @"Video Saving Failed";
        [YAUtils showHudWithText:message];
        
    } else {
        NSString *message = @"Saved! ✌️";
        [YAUtils showHudWithText:message];
    }
}

@end