//
//  CliqueTextField.m
//  Pic6
//
//  Created by Raj Vir on 8/14/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import "CliqueTextField.h"

@implementation CliqueTextField

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (instancetype)initWithPosition:(int)i {
    
    int size = 50;
    int top_padding = 8;
    int margin = 16;
    
    self = [self initWithFrame:CGRectMake(0, top_padding + (size + margin)*i, VIEW_WIDTH, size)];
    [self setBackgroundColor:[UIColor whiteColor]];
    [self setFont:[UIFont fontWithName:BIG_FONT size:18]];
    
    self.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"" attributes:@{NSForegroundColorAttributeName: [UIColor lightGrayColor], NSFontAttributeName: [UIFont fontWithName:BIG_FONT size:18]}];
    
    UIView *paddingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 12, 12)];
    [self setLeftViewMode:UITextFieldViewModeAlways];
    [self setLeftView:paddingView];
    
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
