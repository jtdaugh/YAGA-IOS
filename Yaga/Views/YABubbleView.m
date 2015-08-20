//
//  YABubbleView.m
//  Yaga
//
//  Created by valentinkovalski on 8/19/15.
//  Copyright © 2015 Raj Vir. All rights reserved.
//

#import "YABubbleView.h"

#define strokeWidth 0
#define borderRadius 7
#define WIDTHOFPOPUPTRIANGLE 30
#define HEIGHTOFPOPUPTRIANGLE 10

@implementation YABubbleView


- (void)drawRect:(CGRect)rect {
    CGRect currentFrame = self.bounds;
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetLineJoin(context, kCGLineJoinRound);
    CGContextSetLineWidth(context, strokeWidth);
    CGContextSetStrokeColorWithColor(context, [PRIMARY_COLOR CGColor]);
    CGContextSetFillColorWithColor(context, [[PRIMARY_COLOR colorWithAlphaComponent:0.9] CGColor]);
    
    CGContextBeginPath(context);
    if(self.arrowDirectionUp) {
        CGContextMoveToPoint(context, borderRadius + strokeWidth + 0.5f, strokeWidth + HEIGHTOFPOPUPTRIANGLE + 0.5f);
        CGContextAddLineToPoint(context, round(self.arrowXPosition - WIDTHOFPOPUPTRIANGLE/2 ) + 0.5f, HEIGHTOFPOPUPTRIANGLE + strokeWidth + 0.5f);
        CGContextAddLineToPoint(context, round(self.arrowXPosition) + 0.5f, strokeWidth + 0.5f);
        
        CGContextAddLineToPoint(context, round(self.arrowXPosition) + WIDTHOFPOPUPTRIANGLE/2 + 0.5f, HEIGHTOFPOPUPTRIANGLE + strokeWidth + 0.5f);
        CGContextAddArcToPoint(context, currentFrame.size.width - strokeWidth - 0.5f, strokeWidth + HEIGHTOFPOPUPTRIANGLE + 0.5f, currentFrame.size.width - strokeWidth - 0.5f, currentFrame.size.height - strokeWidth - 0.5f, borderRadius - strokeWidth);
        CGContextAddArcToPoint(context, currentFrame.size.width - strokeWidth - 0.5f, currentFrame.size.height - strokeWidth - 0.5f, round(self.arrowXPosition + WIDTHOFPOPUPTRIANGLE / 2.0f) - strokeWidth + 0.5f, currentFrame.size.height - strokeWidth - 0.5f, borderRadius - strokeWidth);
        CGContextAddArcToPoint(context, strokeWidth + 0.5f, currentFrame.size.height - strokeWidth - 0.5f, strokeWidth + 0.5f, HEIGHTOFPOPUPTRIANGLE + strokeWidth + 0.5f, borderRadius - strokeWidth);
        CGContextAddArcToPoint(context, strokeWidth + 0.5f, strokeWidth + HEIGHTOFPOPUPTRIANGLE + 0.5f, currentFrame.size.width - strokeWidth - 0.5f, HEIGHTOFPOPUPTRIANGLE + strokeWidth + 0.5f, borderRadius - strokeWidth);
        CGContextClosePath(context);
        CGContextDrawPath(context, kCGPathFillStroke);
    }
    else {
        CGContextMoveToPoint(context, borderRadius + strokeWidth + 0.5f, strokeWidth + 0.5f);
        CGContextAddLineToPoint(context, currentFrame.size.width - borderRadius - strokeWidth + 0.5f, strokeWidth + 0.5f);
        CGContextAddArcToPoint(context, currentFrame.size.width - strokeWidth - 0.5f, strokeWidth + 0.5f, currentFrame.size.width - strokeWidth - 0.5f, currentFrame.size.height - strokeWidth - HEIGHTOFPOPUPTRIANGLE - 0.5f, borderRadius - strokeWidth);
        CGContextAddArcToPoint(context, currentFrame.size.width - strokeWidth - 0.5f, currentFrame.size.height - strokeWidth - HEIGHTOFPOPUPTRIANGLE - 0.5f, round(self.arrowXPosition + WIDTHOFPOPUPTRIANGLE / 2.0f) - strokeWidth + 0.5f, currentFrame.size.height - strokeWidth - HEIGHTOFPOPUPTRIANGLE - 0.5f, borderRadius - strokeWidth);
        
        CGContextAddLineToPoint(context, round(self.arrowXPosition + WIDTHOFPOPUPTRIANGLE/2 ) + 0.5f, currentFrame.size.height - strokeWidth - HEIGHTOFPOPUPTRIANGLE + 0.5f);
        
        CGContextAddLineToPoint(context, round(self.arrowXPosition) + 0.5f, currentFrame.size.height - strokeWidth + 0.5f);
        CGContextAddLineToPoint(context, round(self.arrowXPosition - WIDTHOFPOPUPTRIANGLE/2 ) + 0.5f, currentFrame.size.height - strokeWidth - HEIGHTOFPOPUPTRIANGLE + 0.5f);
        CGContextAddLineToPoint(context, borderRadius + strokeWidth + 0.5f, currentFrame.size.height - strokeWidth - HEIGHTOFPOPUPTRIANGLE + 0.5f);
        CGContextAddArcToPoint(context, strokeWidth + 0.5f, currentFrame.size.height - HEIGHTOFPOPUPTRIANGLE - strokeWidth - 0.5f, strokeWidth - HEIGHTOFPOPUPTRIANGLE + 0.5f, strokeWidth + 0.5f, borderRadius - strokeWidth);
        CGContextAddArcToPoint(context, strokeWidth + 0.5f, strokeWidth + 0.5f, currentFrame.size.width - strokeWidth - 0.5f, strokeWidth + 0.5f, borderRadius - strokeWidth);
        
        CGContextClosePath(context);
        CGContextDrawPath(context, kCGPathFillStroke);
    }
    
    // Draw a clipping path for the fill
    //    CGContextBeginPath(context);
    //    CGContextMoveToPoint(context, borderRadius + strokeWidth + 0.5f, round((currentFrame.size.height + HEIGHTOFPOPUPTRIANGLE) * 0.50f) + 0.5f);
    //    CGContextAddArcToPoint(context, currentFrame.size.width - strokeWidth - 0.5f, round((currentFrame.size.height + HEIGHTOFPOPUPTRIANGLE) * 0.50f) + 0.5f, currentFrame.size.width - strokeWidth - 0.5f, currentFrame.size.height - strokeWidth - 0.5f, borderRadius - strokeWidth);
    //    CGContextAddArcToPoint(context, currentFrame.size.width - strokeWidth - 0.5f, currentFrame.size.height - strokeWidth - 0.5f, round(self.arrowXPosition + WIDTHOFPOPUPTRIANGLE / 2.0f) - strokeWidth + 0.5f, currentFrame.size.height - strokeWidth - 0.5f, borderRadius - strokeWidth);
    //    CGContextAddArcToPoint(context, strokeWidth + 0.5f, currentFrame.size.height - strokeWidth - 0.5f, strokeWidth + 0.5f, HEIGHTOFPOPUPTRIANGLE + strokeWidth + 0.5f, borderRadius - strokeWidth);
    //    CGContextAddArcToPoint(context, strokeWidth + 0.5f, round((currentFrame.size.height + HEIGHTOFPOPUPTRIANGLE) * 0.50f) + 0.5f, currentFrame.size.width - strokeWidth - 0.5f, round((currentFrame.size.height + HEIGHTOFPOPUPTRIANGLE) * 0.50f) + 0.5f, borderRadius - strokeWidth);
    //    CGContextClosePath(context);
    //    CGContextClip(context);
}
@end
