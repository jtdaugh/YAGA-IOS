//
//  CountryCell.m
//  Country List
//
//  Created by Pradyumna Doddala on 21/12/13.
//  Copyright (c) 2013 Pradyumna Doddala. All rights reserved.
//

#import "CountryCell.h"
#import "YAUtils.h"

@implementation CountryCell

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if(self) {
        self.contentView.backgroundColor = [UIColor blackColor];
        self.textLabel.textColor = [UIColor whiteColor];
        self.selectedBackgroundView = [YAUtils createBackgroundViewForCell:self alpha:0.9];
    }
    return self;
}

//- (void)setSelected:(BOOL)selected animated:(BOOL)animated
//{
//    [super setSelected:selected animated:animated];
//
//    // Configure the view for the selected state
//    
//    if (selected) {
//        self.accessoryType = UITableViewCellAccessoryCheckmark;
//    } else {
//        self.accessoryType = UITableViewCellAccessoryNone;
//    }
//}

@end
