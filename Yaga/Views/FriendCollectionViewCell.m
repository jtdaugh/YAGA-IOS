//
//  GroupListCell.m
//  Pic6
//
//  Created by Raj Vir on 11/9/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import "FriendCollectionViewCell.h"

@interface FriendCollectionViewCell ()

@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UILabel *vidCountLabel;
@property(nonatomic, strong) UIImageView *disclosureImageView;

@end

#define ACCESSORY_SIZE 18
#define VID_COUNT_WIDTH 70
#define LEFT_MARGIN 20
#define RIGHT_MARGIN 10
#define Y_MARGIN 12
#define NAME_HEIGHT 30
#define TOTAL_HEIGHT (Y_MARGIN*2 + NAME_HEIGHT)

@implementation FriendCollectionViewCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.selectedBackgroundView = [YAUtils createBackgroundViewWithFrame:self.bounds alpha:0.3];

        self.nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(LEFT_MARGIN, Y_MARGIN, [FriendCollectionViewCell maxNameWidth], NAME_HEIGHT)];
        [self.nameLabel setFont:[UIFont fontWithName:BOLD_FONT size:26]];
        self.nameLabel.textColor = PRIMARY_COLOR;
        self.nameLabel.adjustsFontSizeToFitWidth = YES;

        self.vidCountLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.frame.size.width - RIGHT_MARGIN - ACCESSORY_SIZE - 5 - VID_COUNT_WIDTH, (TOTAL_HEIGHT - ACCESSORY_SIZE)/2, VID_COUNT_WIDTH, ACCESSORY_SIZE)];
        self.vidCountLabel.textColor = PRIMARY_COLOR;
        self.vidCountLabel.font = [UIFont fontWithName:BIG_FONT size:16];
        self.vidCountLabel.textAlignment = NSTextAlignmentRight;
        self.vidCountLabel.adjustsFontSizeToFitWidth = YES;

        [self setBackgroundColor:[UIColor clearColor]];
                
        self.disclosureImageView = [[UIImageView alloc] initWithFrame:CGRectMake(self.frame.size.width - RIGHT_MARGIN - ACCESSORY_SIZE, (TOTAL_HEIGHT - ACCESSORY_SIZE)/2, ACCESSORY_SIZE, ACCESSORY_SIZE)];
        self.disclosureImageView.tintColor = PRIMARY_COLOR;
        [self.disclosureImageView setImage:[[UIImage imageNamed:@"Disclosure"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
        self.disclosureImageView.contentMode = UIViewContentModeScaleAspectFit;
        
        UIView *separatorView = [[UIView alloc] initWithFrame:CGRectMake(20, frame.size.height - 0.5, VIEW_WIDTH - 20, 0.5)];
//        separatorView.backgroundColor = [UIColor colorWithWhite:0.8 alpha:1];
        separatorView.backgroundColor = [PRIMARY_COLOR colorWithAlphaComponent:0.2];
        [self addSubview:separatorView];
        
        [self addSubview:self.nameLabel];
        [self addSubview:self.vidCountLabel];
        [self addSubview:self.disclosureImageView];
    }
    
    return self;
}


- (void)setVidCount:(NSUInteger)vidCount {
    self.vidCountLabel.text = [NSString stringWithFormat:@"%lu %@", vidCount, vidCount == 1 ? @"vid" : @"vids"];
}

- (void)setName:(NSString *)name {
    self.nameLabel.text = name;
}

- (void)setMuted:(BOOL)muted {
    self.nameLabel.textColor = muted ? [UIColor lightGrayColor] : PRIMARY_COLOR;
}

+ (CGFloat)maxNameWidth {
    return VIEW_WIDTH - LEFT_MARGIN - RIGHT_MARGIN - ACCESSORY_SIZE - VID_COUNT_WIDTH - 10.0f;
}

+ (CGFloat)cellHeight {
    return TOTAL_HEIGHT;
}

+ (CGSize)size {
    return  CGSizeMake(VIEW_WIDTH, 2*Y_MARGIN + NAME_HEIGHT);
}

@end
