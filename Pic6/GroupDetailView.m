//
//  GroupDetailView.m
//  Pic6
//
//  Created by Veeral Patel on 9/1/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import "GroupDetailView.h"

@implementation GroupDetailView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.58f];
        self.alpha = 0;
        self.font = [UIFont fontWithName:@"Avenir-Heavy" size:33.0f];
        self.textColor = [UIColor whiteColor];
        self.textAlignment = NSTextAlignmentCenter;
    }
    return self;
}

- (void)setInfo:(GroupInfo *)info {
    _info = info;
    
    NSString *groupString = [NSString stringWithFormat:@"%@\n\n•%@", info.name, [info.members componentsJoinedByString:@"\n•"]];
    
    self.text = groupString;
}

- (void)flash {
    self.alpha = 1.0f;
    [self performSelector:@selector(hide) withObject:nil afterDelay:0.5];
}

- (void)hide {
    self.alpha = 0;
}

@end
