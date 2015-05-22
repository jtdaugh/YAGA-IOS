//
//  YACommentsOverlayView.m
//  Yaga
//
//  Created by Christopher Wendel on 5/21/15.
//  Copyright (c) 2015 Raj Vir. All rights reserved.
//

#import "YACommentsOverlayView.h"
#import "YACommentsOverlayViewController.h"
#import "UIImage+YABlur.h"
#import "UIImage+Resize.h"
#import "UIWindow+YASnapshot.h"
#import "YAUser.h"

// Constants
static const NSTimeInterval kDefaultAnimationDuration = 0.25f;
static const CGFloat kBlurFadeRangeSize = 200.0f;
static NSString * const kCellIdentifier = @"Cell";
static const CGFloat kAutoDismissOffset = 80.0f;
static const CGFloat kFlickDownHandlingOffset = 20.0f;
static const CGFloat kFlickDownMinVelocity = 2000.0f;
static const CGFloat kTopSpaceMarginFraction = 0.333f;

// Model representation of a comment or a recaption
@interface YACommentsOverlayViewItem : NSObject
@property (copy, nonatomic) NSString *title;
@property (strong, nonatomic) UIImage *image;
@property (nonatomic, assign) YACommentsOverlayViewRowType rowType;
@end

@implementation YACommentsOverlayViewItem
/* No-op */
@end

@interface YACommentsOverlayView() <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate>
@property (strong, nonatomic) NSMutableArray *items;
@property (weak, nonatomic, readwrite) UIWindow *previousKeyWindow;
@property (strong, nonatomic) UIWindow *window;
@property (weak, nonatomic) UIVisualEffectView *blurredBackgroundView;
@property (weak, nonatomic) UITableView *tableView;
//@property (weak, nonatomic) UIButton *cancelButton;
@property (weak, nonatomic) UITextField *commentTextField;
@property (weak, nonatomic) UIView *cancelButtonShadowView;
@end

@implementation YACommentsOverlayView

#pragma mark - Init

+ (void)initialize
{
    if (self != [YACommentsOverlayView class]) {
        return;
    }
    
    YACommentsOverlayView *appearance = [self appearance];
    [appearance setBlurRadius:16.0f];
    [appearance setBlurTintColor:[UIColor colorWithWhite:1.0f alpha:0.5f]];
    [appearance setBlurSaturationDeltaFactor:1.8f];
    [appearance setButtonHeight:80.0f];
    [appearance setCancelButtonHeight:44.0f];
    [appearance setSelectedBackgroundColor:[UIColor colorWithWhite:0.1f alpha:0.2f]];
    [appearance setCancelButtonTextAttributes:@{ NSFontAttributeName : [UIFont systemFontOfSize:17.0f],
                                                 NSForegroundColorAttributeName : [UIColor darkGrayColor] }];
    [appearance setCommentTextAttributes:@{ NSFontAttributeName : [UIFont systemFontOfSize:17.0f]}];
    [appearance setRecaptionTextAttributes:@{ NSFontAttributeName : [UIFont systemFontOfSize:14.0f],
                                                   NSForegroundColorAttributeName : [UIColor colorWithWhite:0.6f alpha:1.0] }];
    [appearance setTitleTextAttributes:@{ NSFontAttributeName : [UIFont systemFontOfSize:14.0f],
                                          NSForegroundColorAttributeName : [UIColor grayColor] }];
    [appearance setCancelOnPanGestureEnabled:@(YES)];
}

- (instancetype)initWithTitle:(NSString *)title
{
    self = [super init];
    
    if (self) {
        _cancelButtonTitle = @"Cancel";
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(keyboardWillShow:)
                                                     name:UIKeyboardWillShowNotification object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(keyboardWillBeHidden:)
                                                     name:UIKeyboardWillHideNotification object:nil];
    }
    
    return self;
}

- (instancetype)init
{
    return [self initWithTitle:nil];
}

- (void)dealloc
{
    self.tableView.dataSource = nil;
    self.tableView.delegate = nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return (NSInteger)[self.items count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifier forIndexPath:indexPath];
    YACommentsOverlayViewItem  *item = self.items[(NSUInteger)indexPath.row];
    
    NSDictionary *attributes = nil;
    switch (item.rowType)
    {
        case YACommentsOverlayViewRowTypeComment:
            attributes = self.commentTextAttributes;
            break;
        case YACommentsOverlayViewRowTypeRecaption:
            attributes = self.recaptionTextAttributes;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            break;
        default:
            break;
    }
    
    NSAttributedString *attrTitle = [[NSAttributedString alloc] initWithString:item.title attributes:attributes];
    cell.textLabel.attributedText = attrTitle;
    cell.textLabel.textAlignment = NSTextAlignmentCenter;
    cell.textLabel.numberOfLines = 3;
    cell.textLabel.minimumScaleFactor = 0.7f;
    cell.textLabel.adjustsFontSizeToFitWidth = YES;
    
    cell.imageView.image = [item.image imageScaledToSize:CGSizeMake(35, 35)];
    
    cell.imageView.layer.cornerRadius = 35/2.f;
    cell.imageView.clipsToBounds = YES;
    
    
    if ([UIImageView instancesRespondToSelector:@selector(tintColor)]){
        cell.imageView.tintColor = attributes[NSForegroundColorAttributeName] ? attributes[NSForegroundColorAttributeName] : [UIColor blackColor];
    }
    
    cell.backgroundColor = [UIColor clearColor];
    
    if (self.selectedBackgroundColor && ![cell.selectedBackgroundView.backgroundColor isEqual:self.selectedBackgroundColor]) {
        cell.selectedBackgroundView = [[UIView alloc] init];
        cell.selectedBackgroundView.backgroundColor = self.selectedBackgroundColor;
    }
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return self.buttonHeight;
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (![self.cancelOnPanGestureEnabled boolValue]) {
        return;
    }
    
    [self fadeBlursOnScrollToTop];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (![self.cancelOnPanGestureEnabled boolValue]) {
        return;
    }
    
    CGPoint scrollVelocity = [scrollView.panGestureRecognizer velocityInView:self];
    
    BOOL viewWasFlickedDown = scrollVelocity.y > kFlickDownMinVelocity && scrollView.contentOffset.y < -self.tableView.contentInset.top - kFlickDownHandlingOffset;
    BOOL shouldSlideDown = scrollView.contentOffset.y < -self.tableView.contentInset.top - kAutoDismissOffset;
    if (viewWasFlickedDown) {
        // use a shorter duration for a flick down animation
        static const NSTimeInterval duration = 0.2f;
        [self dismissAnimated:YES duration:duration completion:self.cancelHandler];
    } else if (shouldSlideDown) {
        [self dismissAnimated:YES duration:kDefaultAnimationDuration completion:self.cancelHandler];
    }
}

#pragma mark - Properties

- (NSMutableArray *)items
{
    if (!_items) {
        _items = [NSMutableArray array];
    }
    
    return _items;
}

#pragma mark - Actions

- (void)cancelButtonTapped:(id)sender
{
    [self dismissAnimated:YES duration:kDefaultAnimationDuration completion:self.cancelHandler];
}

#pragma mark - Public

- (void)addCommentWithUsername:(NSString *)username Title:(NSString *)title {
    NSString *text = [NSString stringWithFormat:@"%@: %@", username, title];
    [self addItemWithTitle:text image:[UIImage imageNamed:@"chris"] type:YACommentsOverlayViewRowTypeComment];
}

- (void)addRecaptionWithUsername:(NSString *)username newCaption:(NSString *)newCaption {
    [self addItemWithTitle:[NSString stringWithFormat:@"%@ recaptioned the video to '%@'", username, newCaption]
                     image:[UIImage imageNamed:@"chris"]
                      type:YACommentsOverlayViewRowTypeRecaption];

}

- (void)addCaptionCreationWithUsername:(NSString *)username caption:(NSString *)caption {
    [self addItemWithTitle:[NSString stringWithFormat:@"%@ captioned the video '%@'", username, caption]
                     image:[UIImage imageNamed:@"chris"]
                      type:YACommentsOverlayViewRowTypeRecaption];
}

- (void)addCaptionDeletionWithUsername:(NSString *)username {
    [self addItemWithTitle:[NSString stringWithFormat:@"%@ deleted the caption", username]
                     image:[UIImage imageNamed:@"chris"]
                      type:YACommentsOverlayViewRowTypeRecaption];
}

- (void)addCaptionMoveWithUsername:(NSString *)username {
    [self addItemWithTitle:[NSString stringWithFormat:@"%@ moved the caption", username]
                     image:[UIImage imageNamed:@"chris"]
                      type:YACommentsOverlayViewRowTypeRecaption];
}


- (void)show
{
    NSAssert([self.items count] > 0, @"Please add some buttons before calling -show.");
    
    if ([self isVisible]) {
        return;
    }
    
    self.previousKeyWindow = [UIApplication sharedApplication].keyWindow;
    UIImage *previousKeyWindowSnapshot = [self.previousKeyWindow ya_snapshot];
    
    [self setUpNewWindow];
    [self setUpBlurredBackgroundWithSnapshot:previousKeyWindowSnapshot];
    [self setUpCommentTextField];
    [self setUpTableView];
    
    CGFloat slideDownMinOffset = (CGFloat)fmin(CGRectGetHeight(self.frame) + self.tableView.contentOffset.y, CGRectGetHeight(self.frame));
    self.tableView.transform = CGAffineTransformMakeTranslation(0, slideDownMinOffset);
    
    void(^delayedAnimations)(void) = ^(void) {
        self.commentTextField.frame = CGRectMake(15,
                                             CGRectGetMaxY(self.bounds) - self.cancelButtonHeight,
                                             CGRectGetWidth(self.bounds) - 30,
                                             self.cancelButtonHeight);
        
        self.tableView.transform = CGAffineTransformMakeTranslation(0, 0);
        
        self.tableView.contentInset = [self insetsForTableView];
        
        self.tableView.bounces = [self.cancelOnPanGestureEnabled boolValue] || ![self buttonsFitInWithoutScrolling];
    };
    
    if ([UIView respondsToSelector:@selector(animateKeyframesWithDuration:delay:options:animations:completion:)]){
        // Animate sliding in tableView and cancel button with keyframe animation for a nicer effect.
        [UIView animateKeyframesWithDuration:kDefaultAnimationDuration delay:0 options:0 animations:^{
            [UIView addKeyframeWithRelativeStartTime:0.3f relativeDuration:0.7f animations:^{
                delayedAnimations();
            }];
        } completion:nil];
        
    } else {
        
        [UIView animateWithDuration:kDefaultAnimationDuration animations:^{
            delayedAnimations();
        }];
    }
}

- (void)dismissAnimated:(BOOL)animated
{
    [self dismissAnimated:animated duration:kDefaultAnimationDuration completion:self.cancelHandler];
}

#pragma mark - Private

- (void)addItemWithTitle:(NSString *)title image:(UIImage *)image type:(YACommentsOverlayViewRowType)type {
    YACommentsOverlayViewItem *item = [[YACommentsOverlayViewItem alloc] init];
    item.title = title;
    item.image = image;
    item.rowType = type;
    [self.items addObject:item];
}

- (BOOL)isVisible
{
    // action sheet is visible iff it's associated with a window
    return !!self.window;
}

- (UIEdgeInsets)insetsForTableView {
    CGFloat topInset;
    if ([self buttonsFitInWithoutScrolling]) {
        // show all buttons if there isn't many
        topInset = CGRectGetHeight(self.tableView.frame) - [self tableContentHeight];
    } else {
        // leave an empty space on the top to make the control look similar to UIActionSheet
        topInset = (CGFloat)round(CGRectGetHeight(self.tableView.frame) * kTopSpaceMarginFraction);
    }
    
    return UIEdgeInsetsMake(topInset, 0, 0, 0);
}

- (BOOL)buttonsFitInWithoutScrolling {
    BOOL buttonsFitInWithoutScrolling = [self tableContentHeight] < CGRectGetHeight(self.tableView.frame) * (1.0 - kTopSpaceMarginFraction);
    
    return buttonsFitInWithoutScrolling;
}

- (CGFloat)tableContentHeight {
    CGFloat tableContentHeight = [self.items count] * self.buttonHeight + CGRectGetHeight(self.tableView.tableHeaderView.frame);
    
    return tableContentHeight;
}

- (void)dismissAnimated:(BOOL)animated duration:(NSTimeInterval)duration completion:(void(^)())completionHandler
{
    if (![self isVisible]) {
        return;
    }
    
    // delegate isn't needed anymore because tableView will be hidden (and we don't want delegate methods to be called now)
    self.tableView.delegate = nil;
    self.tableView.userInteractionEnabled = NO;
    // keep the table from scrolling back up
    self.tableView.contentInset = UIEdgeInsetsMake(-self.tableView.contentOffset.y, 0, 0, 0);
    
    [self.blurredBackgroundView removeFromSuperview];
    
    void(^tearDownView)(void) = ^(void) {
        // remove the views because it's easiest to just recreate them if the action sheet is shown again
        for (UIView *view in @[self.tableView, self.commentTextField, self.window]) {
            [view removeFromSuperview];
        }
        
        self.window = nil;
        [self.previousKeyWindow makeKeyAndVisible];
        
        if (completionHandler) {
            completionHandler(self);
        }
    };
    
    if (animated) {
        // animate sliding down tableView and cancelButton.
        [UIView animateWithDuration:duration animations:^{
            self.commentTextField.transform = CGAffineTransformTranslate(self.commentTextField.transform, 0, self.cancelButtonHeight);
            self.cancelButtonShadowView.alpha = 0.0f;
            
            // Shortest shift of position sufficient to hide all tableView contents below the bottom margin.
            // contentInset isn't used here (unlike in -show) because it caused weird problems with animations in some cases.
            CGFloat slideDownMinOffset = (CGFloat)fmin(CGRectGetHeight(self.frame) + self.tableView.contentOffset.y, CGRectGetHeight(self.frame));
            self.tableView.transform = CGAffineTransformMakeTranslation(0, slideDownMinOffset);
        } completion:^(BOOL finished) {
            tearDownView();
        }];
    } else {
        tearDownView();
    }
}

- (void)setUpNewWindow
{
    YACommentsOverlayViewController *actionSheetVC = [[YACommentsOverlayViewController alloc] initWithNibName:nil bundle:nil];
    actionSheetVC.commentsOverlayView = self;
    
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.window.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.window.opaque = NO;
    self.window.rootViewController = actionSheetVC;
    [self.window makeKeyAndVisible];
}

- (void)setUpBlurredBackgroundWithSnapshot:(UIImage *)previousKeyWindowSnapshot
{
    UIVisualEffect *blurEffect;
    blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
    
    UIVisualEffectView *visualEffectView;
    visualEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
    
    visualEffectView.frame = self.bounds;
    [self addSubview:visualEffectView];
    self.blurredBackgroundView = visualEffectView;
}

- (void)setUpCommentTextField
{
    UITextField *commentTextField = [[UITextField alloc] initWithFrame:CGRectMake(15,
                                                                                  CGRectGetMaxY(self.bounds) - self.cancelButtonHeight,
                                                                                  CGRectGetWidth(self.bounds) - 30,
                                                                                  self.cancelButtonHeight)];
    
    commentTextField.font = [UIFont systemFontOfSize:15];
    commentTextField.keyboardType = UIKeyboardTypeDefault;
    commentTextField.returnKeyType = UIReturnKeySend;
    commentTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
    commentTextField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    commentTextField.backgroundColor = [UIColor clearColor];
    commentTextField.textColor = [UIColor whiteColor];
    commentTextField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"Write a comment...", nil) attributes:@{NSForegroundColorAttributeName: [UIColor whiteColor]}];
    commentTextField.delegate = self;
    commentTextField.transform = CGAffineTransformMakeTranslation(0, self.cancelButtonHeight);
    commentTextField.keyboardAppearance = UIKeyboardAppearanceDark;
    
    [self addSubview:commentTextField];
    
    self.commentTextField = commentTextField;
}

- (void)setUpTableView
{
    CGRect statusBarViewRect = [self convertRect:[UIApplication sharedApplication].statusBarFrame fromView:nil];
    CGFloat statusBarHeight = CGRectGetHeight(statusBarViewRect);
    CGRect frame = CGRectMake(0,
                              statusBarHeight,
                              CGRectGetWidth(self.bounds),
                              CGRectGetHeight(self.bounds) - statusBarHeight - self.cancelButtonHeight);
    
    UITableView *tableView = [[UITableView alloc] initWithFrame:frame];
    tableView.backgroundColor = [UIColor clearColor];
    tableView.showsVerticalScrollIndicator = NO;
    tableView.allowsSelection = NO;
    tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    
    if ([UITableView instancesRespondToSelector:@selector(setSeparatorInset:)]) {
        tableView.separatorInset = UIEdgeInsetsZero;
    }
    
    if (self.separatorColor) {
        tableView.separatorColor = self.separatorColor;
    }
    
    tableView.delegate = self;
    tableView.dataSource = self;
    [tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:kCellIdentifier];
    [self insertSubview:tableView aboveSubview:self.blurredBackgroundView];
    // move the content below the screen, ready to be animated in -show
    tableView.contentInset = UIEdgeInsetsMake(CGRectGetHeight(self.bounds), 0, 0, 0);
    
    self.tableView = tableView;
}

- (void)fadeBlursOnScrollToTop
{
    if (self.tableView.isDragging || self.tableView.isDecelerating) {
        CGFloat alphaWithoutBounds = 1.0f - ( -(self.tableView.contentInset.top + self.tableView.contentOffset.y) / kBlurFadeRangeSize);
        // limit alpha to the interval [0, 1]
        CGFloat alpha = (CGFloat)fmax(fmin(alphaWithoutBounds, 1.0f), 0.0f);
        self.cancelButtonShadowView.alpha = alpha;
    }
}

#pragma mark - Notification Handlers

- (void)keyboardWillShow:(NSNotification *)notification {
    NSDictionary* info = [notification userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    
    [UIView animateWithDuration:0.3f animations:^{
        UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, kbSize.height, 0.0);
        self.tableView.contentInset = contentInsets;
        self.tableView.scrollIndicatorInsets = contentInsets;
        
        CGRect commentTextFieldFrame = self.commentTextField.frame;
        commentTextFieldFrame.origin.y -= kbSize.height;
        self.commentTextField.frame = commentTextFieldFrame;
    }];
}

- (void)keyboardWillBeHidden:(NSNotification *)notification {
    [UIView animateWithDuration:0.3f animations:^{
        self.tableView.contentInset = [self insetsForTableView];
        
        CGRect commentTextFieldFrame = self.commentTextField.frame;
        commentTextFieldFrame.origin.y = CGRectGetMaxY(self.bounds) - self.cancelButtonHeight;
        self.commentTextField.frame = commentTextFieldFrame;
    }];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self.commentTextField resignFirstResponder];
    self.commentTextField.text = @"";
    
    return YES;
}

@end
