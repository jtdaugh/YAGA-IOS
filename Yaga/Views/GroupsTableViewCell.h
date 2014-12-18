//
//  GroupListCell.h
//  Pic6
//
//  Created by Raj Vir on 11/9/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void (^editButtonClickedBlock)(void);

@interface GroupsTableViewCell : UITableViewCell

@property (nonatomic, copy) editButtonClickedBlock editBlock;

@end
