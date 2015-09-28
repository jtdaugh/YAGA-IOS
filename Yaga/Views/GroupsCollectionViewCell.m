//
//  GroupListCell.m
//  Pic6
//
//  Created by Raj Vir on 11/9/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import "GroupsCollectionViewCell.h"

@interface GroupsCollectionViewCell ()

@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UILabel *membersLabel;
@property(nonatomic, strong) UIImageView *disclosureImageView;
@property (nonatomic, strong) UIView *separatorView;

@end

#define ACCESSORY_SIZE 26
#define LEFT_MARGIN 20
#define RIGHT_MARGIN 10
#define Y_MARGIN 12
#define NAME_HEIGHT 30
#define MEMBERS_HEIGHT 24
#define BETWEEN_MARGIN 5
#define TOTAL_HEIGHT (Y_MARGIN*2 + NAME_HEIGHT + MEMBERS_HEIGHT + BETWEEN_MARGIN)

@implementation GroupsCollectionViewCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.selectedBackgroundView = [YAUtils createBackgroundViewWithFrame:self.bounds alpha:0.3];

        self.nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(LEFT_MARGIN, Y_MARGIN, [GroupsCollectionViewCell contentWidth], NAME_HEIGHT)];
        [self.nameLabel setFont:[UIFont fontWithName:BOLD_FONT size:26]];
        self.nameLabel.textColor = PRIMARY_COLOR;
        self.nameLabel.adjustsFontSizeToFitWidth = YES;

        self.membersLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.nameLabel.frame.origin.x,
                                                                     self.nameLabel.frame.size.height + Y_MARGIN + BETWEEN_MARGIN,
                                                                     self.nameLabel.frame.size.width,
                                                                     MEMBERS_HEIGHT)];
        self.membersLabel.numberOfLines = 0;
        self.membersLabel.lineBreakMode = NSLineBreakByWordWrapping;
//        self.membersLabel.adjustsFontSizeToFitWidth = YES;
        self.membersLabel.minimumScaleFactor = 0.7;
        [self.membersLabel setFont:[UIFont fontWithName:BIG_FONT size:14]];
        [self.membersLabel setBackgroundColor:[UIColor clearColor]];
        self.membersLabel.layer.masksToBounds = NO;
        
        [self setBackgroundColor:[UIColor clearColor]];
                
        self.disclosureImageView = [[UIImageView alloc] initWithFrame:CGRectMake(self.frame.size.width - RIGHT_MARGIN - ACCESSORY_SIZE, (TOTAL_HEIGHT - ACCESSORY_SIZE)/2, ACCESSORY_SIZE, ACCESSORY_SIZE)];
        self.disclosureImageView.tintColor = PRIMARY_COLOR;
        [self.disclosureImageView setImage:[[UIImage imageNamed:@"Disclosure"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
        self.disclosureImageView.contentMode = UIViewContentModeScaleAspectFit;
        
        self.separatorView = [[UIView alloc] initWithFrame:CGRectMake(20, frame.size.height - 0.5, VIEW_WIDTH - 20, 0.5)];
        self.separatorView.backgroundColor = [UIColor colorWithWhite:0.8 alpha:1];
        [self addSubview:self.separatorView];
        
        [self addSubview:self.nameLabel];
        [self addSubview:self.membersLabel];
        [self addSubview:self.disclosureImageView];
    }
    
    return self;
}

- (void)setGroupName:(NSString *)groupName {
    self.nameLabel.text = groupName;
//    self.nameLabel.layer.borderColor = [[UIColor redColor] CGColor];
//    self.nameLabel.layer.borderWidth = 2;

}

- (void)setPublicGroup:(BOOL)publicGroup {
    CGFloat indicatorSize = 10;
    UIImage *img;
    if(publicGroup){

        self.nameLabel.textColor = SECONDARY_COLOR;
        self.disclosureImageView.tintColor = SECONDARY_COLOR;
        
        img = [YAUtils imageWithColor:[SECONDARY_COLOR colorWithAlphaComponent:1.0]];

    } else {
        self.nameLabel.textColor = PRIMARY_COLOR;
        self.disclosureImageView.tintColor = PRIMARY_COLOR;
        img = [YAUtils imageWithColor:[PRIMARY_COLOR colorWithAlphaComponent:1.0]];
    }
}

- (void)setMembersString:(NSString *)membersString {
    self.membersLabel.text = membersString;
    NSDictionary *attributes = @{NSFontAttributeName:[UIFont fontWithName:BIG_FONT size:14]};
    CGRect rect = [membersString boundingRectWithSize:CGSizeMake([GroupsCollectionViewCell contentWidth], CGFLOAT_MAX)
                                       options:NSStringDrawingUsesLineFragmentOrigin
                                    attributes:attributes
                                       context:nil];

    CGRect frame = self.membersLabel.frame;
    frame.size.height = rect.size.height;
    self.membersLabel.frame = frame;
    
    self.separatorView.frame = CGRectMake(20, frame.origin.y + frame.size.height + Y_MARGIN - 0.5, VIEW_WIDTH - 20, 0.5);
    
//    [self.membersLabel sizeToFit];
//    self.clipsToBounds = NO;

//    self.membersLabel.layer.borderColor = [[UIColor redColor] CGColor];
//    self.membersLabel.layer.borderWidth = 2;
}

- (void)setMuted:(BOOL)muted {
    self.membersLabel.textColor = muted ? [UIColor lightGrayColor] : [UIColor colorWithWhite:0.1 alpha:1];
    self.nameLabel.textColor = muted ? [UIColor lightGrayColor] : PRIMARY_COLOR;
}

+ (CGFloat)contentWidth {
    return VIEW_WIDTH - LEFT_MARGIN - RIGHT_MARGIN - ACCESSORY_SIZE - 5.0f;
}

+ (CGFloat)cellHeight {
    return TOTAL_HEIGHT;
}

+ (CGSize)sizeForMembersString:(NSString *)string {
    NSDictionary *attributes = @{NSFontAttributeName:[UIFont fontWithName:BIG_FONT size:14]};
    CGRect rect = [string boundingRectWithSize:CGSizeMake([GroupsCollectionViewCell contentWidth], CGFLOAT_MAX)
                                              options:NSStringDrawingUsesLineFragmentOrigin
                                           attributes:attributes
                                              context:nil];
    if (!string.length) {
        return  CGSizeMake(VIEW_WIDTH, 2*Y_MARGIN + NAME_HEIGHT);
    }
    return CGSizeMake(VIEW_WIDTH, rect.size.height + 2*Y_MARGIN + NAME_HEIGHT + BETWEEN_MARGIN);
}

@end
