//
//  RCounter.m
//  Version 0.1
//
//
//  Created by Ans Riaz on 12/12/13.
//  Copyright (c) 2013 Rizh. All rights reserved.
//
//  Have fun :-)

#import "RCounter.h"

#define kCounterDigitSpriteSpacing 23.0
#define kCounterDigitXSpacing 12.0

// Golden ratio wattup
#define kCounterAnimationDuration 0.1618

@interface RCounter ()

@property (nonatomic) int digits;
@property (nonatomic) CGFloat topDigitCenterY;
@property (nonatomic, strong) NSMutableArray *imgArray;
@property (nonatomic, readwrite) int currentReading;
@property (nonatomic, strong) UIView *counterCanvas;
@end

@implementation RCounter {
    int tagCounterRightToLeft;
    int tagCounterLeftToRight;
}

- (id)initWithValue:(int)value origin:(CGPoint)origin {
    int initialDigits = [RCounter numDigits:value];
    CGRect frame = CGRectMake(origin.x, origin.y, 150, kCounterDigitSpriteSpacing);
    self = [super initWithFrame:frame];
    if (self) {
        _digits = initialDigits;
        self.imgArray = [NSMutableArray array];

        [self setBackgroundColor:[UIColor clearColor]];
        
        // Load the counters
        self.counterCanvas = [[UIView alloc] initWithFrame:self.bounds];
        CGRect frame = CGRectMake(0, 0, 17.0, 299.0);
        for (int i = 0; i < self.digits; i++) {
            UIImageView *img = [[UIImageView alloc] initWithFrame:frame];
            [img setImage:[UIImage imageNamed:@"counter-numbers.png"]];
            self.topDigitCenterY = img.center.y;

            [self.imgArray addObject:img];
            [self.counterCanvas addSubview:img];
            frame.origin.x += kCounterDigitXSpacing;
        }
        
        [self.counterCanvas.layer setMasksToBounds:YES];
        [self addSubview:self.counterCanvas];
        
        // Set the current reading
        self.currentReading = value;
    }
    
    return self;
}

- (void)updateValue:(int)newValue animate:(BOOL)animate {

    // Only do something if it is different
    if (newValue == self.currentReading)
        return;
    
    [self adjustForNumberOfDigits:[RCounter numDigits:newValue]];
    
    
//    // Work out the digits
//    int hthousandth = (newValue % 1000000)/100000;
//    int tenthounsandth = (newValue % 100000) / 10000;
//    int thounsandth = (newValue % 10000)/1000;
//    int hundredth = (newValue % 1000)/ 100;
//    int ten = (newValue % 100) / 10;
//    int unit = newValue % 10;

    for (int i = 0; i < self.digits; i++) {
        UIImageView *img = self.imgArray[i];
        
        CGRect imgFrame = img.frame;
        CGPoint imgCenter = img.center;
        
        int digitMag = 1;
        for (int j = i+1; j < self.digits; j++) {
            digitMag *= 10;
        }
        
        int digitVal = (newValue % (digitMag * 10) / digitMag);
        
        imgFrame.origin.y = 0 - ((digitVal + 1) * kCounterDigitSpriteSpacing);
        imgCenter.y = self.topDigitCenterY - ((digitVal + 1) * kCounterDigitSpriteSpacing);
        
        BOOL imgChanged = NO;
        
        if (imgFrame.origin.y != img.frame.origin.y) {
            imgChanged = YES;
        }
        if (imgChanged) {
            [self updateFrame:img withValue:digitVal andImageCentre:imgCenter];
        }
    }

    self.currentReading = newValue;
}



- (void)updateFrame:(UIImageView*)img withValue:(long)newValue andImageCentre:(CGPoint)imgCentre {
    CALayer *presLayer = (CALayer *)img.layer.presentationLayer;

    CABasicAnimation *anim = [CABasicAnimation animationWithKeyPath:@"position"];
    if (newValue == 0) {
        // Jump instantly to first 9 and then animate to 0
        CGPoint nine = imgCentre;
        nine.y += kCounterDigitSpriteSpacing;
        anim.fromValue = [NSValue valueWithCGPoint:nine];
    } else {
        anim.fromValue = [NSValue valueWithCGPoint:[presLayer position]];
    }
    anim.toValue = [NSValue valueWithCGPoint:imgCentre];
    anim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    anim.duration = kCounterAnimationDuration;
    img.layer.position = [presLayer position];
    if (newValue != 0) {
        [img.layer removeAllAnimations];
    }
    [img.layer addAnimation:anim forKey:@"rollLeft"];

    img.center = imgCentre;
}

// Will add/subtract digits from the front/left side of the counter, and shift existing digits accordingly.
- (void)adjustForNumberOfDigits:(int)numDigits {
    int delta = numDigits - self.digits;
    self.digits = numDigits;
    if (!delta) return;
    if (delta > 0) {
        // add digits at beginning.
        
        // Shift existing digits
        for (UIImageView *img in self.imgArray) {
            CGPoint newCenter = img.center;
            CGRect newFrame = img.frame;
            newFrame.origin.x = newFrame.origin.x += delta * kCounterDigitXSpacing;
            newCenter.x += delta * kCounterDigitXSpacing;
            
            CABasicAnimation *anim = [CABasicAnimation animationWithKeyPath:@"position"];
//            anim.fromValue = [NSValue valueWithCGPoint:img.center];
            anim.toValue = [NSValue valueWithCGPoint:newCenter];
            anim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
            anim.duration = kCounterAnimationDuration;
            [img.layer addAnimation:anim forKey:@"shiftRight"];
            img.frame = newFrame;
        }
        
        // Add new digits
        CGRect frame = CGRectMake(kCounterDigitXSpacing * (delta - 1), 0, 17.0, 299.0);
        for (int i = delta - 1; i >= 0; i--) {
            UIImageView *img = [[UIImageView alloc] initWithFrame:frame];
            [img setImage:[UIImage imageNamed:@"counter-numbers.png"]];

            [self.imgArray insertObject:img atIndex:0];
            [self.counterCanvas addSubview:img];
            frame.origin.x -= kCounterDigitXSpacing;
        }
    } else {
        delta *= -1;
        // remove digits from beginning
        for (int i = 0; i < delta; i++) {
            UIImageView *img = self.imgArray[0];
            [img removeFromSuperview];
            [self.imgArray removeObjectAtIndex:0];
        }
        
        // Shift existing digits
        for (UIImageView *img in self.imgArray) {
            CGPoint newCenter = img.center;
            CGRect newFrame = img.frame;
            newFrame.origin.x = newFrame.origin.x -= delta * kCounterDigitXSpacing;
            newCenter.x -= delta * kCounterDigitXSpacing;
            
            CABasicAnimation *anim = [CABasicAnimation animationWithKeyPath:@"position"];
//            anim.fromValue = [NSValue valueWithCGPoint:img.center];
            anim.toValue = [NSValue valueWithCGPoint:newCenter];
            anim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
            anim.duration = kCounterAnimationDuration;
            [img.layer addAnimation:anim forKey:@"shiftLeft"];
            img.frame = newFrame;
        }
    }
}

+ (int)numDigits:(int)value {
    int digits = 1;
    while ( value /= 10 )
        digits++;
    return digits;
}

@end
