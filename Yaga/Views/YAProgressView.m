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

- (void)setProgress:(CGFloat)progress animated:(BOOL)animated {
    if(progress == 0) {
        progress = 0.75;
        [self enableIndeterminateMode:YES];
        [super setProgress:progress animated:NO];
    }
    else {
        [self enableIndeterminateMode:NO];
        [super setProgress:progress animated:animated];
    }
}

- (void)enableIndeterminateMode:(BOOL)enable {
    if(enable) {
        CABasicAnimation* animation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
        animation.fromValue = [NSNumber numberWithFloat:0.0f];
        animation.toValue = [NSNumber numberWithFloat: 2*M_PI];
        animation.duration = 3.0f;
        animation.repeatCount = HUGE_VAL;
        [self.backgroundView.layer addAnimation:animation forKey:@"Rotation"];
    }
    else {
        [self.backgroundView.layer removeAllAnimations];
    }
}

- (void)configureIndeterminatePercent:(CGFloat)percent {
    self.progressLayer.strokeStart = 0.0;
    self.progressLayer.strokeEnd = percent;
}

@end
