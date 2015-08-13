//
//  YAEditVideoViewController.h
//  Yaga
//
//  Created by valentinkovalski on 7/21/15.
//  Copyright © 2015 Raj Vir. All rights reserved.
//

#import "YAVideo.h"
#import "SAVideoRangeSlider.h"
#import "YASwipingViewController.h"
#import "YAVideoPlayerView.h"

@interface YAEditVideoViewController : YASwipeToDismissViewController <SAVideoRangeSliderDelegate, YAVideoPlayerViewDelegate>
@property (nonatomic, strong) NSURL *videoUrl;
@property (nonatomic) NSTimeInterval totalDuration;

@property (nonatomic, strong) YAGroup *preselectedGroup;

- (BOOL)blockCameraPresentationOnBackground;

@end
