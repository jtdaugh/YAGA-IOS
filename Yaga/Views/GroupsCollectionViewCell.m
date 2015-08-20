//
//  GroupListCell.m
//  Pic6
//
//  Created by Raj Vir on 11/9/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import "GroupsCollectionViewCell.h"
#import "YAGroup.h"

@interface GroupsCollectionViewCell ()

// @property (nonatomic, strong) UILabel *groupEmoji;
@property (nonatomic, strong) UIImageView *groupEmoji;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UILabel *membersLabel;
@property (nonatomic, strong) UILabel *followerCountLabel;
@property(nonatomic, strong) UIImageView *disclosureImageView;

@end

#define ACCESSORY_SIZE 26
#define EMOJI_SIZE 36
#define LEFT_MARGIN 15
#define RIGHT_MARGIN 10
#define Y_MARGIN 20
#define NAME_HEIGHT 30
#define FOLLOWERS_HEIGHT 20
#define MEMBERS_HEIGHT 24
#define BETWEEN_MARGIN 5
#define TOTAL_HEIGHT (Y_MARGIN*2 + NAME_HEIGHT + MEMBERS_HEIGHT + BETWEEN_MARGIN)

@implementation GroupsCollectionViewCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.selectedBackgroundView = [YAUtils createBackgroundViewWithFrame:self.bounds alpha:0.3];

//        self.groupEmoji = [[UILabel alloc] initWithFrame:CGRectMake((LEFT_MARGIN - EMOJI_SIZE) / 2, (TOTAL_HEIGHT - EMOJI_SIZE) / 2, EMOJI_SIZE, EMOJI_SIZE)];
//       self.groupEmoji.textAlignment = NSTextAlignmentCenter;
//        self.groupEmoji.font = [UIFont systemFontOfSize:30];
        
        self.groupEmoji = [[UIImageView alloc] initWithFrame:CGRectMake((LEFT_MARGIN - EMOJI_SIZE) / 2, (TOTAL_HEIGHT - EMOJI_SIZE) / 2, EMOJI_SIZE, EMOJI_SIZE)];
        self.groupEmoji.contentMode = UIViewContentModeScaleAspectFit;
        
        self.nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(LEFT_MARGIN, Y_MARGIN, [GroupsCollectionViewCell contentWidth], NAME_HEIGHT)];
        [self.nameLabel setFont:[UIFont fontWithName:BOLD_FONT size:26]];
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
        
        self.followerCountLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.nameLabel.frame.origin.x,
                                                                           self.nameLabel.frame.size.height + Y_MARGIN + 2,
                                                                           self.nameLabel.frame.size.width,
                                                                           FOLLOWERS_HEIGHT)];
        [self.followerCountLabel setFont:[UIFont fontWithName:BOLD_FONT size:16]];
        
        [self setBackgroundColor:[UIColor clearColor]];
                
        self.disclosureImageView = [[UIImageView alloc] initWithFrame:CGRectMake(self.frame.size.width - RIGHT_MARGIN - ACCESSORY_SIZE, (TOTAL_HEIGHT - ACCESSORY_SIZE)/2, ACCESSORY_SIZE, ACCESSORY_SIZE)];
        [self.disclosureImageView setImage:[[UIImage imageNamed:@"Disclosure"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
        self.disclosureImageView.contentMode = UIViewContentModeScaleAspectFit;
        
//        [self addSubview:self.groupEmoji];
        [self addSubview:self.nameLabel];
        [self addSubview:self.membersLabel];
        [self addSubview:self.followerCountLabel];
        [self addSubview:self.disclosureImageView];
    }
    
    return self;
}

- (void)setGroup:(YAGroup *)group {
    if (_group == group) return;
    _group = group;
    self.nameLabel.text = group.name;
    [self updateColorsAndEmojisBasedGroupType];
    [self updateMembersAndFollowersString];
}


- (void)updateColorsAndEmojisBasedGroupType {
    UIColor *color;
    if(self.group.publicGroup) {
//        self.groupEmoji.text = self.group.amMember ? @"👑" : @"👀"; //@"🙉";
        if (self.group.amMember) {
            self.groupEmoji.image = [[UIImage imageNamed:@"Host"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        } else {
            self.groupEmoji.image = [UIImage imageNamed:@"Monkey"];
        }
        color = self.group.amMember ? HOSTING_GROUP_COLOR : PUBLIC_GROUP_COLOR;
    } else {
        self.groupEmoji.image = [[UIImage imageNamed:@"Private"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
//        self.groupEmoji.text = @"🔐"; // @"🙈";
        color = PRIVATE_GROUP_COLOR;
    }
    if (self.group.muted) color = MUTED_GROUP_COLOR;
    self.groupEmoji.tintColor = color;
    self.nameLabel.textColor = color;
    self.followerCountLabel.textColor = color;
    self.disclosureImageView.tintColor = color;
}

- (void)updateMembersAndFollowersString {
    if (self.group.publicGroup) {
        if (self.group.amMember) {
            NSString *string = self.group.membersString;
            if ([string isEqualToString:@"No members"]) {
                self.membersLabel.text = @"You're the only host";
            } else {
                self.membersLabel.text = [NSString stringWithFormat:@"Co-Hosts: %@", self.group.membersString];
            }
            self.followerCountLabel.text = [NSString stringWithFormat:@"HOST: %lu followers", self.group.followerCount];
        } else {
            self.membersLabel.text = [NSString stringWithFormat:@"Hosted by %@", self.group.membersString];
            self.followerCountLabel.text = [NSString stringWithFormat:@"%lu followers", self.group.followerCount];
        }
    } else {
        self.membersLabel.text = self.group.membersString;
        self.followerCountLabel.text = @"Private Group";
    }
    
    NSDictionary *attributes = @{NSFontAttributeName:[UIFont fontWithName:BIG_FONT size:14]};
    CGRect rect = [self.membersLabel.text boundingRectWithSize:CGSizeMake([GroupsCollectionViewCell contentWidth], CGFLOAT_MAX)
                                       options:NSStringDrawingUsesLineFragmentOrigin
                                    attributes:attributes
                                       context:nil];

    CGRect frame = self.membersLabel.frame;
    frame.origin.y = self.nameLabel.frame.size.height + Y_MARGIN + BETWEEN_MARGIN + FOLLOWERS_HEIGHT;
    frame.size.height = rect.size.height;
    self.membersLabel.frame = frame;
//    [self.membersLabel sizeToFit];
//    self.clipsToBounds = NO;

//    self.membersLabel.layer.borderColor = [[UIColor redColor] CGColor];
//    self.membersLabel.layer.borderWidth = 2;
}

+ (CGFloat)contentWidth {
    return VIEW_WIDTH - LEFT_MARGIN - RIGHT_MARGIN - ACCESSORY_SIZE - 5.0f;
}

+ (CGFloat)cellHeight {
    return TOTAL_HEIGHT;
}

+ (CGSize)sizeForGroup:(YAGroup *)group {
    if (group.publicGroup) {
        NSString *string = group.amMember ? [NSString stringWithFormat:@"Co-Hosts: %@", group.membersString] : [NSString stringWithFormat:@"Hosted by %@", group.membersString];
        NSDictionary *attributes = @{NSFontAttributeName:[UIFont fontWithName:BIG_FONT size:14]};
        CGRect rect = [string boundingRectWithSize:CGSizeMake([GroupsCollectionViewCell contentWidth], CGFLOAT_MAX)
                                           options:NSStringDrawingUsesLineFragmentOrigin
                                        attributes:attributes
                                           context:nil];
        
        return CGSizeMake(VIEW_WIDTH, rect.size.height + 2*Y_MARGIN + NAME_HEIGHT + FOLLOWERS_HEIGHT + BETWEEN_MARGIN);
    } else {
    
    NSDictionary *attributes = @{NSFontAttributeName:[UIFont fontWithName:BIG_FONT size:14]};
    CGRect rect = [group.membersString boundingRectWithSize:CGSizeMake([GroupsCollectionViewCell contentWidth], CGFLOAT_MAX)
                                              options:NSStringDrawingUsesLineFragmentOrigin
                                           attributes:attributes
                                              context:nil];
    
    return CGSizeMake(VIEW_WIDTH, rect.size.height + 2*Y_MARGIN + NAME_HEIGHT + BETWEEN_MARGIN);
    }
}

@end
