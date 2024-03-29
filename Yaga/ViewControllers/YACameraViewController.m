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
#import <MobileCoreServices/UTCoreTypes.h>

#import <QuartzCore/QuartzCore.h>
#import "YASloppyNavigationController.h"
#import "YAMainTabBarController.h"
#import "YAFindGroupsViewConrtoller.h"
#import "YACreateGroupNavigationController.h"
#import "NameGroupViewController.h"
#import "YAEditVideoViewController.h"
#import "YAGroupsListViewController.h"
#import "YAProgressView.h"
#import "YABubbleView.h"

#import "YAPopoverView.h"
#import "QuartzCore/CALayer.h"

#define BUTTON_SIZE (VIEW_WIDTH / 8)
#define HEADER_HEIGHT 60.f


#define INFO_PADDING 10.f
#define INFO_SIZE 36.f

#define kUnviwedBadgeWidth 10

#define kStrobeInterval 0.07

@interface YACameraViewController () <YACameraManagerDelegate, UIGestureRecognizerDelegate,
    UIImagePickerControllerDelegate, UINavigationControllerDelegate> // navigation controller delegate reqd for image picker

@property (nonatomic, strong) YACameraView *cameraView;

@property (strong, nonatomic) UIView *white;
@property (strong, nonatomic) NSDate *recordingTime;

@property (nonatomic) BOOL flash;
@property (strong, nonatomic) NSNumber *previousBrightness;

@property (strong, nonatomic) NSMutableArray *cameraAccessories;

@property (strong, nonatomic) UIView *recordingIndicator;

@property (strong, nonatomic) UIView *bigRecordingIndicator;

@property (strong, nonatomic) UIButton *switchCameraButton;
@property (strong, nonatomic) UIButton *flashButton;
@property (strong, nonatomic) UIButton *doneRecordingButton;
@property (strong, nonatomic) UIButton *gridButton;
@property (strong, nonatomic) UIButton *uploadButton;

@property (strong, nonatomic) YAProgressView *animatedRecorder;
@property (strong, nonatomic) UIView *recordingCircle;

@property (nonatomic) BOOL audioInputAdded;

@property (nonatomic, strong) CTCallCenter *callCenter;

@property double animationStartTime;

@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;
@property (nonatomic, strong) MBProgressHUD *hud;

@property (nonatomic, strong) NSTimer *flashTimer;
@property (nonatomic, strong) NSTimer *strobeTimer;

//@property NSUInteger filterIndex;
//@property (strong, nonatomic) UISwipeGestureRecognizer *swipeCameraLeft;
//@property (strong, nonatomic) UISwipeGestureRecognizer *swipeCameraRight;
//@property (strong, nonatomic) UILabel *filterLabel;
//@property (strong, nonatomic) NSArray *filters;
//@property (strong, nonatomic) AVAudioPlayer *audioPlayer;

@property (strong, nonatomic) YAPopoverView *popover;

@property (strong, nonatomic) UIView *recordingTooltip;

@end

@implementation YACameraViewController

- (void)viewWillAppear:(BOOL)animated {
    
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
    
    self.edgesForExtendedLayout = UIRectEdgeAll;
    
    [super viewWillAppear:animated];
    [YACameraManager sharedManager].delegate = self;
    [[YACameraManager sharedManager] setCameraView:self.cameraView];
    if (![YACameraManager sharedManager].initialized) {
        [[YACameraManager sharedManager] initCamera];
        [[YACameraManager sharedManager] resumeCameraAndNeedsRestart:YES];
    } else if (!self.shownViaBackgrounding) {
        [[YACameraManager sharedManager] resumeCameraAndNeedsRestart:NO];
    } else {
        // Otherwise let app delegate handle it this time.
        self.shownViaBackgrounding = NO;
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [YAUtils setSeenCamera];
    
    [self startRecordingAnimation];
    self.recordingTime = [NSDate date];
       
    [[Mixpanel sharedInstance] track:@"Opened Camera"];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    
    [self.flashTimer invalidate];
    [self.strobeTimer invalidate];
    self.flashTimer = nil;
    self.strobeTimer = nil;

    [self.animatedRecorder removeFromSuperview];
    [self.doneRecordingButton setAlpha:0.0];
    [self.recordingCircle setAlpha:0.0];

    [[YACameraManager sharedManager] pauseCameraAndStop:NO];
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
    
    UIView *tapView = [[UIView alloc] initWithFrame:self.view.bounds];
    tapView.backgroundColor = [UIColor clearColor];
    [self.cameraView addSubview:tapView];
    UITapGestureRecognizer *doubleTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(switchCamera:)];
    doubleTapRecognizer.numberOfTapsRequired = 2;
    [tapView addGestureRecognizer:doubleTapRecognizer];
    
    self.white = [[UIView alloc] initWithFrame:CGRectMake(0, 0, VIEW_WIDTH, VIEW_HEIGHT)];
    [self.white setBackgroundColor:[UIColor whiteColor]];
    [self.white setAlpha:0.6];
    self.white.hidden = YES;
    [self.cameraView addSubview:self.white];
    UITapGestureRecognizer *killFrontFlashTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toggleFlash:)];
    killFrontFlashTapRecognizer.numberOfTapsRequired = 1;
    [self.white addGestureRecognizer:killFrontFlashTapRecognizer];
    [killFrontFlashTapRecognizer requireGestureRecognizerToFail:doubleTapRecognizer];
    
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
    [self.doneRecordingButton addTarget:self action:@selector(doneRecordingTapDown) forControlEvents:UIControlEventTouchDown];
    [self.doneRecordingButton addTarget:self action:@selector(doneRecordingTapCancel) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside | UIControlEventTouchDragExit | UIControlEventTouchDragOutside | UIControlEventTouchCancel];

    self.doneRecordingButton.imageEdgeInsets = UIEdgeInsetsMake(25, 25, 25, 25);
//    self.doneRecordingButton.tintColor = [UIColor whiteColor];
    [self.doneRecordingButton.imageView setContentMode:UIViewContentModeScaleAspectFit];
    self.doneRecordingButton.imageView.tintColor = [UIColor whiteColor];
    self.doneRecordingButton.adjustsImageWhenHighlighted = YES;
    [self.doneRecordingButton setAlpha:0.0];
    [self.doneRecordingButton setEnabled:NO];
    [self.view addSubview:self.doneRecordingButton];

    CGFloat bottomButtonPaddingX = (self.doneRecordingButton.frame.origin.x-BUTTON_SIZE)/2;
    CGFloat bottomButtonTopY = self.doneRecordingButton.center.y - (BUTTON_SIZE/2);
    
    self.switchCameraButton = [[UIButton alloc] initWithFrame:CGRectMake(VIEW_WIDTH - bottomButtonPaddingX - BUTTON_SIZE, bottomButtonTopY, BUTTON_SIZE, BUTTON_SIZE)];
    //    switchButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.switchCameraButton addTarget:self action:@selector(switchCamera:) forControlEvents:UIControlEventTouchUpInside];
    [self.switchCameraButton setImage:[UIImage imageNamed:@"Switch"] forState:UIControlStateNormal];
    [self.switchCameraButton.imageView setContentMode:UIViewContentModeScaleAspectFit];
    
    [self.cameraAccessories addObject:self.switchCameraButton];
    [self.view addSubview:self.switchCameraButton];
    
    //[YAUtils showBubbleWithText:@"Switch camera tooltip" bubbleWidth:220 forView:self.switchCameraButton];
    
    CGFloat flashSize = BUTTON_SIZE - 8;
    UIButton *flashButton = [[UIButton alloc] initWithFrame:CGRectMake(bottomButtonPaddingX+4, bottomButtonTopY+4, flashSize, flashSize)];
    //    flashButton.translatesAutoresizingMaskIntoConstraints = NO;
    [flashButton addTarget:self action:@selector(startFlashTimer) forControlEvents:UIControlEventTouchDown];
    [flashButton addTarget:self action:@selector(killStrobe) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside | UIControlEventTouchCancel];
    [flashButton setImage:[UIImage imageNamed:@"TorchOff"] forState:UIControlStateNormal];
    [flashButton.imageView setContentMode:UIViewContentModeScaleAspectFit];
    
    self.flashButton = flashButton;
    [self.cameraAccessories addObject:self.flashButton];
    [self.view addSubview:self.flashButton];
    
    //[YAUtils showBubbleWithText:@"Flash tooltip" bubbleWidth:220 forView:self.flashButton];
    
    self.recordingCircle = [[UIView alloc] initWithFrame:self.doneRecordingButton.frame];
    
    self.recordingCircle.layer.borderColor = [UIColor whiteColor].CGColor;
    self.recordingCircle.layer.borderWidth = 5.0f;
    [self.recordingCircle setBackgroundColor:[UIColor colorWithWhite:1 alpha:0.2]];
    self.recordingCircle.layer.cornerRadius = doneButtonWidth/2;
    [self.recordingCircle setAlpha:0.0];
    [self.recordingCircle setUserInteractionEnabled:NO];
    [self.view addSubview:self.recordingCircle];

    
    self.gridButton = [[UIButton alloc] initWithFrame:CGRectMake(10, 10, BUTTON_SIZE, BUTTON_SIZE)];
    self.gridButton.imageEdgeInsets = UIEdgeInsetsMake(5, 5, 5, 5);
    [self.gridButton setImage:[UIImage imageNamed:@"X"] forState:UIControlStateNormal];
    self.gridButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.gridButton addTarget:self action:@selector(gridButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.gridButton];

//    [YAUtils showBubbleWithText:@"Another bubble tooltip with arrow up" bubbleWidth:180 forView:self.gridButton];
    
    self.uploadButton = [[UIButton alloc] initWithFrame:CGRectMake(VIEW_WIDTH - BUTTON_SIZE - 10, 10, BUTTON_SIZE, BUTTON_SIZE)];
    self.uploadButton.imageEdgeInsets = UIEdgeInsetsMake(5, 5, 5, 5);
    [self.uploadButton setImage:[UIImage imageNamed:@"Import"] forState:UIControlStateNormal];
    self.uploadButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.uploadButton addTarget:self action:@selector(chooseFromCameraRoll) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.uploadButton];
    
    //stop recording on incoming call
    void (^block)(CTCall*) = ^(CTCall* call) {
        DLog(@"Phone call received, state:%@.", call.callState);
    };
    self.callCenter = [[CTCallCenter alloc] init];
    self.callCenter.callEventHandler = block;
    
//    NSAttributedString *string = [[NSAttributedString alloc] initWithString:@"Recording" attributes:@{
//                                                                                                     NSStrokeWidthAttributeName: @8.0,
//                                                                                                     NSStrokeColorAttributeName: [UIColor whiteColor]
//                                                                                                     }];
}

- (void)doneRecordingTapDown {
    self.panGesture.enabled = NO;
    self.recordingCircle.layer.borderColor = [[UIColor lightGrayColor] CGColor];
}

- (void)doneRecordingTapCancel {
    self.panGesture.enabled = YES;
    self.recordingCircle.layer.borderColor = [[UIColor whiteColor] CGColor];
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
    [self.doneRecordingButton setEnabled:NO];
    
    [self.recordingCircle setAlpha:0.0];
//    self.doneRecordingButton.transform = CGAffineTransformMakeScale(0.8, 0.8);
    
    [self.animatedRecorder setCustomText:@"REC"];
    self.animatedRecorder.textLabel.layer.shadowColor = [UIColor blackColor].CGColor;
    self.animatedRecorder.textLabel.layer.shadowOffset = CGSizeMake(1.0f, 1.0f);
    self.animatedRecorder.textLabel.layer.shadowRadius = 0.0f;
    self.animatedRecorder.textLabel.layer.shadowOpacity = 1.0f;
    [self.animatedRecorder.textLabel setAlpha:0.0];
    
    [self.animatedRecorder.textLabel setTransform:CGAffineTransformMakeScale(0.5, 0.5)];
    
    if(![YAUtils hasTappedRecord]){
        // Hide before showing so we don't add bubbles on bubbles on bubbles.
        [YAUtils hideBubbleWithText:@"The camera is always rolling.\nTap the check to finish recording"];
        [YAUtils showBubbleWithText:@"The camera is always rolling.\nTap the check to finish recording" bubbleWidth:230 forView:self.animatedRecorder];
    }

    [UIView animateWithDuration:.618 delay:0.0 usingSpringWithDamping:0.7 initialSpringVelocity:0.7 options:0 animations:^{
        //
        [self.animatedRecorder setAlpha:1.0];
        [self.recordingCircle setAlpha:1.0];
        [self.animatedRecorder.textLabel setTransform:CGAffineTransformIdentity];
        [self.animatedRecorder.textLabel setAlpha:1.0];
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
        [self.doneRecordingButton setEnabled:YES];
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
    [[Mixpanel sharedInstance] track:@"Done Recording Pressed"];
    
    [YAUtils setTappedRecord];
    [YAUtils hideBubbleWithText:@"The camera is always rolling.\nTap the check to finish recording"];

    if(self.flash){
        [self setFlashMode:NO];
    }
    
    NSDate *recordingFinished = [NSDate date];
    NSTimeInterval executionTime = [recordingFinished timeIntervalSinceDate:self.recordingTime];
    
    if (executionTime > MIN_VIDEO_DURATION) {
        [self stopRecordingVideo];
    }
}

- (void)presentTrimViewWithOutputUrl:(NSURL *)url duration:(NSTimeInterval)duration {
    YAEditVideoViewController *vc = [YAEditVideoViewController new];
    vc.videoUrl = url;
    vc.totalDuration = duration;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.activityIndicator removeFromSuperview];
        self.doneRecordingButton.hidden = NO;
        if (self.hud) {
            [self.hud hide:YES];
        }
        [self.navigationController pushViewController:vc animated:YES];
    });
}

- (void)stopRecordingVideo {
    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    self.activityIndicator.center = self.doneRecordingButton.center;
    [self.activityIndicator startAnimating];
    
    self.doneRecordingButton.hidden = YES;
    [self.view addSubview:self.activityIndicator];
    [[YACameraManager sharedManager] stopContiniousRecordingAndPrepareOutput:YES completion:^(NSURL *outputUrl, NSTimeInterval duration, NSError *error) {
        if (error) {
            dispatch_async(dispatch_get_main_queue(), ^{

                [self.activityIndicator removeFromSuperview];
                self.doneRecordingButton.hidden = NO;
                if (self.hud) {
                    [self.hud hide:YES];
                }
                [YAUtils showHudWithText:@"Sorry! Something went wrong."];

                [self startRecordingAnimation];
            });
        } else {
            [self presentTrimViewWithOutputUrl:outputUrl duration:duration];
        }
    }];
}

- (void)switchCamera:(id)sender {
    [self setFlashMode:NO];
    [[YACameraManager sharedManager] switchCamera];
    [[Mixpanel sharedInstance] track:@"Switch Camera Pressed"];

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
        [self.white setHidden:YES];
    } else {
        // turn flash on
        self.previousBrightness = [NSNumber numberWithFloat: [[UIScreen mainScreen] brightness]];
        [[UIScreen mainScreen] setBrightness:1.0];
        [self.white setHidden:NO];
    }
}

- (void)startFlashTimer {
    [self toggleFlash:nil];

    self.flashTimer = [NSTimer scheduledTimerWithTimeInterval:kStrobeInterval*3 target:self selector:@selector(startStrobe) userInfo:nil repeats:NO];
    self.panGesture.enabled = NO; // So you can drag while strobing
}

- (void)startStrobe {
    self.strobeTimer = [NSTimer scheduledTimerWithTimeInterval:kStrobeInterval target:self selector:@selector(toggleFlash:) userInfo:nil repeats:YES];
}

- (void)killStrobe {
    self.panGesture.enabled = YES;
    if (self.strobeTimer) {
        [self.strobeTimer invalidate];
        self.strobeTimer = nil;
        [self setFlashMode:NO];
    }
    [self.flashTimer invalidate];
    self.flashTimer = nil;
}

- (void)toggleFlash:(id)sender {
    [self setFlashMode:!self.flash];
    [[Mixpanel sharedInstance] track:@"Toggled Flash"];

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
    return NO; // YES;
}

#pragma mark - camera roll upload

- (void)chooseFromCameraRoll {
    DLog(@"Upload from camera roll pressed");
    [[Mixpanel sharedInstance] track:@"Upload from camera roll pressed"];

    self.hud = [YAUtils showIndeterminateHudWithText:@"One sec..."];
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    [picker setVideoMaximumDuration:MAXIMUM_TRIM_TOTAL_LENGTH];

    picker.allowsEditing = YES;
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    [picker setMediaTypes: [NSArray arrayWithObject:(NSString *)kUTTypeMovie]];
    [self presentViewController:picker animated:YES completion:^{
        [self.hud hide:NO];
    }];;
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    DLog(@"Did pick video from camera roll");
    [[Mixpanel sharedInstance] track:@"Did pick video from camera roll"];

    self.hud = [YAUtils showIndeterminateHudWithText:@"One sec..."];
    [picker dismissViewControllerAnimated:YES completion:^{
        NSString *mediaType = [info objectForKey:UIImagePickerControllerMediaType];
        if ([mediaType isEqualToString:(NSString *)kUTTypeMovie])
        {
            NSURL *videoURL = [info objectForKey:UIImagePickerControllerMediaURL];
            [[YAAssetsCreator sharedCreator] reformatExternalVideoAtUrl:videoURL withCompletion:^(NSURL *filePath, NSTimeInterval totalDuration, NSError *error) {
                [self presentTrimViewWithOutputUrl:filePath duration:totalDuration]; // hud will be dismissed after presenting trim
            }];
        } else {
            [self.hud hide:NO];
        }
    }];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    DLog(@"Cancelled picking video from camera roll");
    [[Mixpanel sharedInstance] track:@"Cancelled picking video from camera roll"];

    [picker dismissViewControllerAnimated:YES completion:NULL];
}

@end
