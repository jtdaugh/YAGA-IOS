//
//  GroupListCell.m
//  Pic6
//
//  Created by Raj Vir on 11/9/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import "GroupsTableViewCell.h"

@interface GroupsTableViewCell ()
@property(nonatomic, strong) UIButton *accessorryButton;
@end

#define accessoryHeight 44
#define xMargin 0
#define subtitleDefaultHeight 18
#define between_margin 4

#define imageViewWidth 10

@implementation GroupsTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier];
    
    if (self) {
        CGRect frame = self.frame;
        frame.size.width = VIEW_WIDTH;
        frame.size.height = 54;
        
        self.textLabel.frame = CGRectMake(xMargin, 0, [GroupsTableViewCell contentWidth], self.frame.size.height - subtitleDefaultHeight - between_margin);
        [self.textLabel setClipsToBounds:NO];
        [self.textLabel setFont:[UIFont fontWithName:BIG_FONT size:28]];
        self.textLabel.textColor = PRIMARY_COLOR;
        
        self.detailTextLabel.frame = CGRectMake(self.textLabel.frame.origin.x, self.textLabel.frame.size.height + between_margin, [GroupsTableViewCell contentWidth], subtitleDefaultHeight);
        
        [self.detailTextLabel setFont:[GroupsTableViewCell defaultDetailedLabelFont]];
        self.detailTextLabel.numberOfLines = 0;
        [self.detailTextLabel setTextColor:PRIMARY_COLOR];
        [self.detailTextLabel setBackgroundColor:[UIColor clearColor]];

        [self setBackgroundColor:[UIColor clearColor]];
        self.textLabel.adjustsFontSizeToFitWidth = YES;
        
        self.accessorryButton = [UIButton buttonWithType:UIButtonTypeCustom];
        self.accessorryButton.frame = CGRectMake(self.frame.size.width - xMargin - accessoryHeight, (self.frame.size.height - accessoryHeight)/2, accessoryHeight, accessoryHeight);
        [self.accessorryButton setBackgroundImage:[UIImage imageNamed:@"Info"] forState:UIControlStateNormal];
        self.accessoryView = self.accessorryButton;
        
        [self.accessorryButton addTarget:self action:@selector(showGroupOptions:) forControlEvents:UIControlEventTouchUpInside];
        
        self.imageView.clipsToBounds = YES;
        self.imageView.layer.cornerRadius = imageViewWidth/2;
        
        self.imageView.contentMode = UIViewContentModeScaleAspectFit;
    }
    
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    [self.detailTextLabel sizeToFit];
    
    self.imageView.frame = CGRectMake(0, self.bounds.size.height/2 - imageViewWidth/2, imageViewWidth, imageViewWidth);
    self.clipsToBounds = NO;
}

- (void)showGroupOptions:(id)sender {
    if(self.editBlock)
        self.editBlock();
}

- (void)willTransitionToState:(UITableViewCellStateMask)state{
    [super willTransitionToState:state];
    
    BOOL hide = ((state & UITableViewCellStateShowingDeleteConfirmationMask) == UITableViewCellStateShowingDeleteConfirmationMask);
    self.accessoryView.hidden = hide;
}

+ (CGFloat)contentWidth {
    return VIEW_WIDTH-xMargin*2-accessoryHeight;
}

+ (UIFont*)defaultDetailedLabelFont {
    return [UIFont fontWithName:BIG_FONT size:14];
}


@end
