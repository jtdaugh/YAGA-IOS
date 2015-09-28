//
//  GroupListCell.h
//  Pic6
//
//  Created by Raj Vir on 11/9/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void (^editButtonClickedBlock)(void);

@interface GroupsCollectionViewCell : UICollectionViewCell

@property (nonatomic, copy) editButtonClickedBlock editBlock;

@property (nonatomic, strong) NSString *groupName;
@property (nonatomic, strong) NSString *membersString;
@property (nonatomic, strong) NSString *accessoryString;
@property (nonatomic) BOOL muted;
@property (nonatomic) BOOL publicGroup;

+ (CGFloat)cellHeight;

+ (CGSize) sizeForMembersString:(NSString *)string;

@end
