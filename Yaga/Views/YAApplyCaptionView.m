//
//  YAApplyCaptionView.m
//  Yaga
//
//  Created by Christopher Wendel on 7/16/15.
//  Copyright (c) 2015 Raj Vir. All rights reserved.
//

#import "YAApplyCaptionView.h"
#import "YAPanGestureRecognizer.h"
#import "Constants.h"

@interface YAApplyCaptionView () <UIGestureRecognizerDelegate, UITextViewDelegate>

@property (strong, nonatomic) UIView *editableCaptionWrapperView;
@property (strong, nonatomic) UITextView *editableCaptionTextView;
@property (nonatomic) CGFloat textFieldHeight;
@property (nonatomic) CGAffineTransform textFieldTransform;
@property (nonatomic) CGPoint textFieldCenter;
@property (nonatomic, strong) UIVisualEffectView *captionBlurOverlay;
@property (nonatomic, strong) UIView *captionButtonContainer;
@property (nonatomic, strong) UIButton *cancelCaptionButton;
@property (nonatomic, strong) UIButton *rajsBelovedDoneButton;
@property (strong, nonatomic) YAPanGestureRecognizer *panGestureRecognizer;
@property (strong, nonatomic) UIPinchGestureRecognizer *pinchGestureRecognizer;
@property (strong, nonatomic) UIRotationGestureRecognizer *rotateGestureRecognizer;
@property (nonatomic, strong) UITapGestureRecognizer *captionTapOutGestureRecognizer;

@end

@implementation YAApplyCaptionView

#pragma mark - Initalizers

- (instancetype)initWithFrame:(CGRect)frame {
    return [self initWithFrame:frame captionPoint:CGPointZero initialText:@"" initialTransform:CGAffineTransformIdentity];
}

- (instancetype)initWithFrame:(CGRect)frame captionPoint:(CGPoint)captionPoint initialText:(NSString *)initialText initialTransform:(CGAffineTransform)initialTransform {
    self = [super initWithFrame:frame];
    
    if (self) {
        [self setupCaptionButtonContainer];
        [self setupCaptionGestureRecognizers];
        [self beginEditableCaptionAtPoint:captionPoint initalText:initialText initalTransform:initialTransform];
    }
    
    return self;
}

#pragma mark - Setup

- (void)setupCaptionButtonContainer {
    self.captionButtonContainer = [[UIView alloc] initWithFrame:CGRectMake(0, self.frame.size.height - CAPTION_BUTTON_HEIGHT, VIEW_WIDTH, CAPTION_BUTTON_HEIGHT)];
    
    self.cancelCaptionButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width*(1.0-CAPTION_DONE_PROPORTION), CAPTION_BUTTON_HEIGHT)];
    [self.cancelCaptionButton setTitle:@"Cancel" forState:UIControlStateNormal];
    self.cancelCaptionButton.backgroundColor = [UIColor colorWithRed:(231.f/255.f) green:(76.f/255.f) blue:(60.f/255.f) alpha:.75];
    [self.cancelCaptionButton.titleLabel setFont:[UIFont fontWithName:BOLD_FONT size:24]];
    [self.cancelCaptionButton addTarget:self action:@selector(cancelButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    
    self.rajsBelovedDoneButton = [[UIButton alloc] initWithFrame:CGRectMake(self.cancelCaptionButton.frame.size.width, 0, VIEW_WIDTH*CAPTION_DONE_PROPORTION, CAPTION_BUTTON_HEIGHT)];
    self.rajsBelovedDoneButton.backgroundColor = SECONDARY_COLOR;
    [self.rajsBelovedDoneButton setTitle:@"Done" forState:UIControlStateNormal];
    [self.rajsBelovedDoneButton.titleLabel setFont:[UIFont fontWithName:BOLD_FONT size:24]];
    [self.rajsBelovedDoneButton addTarget:self action:@selector(doneButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.captionButtonContainer addSubview:self.rajsBelovedDoneButton];
    [self.captionButtonContainer addSubview:self.cancelCaptionButton];
}

- (void) setupCaptionGestureRecognizers {
    self.panGestureRecognizer = [[YAPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    self.panGestureRecognizer.delegate = self;
    
    self.rotateGestureRecognizer = [[UIRotationGestureRecognizer alloc] initWithTarget:self action:@selector(handleRotate:)];
    self.rotateGestureRecognizer.delegate = self;
    
    self.pinchGestureRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinch:)];
    self.pinchGestureRecognizer.delegate = self;
}

#pragma mark - UI helpers

- (void)beginEditableCaptionAtPoint:(CGPoint)point initalText:(NSString *)text initalTransform:(CGAffineTransform)transform {
    self.textFieldCenter = point;
    self.textFieldTransform = transform;
    self.editableCaptionWrapperView = [[UIView alloc] initWithFrame:CGRectInfinite];
    
    self.editableCaptionTextView = [self textViewWithCaptionAttributes];
    self.editableCaptionTextView.text = text;
    
    [self resizeTextAboveKeyboardWithAnimation:NO];
    
    [self.editableCaptionWrapperView addSubview:self.editableCaptionTextView];
    [self addSubview:self.editableCaptionWrapperView];
    
    [self.editableCaptionTextView becomeFirstResponder];
}

- (UITextView *)textViewWithCaptionAttributes {
    UITextView *textView = [UITextView new];
    textView.alpha = 1;
    NSAttributedString *string = [[NSAttributedString alloc] initWithString:@"." attributes:@{
                                                                                              NSStrokeColorAttributeName:[UIColor whiteColor],
                                                                                              NSStrokeWidthAttributeName:[NSNumber numberWithFloat:-CAPTION_STROKE_WIDTH]
                                                                                              }];
    [textView setAttributedText:string];
    [textView setBackgroundColor: [UIColor clearColor]]; //[UIColor colorWithWhite:1.0 alpha:0.1]];
    [textView setTextColor:PRIMARY_COLOR];
    [textView setFont:[UIFont fontWithName:CAPTION_FONT size:CAPTION_FONT_SIZE]];
    
    [textView setTextAlignment:NSTextAlignmentCenter];
    [textView setAutocorrectionType:UITextAutocorrectionTypeNo];
    [textView setReturnKeyType:UIReturnKeyDone];
    [textView setScrollEnabled:NO];
    textView.textContainer.lineFragmentPadding = 0;
    textView.textContainerInset = UIEdgeInsetsZero;
    textView.delegate = self;
    
    return textView;
}

- (void)resizeTextAboveKeyboardWithAnimation:(BOOL)animated {
    NSString *captionText = [self.editableCaptionTextView.text length] ? self.editableCaptionTextView.text : @"A";
    CGSize size = [self sizeThatFitsString:captionText];
    CGRect wrapperFrame = CGRectMake((self.frame.size.width / 2.f) - (size.width/2.f) - CAPTION_WRAPPER_INSET,
                                     (self.frame.size.height / 2.f) - (size.height/2.f) - CAPTION_WRAPPER_INSET,
                                     size.width + (2*CAPTION_WRAPPER_INSET),
                                     size.height + (2*CAPTION_WRAPPER_INSET));
    
    CGRect captionFrame = CGRectMake(CAPTION_WRAPPER_INSET, 0, size.width, size.height);
    
    if (animated) {
        [UIView animateWithDuration:0.2f animations:^{
            self.editableCaptionWrapperView.frame = wrapperFrame;
            self.editableCaptionTextView.frame = captionFrame;
        }];
    } else {
        self.editableCaptionWrapperView.frame = wrapperFrame;
        self.editableCaptionTextView.frame = captionFrame;
    }
}

- (void)doneEditingTapOut:(id)sender {
    [self doneTypingCaption];
}

- (void)doneTypingCaption {
    [self removeGestureRecognizer:self.captionTapOutGestureRecognizer];
    
    [self.editableCaptionTextView resignFirstResponder];
    [self.captionBlurOverlay removeFromSuperview];
    
    if (![self.editableCaptionTextView.text length]) {
        [self cancelButtonPressed:nil];
    } else {
        [self moveTextViewBackToSpot];
    }
}

#pragma mark - Caption positioning

- (void)moveTextViewBackToSpot {
    CGFloat fixedWidth = MAX_CAPTION_WIDTH;
    CGSize newSize = [self.editableCaptionTextView sizeThatFits:CGSizeMake(fixedWidth, MAXFLOAT)];
    CGRect captionFrame = CGRectMake(CAPTION_WRAPPER_INSET, CAPTION_WRAPPER_INSET, newSize.width, newSize.height);
    CGRect wrapperFrame = CGRectMake(self.textFieldCenter.x - (newSize.width/2.f) - CAPTION_WRAPPER_INSET,
                                     self.textFieldCenter.y - (newSize.height/2.f) - CAPTION_WRAPPER_INSET,
                                     newSize.width + (2.f*CAPTION_WRAPPER_INSET),
                                     newSize.height + (2.f*CAPTION_WRAPPER_INSET));
    
    [self addSubview:self.captionButtonContainer];
    
    [UIView animateWithDuration:0.2f animations:^{
        self.editableCaptionWrapperView.frame = wrapperFrame;
        self.editableCaptionTextView.frame = captionFrame;
        self.editableCaptionWrapperView.transform = self.textFieldTransform;
    } completion:^(BOOL finished) {
        [self.editableCaptionWrapperView addGestureRecognizer:self.panGestureRecognizer];
        [self.editableCaptionWrapperView addGestureRecognizer:self.rotateGestureRecognizer];
        [self.editableCaptionWrapperView addGestureRecognizer:self.pinchGestureRecognizer];
    }];
}

- (void)positionTextViewAboveKeyboard{
    self.editableCaptionWrapperView.transform = CGAffineTransformIdentity;
    [self.editableCaptionWrapperView removeGestureRecognizer:self.panGestureRecognizer];
    [self.editableCaptionWrapperView removeGestureRecognizer:self.rotateGestureRecognizer];
    [self.editableCaptionWrapperView removeGestureRecognizer:self.pinchGestureRecognizer];
    
    [self resizeTextAboveKeyboardWithAnimation:YES];
}

- (float)doesFit:(UITextView*)textView string:(NSString *)myString range:(NSRange) range;
{
    CGSize maxFrame = [self sizeThatFitsString:@"AA\nAA\nAA"];
    maxFrame.width = MAX_CAPTION_WIDTH;
    
    NSMutableAttributedString *atrs = [[NSMutableAttributedString alloc] initWithAttributedString: textView.textStorage];
    [atrs replaceCharactersInRange:range withString:myString];
    
    NSTextStorage *textStorage = [[NSTextStorage alloc] initWithAttributedString:atrs];
    NSTextContainer *textContainer = [[NSTextContainer alloc] initWithSize: CGSizeMake(maxFrame.width, FLT_MAX)];
    NSLayoutManager *layoutManager = [[NSLayoutManager alloc] init];
    
    [layoutManager addTextContainer:textContainer];
    [textStorage addLayoutManager:layoutManager];
    float textHeight = [layoutManager
                        usedRectForTextContainer:textContainer].size.height;
    
    if (textHeight >= maxFrame.height - 1) {
        DLog(@" textHeight >= maxViewHeight - 1");
        return NO;
    } else
        return YES;
}

#pragma mark - UIGestureRecognizerDelegate

// These 3 recognizers should work simultaneously only with eachother
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)a
shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)b {
    if ([a isEqual:self.panGestureRecognizer]) {
        if ([b isEqual:self.rotateGestureRecognizer] || [b isEqual:self.pinchGestureRecognizer]) {
            return YES;
        }
    }
    if ([a isEqual:self.rotateGestureRecognizer]) {
        if ([b isEqual:self.panGestureRecognizer] || [b isEqual:self.pinchGestureRecognizer]) {
            return YES;
        }
    }
    if ([a isEqual:self.pinchGestureRecognizer]) {
        if ([b isEqual:self.panGestureRecognizer] || [b isEqual:self.rotateGestureRecognizer]) {
            return YES;
        }
    }
    return NO;
}

#pragma mark - UI Actions

- (void)doneButtonPressed:(id)sender {
    
}

- (void)cancelButtonPressed:(id)sender {
    
}

- (void)handlePan:(UIPanGestureRecognizer *)recognizer {
    CGPoint translation = [recognizer translationInView:self];
    recognizer.view.center = CGPointMake(recognizer.view.center.x + translation.x,
                                         MIN(recognizer.view.center.y + translation.y, self.frame.size.height*.666));
    
    [recognizer setTranslation:CGPointMake(0, 0) inView:self];
    
    if (recognizer.state == UIGestureRecognizerStateEnded) {
        
        CGPoint finalPoint = recognizer.view.center;
        recognizer.view.center = finalPoint;
        self.textFieldCenter = finalPoint;
    }
}

- (void)handleRotate:(UIRotationGestureRecognizer *)recognizer {
    CGAffineTransform newTransform = CGAffineTransformRotate(recognizer.view.transform, recognizer.rotation);
    recognizer.view.transform = newTransform;
    recognizer.rotation = 0;
    self.textFieldTransform = newTransform;
}

- (void)handlePinch:(UIPinchGestureRecognizer *)recognizer {
    CGAffineTransform newTransform = CGAffineTransformScale(recognizer.view.transform, recognizer.scale, recognizer.scale);
    recognizer.view.transform = newTransform;
    recognizer.scale = 1;
    self.textFieldTransform = newTransform;
}

#pragma mark - Caption helpers

- (void)commitCurrentCaption {
    if (self.editableCaptionTextView) {
        [self.editableCaptionWrapperView removeGestureRecognizer:self.panGestureRecognizer];
        [self.editableCaptionWrapperView removeGestureRecognizer:self.rotateGestureRecognizer];
        [self.editableCaptionWrapperView removeGestureRecognizer:self.pinchGestureRecognizer];
//        [self.editableCaptionTextView removeGestureRecognizer:self.captionTapRecognizer];
//        [self removeGestureRecognizer:self.captionTapRecognizer];
        
        NSString *text = self.editableCaptionTextView.text;
        CGFloat x = ceil(self.textFieldCenter.x / self.frame.size.width * 10000.0) / 10000.0;
        CGFloat y = ceil(self.textFieldCenter.y / self.frame.size.height * 10000.0) / 10000.0;
        
        CGAffineTransform t = self.textFieldTransform;
        CGFloat scale = sqrt(t.a * t.a + t.c * t.c);
        scale = ceil(scale / CAPTION_SCREEN_MULTIPLIER * 10000.0) / 10000.0;
        
        CGFloat rotation = ceil(atan2f(t.b, t.a) * 10000.0) / 10000.0;
        
//        self.serverCaptionWrapperView = self.editableCaptionWrapperView;
//        self.serverCaptionTextView = self.editableCaptionTextView;
        self.editableCaptionWrapperView = nil;
        self.editableCaptionTextView = nil;
//        self.serverCaptionTextView.editable = NO;
//        [self.view insertSubview:self.serverCaptionWrapperView aboveSubview:self.playerView];
//        [self.captionButtonContainer removeFromSuperview];
//        [self.captionButton removeFromSuperview];
        //        [self.video updateCaption:text withXPosition:x yPosition:y scale:scale rotation:rotation];
    }
}

#pragma mark - UITextViewDelegate

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    
    if([text isEqualToString:@"\n"]) {
        [self doneTypingCaption];
        return NO;
    }
    
    return [self doesFit:textView string:text range:range];
}

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView {
    UIVisualEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
    
    self.captionBlurOverlay = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
    
    self.captionBlurOverlay.frame = self.bounds;
    [self insertSubview:self.captionBlurOverlay belowSubview:self.editableCaptionWrapperView];
    //    [self.captionBlurOverlay addSubview:self.cancelWhileTypingButton];
    
    if (self.editableCaptionTextView) {
        [self positionTextViewAboveKeyboard];
    }
    
    return YES;
}

- (void)textViewDidChange:(UITextView *)textView {
    // Should only be called while keyboard is up
    [self resizeTextAboveKeyboardWithAnimation:NO];
}

- (void)textViewDidBeginEditing:(UITextView *)textView {
    self.captionTapOutGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doneEditingTapOut:)];
    [self addGestureRecognizer:self.captionTapOutGestureRecognizer];
}

#pragma mark - Text calculation

- (CGSize)sizeThatFitsString:(NSString *)string {
    CGRect frame = [string boundingRectWithSize:CGSizeMake(MAX_CAPTION_WIDTH, CGFLOAT_MAX)
                                        options:NSStringDrawingUsesLineFragmentOrigin
                                     attributes:@{ NSFontAttributeName:[UIFont fontWithName:CAPTION_FONT size:CAPTION_FONT_SIZE],
                                                   NSStrokeColorAttributeName:[UIColor whiteColor],
                                                   NSStrokeWidthAttributeName:[NSNumber numberWithFloat:-CAPTION_STROKE_WIDTH] } context:nil];
    return frame.size;
}


@end
