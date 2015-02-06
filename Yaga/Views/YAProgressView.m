//
//  YAProgressView.m
//  Yaga
//
//  Created by valentinkovalski on 2/3/15.
//  Copyright (c) 2015 Raj Vir. All rights reserved.
//

#import "YAProgressView.h"

@implementation YAProgressView

- (UILabel *)textLabel {
    UILabel *result = [super textLabel];
    result.minimumScaleFactor = 0.3;
    result.adjustsFontSizeToFitWidth = YES;
    result.font = [UIFont fontWithName:@"AvenirNext-Medium" size:self.radius];
    result.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
    
    return result;
}

- (void)setCustomText:(NSString*)text {
    self.textLabel.text = text;
    
    NSDictionary *attributes = @{NSFontAttributeName:self.textLabel.font};
    CGFloat width = self.radius*2 - 10;
    CGRect rect = [self.textLabel.text boundingRectWithSize:CGSizeMake(width, width)
                                                    options:NSStringDrawingUsesLineFragmentOrigin
                                                 attributes:attributes
                                                    context:nil];
    self.textLabel.frame = CGRectMake(self.bounds.size.width/2 - rect.size.width/2, self.bounds.size.height/2 - rect.size.height/2, rect.size.width, rect.size.height);
}

- (void)layoutTextLabel {
    self.textLabel.hidden = NO;
    self.textLabel.textColor = self.textColor ?: self.tintColor;
}

@end
