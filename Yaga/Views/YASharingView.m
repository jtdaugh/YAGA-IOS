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
#import "YACameraManager.h"

@interface YASharingView () <FBSDKSharingDelegate, MFMessageComposeViewControllerDelegate, UIActionSheetDelegate>

@property (nonatomic, strong) YAVideo *video;

@property (nonatomic, strong) RLMResults *groups;
@property (strong, nonatomic) UITableView *groupsList;
@property (strong, nonatomic) UILabel *crossPostPrompt;
@property (strong, nonatomic) UIView *shareBar;
@property (strong, nonatomic) UIButton *externalShareButton;
@property (strong, nonatomic) UIButton *saveButton;
@property (strong, nonatomic) UIButton *confirmCrosspost;
@property (strong, nonatomic) UIButton *collapseCrosspostButton;
@property (strong, nonatomic) MBProgressHUD *hud;

@property (nonatomic, copy) void (^completionBlock)(ACAccount *account);
@property (nonatomic, strong) NSArray *accounts;
@property (strong, nonatomic) UIView *topBar;

@property (nonatomic, strong) NSMutableArray *gpuImageRetainables; // Just for retaining various GPUImage components until export finishes

@end

@implementation YASharingView

- (id)initWithFrame:(CGRect)frame video:(YAVideo *)video {
    
    self = [super initWithFrame:frame];
    if (self) {
        _video = video;
        NSString *predicate = [NSString stringWithFormat:@"localId != '%@'", video.group.localId];
        
        self.groups = [[[YAGroup allObjects] objectsWhere:predicate] sortedResultsUsingDescriptors:@[[RLMSortDescriptor sortDescriptorWithProperty:@"publicGroup" ascending:NO], [RLMSortDescriptor sortDescriptorWithProperty:@"updatedAt" ascending:NO]]];
        
        CGFloat topGap = 20;
        CGFloat shareBarHeight = 60;
        CGFloat topBarHeight = 80;
        
        CGFloat totalRowsHeight = XPCellHeight * [self.groups count];
        if (![self.groups count]) totalRowsHeight = 0;
        BOOL myVideo = [self.video.creator isEqualToString:[[YAUser currentUser] username]];
        if (!myVideo) totalRowsHeight = 0;
        
        CGFloat maxTableViewHeight = (frame.size.height * VIEW_HEIGHT_PROPORTION) - topGap - XPCellHeight;
        maxTableViewHeight -= topBarHeight;
    
        CGFloat tableHeight = MIN(maxTableViewHeight, totalRowsHeight);
        
        CGFloat gradientHeight = tableHeight + topBarHeight + topGap;
        UIView *bgGradient = [[UIView alloc] initWithFrame:CGRectMake(0, VIEW_HEIGHT - gradientHeight, VIEW_WIDTH, gradientHeight)];
        //    self.commentsGradient.backgroundColor = [UIColor redColor];
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
        
        CGFloat tableOrigin = frame.size.height - tableHeight;
        self.topBar = [[UIView alloc] initWithFrame:CGRectMake(0, tableOrigin - topBarHeight - (myVideo && [self.groups count] ? topGap : 0), VIEW_WIDTH, topBarHeight)];
        [self addSubview:self.topBar];
        
        CGFloat count = 4;
        CGFloat buttonWidth = VIEW_WIDTH/count - VIEW_WIDTH/(count*2 + 1);
        
        NSArray *files = @[@"Message", @"FB", @"Twitter", @"CameraRoll"];
        
        UIView *tapOutView = [[UIView alloc] initWithFrame:CGRectMake(0, 60, VIEW_WIDTH, VIEW_HEIGHT - tableHeight - topBarHeight - topGap - 60)];
        tapOutView.backgroundColor = [UIColor clearColor];
        [self addSubview:tapOutView];
        self.crosspostTapOutRecognizer = [[UITapGestureRecognizer alloc] init];
        [tapOutView addGestureRecognizer:self.crosspostTapOutRecognizer];
        
        for(float i = 0.0f; i < [files count]; i++){
            UIButton *externalShareButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, buttonWidth, buttonWidth)];
            CGFloat centerRatio = (i*2+1)/(count*2);
            externalShareButton.center = CGPointMake(centerRatio*VIEW_WIDTH, topBarHeight/2);
            externalShareButton.alpha = 0.8;
            //        [externalShareButton setBackgroundColor:[UIColor greenColor]];
            externalShareButton.tag = (int)i;
            [externalShareButton setImage:[UIImage imageNamed:files[(int)i]] forState:UIControlStateNormal];
            [externalShareButton addTarget:self action:@selector(externalShareAction:) forControlEvents:UIControlEventTouchUpInside];
            [self.topBar addSubview:externalShareButton];
        }
        
        self.groupsList = [[UITableView alloc] initWithFrame:CGRectMake(0, tableOrigin, VIEW_WIDTH, tableHeight)];
        [self.groupsList setBackgroundColor:[UIColor clearColor]];
        [self.groupsList registerClass:[YACrosspostCell class] forCellReuseIdentifier:kCrosspostCellId];
        [self.groupsList registerClass:[UITableViewCell class] forCellReuseIdentifier:kNewGroupCellId];
        self.groupsList.separatorStyle = UITableViewCellSeparatorStyleNone;
        self.groupsList.allowsSelection = YES;
        self.groupsList.allowsMultipleSelection = YES;
        self.groupsList.delegate = self;
        self.groupsList.dataSource = self;
        self.groupsList.hidden = !myVideo;
        [self addSubview:self.groupsList];
        self.groupsList.contentInset = UIEdgeInsetsMake(0, 0, XPCellHeight, 0);

        self.crossPostPrompt = [[UILabel alloc] initWithFrame:CGRectMake(24, tableOrigin - topGap, VIEW_WIDTH-24, 24)];
        self.crossPostPrompt.font = [UIFont fontWithName:BOLD_FONT size:20];
        self.crossPostPrompt.textColor = [UIColor whiteColor];
        NSString *title =([self.groups count] ? @"Share to other channels" : @"");
        self.crossPostPrompt.text = title;
        self.crossPostPrompt.hidden = !myVideo;
        self.crossPostPrompt.layer.shadowRadius = 0.5f;
        self.crossPostPrompt.layer.shadowColor = [UIColor blackColor].CGColor;
        self.crossPostPrompt.layer.shadowOffset = CGSizeMake(0.5f, 0.5f);
        self.crossPostPrompt.layer.shadowOpacity = 1.0;
        self.crossPostPrompt.layer.masksToBounds = NO;
        
        [self addSubview:self.crossPostPrompt];
        
        self.shareBar = [[UIView alloc] initWithFrame:CGRectMake(0, self.frame.size.height - shareBarHeight, VIEW_WIDTH, shareBarHeight)];
        //    [self.shareBar setBackgroundColor:PRIMARY_COLOR];
        [self.shareBar setUserInteractionEnabled:NO];
        [self addSubview:self.shareBar];
        
        //    FBShimmeringView *shimmeringView = [[FBShimmeringView alloc] initWithFrame:self.shareBar.frame];
        
        
        // Start shimmering.
        //    shimmeringView.shimmering = YES;
        
        self.confirmCrosspost = [[UIButton alloc] initWithFrame:self.shareBar.frame];
        self.confirmCrosspost.backgroundColor = SECONDARY_COLOR;
        self.confirmCrosspost.titleLabel.font = [UIFont fontWithName:BOLD_FONT size:20];
        self.confirmCrosspost.titleLabel.textColor = [UIColor whiteColor];
        [self.confirmCrosspost setContentHorizontalAlignment:UIControlContentHorizontalAlignmentLeft];
        [self.confirmCrosspost setImage:[UIImage imageNamed:@"Disclosure"] forState:UIControlStateNormal];
        self.confirmCrosspost.imageView.contentMode = UIViewContentModeScaleAspectFit;
        //    [self.confirmCrosspost.imageView setBackgroundColor:[UIColor greenColor]];
        //    [self.confirmCrosspost.titleLabel setBackgroundColor:[UIColor purpleColor]];
        [self.confirmCrosspost setContentEdgeInsets:UIEdgeInsetsZero];
        [self.confirmCrosspost setImageEdgeInsets:UIEdgeInsetsMake(0, self.confirmCrosspost.frame.size.width - 48 - 16, 0, 48)];
        [self.confirmCrosspost setTitleEdgeInsets:UIEdgeInsetsMake(0, 8, 0, 48 - 16)];
        [self.confirmCrosspost setTransform:CGAffineTransformMakeTranslation(0, self.confirmCrosspost.frame.size.height)];
        [self.confirmCrosspost addTarget:self action:@selector(confirmCrosspost:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:self.confirmCrosspost];
        //    shimmeringView.contentView = self.confirmCrosspost;
        //    [self.confirmCrosspost addSubview:shimmeringView];
        
        
        CGFloat buttonRadius = 22.f, padding = 4.f;
                
        self.collapseCrosspostButton = [YAUtils circleButtonWithImage:@"X" diameter:buttonRadius*2 center:CGPointMake(VIEW_WIDTH - buttonRadius - padding, padding + buttonRadius)];
        [self.collapseCrosspostButton addTarget:self action:@selector(collapseCrosspost) forControlEvents:UIControlEventTouchUpInside];
        self.collapseCrosspostButton.alpha = 0.0;
        [self addSubview:self.collapseCrosspostButton];
        
        
        //    [self.groupsList setFrame:CGRectMake(0, VIEW_HEIGHT - shareBarHeight, VIEW_WIDTH, 0)];
        //    [self.overlay insertSubview:self.bgOverlay belowSubview:self.editableCaptionWrapperView];
        //    [self.captionBlurOverlay addSubview:self.cancelWhileTypingButton];
    }
    return self;
}


- (void)setTopButtonsHidden:(BOOL)hidden animated:(BOOL)animated {
    [UIView animateWithDuration:animated ? 0.2 : 0.0 animations:^{
        self.collapseCrosspostButton.alpha = hidden ? 0.0 : 1.0;
    }];
}


- (void)collapseCrosspost {
    [self.page collapseCrosspost];
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
//            // save
//            ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
//            [library writeVideoAtPathToSavedPhotosAlbum:fileUrl completionBlock:^(NSURL *assetURL, NSError *error){
//                if(error) {
//                    NSLog(@"CameraViewController: Error on saving movie : %@ {imagePickerController}", error);
//                }
//                else {
//                    NSLog(@"URL: %@", assetURL);
//                }
//                
//                [self showSuccessHud];
//            }];
            
//TODO watermark
            __weak typeof(self) weakSelf = self;
            [self addCaptionWatermakAndSaveToPhotosAlbumWithCompletion:^(NSError *error) {
                [weakSelf showSuccessHud];
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

- (void)renderButton:(NSUInteger) count {
    if(count > 0){
        NSString *title;
        if(count == 1){
            title = @"Post to 1 group";
        } else {
            title = [NSString stringWithFormat:@"Post to %lu channels", (unsigned long)count];
        }
        [self.confirmCrosspost setTitle:title forState:UIControlStateNormal];
        [UIView animateWithDuration:0.2 delay:0.0 options:UIViewAnimationOptionAllowAnimatedContent animations:^{
            [self.confirmCrosspost setTransform:CGAffineTransformIdentity];
        } completion:^(BOOL finished) {
            //
        }];
    } else {
        [UIView animateWithDuration:0.2 delay:0.0 options:UIViewAnimationOptionAllowAnimatedContent animations:^{
            [self.confirmCrosspost setTransform:CGAffineTransformMakeTranslation(0, self.confirmCrosspost.frame.size.height)];
        } completion:^(BOOL finished) {
            //
        }];
    }
}

- (void)confirmCrosspost:(id)sender {
    NSMutableArray *groupIds = [NSMutableArray new];
    NSMutableArray *yaGroups = [NSMutableArray new];
    
    for(NSIndexPath *indexPath in self.groupsList.indexPathsForSelectedRows) {
        if(self.groups.count > indexPath.row) {
            YAGroup *group = self.groups[indexPath.row];
            [groupIds addObject:group.serverId];
            [yaGroups addObject:group];
        }
    }
    __block MBProgressHUD *hud = [YAUtils showIndeterminateHudWithText:NSLocalizedString(@"Copying video to channels", @"")];
    [[YAServer sharedServer] copyVideo:self.video toGroupsWithIds:groupIds withCompletion:^(id response, NSError *error) {
        [hud hide:NO];
        
        if(!error) {
            [YAUtils showHudWithText:NSLocalizedString(@"Copied successfully", @"")];
        }
        else {
            DLog(@"%@", error);
            [YAUtils showHudWithText:NSLocalizedString(@"Can not copy video to channels", @"")];
        }
    }];
    [self.page collapseCrosspost];
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
                                                                [self.page collapseCrosspost];
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
                                                        [self.page collapseCrosspost];
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

//- (void)video:(NSString*)videoPath didFinishSavingWithError:(NSError*)error contextInfo:(void*)contextInfo {
//    if (error) {
//        NSString *message = @"Video Saving Failed";
//        [YAUtils showHudWithText:message];
//        
//    } else {
//        NSString *message = @"Saved! ✌️";
//        [YAUtils showHudWithText:message];
//    }
//}

#pragma mark - UITableViewDataSource / UITableViewDelegate
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
        YACrosspostCell *cell = [tableView dequeueReusableCellWithIdentifier:kCrosspostCellId forIndexPath:indexPath];
        YAGroup *group = [self.groups objectAtIndex:indexPath.row];
        [cell setGroupTitle:group.name];
        return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return XPCellHeight;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.groups count];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
        [self renderButton:[[tableView indexPathsForSelectedRows] count]];
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self renderButton:[[tableView indexPathsForSelectedRows] count]];
}

#pragma mark - Watermark
- (void)addCaptionWatermakAndSaveToPhotosAlbumWithCompletion:(completionBlock)completion {
    self.gpuImageRetainables = [NSMutableArray array];
    AVURLAsset *asset = [AVURLAsset assetWithURL:[YAUtils urlFromFileName:self.video.mp4Filename]];
    [self.gpuImageRetainables addObject:asset];
    
    GPUImageMovie *movieFile = [[GPUImageMovie alloc] initWithAsset:asset];
    [self.gpuImageRetainables addObject:movieFile];
    
    movieFile.runBenchmark = YES;
    movieFile.playAtActualSpeed = NO;
    
    GPUImageBrightnessFilter *blendFilter = [[GPUImageBrightnessFilter alloc] init];
    [self.gpuImageRetainables addObject:blendFilter];
    
    blendFilter.brightness = 0.0;
    
    UIView *contentView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, VIEW_WIDTH, VIEW_HEIGHT)];
    contentView.backgroundColor = [UIColor clearColor];
    
    UILabel *captionLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 50, VIEW_WIDTH, VIEW_HEIGHT)];
    
    NSAttributedString *string = [[NSAttributedString alloc] initWithString:@"." attributes:@{
                                                                                              NSStrokeColorAttributeName:[UIColor whiteColor],
                                                                                              NSStrokeWidthAttributeName:[NSNumber numberWithFloat:-CAPTION_STROKE_WIDTH]
                                                                                              }];
    [captionLabel setAttributedText:string];
    [captionLabel setBackgroundColor: [UIColor clearColor]];
    [captionLabel setTextColor:PRIMARY_COLOR];
    [captionLabel setFont:[UIFont fontWithName:CAPTION_FONT size:CAPTION_FONT_SIZE]];
    captionLabel.textAlignment = NSTextAlignmentCenter;
    captionLabel.text = self.video.caption;
    captionLabel.backgroundColor = [UIColor clearColor];
    [contentView addSubview:captionLabel];
    [self.gpuImageRetainables addObject:contentView];

    //test
    captionLabel.transform = CGAffineTransformRotate(captionLabel.transform, M_PI/6);
    
    GPUImageUIElement *uiElementInput = [[GPUImageUIElement alloc] initWithView:contentView];
    [self.gpuImageRetainables addObject:uiElementInput];

//    [uiElementInput addTarget:blendFilter atTextureLocation:1];
    [movieFile addTarget:blendFilter];

//    [filter setFrameProcessingCompletionBlock:^(GPUImageOutput * filter, CMTime frameTime){
//        //set label.hidden to YES and here to NO in case it should be shown at the beginning/end of the video
//        //        if (frameTime.value/frameTime.timescale == 2) {
//        //            [contentView viewWithTag:1].hidden = NO;
//        //        }
//        [uiElementInput update];
//    }];
    
    // In addition to displaying to the screen, write out a processed version of the movie to disk
    NSString *pathToMovie = [NSTemporaryDirectory() stringByAppendingPathComponent:@"video_with_watermark.mp4"];
    unlink([pathToMovie UTF8String]); // If a file already exists, AVAssetWriter won't let you record new frames, so delete the old movie
    
    CGSize size = [[[asset tracksWithMediaType:AVMediaTypeVideo] firstObject] naturalSize];
    
    GPUImageMovieWriter *movieWriter = [[GPUImageMovieWriter alloc] initWithMovieURL:[NSURL fileURLWithPath:pathToMovie] size:size];
    [self.gpuImageRetainables addObject:movieWriter];
    [blendFilter addTarget:movieWriter];
    
//    movieWriter.encodingLiveVideo = NO;
    
    // Configure this for video from the movie file, where we want to preserve all video frames and audio samples
//    movieWriter.shouldPassthroughAudio = YES;
    movieFile.audioEncodingTarget = movieWriter;
    [movieFile enableSynchronizedEncodingUsingMovieWriter:movieWriter];
    
    [movieWriter startRecording];
    [movieFile startProcessing];
    
    [movieWriter setCompletionBlock:^{
//        [movieFile removeAllTargets];
//        [uiElementInput removeAllTargets];
//        [filter removeAllTargets];
        movieFile.audioEncodingTarget = nil;
        [blendFilter removeTarget:movieWriter];
        [movieWriter finishRecording];

        UISaveVideoAtPathToSavedPhotosAlbum(pathToMovie, self, @selector(video:didFinishSavingWithError: contextInfo:), (__bridge void *)(completion));
    }];
}

- (void)video:(NSString *)videoPath didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    completionBlock completion;
    if (contextInfo)
        completion = (__bridge completionBlock) contextInfo;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.gpuImageRetainables removeAllObjects];
        if (!error) {
            DLog(@"video with watermark saved to the camera roll");
            if(completion)
                completion(nil);
        } else {
            DLog(@"Save to cam roll error: %@", error);
            if(completion)
                completion(error);
        };
    });

}


@end
