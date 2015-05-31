//
//  YACommentsCell.h
//  Yaga
//
//  Created by Jesse on 5/29/15.
//  Copyright (c) 2015 Raj Vir. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, YACommentsCellType) {
    YACommentsCellTypeComment,
    YACommentsCellTypePost,
};

@interface YACommentsCell : UITableViewCell

+ (CGFloat)heightForCommentCellWithUsername:(NSString *)username comment:(NSString *)comment;
+ (CGFloat)heightForPostCellWithUsername:(NSString *)username timestamp:(NSString *)timestamp;

- (void)setUsername:(NSString *)username;
- (void)setComment:(NSString *)comment;
- (void)setTimestamp:(NSString *)timestamp;
- (void)setCellType:(YACommentsCellType)cellType;

@end
