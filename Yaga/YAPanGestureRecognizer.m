//
//  YAPanGestureRecognizer.m
//  Yaga
//
//  Created by Jesse on 4/28/15.
//  Copyright (c) 2015 Raj Vir. All rights reserved.
//

#import "YAPanGestureRecognizer.h"

@implementation YAPanGestureRecognizer

#pragma mark - UIGestureRecognizerSubclass Methods

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event;
{ [super touchesBegan:touches withEvent:event ]; }

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self setState:UIGestureRecognizerStateChanged ];
    [super touchesMoved:touches withEvent:event ];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{ [super touchesEnded:touches withEvent:event ]; }

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{ [super touchesCancelled:touches withEvent:event ]; }


@end
