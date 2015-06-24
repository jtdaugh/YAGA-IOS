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

#import "YASwipingViewController.h"

@interface YASharingView ()

@property (strong, nonatomic) UIView *bgOverlay;

@property (nonatomic, strong) RLMResults *groups;
@property (strong, nonatomic) UITableView *groupsList;
@property (strong, nonatomic) UILabel *crossPostPrompt;
@property (strong, nonatomic) UIView *shareBar;
@property (strong, nonatomic) UIButton *externalShareButton;
@property (strong, nonatomic) UIButton *saveButton;
@property (strong, nonatomic) UIButton *confirmCrosspost;
@property (strong, nonatomic) UIButton *closeCrosspost;
@end

@implementation YASharingView

- (id) initWithFrame:(CGRect)frame {
//    [super init];
//    [super viewDidLoad];
    
    self = [super initWithFrame:frame];
    
//    [self setUserInteractionEnabled:NO];
    
    self.bgOverlay = [[UIView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
    
    //    [self.bgOverlay setAlpha:0.0];
    [self addSubview:self.bgOverlay];
    
    CGFloat topPadding = 10;
    CGFloat shareBarHeight = 60;
    
    CGFloat borderWidth = 4;
    
    //exclude current group
    NSString *predicate = [NSString stringWithFormat:@"localId != '%@'", [YAUser currentUser].currentGroup.localId];
    self.groups = [[YAGroup objectsWhere:predicate] sortedResultsUsingProperty:@"updatedAt" ascending:NO];
    
    self.groupsList = [[UITableView alloc] initWithFrame:CGRectMake(0, topPadding, VIEW_WIDTH, self.frame.size.height - topPadding)];
    [self.groupsList setBackgroundColor:[UIColor clearColor]];
    [self.groupsList registerClass:[YACrosspostCell class] forCellReuseIdentifier:@"crossPostCell"];
    self.groupsList.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.groupsList.allowsSelection = YES;
    self.groupsList.allowsMultipleSelection = YES;
    
    self.groupsList.delegate = self;
    self.groupsList.dataSource = self;
    [self.bgOverlay addSubview:self.groupsList];
    
    self.crossPostPrompt = [[UILabel alloc] initWithFrame:CGRectMake(24, topPadding - 24, VIEW_WIDTH-24, 24)];
    self.crossPostPrompt.font = [UIFont fontWithName:BOLD_FONT size:20];
    self.crossPostPrompt.textColor = [UIColor whiteColor];
    self.crossPostPrompt.text = @"Post to more groups";
//    self.crossPostPrompt.layer.shadowRadius = 0.5f;
//    self.crossPostPrompt.layer.shadowColor = [UIColor blackColor].CGColor;
//    self.crossPostPrompt.layer.shadowOffset = CGSizeMake(0.0f, 0.0f);
//    self.crossPostPrompt.layer.shadowOpacity = 1.0;
//    self.crossPostPrompt.layer.masksToBounds = NO;
    [self.bgOverlay addSubview:self.crossPostPrompt];
    
    
    self.shareBar = [[UIView alloc] initWithFrame:CGRectMake(0, self.frame.size.height - shareBarHeight, VIEW_WIDTH, shareBarHeight)];
//    [self.shareBar setBackgroundColor:PRIMARY_COLOR];
    [self.bgOverlay addSubview:self.shareBar];
    
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
    [self.bgOverlay addSubview:self.confirmCrosspost];
//    shimmeringView.contentView = self.confirmCrosspost;
//    [self.confirmCrosspost addSubview:shimmeringView];


    
    CGFloat buttonRadius = 22.f, padding = 4.f;
    self.closeCrosspost = [YAUtils circleButtonWithImage:@"X" diameter:buttonRadius*2 center:CGPointMake(VIEW_WIDTH - buttonRadius - padding, padding + buttonRadius)];
    [self.closeCrosspost addTarget:self action:@selector(collapseCrosspost) forControlEvents:UIControlEventTouchUpInside];
//    [self.bgOverlay addSubview:self.closeCrosspost];
    
    UIView *separator = [[UIView alloc] initWithFrame:CGRectMake(0, self.frame.size.height - shareBarHeight - borderWidth, VIEW_WIDTH, borderWidth)];
    [separator setBackgroundColor:[UIColor whiteColor]];
//    [self.bgOverlay addSubview:separator];
    
    self.saveButton = [[UIButton alloc] initWithFrame:CGRectMake(VIEW_WIDTH/2 + borderWidth/2, 0, VIEW_WIDTH/2 - borderWidth/2, self.shareBar.frame.size.height)];
    [self.saveButton setImage:[UIImage imageNamed:@"Download"] forState:UIControlStateNormal];
    [self.saveButton setTitle:@"Save" forState:UIControlStateNormal];
    [self.saveButton.titleLabel setFont:[UIFont fontWithName:BIG_FONT size:18]];
    [self.saveButton addTarget:self action:@selector(saveToCameraRollPressed) forControlEvents:UIControlEventTouchUpInside];
//    [self.saveButton setBackgroundColor:PRIMARY_COLOR];
//    [self.shareBar addSubview:self.saveButton];
    
    self.externalShareButton = [[YACenterImageButton alloc] initWithFrame:CGRectMake(0, 0, VIEW_WIDTH/2 - borderWidth/2, self.shareBar.frame.size.height)];
    [self.externalShareButton setImage:[UIImage imageNamed:@"External_Share"] forState:UIControlStateNormal];
    [self.externalShareButton setTitle:@"Share" forState:UIControlStateNormal];
    [self.externalShareButton.titleLabel setFont:[UIFont fontWithName:BOLD_FONT size:18]];
    [self.externalShareButton addTarget:self action:@selector(externalShareButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    [self.externalShareButton setBackgroundColor:PRIMARY_COLOR];
//    [self.shareBar addSubview:self.externalShareButton];
    
    UIView *vSeparator = [[UIView alloc] initWithFrame:CGRectMake(VIEW_WIDTH/2 - borderWidth/2, 0, borderWidth, self.shareBar.frame.size.height)];
    [vSeparator setBackgroundColor:[UIColor whiteColor]];
//    [self.shareBar addSubview:vSeparator];
    
    //    [self.groupsList setFrame:CGRectMake(0, VIEW_HEIGHT - shareBarHeight, VIEW_WIDTH, 0)];
    //    [self.overlay insertSubview:self.bgOverlay belowSubview:self.editableCaptionWrapperView];
    //    [self.captionBlurOverlay addSubview:self.cancelWhileTypingButton];
    
    return self;
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
    
    __block MBProgressHUD *hud = [YAUtils showIndeterminateHudWithText:NSLocalizedString(@"Copying video to groups", @"")];
    [[YAServer sharedServer] copyVideo:self.video toGroupsWithIds:groupIds withCompletion:^(id response, NSError *error) {
        [hud hide:NO];
        
        if(!error) {
            [self collapseCrosspost];
            [YAUtils showHudWithText:NSLocalizedString(@"Copied successfully", @"")];
        }
        else {
            NSLog(@"%@", error);
            [YAUtils showHudWithText:NSLocalizedString(@"Can not copy video to groups", @"")];
        }
    }];
}

- (void)collapseCrosspost {
    NSLog(@"collapsing 1");
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
                                                        
                                                        
                                                        (YASwipingViewController *) self.page.presentingVC;
                                                        YASwipingViewController *presentingVC = (YASwipingViewController *) self.page.presentingVC;
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
