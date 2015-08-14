//
//  YAPostGroupCell.m
//  Yaga
//
//  Created by valentinkovalski on 8/14/15.
//  Copyright © 2015 Raj Vir. All rights reserved.
//

#import "YAPostGroupCell.h"

#define kSelectionBorder 3

@implementation YAPostGroupCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if(self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.textLabel.backgroundColor = [UIColor clearColor];
        self.textLabel.font = [UIFont fontWithName:BOLD_FONT size:30];
    }
    return self;
}
- (void)setSelectionColor:(UIColor*)color {
    _selectionColor = color;
    
    //selected
    self.selectedBackgroundView = [[UIView alloc] initWithFrame:self.bounds];
    self.selectedBackgroundView.backgroundColor = [UIColor whiteColor];
    UIView *colorView = [[UIView alloc] initWithFrame:CGRectMake(kSelectionBorder, kSelectionBorder, self.bounds.size.width - kSelectionBorder * 2, self.bounds.size.height - kSelectionBorder * 2)];
    [self.selectedBackgroundView addSubview:colorView];
    colorView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    colorView.backgroundColor = color;
    

    //not selected
    self.backgroundView = [[UIView alloc] initWithFrame:self.bounds];
    self.backgroundView.backgroundColor = [UIColor whiteColor];
    colorView = [[UIView alloc] initWithFrame:CGRectMake(kSelectionBorder, kSelectionBorder, self.bounds.size.width - kSelectionBorder * 2, self.bounds.size.height - kSelectionBorder * 2)];
    [self.backgroundView addSubview:colorView];
    colorView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    colorView.backgroundColor = color;
    UIView *whiteView = [[UIView alloc] initWithFrame:CGRectMake(kSelectionBorder, kSelectionBorder, colorView.bounds.size.width - kSelectionBorder * 2, colorView.bounds.size.height - kSelectionBorder * 2)];
    [colorView addSubview:whiteView];
    whiteView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    whiteView.backgroundColor = [UIColor whiteColor];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    
    self.accessoryView = selected ? [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Checkmark"]]
                                    : nil;
    self.textLabel.textColor = selected ? [UIColor whiteColor] : self.selectionColor;
}
@end
