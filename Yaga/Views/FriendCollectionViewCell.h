//
//  GroupListCell.h
//  Pic6
//
//  Created by Raj Vir on 11/9/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface FriendCollectionViewCell : UICollectionViewCell

@property (nonatomic, strong) NSString *name;
@property (nonatomic) BOOL muted;

+ (CGFloat)cellHeight;
+ (CGFloat)contentWidth;

+ (CGSize)size;

@end
