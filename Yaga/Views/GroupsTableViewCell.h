//
//  GroupsTableViewCell.h
//  
//
//  Created by valentinkovalski on 6/22/15.
//
//

#import <UIKit/UIKit.h>

typedef void (^editButtonClickedBlock)(void);

@interface GroupsTableViewCell : UITableViewCell

@property (nonatomic, copy) editButtonClickedBlock editBlock;

+ (CGFloat)contentWidth;
+ (UIFont*)defaultDetailedLabelFont;
@end
