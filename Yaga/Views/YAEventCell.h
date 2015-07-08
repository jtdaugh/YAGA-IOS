//
//  YACommentsCell.h
//  Yaga
//
//  Created by Jesse on 5/29/15.
//  Copyright (c) 2015 Raj Vir. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "YAVideoPage.h"

typedef NS_ENUM(NSUInteger, YAEventCellVideoState) {
    YAEventCellVideoStateUploading,
    YAEventCellVideoStateUnapproved,
    YAEventCellVideoStateApproved
};

@interface YAEventCell : UITableViewCell

@property (nonatomic, weak) YAVideoPage *containingVideoPage;

+ (CGFloat)heightForCellWithEvent:(YAEvent *)event;

- (void)configureCellWithEvent:(YAEvent *)event;

- (void)setVideoState:(YAEventCellVideoState)state;

@end
