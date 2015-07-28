//
//  YAApplyCaptionView.h
//  Yaga
//
//  Created by Christopher Wendel on 7/16/15.
//  Copyright (c) 2015 Raj Vir. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void (^YACaptionViewCompletionHandler)(BOOL completed, UIView *captionView, UITextView *captionTextView, NSString *text, CGFloat x, CGFloat y, CGFloat scale, CGFloat rotation);

@interface YAApplyCaptionView : UIView

- (instancetype)initWithFrame:(CGRect)frame captionPoint:(CGPoint)captionPoint initialText:(NSString *)initialText initialTransform:(CGAffineTransform)initialTransform;

@property (nonatomic, copy) YACaptionViewCompletionHandler completionHandler;

+ (UITextView *)textViewWithCaptionAttributes;

@end
