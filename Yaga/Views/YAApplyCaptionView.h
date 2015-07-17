//
//  YAApplyCaptionView.h
//  Yaga
//
//  Created by Christopher Wendel on 7/16/15.
//  Copyright (c) 2015 Raj Vir. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void (^YACaptionViewDoneCompletionHandler)(UITextView *textView);

@interface YAApplyCaptionView : UIView

- (instancetype)initWithFrame:(CGRect)frame captionPoint:(CGPoint)captionPoint initialText:(NSString *)initialText initialTransform:(CGAffineTransform)initialTransform;

@end
