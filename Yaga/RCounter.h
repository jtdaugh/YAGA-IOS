//
//  RCounter.h
//  Version 0.1
//
//
//  Created by Ans Riaz on 12/12/13.
//  Copyright (c) 2013 Rizh. All rights reserved.
//
//  Have fun :-)

#import <UIKit/UIKit.h>

@interface RCounter : UIControl

@property (nonatomic, readonly) int currentReading;

// The overall frame will grow to the right from this origin.
// The frame is 23 points tall and 15 points per digit wide
- (id)initWithValue:(int)value origin:(CGPoint)origin;

- (void)updateValue:(int)newValue animate:(BOOL)animate;

@end
