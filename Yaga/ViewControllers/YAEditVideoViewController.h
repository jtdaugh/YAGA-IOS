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

@interface YAEditVideoViewController : YASwipeToDismissViewController <SAVideoRangeSliderDelegate>
@property (nonatomic, strong) YAVideo *video;

@end