//
//  YAPage.h
//  testReuse
//
//  Created by valentinkovalski on 1/9/15.
//  Copyright (c) 2015 test. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "YAVideoPlayerView.h"
#import "YAVideo.h"
#import "YAEventManager.h"
#import "YAViewCountManager.h"

@protocol YASwipableContainer;

@interface YAVideoPage : UIView<UITextViewDelegate, UIActionSheetDelegate,
    UIGestureRecognizerDelegate, YAEventReceiver, YAVideoViewCountDelegate>

@property (nonatomic, strong) YAVideo *video;
@property (nonatomic, readonly) YAVideoPlayerView *playerView;
@property (nonatomic, weak) id<YASwipableContainer> presentingVC;

- (void)setVideo:(YAVideo *)video shouldPreload:(BOOL)shouldPreload;
- (void)collapseCrosspost;
- (void)closeAnimated;

@property (nonatomic, assign) BOOL showAdminControls;

@property (nonatomic, assign) BOOL showBottomControls;

@property (nonatomic, assign) BOOL streamMode;

- (void)showSharingOptions;

@end
