//
//  YACameraViewController.m
//  Yaga
//
//  Created by valentinkovalski on 12/18/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import "YACameraViewController.h"

#import "YAUser.h"
#import "YAUtils.h"
#import "YAAssetsCreator.h"
#import "YACameraManager.h"

#import <CoreTelephony/CTCall.h>
#import <CoreTelephony/CTCallCenter.h>

#import <QuartzCore/QuartzCore.h>
#import "YAGroupsNavigationController.h"
#import "YAFindGroupsViewConrtoller.h"
#import "YACreateGroupNavigationController.h"
#import "NameGroupViewController.h"
#import "YAEditVideoViewController.h"
#import "YAGifGridViewController.h"
#import "YAGroupsListViewController.h"
#import "YAProgressView.h"

#import "YAPopoverView.h"
#import "QuartzCore/CALayer.h"

#define BUTTON_SIZE (VIEW_WIDTH / 7)
#define HEADER_HEIGHT 60.f


#define INFO_PADDING 10.f
#define INFO_SIZE 36.f

#define kUnviwedBadgeWidth 10

@interface YACameraViewController () <YACameraManagerDelegate>

@property (nonatomic, strong) YACameraView *cameraView;

@property (strong, nonatomic) UIView *white;
@property (strong, nonatomic) NSDate *recordingTime;

@property (nonatomic) BOOL flash;
@property (strong, nonatomic) NSNumber *previousBrightness;

@property (strong, nonatomic) NSMutableArray *cameraAccessories;

@property (strong, nonatomic) UIView *recordingIndicator;

@property (strong, nonatomic) UILabel *recordingMessage;
@property (strong, nonatomic) UIView *bigRecordingIndicator;

@property (strong, nonatomic) UIButton *switchCameraButton;
@property (strong, nonatomic) UIButton *flashButton;
@property (strong, nonatomic) UIButton *doneRecordingButton;
@property (strong, nonatomic) UIButton *gridButton;

@property (strong, nonatomic) YAProgressView *animatedRecorder;
@property (strong, nonatomic) UIView *recordingCircle;

@property (nonatomic) BOOL audioInputAdded;

@property (nonatomic, strong) CTCallCenter *callCenter;

@property double animationStartTime;

//@property NSUInteger filterIndex;
//@property (strong, nonatomic) UISwipeGestureRecognizer *swipeCameraLeft;
//@property (strong, nonatomic) UISwipeGestureRecognizer *swipeCameraRight;
//@property (strong, nonatomic) UILabel *filterLabel;
//@property (strong, nonatomic) NSArray *filters;
//@property (strong, nonatomic) AVAudioPlayer *audioPlayer;

@property (strong, nonatomic) YAPopoverView *popover;

@end

@implementation YACameraViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
//    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
    [[YACameraManager sharedManager] initCamera];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [YACameraManager sharedManager].delegate = self;
        [[YACameraManager sharedManager] setCameraView:self.cameraView];
    });
    
    if (!self.shownViaBackgrounding) {
        [[YACameraManager sharedManager] resumeCameraAndNeedsRestart:YES];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[YACameraManager sharedManager] pauseCameraAndStop:NO];
//    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationController.navigationBarHidden = YES;
    [YACameraManager sharedManager].delegate = self;
    
    self.cameraView = [[YACameraView alloc] initWithFrame:CGRectMake(0, 0, VIEW_WIDTH, VIEW_HEIGHT)];
    [self.cameraView setBackgroundColor:[UIColor blackColor]];
    [self.view addSubview:self.cameraView];
    [self.cameraView setUserInteractionEnabled:YES];
    self.cameraView.clipsToBounds = YES;
    self.cameraView.autoresizingMask = UIViewAutoresizingNone;
    
    self.cameraAccessories = [@[] mutableCopy];
    
    self.white = [[UIView alloc] initWithFrame:CGRectMake(0, 0, VIEW_WIDTH, VIEW_HEIGHT)];
    [self.white setBackgroundColor:[UIColor whiteColor]];
    [self.white setAlpha:0.8];
    
    [self.white setUserInteractionEnabled:YES];
    
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toggleFlash:)];
    tapGestureRecognizer.delegate = self;
    [self.white addGestureRecognizer:tapGestureRecognizer];
    
    self.switchCameraButton = [[UIButton alloc] initWithFrame:CGRectMake(self.cameraView.frame.size.width - BUTTON_SIZE - 8, 10, BUTTON_SIZE, BUTTON_SIZE)];
    //    switchButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.switchCameraButton addTarget:self action:@selector(switchCamera:) forControlEvents:UIControlEventTouchUpInside];
    [self.switchCameraButton setImage:[UIImage imageNamed:@"Switch"] forState:UIControlStateNormal];
    [self.switchCameraButton.imageView setContentMode:UIViewContentModeScaleAspectFit];
    
    [self.cameraAccessories addObject:self.switchCameraButton];
    [self.view addSubview:self.switchCameraButton];
    
    CGFloat flashSize = BUTTON_SIZE - 8;
    UIButton *flashButton = [[UIButton alloc] initWithFrame:CGRectMake(10, 10, flashSize, flashSize)];
    //    flashButton.translatesAutoresizingMaskIntoConstraints = NO;
    [flashButton addTarget:self action:@selector(toggleFlash:) forControlEvents:UIControlEventTouchUpInside];
    [flashButton setImage:[UIImage imageNamed:@"TorchOff"] forState:UIControlStateNormal];
    [flashButton.imageView setContentMode:UIViewContentModeScaleAspectFit];
    self.flashButton = flashButton;
    [self.cameraAccessories addObject:self.flashButton];
    [self.view addSubview:self.flashButton];
    
// Filters
//    self.swipeCameraLeft = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipedCameraLeft:)];
//    self.swipeCameraLeft.direction = UISwipeGestureRecognizerDirectionLeft;
//        [self.cameraView addGestureRecognizer:self.swipeCameraLeft];
//    self.swipeCameraRight = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipedCameraRight:)];
//    self.swipeCameraRight.direction = UISwipeGestureRecognizerDirectionRight;
//        [self.cameraView addGestureRecognizer:self.swipeCameraRight];
//    self.filters = @[@"#nofilter"];
//    self.filterIndex = 0;

    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didEnterBackground)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(willEnterForeground)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];

    
    const CGFloat doneButtonWidth = 90;
    self.doneRecordingButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.doneRecordingButton.frame = CGRectMake((self.cameraView.bounds.size.width - doneButtonWidth)/2, self.cameraView.bounds.size.height - doneButtonWidth - 10, doneButtonWidth, doneButtonWidth);
    self.doneRecordingButton.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
    [self.doneRecordingButton setImage:[[UIImage imageNamed:@"PaperPlane"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    [self.doneRecordingButton addTarget:self action:@selector(doneRecordingTapped) forControlEvents:UIControlEventTouchUpInside];
    self.doneRecordingButton.imageEdgeInsets = UIEdgeInsetsMake(25, 25, 25, 25);
//    self.doneRecordingButton.tintColor = [UIColor whiteColor];
    [self.doneRecordingButton.imageView setContentMode:UIViewContentModeScaleAspectFit];
    self.doneRecordingButton.imageView.tintColor = [UIColor whiteColor];
    
    [self.doneRecordingButton setAlpha:0.0];
    
    [self.view addSubview:self.doneRecordingButton];

    self.recordingCircle = [[UIView alloc] initWithFrame:self.doneRecordingButton.frame];
    
    self.recordingCircle.layer.borderColor = [UIColor whiteColor].CGColor;
    self.recordingCircle.layer.borderWidth = 5.0f;
    self.recordingCircle.layer.cornerRadius = doneButtonWidth/2;
    [self.recordingCircle setAlpha:0.0];
    [self.recordingCircle setUserInteractionEnabled:NO];
    [self.view addSubview:self.recordingCircle];

    
    self.gridButton = [[UIButton alloc] initWithFrame:CGRectMake(VIEW_WIDTH - BUTTON_SIZE - 10, VIEW_HEIGHT - BUTTON_SIZE - 10, BUTTON_SIZE, BUTTON_SIZE)];
    self.gridButton.imageEdgeInsets = UIEdgeInsetsMake(5, 5, 5, 5);
    [self.gridButton setImage:[UIImage imageNamed:@"Grid"] forState:UIControlStateNormal];
    self.gridButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.gridButton addTarget:self action:@selector(gridButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.gridButton];
    
    //stop recording on incoming call
    void (^block)(CTCall*) = ^(CTCall* call) {
        DLog(@"Phone call received, state:%@.", call.callState);
    };
    self.callCenter = [[CTCallCenter alloc] init];
    self.callCenter.callEventHandler = block;
    
    CGFloat redDotSize = 24;
    self.recordingIndicator = [[UIView alloc] initWithFrame:CGRectMake(VIEW_WIDTH/2 - redDotSize/2, 24, redDotSize, redDotSize)];
    [self.recordingIndicator setBackgroundColor:[UIColor redColor]];
    self.recordingIndicator.layer.cornerRadius = redDotSize/2;
    self.recordingIndicator.layer.masksToBounds = YES;
    
    [self.recordingIndicator setAlpha:1.0];
//    [self.view addSubview:self.recordingIndicator];
    
//    NSAttributedString *string = [[NSAttributedString alloc] initWithString:@"Recording" attributes:@{
//                                                                                                     NSStrokeWidthAttributeName: @8.0,
//                                                                                                     NSStrokeColorAttributeName: [UIColor whiteColor]
//                                                                                                     }];
    
    self.recordingMessage = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, VIEW_WIDTH * 2.0f / 3.0f, 36)];
    [self.recordingMessage setText:@"Recording"];
    [self.recordingMessage setCenter:CGPointMake(VIEW_WIDTH/2, VIEW_HEIGHT - 12 - 24)];
    [self.recordingMessage setFont:[UIFont fontWithName:BOLD_FONT size:24]];
    [self.recordingMessage setTextColor:[UIColor whiteColor]];
    [self.recordingMessage setTextAlignment:NSTextAlignmentCenter];
    
    self.recordingMessage.layer.shadowColor = [UIColor blackColor].CGColor;
    self.recordingMessage.layer.shadowOffset = CGSizeMake(3.0f, 3.0f);
    self.recordingMessage.layer.shadowRadius = 0.0f;
    self.recordingMessage.layer.shadowOpacity = 1.0f;
    self.recordingMessage.alpha = 0.0;
    [self.view addSubview:self.recordingMessage];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    [self startRecordingAnimation];
    self.recordingTime = [NSDate date];

}

- (void)startRecordingAnimation {
    
    [self.animatedRecorder removeFromSuperview];
    
    self.animatedRecorder = [[YAProgressView alloc] initWithFrame:self.doneRecordingButton.frame];
    self.animatedRecorder.indeterminate = YES;
    self.animatedRecorder.radius = self.doneRecordingButton.frame.size.width/2 - 5.0f;
    self.animatedRecorder.lineWidth = 5;
    self.animatedRecorder.showsText = NO;
    self.animatedRecorder.tintColor = [UIColor redColor];
    [self.animatedRecorder setUserInteractionEnabled:NO];
    [self.animatedRecorder setBackgroundColor:[UIColor clearColor]];
    
    [self.animatedRecorder configureIndeterminatePercent:0.1];
    
    UIView *progressBkgView = [[UIView alloc] initWithFrame:self.animatedRecorder.frame];
    progressBkgView.backgroundColor = [UIColor clearColor];
    self.animatedRecorder.backgroundView = progressBkgView;
    [self.animatedRecorder setAlpha:0.0];
    [self.view addSubview:self.animatedRecorder];

    [self.doneRecordingButton setAlpha:0.0];
    
    [self showRecordButton];
//    [UIView animateKeyframesWithDuration:1.618 delay:0.0 options:UIViewKeyframeAnimationOptionAllowUserInteraction animations:^{
//        //
//        [UIView addKeyframeWithRelativeStartTime:0.0 relativeDuration:0.2 animations:^{
//            //
//            [self.recordingMessage setAlpha:1.0];
//        }];
//
//        [UIView addKeyframeWithRelativeStartTime:0.8 relativeDuration:0.2 animations:^{
//            //
//            [self.recordingMessage setAlpha:0.0];
//        }];
//    } completion:^(BOOL finished) {
//        //
//        [self showRecordButton];
//    }];
    
//    self.doneRecordingButton.transform = CGAffineTransformMakeScale(0.8, 0.8);
    self.animatedRecorder.transform = CGAffineTransformMakeScale(0.8, 0.8);
    
    [self.animatedRecorder setCustomText:@"REC"];
    self.animatedRecorder.textLabel.layer.shadowColor = [UIColor blackColor].CGColor;
    self.animatedRecorder.textLabel.layer.shadowOffset = CGSizeMake(1.0f, 1.0f);
    self.animatedRecorder.textLabel.layer.shadowRadius = 0.0f;
    self.animatedRecorder.textLabel.layer.shadowOpacity = 1.0f;
    self.recordingMessage.alpha = 0.0;

    
    [UIView animateWithDuration:.618 delay:0.0 usingSpringWithDamping:0.7 initialSpringVelocity:0.7 options:0 animations:^{
        //
        [self.animatedRecorder setAlpha:1.0];
        [self.recordingCircle setAlpha:1.0];
        self.animatedRecorder.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished) {
        //
    }];
    
    [UIView animateWithDuration:.618 delay:0.618*2 usingSpringWithDamping:0.7 initialSpringVelocity:0.7 options:0 animations:^{
        //
        [self.animatedRecorder.textLabel setAlpha:0.0];
        [self.animatedRecorder.textLabel setTransform:CGAffineTransformMakeScale(0.5, 0.5)];
    } completion:^(BOOL finished) {
        //
    }];

    [self.doneRecordingButton setTransform:CGAffineTransformMakeScale(0.5, 0.5)];
    [UIView animateWithDuration:.618 delay:0.618*2.5 usingSpringWithDamping:0.7 initialSpringVelocity:0.7 options:0 animations:^{
        //
        [self.doneRecordingButton setAlpha:1.0];
        [self.doneRecordingButton setTransform:CGAffineTransformIdentity];
    } completion:^(BOOL finished) {
        //
    }];

}

- (void)showRecordButton {
    
    
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
}

#pragma mark - recording

//val: refactor, method copied from endHold but without if(self.recording) condition
- (void)doneRecordingTapped {
    
    if(self.flash){
        [self setFlashMode:NO];
    }
    
    NSDate *recordingFinished = [NSDate date];
    NSTimeInterval executionTime = [recordingFinished timeIntervalSinceDate:self.recordingTime];
    
    if (executionTime > 0.5) {
        [self stopRecordingVideo];
    }
}

- (void)stopRecordingVideo {
    [[YACameraManager sharedManager] stopContiniousRecordingWithCompletion:^(NSURL *recordedURL) {
        YAEditVideoViewController *vc = [YAEditVideoViewController new];
        vc.videoUrl = recordedURL;
        vc.previewImage = [[YACameraManager sharedManager] capturePreviewImage];
        
        YAGroupsNavigationController *navVC = (YAGroupsNavigationController *)self.navigationController;
        vc.transitioningDelegate = navVC;
        vc.modalPresentationStyle = UIModalPresentationCustom;
        
        vc.showsStatusBarOnDismiss = NO;
        
        CGRect initialFrame = [UIApplication sharedApplication].keyWindow.bounds;
        
        CGAffineTransform initialTransform = CGAffineTransformMakeTranslation(0, VIEW_HEIGHT * .6); //(0.2, 0.2);
        initialTransform = CGAffineTransformScale(initialTransform, 0.3, 0.3);
        //    initialFrame.origin.y += self.view.frame.origin.y;
        //    initialFrame.origin.x = 0;
        
        [navVC setInitialAnimationFrame: initialFrame];
        [navVC setInitialAnimationTransform:initialTransform];

        DLog(@"recording url: %@", recordedURL);
        // We don't actually want this to animate in, but the dismiss animation doesnt work if animated = NO;
        // So set the initial frame to the end frame.
        [self presentViewController:vc animated:YES completion:nil];

    }];
}

- (void)switchCamera:(id)sender {
    [self setFlashMode:NO];
    [[YACameraManager sharedManager] switchCamera];
}

- (YACameraView *)currentCameraView {
    return self.cameraView;
}

#pragma mark - flash

- (void)setFrontFacingFlash:(BOOL)showFlash {
    if(!showFlash) {
        // turn flash off
        if(self.previousBrightness){
            [[UIScreen mainScreen] setBrightness:[self.previousBrightness floatValue]];
        }
        [self.white removeFromSuperview];
    } else {
        // turn flash on
        self.previousBrightness = [NSNumber numberWithFloat: [[UIScreen mainScreen] brightness]];
        [[UIScreen mainScreen] setBrightness:1.0];
        [self.view addSubview:self.white];
        
        [self.view bringSubviewToFront:self.cameraView];
        [self showCameraAccessories:YES];
    }
}

- (void)toggleFlash:(id)sender {
    [self setFlashMode:!self.flash];
}

- (void)setFlashMode:(BOOL)flashOn {
    self.flash = flashOn;
    DLog(@"switching flash mode");
    [self configureFlashButton:flashOn];
    [[YACameraManager sharedManager] toggleFlash:flashOn];
}

- (void)configureFlashButton:(BOOL)flash {
    if(flash){
        [self.flashButton setImage:[UIImage imageNamed:@"TorchOn"] forState:UIControlStateNormal];
    } else {
        [self.flashButton setImage:[UIImage imageNamed:@"TorchOff"] forState:UIControlStateNormal];
    }
}

- (void)didEnterBackground {
    if(self.flash){
        [self setFlashMode:NO];
    }
}

- (void)willEnterForeground {
    NSLog(@"will enter foreground?");
    [self startRecordingAnimation];
}

- (void)showCameraAccessories:(BOOL)show {
    for(UIView *v in self.cameraAccessories){
        [v setAlpha:show ? 1 : 0];
        if(show)
            [self.view bringSubviewToFront:v];
    }
}

- (void)gridButtonPressed {
    [self dismissAnimated];
}

- (void)showHumanityTooltip {
    [[[YAPopoverView alloc] initWithTitle:NSLocalizedString(@"FIRST_HUMANITY_VISIT_TITLE", @"") bodyText:NSLocalizedString(@"FIRST_HUMANITY_VISIT_BODY", @"") dismissText:@"Got it" addToView:self.parentViewController.view] show];
}

//
//- (void)showTooltipIfNeeded {
//    if(![[NSUserDefaults standardUserDefaults] boolForKey:kFirstVideoRecorded]) {
//        //first start tooltips
//
//        CGFloat tooltipPadding = recordButtonWidth / 2 * 3 / 2;
//
//        self.recordTooltipLabel = [[UILabel alloc] initWithFrame:CGRectMake(VIEW_WIDTH/2 - 108, 0, 120, VIEW_HEIGHT/2 - tooltipPadding)];
//        NSString *fontName = @"AvenirNext-HeavyItalic";
//        CGFloat fontSize = 26;
//
//        self.recordTooltipLabel.font = [UIFont fontWithName:fontName size:fontSize];
//        NSAttributedString *string = [[NSAttributedString alloc] initWithString:@"Tap and hold to record\n \u2B07\U0000FE0E"
//                                                                     attributes:@{
//                                                                                  NSStrokeColorAttributeName:[UIColor whiteColor],
//                                                                                  NSStrokeWidthAttributeName:[NSNumber numberWithFloat:-5.0]
//                                                                                  }];
//
//        self.recordTooltipLabel.textAlignment = NSTextAlignmentRight;
//        self.recordTooltipLabel.attributedText = string;
//        self.recordTooltipLabel.numberOfLines = 4;
//        self.recordTooltipLabel.textColor = PRIMARY_COLOR;
//        [self.view addSubview:self.recordTooltipLabel];
//
//
//        NSStringDrawingOptions option = NSStringDrawingUsesLineFragmentOrigin;
//
//        NSString *text = self.recordTooltipLabel.text;
//
//
//        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//            NSDictionary *attributes = @{NSFontAttributeName: [UIFont fontWithName:fontName size:fontSize]};
//            CGRect rect = [text boundingRectWithSize:CGSizeMake(self.recordTooltipLabel.frame.size.width, CGFLOAT_MAX)
//                                             options:option
//                                          attributes:attributes
//                                             context:nil];
//
//            dispatch_async(dispatch_get_main_queue(), ^{
//                CGRect frame = self.recordTooltipLabel.frame;
//                frame.origin.y = VIEW_HEIGHT/2 - rect.size.height - tooltipPadding;
//                frame.size.height = rect.size.height;
//                self.recordTooltipLabel.frame = frame;
//            });
//        });
//    }
//}


#pragma mark - filters (commented out)
//- (void)swipedCameraRight:(UISwipeGestureRecognizer *)recognizer {
//    DLog(@"swiped right");
//    [self removeFilterAtIndex:self.filterIndex];
//
//    self.filterIndex--;
//    if(self.filterIndex == -1){
//        self.filterIndex = [self.filters count] - 1;
//    }
//
//    [self addFilterAtIndex:self.filterIndex];
//
//    [self showFilterLabel:self.filters[self.filterIndex]];
//
//}
//
//- (void)swipedCameraLeft:(UISwipeGestureRecognizer *)recognizer {
//    DLog(@"swiped left");
//
//    // remove filter at index: self.filterIndex
//
//    // filterIndex++
//
//    // add filter at index: self.filterIndex
//
//    // show filter label: self.filters[self.filterIndex
//
//    [self removeFilterAtIndex:self.filterIndex];
//
//    self.filterIndex++;
//    if(self.filterIndex > ([self.filters count] - 1)){
//        self.filterIndex = 0;
//    }
//
//    [self addFilterAtIndex:self.filterIndex];
//
//    [self showFilterLabel:self.filters[self.filterIndex]];
//}
//
//- (void) showFilterLabel:(NSString *) label {
////    [self.filterLabel.layer removeAllAnimations];
//    [self.filterLabel removeFromSuperview];
//
//    self.filterLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 300, 300)];
//    self.filterLabel.center = self.cameraView.center;
//    self.filterLabel.font = [UIFont fontWithName:BOLD_FONT size:36];
//    NSAttributedString *string = [[NSAttributedString alloc] initWithString:label
//                                                                 attributes:@{
//                                                                              NSStrokeColorAttributeName:[UIColor whiteColor],
//                                                                              NSStrokeWidthAttributeName:[NSNumber numberWithFloat:-2.0]
//                                                                              }];
//    [self.filterLabel setAttributedText:string];
//    [self.filterLabel setTextAlignment:NSTextAlignmentCenter];
//    [self.filterLabel setTextColor:PRIMARY_COLOR];
//
//
////    [self.filterLabel setText:label];
//
//    [self.filterLabel setAlpha:0.0];
//    [self.filterLabel setTransform:CGAffineTransformMakeScale(1.5, 1.5)];
//
//    [self.view addSubview:self.filterLabel];
//
//    [UIView animateKeyframesWithDuration:1.0 delay:0.0 options:0 animations:^{
//        //
//        [UIView addKeyframeWithRelativeStartTime:0.0 relativeDuration:0.05 animations:^{
//            //
//            self.filterLabel.transform = CGAffineTransformIdentity;
//            [self.filterLabel setAlpha:1.0];
//        }];
//
//        [UIView addKeyframeWithRelativeStartTime:0.95 relativeDuration:0.05 animations:^{
//            //
//            self.filterLabel.transform = CGAffineTransformMakeScale(0.5, 0.5);
//            [self.filterLabel setAlpha:0.0];
//        }];
//
//    } completion:^(BOOL finished) {
//        //
//        if(finished){
//            [self.filterLabel removeFromSuperview];
//        }
//    }];
//
//}
//
//- (void)removeFilterAtIndex:(NSUInteger)index {
//    switch (index) {
//        case 0:
//            // #nofilter
//            break;
//
//        case 1:
//            // beats
//            [self.audioPlayer stop];
//            self.audioPlayer = nil;
//
//            break;
//        default:
//            break;
//    }
//
//}
//
//- (void)addFilterAtIndex:(NSUInteger)index {
//    switch (index) {
//        case 0: {
//            // #nofilter
//            DLog(@"case 0");
//            break;
//
//        }
//        case 1: {
//            // beats
//            NSString *path = [[NSBundle mainBundle] pathForResource:@"snoop" ofType:@"mp3"];
//            NSURL *url = [NSURL fileURLWithPath:path];
//            self.audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:nil];
//            self.audioPlayer.numberOfLoops = -1;
//            [self.audioPlayer play];
//        }
//        default:
//            break;
//    }
//}

- (BOOL)blockCameraPresentationOnBackground {
    return YES;
}

@end
