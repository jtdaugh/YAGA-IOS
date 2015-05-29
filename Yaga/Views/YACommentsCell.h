//
//  YACommentsCell.h
//  Yaga
//
//  Created by Jesse on 5/29/15.
//  Copyright (c) 2015 Raj Vir. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface YACommentsCell : UITableViewCell

+ (CGFloat)heightForCellWithUsername:(NSString *)username comment:(NSString *)comment;

- (void)setUsername:(NSString *)username;
- (void)setComment:(NSString *)comment;

@end
