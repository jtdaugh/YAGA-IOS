//
//  YACommentsOverlayView.h
//  Yaga
//
//  Created by Christopher Wendel on 5/21/15.
//  Copyright (c) 2015 Raj Vir. All rights reserved.
//

#import <UIKit/UIKit.h>

// Enum because we may want to add more types
typedef NS_ENUM(NSInteger, YACommentsOverlayViewRowType) {
    YACommentsOverlayViewRowTypeComment = 0,
    YACommentsOverlayViewRowTypeRecaption,
};

typedef void(^YACommentsOverlayViewCancelHandler)();

/*!
 *  Comments overlay view based of of AHKActionSheet.
 *
 *  View that shows comments and recaptions on the presented video.
 */
@interface YACommentsOverlayView : UIView <UIAppearanceContainer>

@property (strong, nonatomic) UIColor *blurTintColor UI_APPEARANCE_SELECTOR;
@property (nonatomic) CGFloat blurRadius UI_APPEARANCE_SELECTOR;
@property (nonatomic) CGFloat buttonHeight UI_APPEARANCE_SELECTOR;
@property (nonatomic) CGFloat cancelButtonHeight UI_APPEARANCE_SELECTOR;
@property (strong, nonatomic) UIColor *cancelButtonShadowColor UI_APPEARANCE_SELECTOR;
@property (strong, nonatomic) UIColor *separatorColor UI_APPEARANCE_SELECTOR;
@property (strong, nonatomic) UIColor *selectedBackgroundColor UI_APPEARANCE_SELECTOR;

@property (copy, nonatomic) NSDictionary *titleTextAttributes UI_APPEARANCE_SELECTOR;
@property (copy, nonatomic) NSDictionary *commentTextAttributes UI_APPEARANCE_SELECTOR;
@property (copy, nonatomic) NSDictionary *recaptionTextAttributes UI_APPEARANCE_SELECTOR;
@property (copy, nonatomic) NSDictionary *cancelButtonTextAttributes UI_APPEARANCE_SELECTOR;

@property (strong, nonatomic) NSNumber *cancelOnPanGestureEnabled;

@property (nonatomic) CGFloat blurSaturationDeltaFactor UI_APPEARANCE_SELECTOR;

@property (nonatomic, strong) NSString *cancelButtonTitle;
@property (copy, nonatomic) YACommentsOverlayViewCancelHandler cancelHandler;

@property (weak, nonatomic, readonly) UIWindow *previousKeyWindow;

- (instancetype)initWithTitle:(NSString *)title;

- (void)addCommentWithUsername:(NSString *)username Title:(NSString *)title;
- (void)addRecaptionWithUsername:(NSString *)username newCaption:(NSString *)newCaption;
- (void)addCaptionCreationWithUsername:(NSString *)username caption:(NSString *)caption;
- (void)addCaptionMoveWithUsername:(NSString *)username;
- (void)addCaptionDeletionWithUsername:(NSString *)username;

- (void)show;

- (void)dismissAnimated:(BOOL)animated;

@end
