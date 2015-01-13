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

@interface YAVideoPage : UIView<UITextFieldDelegate>

@property (nonatomic, strong) YAVideo *video;
@property (nonatomic, strong) YAVideoPlayerView *playerView;
- (void)showLoading:(BOOL)show;
@end
