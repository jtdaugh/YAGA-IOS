//
//  ShareViewController.m
//  YAVideoShareExtension
//
//  Created by Christopher Wendel on 7/16/15.
//  Copyright (c) 2015 Raj Vir. All rights reserved.
//

#import "YAShareVideoViewController.h"
#import "YAVideoPlayerView.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "YACrosspostCell.h"
#import "Constants.h"
#import "YAShareServer.h"
#import "YAShareGroup.h"
#import "YAPanGestureRecognizer.h"
#import "YAApplyCaptionView.h"

#import <Firebase/Firebase.h>

@interface YAShareVideoViewController ()

@property (nonatomic) BOOL editingCaption;

@property (nonatomic, weak) IBOutlet YAVideoPlayerView *playerView;
@property (nonatomic, strong) UITableView *groupsList;
@property (nonatomic, strong) UIButton *confirmCrosspost;
@property (nonatomic, strong) UIButton *XButton;
@property (nonatomic, strong) UIButton *captionButton;
@property (nonatomic, strong) UILabel *crossPostPrompt;
@property (nonatomic, strong) UITapGestureRecognizer *captionTapRecognizer;

// Caption stuff
//@property (strong, nonatomic) UIView *editableCaptionWrapperView;
//@property (strong, nonatomic) UITextView *editableCaptionTextView;
//@property (nonatomic) CGFloat textFieldHeight;
//@property (nonatomic) CGAffineTransform textFieldTransform;
//@property (nonatomic) CGPoint textFieldCenter;
//@property (nonatomic, strong) UIVisualEffectView *captionBlurOverlay;
//@property (nonatomic, strong) UIView *captionButtonContainer;
//@property (nonatomic, strong) UIButton *cancelCaptionButton;
//@property (nonatomic, strong) UIButton *rajsBelovedDoneButton;
//@property (strong, nonatomic) YAPanGestureRecognizer *panGestureRecognizer;
//@property (strong, nonatomic) UIPinchGestureRecognizer *pinchGestureRecognizer;
//@property (strong, nonatomic) UIRotationGestureRecognizer *rotateGestureRecognizer;
//@property (nonatomic, strong) UITapGestureRecognizer *captionTapOutGestureRecognizer;

@property (strong, nonatomic) UIView *serverCaptionWrapperView;
@property (strong, nonatomic) UITextView *serverCaptionTextView;
@property (strong, nonatomic) FDataSnapshot *currentCaptionSnapshot;

@end

@implementation YAShareVideoViewController

#pragma mark - View setup

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self loadExtensionItem];
    
    CGFloat topGap = 20;
    CGFloat shareBarHeight = 60;
    CGFloat topBarHeight = 80;
    CGFloat buttonRadius = 22.f, padding = 15.f;
    
    CGFloat totalRowsHeight = XPCellHeight * ([self.groups count] + 1);
    if (![self.groups count]) totalRowsHeight = 0;
    
    CGRect frame = self.view.frame;
    
    CGFloat maxTableViewHeight = (frame.size.height * VIEW_HEIGHT_PROPORTION) - topGap - XPCellHeight;
    
    CGFloat tableHeight = MIN(maxTableViewHeight, totalRowsHeight);
    
    CGFloat gradientHeight = tableHeight + topBarHeight + topGap;
    UIView *bgGradient = [[UIView alloc] initWithFrame:CGRectMake(0, frame.size.height - gradientHeight, frame.size.width, gradientHeight)];
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.frame = bgGradient.bounds;
    ;
    gradient.colors = [NSArray arrayWithObjects:
                       (id)[[UIColor colorWithWhite:0.0 alpha:.0] CGColor],
                       (id)[[UIColor colorWithWhite:0.0 alpha:.6] CGColor],
                       (id)[[UIColor colorWithWhite:0.0 alpha:.7] CGColor],
                       (id)[[UIColor colorWithWhite:0.0 alpha:.7] CGColor],
                       (id)[[UIColor colorWithWhite:0.0 alpha:.8] CGColor],
                       nil];
    
    [bgGradient.layer insertSublayer:gradient atIndex:0];
    [self.view addSubview:bgGradient];
    
    UIView *tapCaptionTarget = [[UIView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:tapCaptionTarget];
    
    self.captionTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    [tapCaptionTarget addGestureRecognizer:self.captionTapRecognizer];

    CGFloat tableOrigin = frame.size.height - tableHeight;
    
    self.groupsList = [[UITableView alloc] initWithFrame:CGRectMake(0, tableOrigin, VIEW_WIDTH, tableHeight)];
    [self.groupsList setBackgroundColor:[UIColor clearColor]];
    [self.groupsList registerClass:[YACrosspostCell class] forCellReuseIdentifier:kCrosspostCellId];
    [self.groupsList registerClass:[UITableViewCell class] forCellReuseIdentifier:kNewGroupCellId];
    self.groupsList.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.groupsList.allowsSelection = YES;
    self.groupsList.allowsMultipleSelection = YES;
    self.groupsList.delegate = self;
    self.groupsList.dataSource = self;
    self.groupsList.contentInset = UIEdgeInsetsMake(0, 0, XPCellHeight, 0);
    [self.view addSubview:self.groupsList];
    
    self.confirmCrosspost = [[UIButton alloc] initWithFrame:CGRectMake(0, frame.size.height - shareBarHeight, VIEW_WIDTH, shareBarHeight)];
    self.confirmCrosspost.backgroundColor = SECONDARY_COLOR;
    self.confirmCrosspost.titleLabel.font = [UIFont fontWithName:BOLD_FONT size:20];
    self.confirmCrosspost.titleLabel.textColor = [UIColor whiteColor];
    [self.confirmCrosspost setContentHorizontalAlignment:UIControlContentHorizontalAlignmentLeft];
    [self.confirmCrosspost setImage:[UIImage imageNamed:@"Disclosure"] forState:UIControlStateNormal];
    self.confirmCrosspost.imageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.confirmCrosspost setContentEdgeInsets:UIEdgeInsetsZero];
    [self.confirmCrosspost setImageEdgeInsets:UIEdgeInsetsMake(0, self.confirmCrosspost.frame.size.width - 48 - 16, 0, 48)];
    [self.confirmCrosspost setTitleEdgeInsets:UIEdgeInsetsMake(0, 8, 0, 48 - 16)];
    [self.confirmCrosspost setTransform:CGAffineTransformMakeTranslation(0, self.confirmCrosspost.frame.size.height)];
    [self.confirmCrosspost addTarget:self action:@selector(confirmCrosspost:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.confirmCrosspost];
    
    self.crossPostPrompt = [[UILabel alloc] initWithFrame:CGRectMake(24, tableOrigin - topGap, VIEW_WIDTH-24, 24)];
    self.crossPostPrompt.font = [UIFont fontWithName:BOLD_FONT size:20];
    self.crossPostPrompt.textColor = [UIColor whiteColor];
    NSString *title = @"Post to Groups";
    self.crossPostPrompt.text = title;
    self.crossPostPrompt.layer.shadowRadius = 0.5f;
    self.crossPostPrompt.layer.shadowColor = [UIColor blackColor].CGColor;
    self.crossPostPrompt.layer.shadowOffset = CGSizeMake(0.5f, 0.5f);
    self.crossPostPrompt.layer.shadowOpacity = 1.0;
    self.crossPostPrompt.layer.masksToBounds = NO;
    
    [self.view addSubview:self.crossPostPrompt];
    
    self.XButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, buttonRadius*2, buttonRadius*2)];
    self.XButton.center = CGPointMake(frame.size.width - buttonRadius - padding, padding + buttonRadius);
    [self.XButton setBackgroundImage:[UIImage imageNamed:@"X"] forState:UIControlStateNormal];
    self.XButton.transform = CGAffineTransformMakeScale(0.85, 0.85);
    self.XButton.alpha = 0.7;
    [self.XButton addTarget:self action:@selector(closeButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.XButton];
    
    self.captionButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, buttonRadius * 2, buttonRadius * 2)];
    [self.captionButton setBackgroundImage:[UIImage imageNamed:@"Text"] forState:UIControlStateNormal];
    self.captionButton.center = CGPointMake(buttonRadius + padding, padding + buttonRadius);
    [self.captionButton addTarget:self action:@selector(captionButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.captionButton];
    
    [self toggleEditingCaption:NO];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

//- (void)setupCaptionButtonContainer {
//    self.captionButtonContainer = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height - CAPTION_BUTTON_HEIGHT, VIEW_WIDTH, CAPTION_BUTTON_HEIGHT)];
//    
//    self.cancelCaptionButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, VIEW_WIDTH*(1.0-CAPTION_DONE_PROPORTION), CAPTION_BUTTON_HEIGHT)];
//    [self.cancelCaptionButton setTitle:@"Cancel" forState:UIControlStateNormal];
//    self.cancelCaptionButton.backgroundColor = [UIColor colorWithRed:(231.f/255.f) green:(76.f/255.f) blue:(60.f/255.f) alpha:.75];
//    [self.cancelCaptionButton.titleLabel setFont:[UIFont fontWithName:BOLD_FONT size:24]];
//    [self.cancelCaptionButton addTarget:self action:@selector(cancelButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
//    
//    self.rajsBelovedDoneButton = [[UIButton alloc] initWithFrame:CGRectMake(self.cancelCaptionButton.frame.size.width, 0, VIEW_WIDTH*CAPTION_DONE_PROPORTION, CAPTION_BUTTON_HEIGHT)];
//    self.rajsBelovedDoneButton.backgroundColor = SECONDARY_COLOR;
//    [self.rajsBelovedDoneButton setTitle:@"Done" forState:UIControlStateNormal];
//    [self.rajsBelovedDoneButton.titleLabel setFont:[UIFont fontWithName:BOLD_FONT size:24]];
//    [self.rajsBelovedDoneButton addTarget:self action:@selector(doneButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
//    
//    [self.captionButtonContainer addSubview:self.rajsBelovedDoneButton];
//    [self.captionButtonContainer addSubview:self.cancelCaptionButton];
//    
//    [self toggleEditingCaption:NO];
//}
//
//- (void) setupCaptionGestureRecognizers {
//    self.panGestureRecognizer = [[YAPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
//    self.panGestureRecognizer.delegate = self;
//    
//    self.rotateGestureRecognizer = [[UIRotationGestureRecognizer alloc] initWithTarget:self action:@selector(handleRotate:)];
//    self.rotateGestureRecognizer.delegate = self;
//    
//    self.pinchGestureRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinch:)];
//    self.pinchGestureRecognizer.delegate = self;
//}

//#pragma mark - UIGestureRecognizer
//
//// These 3 recognizers should work simultaneously only with eachother
//- (BOOL)gestureRecognizer:(UIGestureRecognizer *)a
//shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)b {
//    if ([a isEqual:self.panGestureRecognizer]) {
//        if ([b isEqual:self.rotateGestureRecognizer] || [b isEqual:self.pinchGestureRecognizer]) {
//            return YES;
//        }
//    }
//    if ([a isEqual:self.rotateGestureRecognizer]) {
//        if ([b isEqual:self.panGestureRecognizer] || [b isEqual:self.pinchGestureRecognizer]) {
//            return YES;
//        }
//    }
//    if ([a isEqual:self.pinchGestureRecognizer]) {
//        if ([b isEqual:self.panGestureRecognizer] || [b isEqual:self.rotateGestureRecognizer]) {
//            return YES;
//        }
//    }
//    return NO;
//}

#pragma mark - Extensions

- (void)loadExtensionItem {
    if ([self.itemProvider hasItemConformingToTypeIdentifier:@"public.movie"]) {
        [self.itemProvider loadItemForTypeIdentifier:@"public.movie" options:nil completionHandler:^(id response, NSError *error) {
            NSURL *movieURL = (NSURL *)response;
            NSData *videoData = [NSData dataWithContentsOfURL:movieURL];
            
            if (movieURL) {
                [self prepareVideoForPlaying:movieURL];
                
                self.playerView.playWhenReady = YES;
            }
        }];
    }
}

#pragma mark - Video

- (void)prepareVideoForPlaying:(NSURL *)movUrl {
    self.playerView.URL = movUrl;
}

#pragma mark - UITableViewDataSource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    YACrosspostCell *cell = [tableView dequeueReusableCellWithIdentifier:kCrosspostCellId forIndexPath:indexPath];
    YAShareGroup *group = [self.groups objectAtIndex:indexPath.row];
    [cell setGroupTitle:group.name];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return XPCellHeight;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.groups count];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self renderButton:[[tableView indexPathsForSelectedRows] count]];
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self renderButton:[[tableView indexPathsForSelectedRows] count]];
}

#pragma mark - UITableViewDelegate

#pragma mark - UI helpers

- (void)renderButton:(NSUInteger) count {
    if(count > 0){
        NSString *title;
        if(count == 1){
            title = @"Post to 1 group";
        } else {
            title = [NSString stringWithFormat:@"Post to %lu groups", (unsigned long)count];
        }
        [self.confirmCrosspost setTitle:title forState:UIControlStateNormal];
        [UIView animateWithDuration:0.2 delay:0.0 options:UIViewAnimationOptionAllowAnimatedContent animations:^{
            [self.confirmCrosspost setTransform:CGAffineTransformIdentity];
        } completion:^(BOOL finished) {
            
        }];
    } else {
        [UIView animateWithDuration:0.2 delay:0.0 options:UIViewAnimationOptionAllowAnimatedContent animations:^{
            [self.confirmCrosspost setTransform:CGAffineTransformMakeTranslation(0, self.confirmCrosspost.frame.size.height)];
        } completion:^(BOOL finished) {
            
        }];
    }
}

- (void)toggleEditingCaption:(BOOL)editing {
    self.editingCaption = editing;
    if (editing) {
        self.captionButton.hidden = YES;
        self.groupsList.hidden = YES;
        self.crossPostPrompt.hidden = YES;
        self.confirmCrosspost.hidden = YES;
        self.serverCaptionTextView.hidden = YES;
        self.captionTapRecognizer.enabled = NO;
    } else {
        self.captionButton.hidden = NO;
        self.groupsList.hidden = NO;
        self.crossPostPrompt.hidden = NO;
        self.confirmCrosspost.hidden = NO;
        self.serverCaptionTextView.hidden = NO;
        self.captionTapRecognizer.enabled = YES;
    }
}

//- (void)beginEditableCaptionAtPoint:(CGPoint)point initalText:(NSString *)text initalTransform:(CGAffineTransform)transform {
//    self.textFieldCenter = point;
//    self.textFieldTransform = transform;
//    self.editableCaptionWrapperView = [[UIView alloc] initWithFrame:CGRectInfinite];
//    
//    self.editableCaptionTextView = [self textViewWithCaptionAttributes];
//    self.editableCaptionTextView.text = text;
//    
//    [self resizeTextAboveKeyboardWithAnimation:NO];
//    
//    [self.editableCaptionWrapperView addSubview:self.editableCaptionTextView];
//    [self.view addSubview:self.editableCaptionWrapperView];
//    
//    [self.editableCaptionTextView becomeFirstResponder];
//}

//// Shared with \c YAVideoPage
//- (UITextView *)textViewWithCaptionAttributes {
//    UITextView *textView = [UITextView new];
//    textView.alpha = 1;
//    NSAttributedString *string = [[NSAttributedString alloc] initWithString:@"." attributes:@{
//                                                                                              NSStrokeColorAttributeName:[UIColor whiteColor],
//                                                                                              NSStrokeWidthAttributeName:[NSNumber numberWithFloat:-CAPTION_STROKE_WIDTH]
//                                                                                              }];
//    [textView setAttributedText:string];
//    [textView setBackgroundColor: [UIColor clearColor]]; //[UIColor colorWithWhite:1.0 alpha:0.1]];
//    [textView setTextColor:PRIMARY_COLOR];
//    [textView setFont:[UIFont fontWithName:CAPTION_FONT size:CAPTION_FONT_SIZE]];
//    
//    [textView setTextAlignment:NSTextAlignmentCenter];
//    [textView setAutocorrectionType:UITextAutocorrectionTypeNo];
//    [textView setReturnKeyType:UIReturnKeyDone];
//    [textView setScrollEnabled:NO];
//    textView.textContainer.lineFragmentPadding = 0;
//    textView.textContainerInset = UIEdgeInsetsZero;
//    textView.delegate = self;
//    
//    return textView;
//}

//- (void)resizeTextAboveKeyboardWithAnimation:(BOOL)animated {
//    NSString *captionText = [self.editableCaptionTextView.text length] ? self.editableCaptionTextView.text : @"A";
//    CGSize size = [self sizeThatFitsString:captionText];
//    CGRect wrapperFrame = CGRectMake((self.view.frame.size.width / 2.f) - (size.width/2.f) - CAPTION_WRAPPER_INSET,
//                                     (self.view.frame.size.height / 2.f) - (size.height/2.f) - CAPTION_WRAPPER_INSET,
//                                     size.width + (2*CAPTION_WRAPPER_INSET),
//                                     size.height + (2*CAPTION_WRAPPER_INSET));
//    
//    CGRect captionFrame = CGRectMake(CAPTION_WRAPPER_INSET, 0, size.width, size.height);
//    
//    if (animated) {
//        [UIView animateWithDuration:0.2f animations:^{
//            self.editableCaptionWrapperView.frame = wrapperFrame;
//            self.editableCaptionTextView.frame = captionFrame;
//        }];
//    } else {
//        self.editableCaptionWrapperView.frame = wrapperFrame;
//        self.editableCaptionTextView.frame = captionFrame;
//    }
//}

//- (void)doneEditingTapOut:(id)sender {
//    [self doneTypingCaption];
//}
//
//- (void)doneTypingCaption {
//    [self.view removeGestureRecognizer:self.captionTapOutGestureRecognizer];
//    
//    [self.editableCaptionTextView resignFirstResponder];
//    [self.captionBlurOverlay removeFromSuperview];
//    
//    if (![self.editableCaptionTextView.text length]) {
//        [self closeButtonPressed:nil];
//    } else {
//        [self moveTextViewBackToSpot];
//    }
//}

//#pragma mark - Caption positioning
//
//- (void)moveTextViewBackToSpot {
//    CGFloat fixedWidth = MAX_CAPTION_WIDTH;
//    CGSize newSize = [self.editableCaptionTextView sizeThatFits:CGSizeMake(fixedWidth, MAXFLOAT)];
//    CGRect captionFrame = CGRectMake(CAPTION_WRAPPER_INSET, CAPTION_WRAPPER_INSET, newSize.width, newSize.height);
//    CGRect wrapperFrame = CGRectMake(self.textFieldCenter.x - (newSize.width/2.f) - CAPTION_WRAPPER_INSET,
//                                     self.textFieldCenter.y - (newSize.height/2.f) - CAPTION_WRAPPER_INSET,
//                                     newSize.width + (2.f*CAPTION_WRAPPER_INSET),
//                                     newSize.height + (2.f*CAPTION_WRAPPER_INSET));
//    
//    // sort of hacky way to enable confirming/cancelling caption when near buttons
//    [self.view addSubview:self.captionButtonContainer];
//    
//    [UIView animateWithDuration:0.2f animations:^{
//        self.editableCaptionWrapperView.frame = wrapperFrame;
//        self.editableCaptionTextView.frame = captionFrame;
//        self.editableCaptionWrapperView.transform = self.textFieldTransform;
//    } completion:^(BOOL finished) {
//        [self.editableCaptionWrapperView addGestureRecognizer:self.panGestureRecognizer];
//        [self.editableCaptionWrapperView addGestureRecognizer:self.rotateGestureRecognizer];
//        [self.editableCaptionWrapperView addGestureRecognizer:self.pinchGestureRecognizer];
//    }];
//}
//
//- (void)positionTextViewAboveKeyboard{
//    self.editableCaptionWrapperView.transform = CGAffineTransformIdentity;
//    [self.editableCaptionWrapperView removeGestureRecognizer:self.panGestureRecognizer];
//    [self.editableCaptionWrapperView removeGestureRecognizer:self.rotateGestureRecognizer];
//    [self.editableCaptionWrapperView removeGestureRecognizer:self.pinchGestureRecognizer];
//    
//    [self resizeTextAboveKeyboardWithAnimation:YES];
//}
//
//- (float)doesFit:(UITextView*)textView string:(NSString *)myString range:(NSRange) range;
//{
//    CGSize maxFrame = [self sizeThatFitsString:@"AA\nAA\nAA"];
//    maxFrame.width = MAX_CAPTION_WIDTH;
//    
//    NSMutableAttributedString *atrs = [[NSMutableAttributedString alloc] initWithAttributedString: textView.textStorage];
//    [atrs replaceCharactersInRange:range withString:myString];
//    
//    NSTextStorage *textStorage = [[NSTextStorage alloc] initWithAttributedString:atrs];
//    NSTextContainer *textContainer = [[NSTextContainer alloc] initWithSize: CGSizeMake(maxFrame.width, FLT_MAX)];
//    NSLayoutManager *layoutManager = [[NSLayoutManager alloc] init];
//    
//    [layoutManager addTextContainer:textContainer];
//    [textStorage addLayoutManager:layoutManager];
//    float textHeight = [layoutManager
//                        usedRectForTextContainer:textContainer].size.height;
//    
//    if (textHeight >= maxFrame.height - 1) {
//        DLog(@" textHeight >= maxViewHeight - 1");
//        return NO;
//    } else
//        return YES;
//}

//#pragma mark - Caption helpers
//
//- (void)commitCurrentCaption {
//    if (self.editableCaptionTextView) {
//        [self.editableCaptionWrapperView removeGestureRecognizer:self.panGestureRecognizer];
//        [self.editableCaptionWrapperView removeGestureRecognizer:self.rotateGestureRecognizer];
//        [self.editableCaptionWrapperView removeGestureRecognizer:self.pinchGestureRecognizer];
//        [self.editableCaptionTextView removeGestureRecognizer:self.captionTapRecognizer];
//        [self.view removeGestureRecognizer:self.captionTapRecognizer];
//        
//        NSString *text = self.editableCaptionTextView.text;
//        CGFloat x = ceil(self.textFieldCenter.x / self.view.frame.size.width * 10000.0) / 10000.0;
//        CGFloat y = ceil(self.textFieldCenter.y / self.view.frame.size.height * 10000.0) / 10000.0;
//        
//        CGAffineTransform t = self.textFieldTransform;
//        CGFloat scale = sqrt(t.a * t.a + t.c * t.c);
//        scale = ceil(scale / CAPTION_SCREEN_MULTIPLIER * 10000.0) / 10000.0;
//        
//        CGFloat rotation = ceil(atan2f(t.b, t.a) * 10000.0) / 10000.0;
//        
//        self.serverCaptionWrapperView = self.editableCaptionWrapperView;
//        self.serverCaptionTextView = self.editableCaptionTextView;
//        self.editableCaptionWrapperView = nil;
//        self.editableCaptionTextView = nil;
//        self.serverCaptionTextView.editable = NO;
//        [self.view insertSubview:self.serverCaptionWrapperView aboveSubview:self.playerView];
//        [self.captionButtonContainer removeFromSuperview];
//        [self.captionButton removeFromSuperview];
////        [self.video updateCaption:text withXPosition:x yPosition:y scale:scale rotation:rotation];
//    }
//}
//
//#pragma mark - UITextViewDelegate
//
//- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
//    
//    if([text isEqualToString:@"\n"]) {
//        [self doneTypingCaption];
//        return NO;
//    }
//    
//    return [self doesFit:textView string:text range:range];
//}
//
//- (BOOL)textViewShouldBeginEditing:(UITextView *)textView {
//    UIVisualEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
//    
//    self.captionBlurOverlay = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
//    
//    self.captionBlurOverlay.frame = self.view.bounds;
//    [self.view insertSubview:self.captionBlurOverlay belowSubview:self.editableCaptionWrapperView];
////    [self.captionBlurOverlay addSubview:self.cancelWhileTypingButton];
//    
//    if (self.editableCaptionTextView) {
//        [self positionTextViewAboveKeyboard];
//    }
//    
//    return YES;
//}
//
//- (void)textViewDidChange:(UITextView *)textView {
//    // Should only be called while keyboard is up
//    [self resizeTextAboveKeyboardWithAnimation:NO];
//}
//
//- (void)textViewDidBeginEditing:(UITextView *)textView {
//    self.captionTapOutGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doneEditingTapOut:)];
//    [self.view addGestureRecognizer:self.captionTapOutGestureRecognizer];
//}

#pragma mark - Actions

- (void)confirmCrosspost:(id)sender {
    
}

- (void)closeButtonPressed:(id)sender {
    
}

//- (void)doneButtonPressed:(id)sender {
//    [self toggleEditingCaption:NO];
//    [self commitCurrentCaption];
//}

- (void)captionButtonPressed:(id)sender {
    float randomX = ((float)rand() / RAND_MAX) * 100;
    float randomY = ((float)rand() / RAND_MAX) * 200;
    CGPoint loc = CGPointMake(self.view.frame.size.width/2 - 50 + randomX, self.view.frame.size.height/2 - randomY);
    
    [self addCaptionOverlays:loc];
}

- (void)handleTap:(UITapGestureRecognizer *)tapGestureRecognizer {
    CGPoint loc = [tapGestureRecognizer locationInView:self.view];
    
    [self addCaptionOverlays:loc];
}

- (void)addCaptionOverlays:(CGPoint)loc {
    [self toggleEditingCaption:YES];
    
    float randomRotation = ((float)rand() / RAND_MAX) * .4;
    CGAffineTransform t = CGAffineTransformConcat(CGAffineTransformMakeScale(CAPTION_DEFAULT_SCALE * CAPTION_SCREEN_MULTIPLIER,
                                                                             CAPTION_DEFAULT_SCALE * CAPTION_SCREEN_MULTIPLIER), CGAffineTransformMakeRotation(-.2 + randomRotation));
    
    YAApplyCaptionView *applyCaptionView = [[YAApplyCaptionView alloc] initWithFrame:self.view.bounds captionPoint:loc initialText:@"" initialTransform:t];
    
    [self.view addSubview:applyCaptionView];
}

//- (void)handlePan:(UIPanGestureRecognizer *)recognizer {
//    CGPoint translation = [recognizer translationInView:self.view];
//    recognizer.view.center = CGPointMake(recognizer.view.center.x + translation.x,
//                                         MIN(recognizer.view.center.y + translation.y, self.view.frame.size.height*.666));
//    
//    [recognizer setTranslation:CGPointMake(0, 0) inView:self.view];
//    
//    //    if (recognizer.state == UIGestureRecognizerStateBegan && self.captionTextView.isFirstResponder)
//    //        [self doneEditingCaption];
//    
//    if (recognizer.state == UIGestureRecognizerStateEnded) {
//        
//        CGPoint finalPoint = recognizer.view.center;
//        recognizer.view.center = finalPoint;
//        self.textFieldCenter = finalPoint;
//    }
//}
//
//- (void)handleRotate:(UIRotationGestureRecognizer *)recognizer {
//    CGAffineTransform newTransform = CGAffineTransformRotate(recognizer.view.transform, recognizer.rotation);
//    recognizer.view.transform = newTransform;
//    recognizer.rotation = 0;
//    self.textFieldTransform = newTransform;
//}
//
//- (void)handlePinch:(UIPinchGestureRecognizer *)recognizer {
//    CGAffineTransform newTransform = CGAffineTransformScale(recognizer.view.transform, recognizer.scale, recognizer.scale);
//    recognizer.view.transform = newTransform;
//    recognizer.scale = 1;
//    self.textFieldTransform = newTransform;
//}
//
//#pragma mark - Text calculation
//
//- (CGSize)sizeThatFitsString:(NSString *)string {
//    CGRect frame = [string boundingRectWithSize:CGSizeMake(MAX_CAPTION_WIDTH, CGFLOAT_MAX)
//                                        options:NSStringDrawingUsesLineFragmentOrigin
//                                     attributes:@{ NSFontAttributeName:[UIFont fontWithName:CAPTION_FONT size:CAPTION_FONT_SIZE],
//                                                   NSStrokeColorAttributeName:[UIColor whiteColor],
//                                                   NSStrokeWidthAttributeName:[NSNumber numberWithFloat:-CAPTION_STROKE_WIDTH] } context:nil];
//    return frame.size;
//}

@end
