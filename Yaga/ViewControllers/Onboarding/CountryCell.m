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
        self.selectedBackgroundView = [YAUtils createBackgroundViewWithFrame:self.bounds alpha:0.9];
    }
    return self;
}

@end
