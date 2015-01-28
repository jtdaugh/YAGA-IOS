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
@property (nonatomic, readonly) YAVideoPlayerView *playerView;

- (void)setVideo:(YAVideo *)video shouldPlay:(BOOL)shouldPlay;
@end
