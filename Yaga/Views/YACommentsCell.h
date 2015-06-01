//
//  YACommentsCell.h
//  Yaga
//
//  Created by Jesse on 5/29/15.
//  Copyright (c) 2015 Raj Vir. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "YAVideoPage.h"

@interface YACommentsCell : UITableViewCell

@property (nonatomic, weak) YAVideoPage *containingVideoPage;

+ (CGFloat)heightForCommentCellWithUsername:(NSString *)username comment:(NSString *)comment;
+ (CGFloat)heightForPostCell;
+ (CGFloat)heightForLikeCell;

- (void)configurePostCellWithUsername:(NSString *)username timestamp:(NSString *)timestamp isOwnVideo:(BOOL)isOwnVideo;
- (void)configureLikeCellWithUsername:(NSString *)username;
- (void)configureCommentCellWithUsername:(NSString *)username comment:(NSString *)comment;

@end
