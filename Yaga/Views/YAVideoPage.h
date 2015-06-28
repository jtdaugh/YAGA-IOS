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

@protocol YASuspendableGesturesDelegate;

@interface YAVideoPage : UIView<UITextViewDelegate, UIActionSheetDelegate,
    UIGestureRecognizerDelegate, YAEventReceiver, YAViewCountDelegate>

@property (nonatomic, strong) YAVideo *video;
@property (nonatomic, readonly) YAVideoPlayerView *playerView;
@property (nonatomic, weak) id<YASuspendableGesturesDelegate> presentingVC;

- (void)setVideo:(YAVideo *)video shouldPreload:(BOOL)shouldPreload;
- (void)collapseCrosspost;
- (void)closeAnimated;

@end
