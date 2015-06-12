//
//  YAShareViewController.m
//  Yaga
//
//  Created by valentinkovalski on 6/12/15.
//  Copyright (c) 2015 Raj Vir. All rights reserved.
//

#import "YASharingViewController.h"
#import "YACenterImageButton.h"

#import "YAGroup.h"
#import "YAUser.h"

#import "YACrosspostCell.h"
#import "YAServer.h"
#import "YAAssetsCreator.h"

@interface YASharingViewController ()
@property (strong, nonatomic) UIVisualEffectView *shareBlurOverlay;

@property (nonatomic, strong) RLMResults *groups;
@property (strong, nonatomic) UITableView *groupsList;
@property (strong, nonatomic) UILabel *crossPostPrompt;
@property (strong, nonatomic) UIView *shareBar;
@property (strong, nonatomic) YACenterImageButton *externalShareButton;
@property (strong, nonatomic) YACenterImageButton *saveButton;
@property (strong, nonatomic) UIButton *confirmCrosspost;
@property (strong, nonatomic) UIButton *closeCrosspost;
@end

@implementation YASharingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIVisualEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
    
    self.shareBlurOverlay = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
    
    self.shareBlurOverlay.frame = self.view.bounds;
    //    [self.shareBlurOverlay setAlpha:0.0];
    [self.view addSubview:self.shareBlurOverlay];
    
    CGFloat topPadding = 100;
    CGFloat shareBarHeight = 100;
    
    CGFloat borderWidth = 4;
    
    //exclude current group
    NSString *predicate = [NSString stringWithFormat:@"localId != '%@'", [YAUser currentUser].currentGroup.localId];
    self.groups = [[YAGroup objectsWhere:predicate] sortedResultsUsingProperty:@"updatedAt" ascending:NO];
    
    self.groupsList = [[UITableView alloc] initWithFrame:CGRectMake(0, topPadding, VIEW_WIDTH, VIEW_HEIGHT - topPadding - shareBarHeight - borderWidth)];
    [self.groupsList setBackgroundColor:[UIColor clearColor]];
    [self.groupsList registerClass:[YACrosspostCell class] forCellReuseIdentifier:@"crossPostCell"];
    self.groupsList.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.groupsList.allowsSelection = YES;
    self.groupsList.allowsMultipleSelection = YES;
    
    self.groupsList.delegate = self;
    self.groupsList.dataSource = self;
    [self.shareBlurOverlay addSubview:self.groupsList];
    
    self.crossPostPrompt = [[UILabel alloc] initWithFrame:CGRectMake(24, topPadding - 24, VIEW_WIDTH-24, 24)];
    self.crossPostPrompt.font = [UIFont fontWithName:BOLD_FONT size:20];
    self.crossPostPrompt.textColor = [UIColor whiteColor];
    self.crossPostPrompt.text = @"Post to other groups";
    [self.shareBlurOverlay addSubview:self.crossPostPrompt];
    
    
    self.shareBar = [[UIView alloc] initWithFrame:CGRectMake(0, VIEW_HEIGHT - shareBarHeight, VIEW_WIDTH, shareBarHeight)];
    [self.shareBar setBackgroundColor:PRIMARY_COLOR];
    [self.shareBlurOverlay addSubview:self.shareBar];
    
    self.confirmCrosspost = [[UIButton alloc] initWithFrame:self.shareBar.frame];
    self.confirmCrosspost.backgroundColor = SECONDARY_COLOR;
    self.confirmCrosspost.titleLabel.font = [UIFont fontWithName:BOLD_FONT size:24];
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
    [self.shareBlurOverlay addSubview:self.confirmCrosspost];
    
    CGFloat buttonRadius = 22.f, padding = 4.f;
    self.closeCrosspost = [YAUtils circleButtonWithImage:@"X" diameter:buttonRadius*2 center:CGPointMake(VIEW_WIDTH - buttonRadius - padding, padding + buttonRadius)];
    [self.closeCrosspost addTarget:self action:@selector(collapseCrosspost) forControlEvents:UIControlEventTouchUpInside];
    [self.shareBlurOverlay addSubview:self.closeCrosspost];
    
    UIView *separator = [[UIView alloc] initWithFrame:CGRectMake(0, VIEW_HEIGHT - shareBarHeight - borderWidth, VIEW_WIDTH, borderWidth)];
    [separator setBackgroundColor:[UIColor whiteColor]];
    [self.shareBlurOverlay addSubview:separator];
    
    self.saveButton = [[YACenterImageButton alloc] initWithFrame:CGRectMake(VIEW_WIDTH/2 + borderWidth/2, 0, VIEW_WIDTH/2 - borderWidth/2, self.shareBar.frame.size.height)];
    [self.saveButton setImage:[UIImage imageNamed:@"Download"] forState:UIControlStateNormal];
    [self.saveButton setTitle:@"Save" forState:UIControlStateNormal];
    [self.saveButton.titleLabel setFont:[UIFont fontWithName:BOLD_FONT size:24]];
    [self.saveButton addTarget:self action:@selector(saveToCameraRollPressed) forControlEvents:UIControlEventTouchUpInside];
    [self.saveButton setBackgroundColor:PRIMARY_COLOR];
    [self.shareBar addSubview:self.saveButton];
    
    self.externalShareButton = [[YACenterImageButton alloc] initWithFrame:CGRectMake(0, 0, VIEW_WIDTH/2 - borderWidth/2, self.shareBar.frame.size.height)];
    [self.externalShareButton setImage:[UIImage imageNamed:@"External_Share"] forState:UIControlStateNormal];
    [self.externalShareButton setTitle:@"Share" forState:UIControlStateNormal];
    [self.externalShareButton.titleLabel setFont:[UIFont fontWithName:BOLD_FONT size:24]];
    [self.externalShareButton addTarget:self action:@selector(externalShareButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    [self.externalShareButton setBackgroundColor:PRIMARY_COLOR];
    [self.shareBar addSubview:self.externalShareButton];
    
    UIView *vSeparator = [[UIView alloc] initWithFrame:CGRectMake(VIEW_WIDTH/2 - borderWidth/2, 0, borderWidth, self.shareBar.frame.size.height)];
    [vSeparator setBackgroundColor:[UIColor whiteColor]];
    [self.shareBar addSubview:vSeparator];
    
    //    [self.groupsList setFrame:CGRectMake(0, VIEW_HEIGHT - shareBarHeight, VIEW_WIDTH, 0)];
    [self.shareBlurOverlay setTransform:CGAffineTransformMakeTranslation(0, self.shareBlurOverlay.frame.size.height)];
    [UIView animateWithDuration:0.4 delay:0.0 usingSpringWithDamping:1.0 initialSpringVelocity:0.5 options:UIViewAnimationOptionAllowAnimatedContent animations:^{
        //
        //    } completion:^(BOOL finished) {
        //        //
        //    }]
        //
        //    [UIView animateWithDuration:0.2 delay:0.0 options:UIViewAnimationOptionAllowAnimatedContent animations:^{
        //
        [self.shareBlurOverlay setTransform:CGAffineTransformIdentity];
        //        [self.groupsList setFrame:CGRectMake(0, 100, VIEW_WIDTH, VIEW_HEIGHT - topPadding - shareBarHeight - borderWidth)];
        
    } completion:^(BOOL finished) {
        //
    }];
    //    [self.overlay insertSubview:self.shareBlurOverlay belowSubview:self.editableCaptionWrapperView];
    //    [self.captionBlurOverlay addSubview:self.cancelWhileTypingButton];
    

}

- (void)renderButton:(NSUInteger) count {
    if(count > 0){
        NSString *title;
        if(count == 1){
            title = @"Post to 1 more group";
        } else {
            title = [NSString stringWithFormat:@"Post to %lu more groups", count];
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
    for(NSIndexPath *indexPath in self.groupsList.indexPathsForSelectedRows) {
        if(self.groups.count > indexPath.row) {
            YAGroup *group = self.groups[indexPath.row];
            [groupIds addObject:group.serverId];
        }
    }
    
    [[YAServer sharedServer] copyVideo:self.video toGroupsWithIds:groupIds withCompletion:^(id response, NSError *error) {
        if(!error) {
            [self collapseCrosspost];
        }
        else {
            DLog(@"unable to copy video to groups: %@", groupIds);
        }
    }];
}

- (void)collapseCrosspost {
    [UIView animateWithDuration:0.2 delay:0.0 options:UIViewAnimationOptionAllowAnimatedContent animations:^{
        //
        [self.shareBlurOverlay setTransform:CGAffineTransformMakeTranslation(0, self.shareBlurOverlay.frame.size.height)];
    } completion:^(BOOL finished) {
        //
        [self.shareBlurOverlay removeFromSuperview];
    }];
    [self dismissViewControllerAnimated:YES completion:nil];
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
                                                        
                                                        //        activityViewController.excludedActivityTypes = @[UIActivityTypeCopyToPasteboard];

                                                        [self presentViewController:activityViewController
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
                                                                [self collapseCrosspost];
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
                                                        [self collapseCrosspost];
                                                        //Your code goes in here
                                                        NSLog(@"Main Thread Code");
                                                        
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


#pragma mark - UITableViewDataSource / UITableViewDelegate
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    YACrosspostCell *cell = [tableView dequeueReusableCellWithIdentifier:@"crossPostCell" forIndexPath:indexPath];
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

-(void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self renderButton:[[tableView indexPathsForSelectedRows] count]];
}

@end
