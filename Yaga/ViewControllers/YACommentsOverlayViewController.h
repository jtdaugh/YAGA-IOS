//
//  YACommentsOverlayViewController.h
//  Yaga
//
//  Created by Christopher Wendel on 5/21/15.
//  Copyright (c) 2015 Raj Vir. All rights reserved.
//

#import <UIKit/UIKit.h>

@class YACommentsOverlayView;

/*!
 * View controller than contains and shows a \c YACommentsOverlayView.
 */
@interface YACommentsOverlayViewController : UIViewController

@property (nonatomic, strong) YACommentsOverlayView *commentsOverlayView;

@end
