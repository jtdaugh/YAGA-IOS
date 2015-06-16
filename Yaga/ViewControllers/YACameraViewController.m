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

#import <CoreTelephony/CTCall.h>
#import <CoreTelephony/CTCallCenter.h>

#import <QuartzCore/QuartzCore.h>

typedef enum {
    YATouchDragStateInsideTrash,
    YATouchDragStateInsideFlip,
    YATouchDragStateOutside
} YATouchDragState;

@interface YACameraViewController ()

@property (strong, nonatomic) UIView *indicator;
@property (strong, nonatomic) UILabel *indicatorText;
@property (strong, nonatomic) UIView *white;
@property (strong, nonatomic) NSNumber *recording;
@property (strong, nonatomic) NSDate *recordingTime;
@property (strong, nonatomic) NSNumber *FrontCamera; // to remove
@property BOOL cancelledRecording;

@property (strong, nonatomic) NSNumber *previousBrightness;

@property (strong, nonatomic) AVCaptureSession *session; // to remove
@property (nonatomic) dispatch_queue_t sessionQueue; // to remove

@property (strong, nonatomic) AVCaptureMovieFileOutput *movieFileOutput; // to remove

@property (strong, nonatomic) NSMutableArray *cameraAccessories;
@property (strong, nonatomic) NSMutableArray *recordingAccessories;
@property (strong, nonatomic) UIButton *switchCameraButton;
@property (strong, nonatomic) UIButton *switchGroupsButton;
@property (strong, nonatomic) UIImageView *unviewedVideosBadge;
@property (strong, nonatomic) UIButton *groupButton;

@property (strong, nonatomic) UIButton *flashButton;
@property (strong, nonatomic) UIButton *recordButton;

@property (strong, nonatomic) UIButton *infoButton;

@property (strong, nonatomic) UILongPressGestureRecognizer *longPressFullScreenGestureRecognizer;
@property (strong, nonatomic) UILongPressGestureRecognizer *longPressRedButtonGestureRecognizer;
@property (nonatomic) BOOL audioInputAdded;

@property (nonatomic, strong) UILabel *recordTooltipLabel;

@property (nonatomic, strong) UIButton *openSettingsButton;

@property (nonatomic, strong) dispatch_semaphore_t recordingSemaphore;

@property (nonatomic, strong) CTCallCenter *callCenter;

@property (nonatomic, strong) NSMutableArray *currentRecordingURLs;
@property (strong, nonatomic) NSURL *currentlyRecordingUrl;
@property (strong, nonatomic) UIView *recordingIndicator;

@property (nonatomic) YATouchDragState lastTouchDragState;
@property (strong, nonatomic) UIView *switchCamZone;
@property (strong, nonatomic) UIView *trashZone;
@property (nonatomic, strong) UITapGestureRecognizer *switchCamZoneTapRecognizer;
@property (nonatomic, strong) UITapGestureRecognizer *trashZoneTapRecognizer;
@property (nonatomic, strong) UITapGestureRecognizer *scrollToTopTapRecognizer;
@property (nonatomic, strong) NSTimer *accidentalDragOffscreenTimer;

@property (strong, nonatomic) NSTimer *countdown;
@property int count;
@property (strong, nonatomic) UILabel *countdownLabel;

@property (strong, nonatomic) UISwipeGestureRecognizer *swipeEnlargeCamera;
@property (strong, nonatomic) UISwipeGestureRecognizer *swipeCollapseCamera;
@property BOOL largeCamera;

@property (nonatomic, assign) CGRect previousViewFrame;

@property NSUInteger filterIndex;
@property (strong, nonatomic) UISwipeGestureRecognizer *swipeCameraLeft;
@property (strong, nonatomic) UISwipeGestureRecognizer *swipeCameraRight;
@property (strong, nonatomic) UILabel *filterLabel;
@property (strong, nonatomic) NSArray *filters;
@property (strong, nonatomic) AVAudioPlayer *audioPlayer;

@end

@implementation YACameraViewController

- (id)init {
    self = [super init];
    if(self) {
        self.cameraView = [[AVCamPreviewView alloc] initWithFrame:CGRectMake(0, -0, VIEW_WIDTH, VIEW_HEIGHT / 2)];
        self.view.frame = CGRectMake(0, -0, VIEW_WIDTH, VIEW_HEIGHT / 2 + recordButtonWidth/2);
        [self.cameraView setBackgroundColor:[UIColor blackColor]];
//        [self.view addSubview:self.cameraView];
        [self.cameraView setUserInteractionEnabled:YES];
        self.cameraView.autoresizingMask = UIViewAutoresizingNone;
        
        self.gpuCameraView = [[GPUImageView alloc] initWithFrame:CGRectMake(0, 0, VIEW_WIDTH, VIEW_HEIGHT/2)];
        [self.gpuCameraView setBackgroundColor:[UIColor blackColor]];
        [self.view addSubview:self.gpuCameraView];
        [self.gpuCameraView setUserInteractionEnabled:YES];
        [self.gpuCameraView setFillMode:kGPUImageFillModePreserveAspectRatioAndFill];
        self.gpuCameraView.autoresizingMask = UIViewAutoresizingNone;
        
        self.cameraAccessories = [@[] mutableCopy];
        self.recordingAccessories = [@[] mutableCopy];
        
        self.white = [[UIView alloc] initWithFrame:CGRectMake(0, 0, VIEW_WIDTH, VIEW_HEIGHT)];
        [self.white setBackgroundColor:[UIColor whiteColor]];
        [self.white setAlpha:0.8];
        
        [self.white setUserInteractionEnabled:YES];
        
        UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(switchFlashMode:)];
        tapGestureRecognizer.delegate = self;
        [self.white addGestureRecognizer:tapGestureRecognizer];
        
        CGFloat size = 60;
        self.switchCameraButton = [[UIButton alloc] initWithFrame:CGRectMake(self.cameraView.frame.size.width-size- 10, 10, size, size)];
        //    switchButton.translatesAutoresizingMaskIntoConstraints = NO;
        [self.switchCameraButton addTarget:self action:@selector(switchCamera:) forControlEvents:UIControlEventTouchUpInside];
        [self.switchCameraButton setImage:[UIImage imageNamed:@"Switch"] forState:UIControlStateNormal];
        [self.switchCameraButton.imageView setContentMode:UIViewContentModeScaleAspectFit];
        
        [self.cameraAccessories addObject:self.switchCameraButton];
        [self.cameraView addSubview:self.switchCameraButton];
        
        UIButton *flashButton = [[UIButton alloc] initWithFrame:CGRectMake(10, 10, size - 10, size - 10)];
        //    flashButton.translatesAutoresizingMaskIntoConstraints = NO;
        [flashButton addTarget:self action:@selector(switchFlashMode:) forControlEvents:UIControlEventTouchUpInside];
        [flashButton setImage:[UIImage imageNamed:@"TorchOff"] forState:UIControlStateNormal];
        [flashButton.imageView setContentMode:UIViewContentModeScaleAspectFit];
        self.flashButton = flashButton;
        [self.cameraAccessories addObject:self.flashButton];
        [self.cameraView addSubview:self.flashButton];
        
        //current group
        CGFloat groupButtonXOrigin = flashButton.frame.origin.x + flashButton.frame.size.width + 5;
        self.groupButton = [[UIButton alloc] initWithFrame:CGRectMake(groupButtonXOrigin, 10, self.switchCameraButton.frame.origin.x - groupButtonXOrigin - 10 , size)];
        [self.groupButton addTarget:self action:@selector(openGroupOptions:) forControlEvents:UIControlEventTouchUpInside];
        [self.groupButton setTitle:[YAUser currentUser].currentGroup.name forState:UIControlStateNormal];
        [self.groupButton.titleLabel setFont:[UIFont fontWithName:BIG_FONT size:18]];
        self.groupButton.layer.shadowColor = [[UIColor blackColor] CGColor];
        self.groupButton.layer.shadowRadius = 1.0f;
        self.groupButton.layer.shadowOpacity = 1.0;
        self.groupButton.layer.shadowOffset = CGSizeZero;
        [self.cameraAccessories addObject:self.groupButton];
        [self.cameraView addSubview:self.groupButton];
        
        //record button
        self.recordButton = [[UIButton alloc] initWithFrame:CGRectMake(self.cameraView.frame.size.width/2.0 - recordButtonWidth/2.0, self.cameraView.frame.size.height - 1.0*recordButtonWidth/2.0, recordButtonWidth, recordButtonWidth)];
        [self.recordButton setBackgroundColor:[UIColor redColor]];
        [self.recordButton.layer setCornerRadius:recordButtonWidth/2.0];
        [self.recordButton.layer setBorderColor:[UIColor whiteColor].CGColor];
        [self.recordButton.layer setBorderWidth:4.0f];

        [self.cameraAccessories addObject:self.recordButton];
        [self.view addSubview:self.recordButton];
        
        //switch groups button
        
        self.switchGroupsButton = [[UIButton alloc] initWithFrame:CGRectMake(VIEW_WIDTH/2+30, self.cameraView.frame.size.height - 40, VIEW_WIDTH - VIEW_WIDTH/2-30-10, 40)];
        //        self.switchGroupsButton.backgroundColor= [UIColor yellowColor];
        [self.switchGroupsButton setContentHorizontalAlignment:UIControlContentHorizontalAlignmentRight];
        [self.switchGroupsButton.titleLabel setFont:[UIFont fontWithName:BIG_FONT size:18]];
        [self.switchGroupsButton addTarget:self action:@selector(toggleGroups:) forControlEvents:UIControlEventTouchUpInside];
        [self.switchGroupsButton setTitle:[NSString stringWithFormat:@"%@", NSLocalizedString(@"Groups", @"")] forState:UIControlStateNormal];
        
        CGFloat requiredWidth = [self.switchGroupsButton.titleLabel.attributedText size].width;
        CGRect tempFrame = self.switchGroupsButton.frame;
        tempFrame.origin.x = VIEW_WIDTH - 10 - requiredWidth;
        tempFrame.size.width = requiredWidth;
        [self.switchGroupsButton setFrame:tempFrame];
        
        self.switchGroupsButton.layer.shadowColor = [[UIColor blackColor] CGColor];
        self.switchGroupsButton.layer.shadowRadius = 1.0f;
        self.switchGroupsButton.layer.shadowOpacity = 1.0;
        self.switchGroupsButton.layer.shadowOffset = CGSizeZero;
        
        [self.cameraAccessories addObject:self.switchGroupsButton];
        [self.cameraView addSubview:self.switchGroupsButton];
        
        CGFloat infoSize = 36;
        self.infoButton = [[UIButton alloc] initWithFrame:CGRectMake(4, self.cameraView.frame.size.height - infoSize - 4, infoSize, infoSize)];
        //    switchButton.translatesAutoresizingMaskIntoConstraints = NO;
        [self.infoButton addTarget:self action:@selector(openGroupOptions:) forControlEvents:UIControlEventTouchUpInside];
        [self.infoButton setImage:[UIImage imageNamed:@"InfoWhite"] forState:UIControlStateNormal];
        [self.infoButton.imageView setContentMode:UIViewContentModeScaleAspectFit];
        
        [self.cameraAccessories addObject:self.infoButton];
        [self.cameraView addSubview:self.infoButton];
        
        CGFloat labelWidth = 96;
        self.countdownLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, labelWidth, labelWidth)];
        self.countdownLabel.alpha = 0.0;
        self.countdownLabel.center = CGPointMake(VIEW_WIDTH/2, VIEW_HEIGHT/2 - 100.0f);
        [self.countdownLabel setTextAlignment:NSTextAlignmentCenter];
        [self.countdownLabel setFont:[UIFont fontWithName:@"AvenirNext-HeavyItalic" size:72]];
        NSAttributedString *string = [[NSAttributedString alloc] initWithString:@"."
                                                                     attributes:@{
                                                                                  NSStrokeColorAttributeName:[UIColor whiteColor],
                                                                                  NSStrokeWidthAttributeName:[NSNumber numberWithFloat:-5.0]
                                                                                  }];
        self.countdownLabel.attributedText = string;
        [self.countdownLabel setTextColor:PRIMARY_COLOR];
        [self.cameraView addSubview:self.countdownLabel];
        
        //unviewed badge
        const CGFloat badgeWidth = 10;
        CGFloat badgeMargin = 8;
        self.unviewedVideosBadge = [[UIImageView alloc] initWithFrame:CGRectMake(self.switchGroupsButton.frame.origin.x - badgeWidth - badgeMargin, self.switchGroupsButton.frame.origin.y + badgeWidth + 5, badgeWidth, badgeWidth)];
        self.unviewedVideosBadge.image = [YAUtils imageWithColor:[PRIMARY_COLOR colorWithAlphaComponent:0.5]];
        self.unviewedVideosBadge.clipsToBounds = YES;
        self.unviewedVideosBadge.layer.cornerRadius = badgeWidth/2;
        [self.cameraAccessories addObject:self.unviewedVideosBadge];
        [self.cameraView addSubview:self.unviewedVideosBadge];
        
        
        CGFloat width = 48;
        self.recordingIndicator = [[UIView alloc] initWithFrame:CGRectMake(self.cameraView.frame.size.width/2 - width/2, 20, width, width)];
        UIImageView *monkeyIndicator = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, width, width)];
        [monkeyIndicator setImage:[UIImage imageNamed:@"Monkey_Pink"]];
        [self.recordingIndicator addSubview:monkeyIndicator];
        self.recordingIndicator.alpha = 0.0;
        [self.cameraView addSubview:self.recordingIndicator];
                
        CGFloat switchCamZoneRadius = VIEW_WIDTH / 3;
        self.switchCamZone = [[UIView alloc] initWithFrame:CGRectMake(VIEW_WIDTH - switchCamZoneRadius, VIEW_HEIGHT - switchCamZoneRadius, switchCamZoneRadius*2, switchCamZoneRadius*2)];
        [self.switchCamZone setBackgroundColor:[UIColor clearColor]];
        self.switchCamZone.layer.cornerRadius = switchCamZoneRadius;
        self.switchCamZone.layer.masksToBounds = YES;
        self.switchCamZone.layer.borderColor = [UIColor whiteColor].CGColor;
        self.switchCamZone.layer.borderWidth = 3.0f;
        
        self.switchCamZone.layer.shadowColor = [[UIColor blackColor] CGColor];
        self.switchCamZone.layer.shadowOffset = CGSizeMake(0.0f, 0.0f);
        self.switchCamZone.layer.shadowRadius = 1.0f;
        self.switchCamZone.layer.shadowOpacity = 1.0f;
        
        [self.recordingAccessories addObject:self.switchCamZone];
        
        CGFloat zoneIconSize = 60;
        UIImageView *switchZoneIcon = [[UIImageView alloc] initWithFrame:CGRectMake(self.switchCamZone.frame.size.width/3 - zoneIconSize/2, self.switchCamZone.frame.size.height/3 - zoneIconSize/2, zoneIconSize, zoneIconSize)];
        [switchZoneIcon setImage:[UIImage imageNamed:@"Switch"]];
        [self.switchCamZone addSubview:switchZoneIcon];
        
        self.switchCamZoneTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(switchCamera:)];
        self.switchCamZoneTapRecognizer.delegate = self;
        [self.switchCamZone addGestureRecognizer:self.switchCamZoneTapRecognizer];
        [self.cameraView addSubview:self.switchCamZone];
        
        
        CGFloat trashZoneRadius = VIEW_WIDTH / 3;
        self.trashZone = [[UIView alloc] initWithFrame:CGRectMake(0 - trashZoneRadius, VIEW_HEIGHT - trashZoneRadius, trashZoneRadius*2, trashZoneRadius*2)];
        [self.trashZone setBackgroundColor:[UIColor clearColor]];
        self.trashZone.layer.cornerRadius = trashZoneRadius;
        self.trashZone.layer.masksToBounds = YES;
        self.trashZone.layer.borderColor = [UIColor whiteColor].CGColor;
        self.trashZone.layer.borderWidth = 3.0f;
        
        self.trashZone.layer.shadowColor = [[UIColor blackColor] CGColor];
        self.trashZone.layer.shadowOffset = CGSizeMake(0.0f, 0.0f);
        self.trashZone.layer.shadowRadius = 1.0f;
        self.trashZone.layer.shadowOpacity = 1.0f;
        
        UIImageView *trashZoneIcon = [[UIImageView alloc] initWithFrame:CGRectMake(2*(self.trashZone.frame.size.width/3) - zoneIconSize/2, self.switchCamZone.frame.size.height/3 - zoneIconSize/2, zoneIconSize, zoneIconSize)];
        [trashZoneIcon setImage:[UIImage imageNamed:@"Delete"]];
        [self.trashZone addSubview:trashZoneIcon];
        
        self.trashZoneTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(cancelRecording)];
        self.trashZoneTapRecognizer.delegate = self;
        [self.trashZone addGestureRecognizer:self.trashZoneTapRecognizer];
        
        [self.recordingAccessories addObject:self.trashZone];
        [self.cameraView addSubview:self.trashZone];
        
        [self showRecordingAccessories:NO];
        
        [self enableScrollToTop:YES];
        
        // Add shadow to view
        self.view.layer.masksToBounds = NO;
        self.view.layer.shadowOffset = CGSizeMake(0, 8);
        self.view.layer.shadowRadius = 3;
        self.view.layer.shadowOpacity = 0.f;
        self.view.layer.shadowColor = [UIColor blackColor].CGColor;
        
        self.previousViewFrame = CGRectMake(0, 0, VIEW_WIDTH, VIEW_HEIGHT/2 + recordButtonWidth/2);

        self.swipeCameraLeft = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipedCameraLeft:)];
        self.swipeCameraLeft.direction = UISwipeGestureRecognizerDirectionLeft;
        [self.cameraView addGestureRecognizer:self.swipeCameraLeft];
        
        self.swipeCameraRight = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipedCameraRight:)];
        self.swipeCameraRight.direction = UISwipeGestureRecognizerDirectionRight;
        [self.cameraView addGestureRecognizer:self.swipeCameraRight];

        self.swipeEnlargeCamera = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(enlargeCamera:)];
        self.swipeEnlargeCamera.direction = UISwipeGestureRecognizerDirectionDown;
        [self.cameraView addGestureRecognizer:self.swipeEnlargeCamera];
        
        self.swipeCollapseCamera = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(collapseCamera:)];
        self.swipeCollapseCamera.direction = UISwipeGestureRecognizerDirectionUp;
        [self.cameraView addGestureRecognizer:self.swipeCollapseCamera];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(willEnterForeground)
                                                     name:UIApplicationWillEnterForegroundNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didEnterBackground)
                                                     name:UIApplicationDidEnterBackgroundNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(groupDidRefresh:)
                                                     name:GROUP_DID_REFRESH_NOTIFICATION
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(groupDidChange:)
                                                     name:GROUP_DID_CHANGE_NOTIFICATION
                                                   object:nil];
        
        [self updateUviewedViedeosBadge];
        
        if(![[NSUserDefaults standardUserDefaults] boolForKey:kFirstVideoRecorded]) {
            //first start tooltips
            
            CGFloat tooltipPadding = recordButtonWidth / 2 * 3 / 2;
            
            self.recordTooltipLabel = [[UILabel alloc] initWithFrame:CGRectMake(VIEW_WIDTH/2 - 108, 0, 120, VIEW_HEIGHT/2 - tooltipPadding)];
            NSString *fontName = @"AvenirNext-HeavyItalic";
            CGFloat fontSize = 26;

            self.recordTooltipLabel.font = [UIFont fontWithName:fontName size:fontSize];
            NSAttributedString *string = [[NSAttributedString alloc] initWithString:@"Tap and hold to record\n \u2B07\U0000FE0E"
                                                                         attributes:@{
                                                                                      NSStrokeColorAttributeName:[UIColor whiteColor],
                                                                                      NSStrokeWidthAttributeName:[NSNumber numberWithFloat:-5.0]
                                                                                      }];
            
            self.recordTooltipLabel.textAlignment = NSTextAlignmentRight;
            self.recordTooltipLabel.attributedText = string;
            self.recordTooltipLabel.numberOfLines = 4;
            self.recordTooltipLabel.textColor = PRIMARY_COLOR;
            [self.view addSubview:self.recordTooltipLabel];
            
            
            NSStringDrawingOptions option = NSStringDrawingUsesLineFragmentOrigin;
            
            NSString *text = self.recordTooltipLabel.text;
            NSDictionary *attributes = @{NSFontAttributeName: [UIFont fontWithName:fontName size:fontSize]};
            
            CGRect rect = [text boundingRectWithSize:CGSizeMake(self.recordTooltipLabel.frame.size.width, CGFLOAT_MAX)
                                             options:option
                                          attributes:attributes
                                             context:nil];

            CGRect frame = self.recordTooltipLabel.frame;
            frame.origin.y = VIEW_HEIGHT/2 - rect.size.height - tooltipPadding;
            frame.size.height = rect.size.height;
            self.recordTooltipLabel.frame = frame;
            //warning create varible for all screen sizes
//            CGPoint center = self.view.center;
//            center.x -= 47.f;
//            center.y += 65.f;
//            self.recordTooltipLabel.center = center;
        }
        
        self.filters = @[@"#nofilter", @"FREESTYLE"];
        self.filterIndex = 0;

    }
    
    //stop recording on incoming call
    void (^block)(CTCall*) = ^(CTCall* call) {
        DLog(@"Phone call received, state:%@. Stopping recording..", call.callState);
        dispatch_async(dispatch_get_main_queue(), ^{
            [self endHold];
        });
    };
    self.callCenter = [[CTCallCenter alloc] init];
    self.callCenter.callEventHandler = block;
    
    return self;
}

- (void)cameraViewTapped:(id)sender {
    [self.delegate scrollToTop];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self initCamera];
        
        [self enableRecording:YES];
        
        [self updateCurrentGroupName];
    });
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self enableRecording:NO];
        
        [self closeCamera];
    });
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //2 px view in the bottom
    UIView *v = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height/2, self.view.bounds.size.width, 2)];
    v.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    v.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:v];

}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
}

- (void)enableRecording:(BOOL)enable {
    if(enable) {
        
        self.longPressFullScreenGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleHold:)];
        self.longPressFullScreenGestureRecognizer.delegate = self;
        [self.longPressFullScreenGestureRecognizer setMinimumPressDuration:0.2f];
        [self.cameraView addGestureRecognizer:self.longPressFullScreenGestureRecognizer];
        self.longPressRedButtonGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleHold:)];
        [self.longPressRedButtonGestureRecognizer setMinimumPressDuration:0.0f];
        self.longPressRedButtonGestureRecognizer.delegate = self;
        [self.recordButton addGestureRecognizer:self.longPressRedButtonGestureRecognizer];
    }
    else {
        [self.cameraView removeGestureRecognizer:self.longPressFullScreenGestureRecognizer];
//        [self.cameraView removeGestureRecognizer:self.swipeEnlargeCamera];
//        [self.cameraView removeGestureRecognizer:self.swipeCollapseCamera];
        [self.recordButton removeGestureRecognizer:self.longPressRedButtonGestureRecognizer];
    }
//    [UIView animateWithDuration:0.2 animations:^{
//        self.recordButton.transforgm = enable ? CGAffineTransformIdentity : CGAffineTransformMakeScale(0, 0);
//    }];
}

- (void)swipedCameraRight:(UISwipeGestureRecognizer *)recognizer {
    NSLog(@"swiped right");
    [self removeFilterAtIndex:self.filterIndex];
    
    self.filterIndex--;
    if(self.filterIndex == -1){
        self.filterIndex = [self.filters count] - 1;
    }
    
    [self addFilterAtIndex:self.filterIndex];
    
    [self showFilterLabel:self.filters[self.filterIndex]];

}

- (void)swipedCameraLeft:(UISwipeGestureRecognizer *)recognizer {
    NSLog(@"swiped left");
    
    // remove filter at index: self.filterIndex
    
    // filterIndex++
    
    // add filter at index: self.filterIndex
    
    // show filter label: self.filters[self.filterIndex
    
    [self removeFilterAtIndex:self.filterIndex];
    
    self.filterIndex++;
    if(self.filterIndex > ([self.filters count] - 1)){
        self.filterIndex = 0;
    }
    
    [self addFilterAtIndex:self.filterIndex];
    
    [self showFilterLabel:self.filters[self.filterIndex]];
}

- (void) showFilterLabel:(NSString *) label {
//    [self.filterLabel.layer removeAllAnimations];
    [self.filterLabel removeFromSuperview];
    
    self.filterLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 300, 300)];
    self.filterLabel.center = self.cameraView.center;
    self.filterLabel.font = [UIFont fontWithName:BOLD_FONT size:36];
    NSAttributedString *string = [[NSAttributedString alloc] initWithString:label
                                                                 attributes:@{
                                                                              NSStrokeColorAttributeName:[UIColor whiteColor],
                                                                              NSStrokeWidthAttributeName:[NSNumber numberWithFloat:-2.0]
                                                                              }];
    [self.filterLabel setAttributedText:string];
    [self.filterLabel setTextAlignment:NSTextAlignmentCenter];
    [self.filterLabel setTextColor:PRIMARY_COLOR];
    
    
//    [self.filterLabel setText:label];
    
    [self.filterLabel setAlpha:0.0];
    [self.filterLabel setTransform:CGAffineTransformMakeScale(1.5, 1.5)];
    
    [self.cameraView addSubview:self.filterLabel];
    
    [UIView animateKeyframesWithDuration:1.0 delay:0.0 options:0 animations:^{
        //
        [UIView addKeyframeWithRelativeStartTime:0.0 relativeDuration:0.05 animations:^{
            //
            self.filterLabel.transform = CGAffineTransformIdentity;
            [self.filterLabel setAlpha:1.0];
        }];
        
        [UIView addKeyframeWithRelativeStartTime:0.95 relativeDuration:0.05 animations:^{
            //
            self.filterLabel.transform = CGAffineTransformMakeScale(0.5, 0.5);
            [self.filterLabel setAlpha:0.0];
        }];
        
    } completion:^(BOOL finished) {
        //
        if(finished){
            [self.filterLabel removeFromSuperview];
        }
    }];
    
}

- (void)removeFilterAtIndex:(NSUInteger)index {
    switch (index) {
        case 0:
            // #nofilter
            break;
            
        case 1:
            // beats
            [self.audioPlayer stop];
            self.audioPlayer = nil;
            
            break;
        default:
            break;
    }
    
}

- (void)addFilterAtIndex:(NSUInteger)index {
    switch (index) {
        case 0: {
            // #nofilter
            NSLog(@"case 0");
            break;
            
        }
        case 1: {
            // beats
            NSString *path = [[NSBundle mainBundle] pathForResource:@"snoop" ofType:@"mp3"];
            NSURL *url = [NSURL fileURLWithPath:path];
            self.audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:nil];
            self.audioPlayer.numberOfLoops = -1;
            [self.audioPlayer play];
        }
        default:
            break;
    }
}

- (void)collapseCamera:(UISwipeGestureRecognizer *)recognizer {
    
    if(self.largeCamera){
        [UIView animateWithDuration:0.2 delay:0.0 options:UIViewAnimationOptionAllowAnimatedContent animations:^{
            //
            self.view.frame = self.previousViewFrame;
            [self.cameraView setFrame:CGRectMake(0, 0, VIEW_WIDTH, VIEW_HEIGHT/2)];
            [self.infoButton setAlpha:1.0];
//            [self.groupButton setAlpha:1.0];
            [self.switchGroupsButton setAlpha:1.0];
//            self.recordButton.transform = CGAffineTransformIdentity;
            self.recordButton.frame = CGRectMake(VIEW_WIDTH/2 - recordButtonWidth/2, VIEW_HEIGHT/2 - recordButtonWidth/2, recordButtonWidth, recordButtonWidth);
            [self.unviewedVideosBadge setAlpha:1.0];
        } completion:^(BOOL finished) {
        }];
        self.largeCamera = NO;
    }
}

- (void)enlargeCamera:(UISwipeGestureRecognizer *)recognizer {
    if(!self.largeCamera){
        if(self.recordTooltipLabel){
            [self.recordTooltipLabel removeFromSuperview];
        }
        
        self.previousViewFrame = self.view.frame;
        
        [UIView animateWithDuration:0.2 delay:0.0 options:UIViewAnimationOptionAllowAnimatedContent animations:^{
            //
            self.view.frame = CGRectMake(0, 0, VIEW_WIDTH, VIEW_HEIGHT);
            [self.cameraView setFrame:CGRectMake(0, 0, VIEW_WIDTH, VIEW_HEIGHT)];
            [self.infoButton setAlpha:0.0];
//            [self.groupButton setAlpha:0.0];
            [self.switchGroupsButton setAlpha:0.0];
            [self.unviewedVideosBadge setAlpha:0.0];
            
//            self.recordButton.transform = CGAffineTransformMakeScale(1.5, 1.5);
            self.recordButton.center = CGPointMake(VIEW_WIDTH/2, VIEW_HEIGHT - recordButtonWidth);
        } completion:^(BOOL finished) {
        }];
        
        self.largeCamera = YES;
    }
}

- (void)initCamera {
    // only init camera if not simulator
    
    if(TARGET_IPHONE_SIMULATOR){
        DLog(@"no camera, simulator");
    } else {
        
        DLog(@"init camera");
        
        //set still image output
        
        self.videoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPreset640x480 cameraPosition:AVCaptureDevicePositionBack];
        self.videoCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
        
        
        
        [self.videoCamera addTarget:self.gpuCameraView];
        [self.videoCamera startCameraCapture];
        
//        AVAuthorizationStatus videoStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
//        if (videoStatus == AVAuthorizationStatusAuthorized) {
//            
//            self.session = [[AVCaptureSession alloc] init];
//           
//            [self.session beginConfiguration];
////            self.session.automaticallyConfiguresApplicationAudioSession = NO;
//            
//            self.session.sessionPreset = AVCaptureSessionPreset640x480;
//            
//            [(AVCaptureVideoPreviewLayer *)([self.cameraView layer]) setSession:self.session];
//            [(AVCaptureVideoPreviewLayer *)(self.cameraView.layer) setVideoGravity:AVLayerVideoGravityResizeAspectFill];
//            
//            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//                [self setupVideoInput];
//            });
//            
//            [self.session commitConfiguration];
//            
//            [self removeOpenSettingsButton];
//            
//        } else {
//            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo
//                                     completionHandler:^(BOOL granted) {
//                                         self.session = [[AVCaptureSession alloc] init];
//                                         [self.session beginConfiguration];
//                                         self.session.sessionPreset = AVCaptureSessionPreset640x480;
//                                         
//                                         [(AVCaptureVideoPreviewLayer *)([self.cameraView layer]) setSession:self.session];
//                                         [(AVCaptureVideoPreviewLayer *)(self.cameraView.layer) setVideoGravity:AVLayerVideoGravityResizeAspectFill];
//                                         if (granted) {
//                                             [self setupVideoInput];
//                                         } else {
//                                             dispatch_async(dispatch_get_main_queue(), ^{
//                                                 [self addOpenSettingsButton];
//                                             });
//                                             
//                                         }
//                                         [self.session commitConfiguration];
//                                     }];
//        }
    }
}

- (void)setupVideoInput {
    NSError *error = nil;
    
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    AVCaptureDevice *captureDevice = [devices firstObject];
    
    for (AVCaptureDevice *device in devices)
    {
        if ([device position] == AVCaptureDevicePositionBack)
        {
            captureDevice = device;
            break;
        }
    }
    
    if([captureDevice lockForConfiguration:nil]){
        if([captureDevice isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus]){
            [captureDevice setFocusMode:AVCaptureFocusModeContinuousAutoFocus];
        }
        
        if([captureDevice isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure]){
            [captureDevice setExposureMode:AVCaptureExposureModeContinuousAutoExposure];
        }
        [captureDevice unlockForConfiguration];
    }
    
    self.videoInput = [AVCaptureDeviceInput deviceInputWithDevice:captureDevice error:&error];
    
    if (error)
    {
        DLog(@"add video input error: %@", error);
    }
    
    if ([self.session canAddInput:self.videoInput])
    {
        [self.session addInput:self.videoInput];
    }
    
    self.movieFileOutput = [[AVCaptureMovieFileOutput alloc] init];
    
    if ([self.session canAddOutput:self.movieFileOutput])
    {
        [self.session addOutput:self.movieFileOutput];
    }
    
    AVAuthorizationStatus audioStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio];
    if (audioStatus == AVAuthorizationStatusAuthorized) {
        [self initAudioInput];
        [self.session startRunning];
    } else {
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeAudio
                                 completionHandler:^(BOOL granted) {
                                     if (granted) {
                                         [self initAudioInput];
                                         [self.session startRunning];
                                     }
                                 }];
    }
    
}

- (void)initAudioInput {
    NSError *error = nil;
    AVCaptureDevice *audioDevice = [[AVCaptureDevice devicesWithMediaType:AVMediaTypeAudio] firstObject];
    self.audioInput = [AVCaptureDeviceInput deviceInputWithDevice:audioDevice error:&error];
    
    if (error)
    {
        DLog(@"add audio input error: %@", error);
    }
    
    //Don't add just now to allow bg audio to play
    if ([self.session canAddInput:self.audioInput])
    {
        [self.session addInput:self.audioInput];
    }
    
}

- (void)closeCamera {
    AVAuthorizationStatus videoStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    // Don't try to configure anything if no permissions are granted. This would be rare anyway.
    if (videoStatus == AVAuthorizationStatusAuthorized) {
        if (self.session) {
            [self.session beginConfiguration];
            for(AVCaptureDeviceInput *input in self.session.inputs){
                [self.session removeInput:input];
            }
            [self.session commitConfiguration];
            
            if ([self.session isRunning])
                [self.session stopRunning];
        }
        self.session = nil;
    }
}

- (void)accidentalDragOffscreenTimedOut:(NSTimer *)timer {
    DLog(@"accidental offscreen drag timed out. Video done.");
    [self endHold];
}


- (void)handleHold:(UILongPressGestureRecognizer *)recognizer {
//    DLog(@"%ld", (unsigned long)recognizer.state);

    CGPoint loc = [recognizer locationInView:self.view];
    if (recognizer.state == UIGestureRecognizerStateEnded) {
        if ([self touchDragStateForPoint:loc] == YATouchDragStateInsideFlip && loc.y ) {
            DLog(@"accidental offscreen drag began");
            self.longPressFullScreenGestureRecognizer.minimumPressDuration = 0.0f;
            self.accidentalDragOffscreenTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(accidentalDragOffscreenTimedOut:) userInfo:nil repeats:NO];
        } else {
            [self endHold];
        }
    } else if (recognizer.state == UIGestureRecognizerStateBegan){
        if (self.accidentalDragOffscreenTimer) {
            // invalidate the timer to continue recording
            DLog(@"accidental offscreen drag ended");
            [self.accidentalDragOffscreenTimer invalidate];
            self.accidentalDragOffscreenTimer = nil;
            self.longPressFullScreenGestureRecognizer.minimumPressDuration = 0.2f;
        } else {
            self.lastTouchDragState = [self touchDragStateForPoint:loc];
            [self startHold];
        }
    } else if (recognizer.state == UIGestureRecognizerStateChanged) {
        YATouchDragState prevState = self.lastTouchDragState;
        self.lastTouchDragState = [self touchDragStateForPoint:loc];
        if (prevState == YATouchDragStateOutside){
            if(self.lastTouchDragState == YATouchDragStateInsideFlip){
                [self switchCamera:nil];
            } else if(self.lastTouchDragState == YATouchDragStateInsideTrash){
                // end hold?
                NSLog(@"inside trash?");
                [self cancelRecording];
            }
        }
    }
}

- (void)cancelRecording {
    self.cancelledRecording = YES;
    [self endHold];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)a shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)b {
    // return yes only if it's the switch camera tap recognizer and one of the long hold recognizers
    if ([a isEqual:self.switchCamZoneTapRecognizer] &&
        ([b isEqual:self.longPressFullScreenGestureRecognizer]
         || [b isEqual:self.longPressRedButtonGestureRecognizer])) {
            return YES;
        } else if ([a isEqual:self.longPressRedButtonGestureRecognizer] && [b isEqual:self.switchCamZoneTapRecognizer]) {
            return YES;
        } else if ([a isEqual:self.longPressFullScreenGestureRecognizer] && [b isEqual:self.switchCamZoneTapRecognizer]) {
            return YES;
        }
    return NO;
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    if (![gestureRecognizer isEqual:self.longPressFullScreenGestureRecognizer])
        return YES;
    if ([self.recording boolValue] && !self.accidentalDragOffscreenTimer) {
        return NO;
    }
    return YES;
}

- (YATouchDragState)touchDragStateForPoint:(CGPoint)point {
    CGPoint switchSpot = CGPointMake(VIEW_WIDTH, VIEW_HEIGHT);
    CGPoint trashSpot = CGPointMake(0, VIEW_HEIGHT);
    CGFloat switchXDif = point.x - switchSpot.x;
    CGFloat switchYDif = point.y - switchSpot.y;

    CGFloat trashXDif = point.x - trashSpot.x;
    CGFloat trashYDif = point.y - trashSpot.y;
    
    CGFloat maxDif = VIEW_WIDTH / 3;
    
    if (((switchXDif * switchXDif) + (switchYDif * switchYDif)) < (maxDif * maxDif)) {
        return YATouchDragStateInsideFlip;
    }

    if (((trashXDif * trashXDif) + (trashYDif * trashYDif)) < (maxDif * maxDif)) {
        return YATouchDragStateInsideTrash;
    }

    return YATouchDragStateOutside;
}

- (void)startHold {

    DLog(@"starting hold");
    
    self.recordingTime = [NSDate date];
    
//    if ([self.session canAddInput:self.audioInput])
//    {
//        [self.session addInput:self.audioInput];
//    }

    
//    //We're starting to shoot so add audio
//    if (!self.audioInputAdded) {
//        [self.session beginConfiguration];
//        [self.session addInput:self.audioInput];
//        self.audioInputAdded = YES;
//        [self.session commitConfiguration];
//    }

    self.currentRecordingURLs = [NSMutableArray new];
    self.cancelledRecording = NO;
    self.recording = [NSNumber numberWithBool:YES];
//    self.recordingIndicator.alpha = 1.0;
    self.indicator = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.cameraView.frame.size.width, VIEW_HEIGHT/32.f)];
    [self.indicator setBackgroundColor:PRIMARY_COLOR];
    [self.indicator setUserInteractionEnabled:NO];
//    [self.indicatorText setText:@"Recording..."];
    [self.view addSubview:self.indicator];
    
    [self.view bringSubviewToFront:self.white];
    [self.view bringSubviewToFront:self.indicator];
    
    [self.countdown invalidate];
    self.countdown = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(countdownTick:) userInfo:nil repeats:YES];
    self.count = 0;
    
    if(self.recordTooltipLabel) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kFirstVideoRecorded];
        
        [UIView animateWithDuration:0.2 animations:^{
            self.recordTooltipLabel.alpha = 0.0;
        } completion:^(BOOL finished) {
            [self.recordTooltipLabel removeFromSuperview];
            self.recordTooltipLabel = nil;
        }];
        
        [[Mixpanel sharedInstance] track:@"First video post"];
    }
    
    if (!self.largeCamera) {
        self.previousViewFrame = self.view.frame;
    }
    
    self.recordButton.hidden = YES;
    
    [UIView animateWithDuration:0.2 animations:^{
        [self showCameraAccessories:0];
        [self showRecordingAccessories:1];
        [self.view setFrame:CGRectMake(0, 0, VIEW_WIDTH, VIEW_HEIGHT)];
        [self.cameraView setFrame:CGRectMake(0, 0, VIEW_WIDTH, VIEW_HEIGHT)];
    } completion:^(BOOL finished) {
        
    }];
    
//    self.recordingIndicator.transform = CGAffineTransformIdentity;
//    [UIView animateWithDuration:0.5 delay:0.0 options:UIViewAnimationOptionRepeat | UIViewAnimationOptionAutoreverse animations:^{
//        //
//        self.recordingIndicator.transform = CGAffineTransformMakeScale(1.618, 1.618);
//    } completion:^(BOOL finished) {
//        //
//    }];
    
//    [UIView animateWithDuration:MAX_VIDEO_DURATION delay:0.0 usingSpringWithDamping:1.0 initialSpringVelocity:1.0 options:0 animations:^{
//        //
//        [self.indicator setFrame:CGRectMake(self.cameraView.frame.size.width, 0, 0, self.indicator.frame.size.height)];
//    } completion:^(BOOL finished) {
//        //
//        if(finished){
//            [self endHold];
//        }
//    }];

    [UIView animateWithDuration:MAX_VIDEO_DURATION delay:0.0 options:UIViewAnimationOptionCurveLinear animations:^{
        [self.indicator setFrame:CGRectMake(self.cameraView.frame.size.width, 0, 0, self.indicator.frame.size.height)];
    } completion:^(BOOL finished) {
        if(finished){
            [self endHold];
        }
        //
    }];

//    [GPUImageMovieWriter alloc] initWith
//    [self.movieWriter startRecording];
    [self startRecordingVideo];
    NSLog(@"starting something...");
    
}

- (void)countdownTick:(NSTimer *) timer {
    self.count++;
    
    int remaining = MAX_VIDEO_DURATION - self.count;
    int max_countdown = 5;
    if(remaining <= (max_countdown + 1) && remaining > 1){
        // flash remaining - 1
        self.countdownLabel.text = [NSString stringWithFormat:@"%i", remaining-1];
        NSAttributedString *string = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%i", remaining-1]
                                                                     attributes:@{
                                                                                  NSStrokeColorAttributeName:[UIColor whiteColor],
                                                                                  NSStrokeWidthAttributeName:[NSNumber numberWithFloat:-5.0]
                                                                                  }];
        self.countdownLabel.attributedText = string;

        self.countdownLabel.alpha = 0.0;
        self.countdownLabel.transform = CGAffineTransformIdentity;
        
        [UIView animateKeyframesWithDuration:0.8 delay:0.0 options:UIViewKeyframeAnimationOptionAllowUserInteraction animations:^{
            //
            [UIView addKeyframeWithRelativeStartTime:0.0 relativeDuration:0.33 animations:^{
                //
                self.countdownLabel.transform = CGAffineTransformMakeScale(1.5, 1.5);
                self.countdownLabel.alpha = 1.0;
            }];
            
            [UIView addKeyframeWithRelativeStartTime:0.66 relativeDuration:0.33 animations:^{
                //
                self.countdownLabel.transform = CGAffineTransformIdentity;
                self.countdownLabel.alpha = 0.0;
            }];
        } completion:^(BOOL finished) {
            //
//            self.countdownLabel.transform = CGAffineTransformIdentity;
//            self.countdownLabel.alpha = 0.0;
        }];
        
    } else if(remaining == 0) {
        [self endHold];
    }
}

- (void)endHold {
    [self.accidentalDragOffscreenTimer invalidate];
    self.accidentalDragOffscreenTimer = nil;
    self.longPressFullScreenGestureRecognizer.minimumPressDuration = 0.2f;
    
    if([self.recording boolValue]){
        self.recordingIndicator.alpha = 0.0;
        self.recordButton.hidden = NO;
        
        [self.view bringSubviewToFront:self.cameraView];
        //        [self.view bringSubviewToFront:self.recordButton];
        
        [UIView animateWithDuration:0.2 animations:^{
            self.view.frame = self.previousViewFrame;
            [self.cameraView setFrame:CGRectMake(0, 0, VIEW_WIDTH, VIEW_HEIGHT/2)];
            [self showCameraAccessories:YES];
            [self showRecordingAccessories:0];
            self.recordButton.transform = CGAffineTransformIdentity;
            self.recordButton.frame = CGRectMake(VIEW_WIDTH/2 - recordButtonWidth/2, VIEW_HEIGHT/2 - recordButtonWidth/2, recordButtonWidth, recordButtonWidth);
         }];
        self.largeCamera = NO;
        
        [self.indicatorText setText:NSLocalizedString(@"RECORD_TIP", @"")];
        [self.indicator removeFromSuperview];
        // Do Whatever You want on End of Gesture
        self.recording = [NSNumber numberWithBool:NO];
        
        [self.recordingIndicator.layer removeAllAnimations];
        
        if(self.flash){
            [self switchFlashMode:nil];
        }
        
        [self.countdown invalidate];
        self.countdown = nil;
        
        //        [self.session removeInput:self.audioInput];
        //        if ([self.session canAddInput:self.audioInput])
        //        {
        //            [self.session addInput:self.audioInput];
        //        }
        
        
        NSDate *recordingFinished = [NSDate date];
        NSTimeInterval executionTime = [recordingFinished timeIntervalSinceDate:self.recordingTime];
        
        if(executionTime < 0.5){
            self.cancelledRecording = YES;
        }
        
        [self stopRecordingVideo];
    }

}

- (void) startRecordingVideo {
//    if(!self.session.outputs.count)
//        NSLog(@"return?");
//        return;
    
    //    AVCaptureMovieFileOutput *aMovieFileOutput = [[AVCaptureMovieFileOutput alloc] init];
    
    //Create temporary URL to record to
    NSString *randomString = [[NSProcessInfo processInfo] globallyUniqueString];
    NSString *outputPath = [[NSString alloc] initWithFormat:@"%@%@.mov", NSTemporaryDirectory(), randomString];
    self.currentlyRecordingUrl = [[NSURL alloc] initFileURLWithPath:outputPath];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:outputPath])
    {
        NSError *error;
        if ([fileManager removeItemAtPath:outputPath error:&error] == NO)
        {
            //Error - handle if requried
        }
    }
    
    
    //Start recording
    
//    self.recordingSemaphore = dispatch_semaphore_create(0);
//    [self.movieFileOutput startRecordingToOutputFileURL:outputURL recordingDelegate:self];
    
//    GPUImagePixellatePositionFilter *customFilter = [[GPUImagePixellatePositionFilter alloc] init];
    
    self.movieWriter = [[GPUImageMovieWriter alloc] initWithMovieURL:self.currentlyRecordingUrl size:CGSizeMake(480.0, 640.0)];
    self.movieWriter.encodingLiveVideo = YES;
    self.movieWriter.shouldPassthroughAudio = YES;
    self.videoCamera.audioEncodingTarget = self.movieWriter;
    
//    [self.videoCamera addTarget:customFilter];
//    [customFilter addTarget:self.gpuCameraView];
    
    [self.movieWriter startRecording];
    
//    [self performSelector:@selector(gpuSwitchCamera) withObject:self afterDelay:3.0];
    
    NSLog(@"start recording video?!?!?!");
}

- (void) gpuSwitchCamera {
    [self.videoCamera rotateCamera];
}

- (void) stopRecordingVideo {
    NSLog(@"Finish recording?");
//    [self.videoCamera stopCameraCapture];
    [self.movieWriter finishRecordingWithCompletionHandler:^{
        NSLog(@"Finish recording 2?");
        NSLog(@"recording path: %@ ?", self.currentlyRecordingUrl.path);
        
        UISaveVideoAtPathToSavedPhotosAlbum(self.currentlyRecordingUrl.path, nil, nil, nil);
        
        if(!self.cancelledRecording){
            if (![self.recording boolValue]) {
                [[YAAssetsCreator sharedCreator] createVideoFromRecodingURL:self.currentlyRecordingUrl addToGroup:[YAUser currentUser].currentGroup];
            }
        } else {
            self.cancelledRecording = NO;
        }

        //
    }];
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//        if(self.recordingSemaphore)
//            dispatch_semaphore_wait(self.recordingSemaphore, DISPATCH_TIME_FOREVER);
//        
//        dispatch_async(dispatch_get_main_queue(), ^{
//            [self.movieFileOutput stopRecording];
//            DLog(@"stop recording video");
//        });
//    });
}

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didStartRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray *)connections
{
    dispatch_semaphore_signal(self.recordingSemaphore);
    
    DLog(@"didStartRecordingToOutputFileAtURL");
}

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error {
    
    DLog(@"didFinishRecordingToOutputFileAtURL");
    
    BOOL RecordedSuccessfully = YES;
    if ([error code] != noErr) {
        // A problem occurred: Find out if the recording was successful.
        id value = [[error userInfo] objectForKey:AVErrorRecordingSuccessfullyFinishedKey];
        if (value) {
            RecordedSuccessfully = [value boolValue];
        }
    }
    
    
    if (RecordedSuccessfully) {
        
        if(error) {
            [YAUtils showNotification:[NSString stringWithFormat:@"Unable to save recording, %@", error.localizedDescription] type:YANotificationTypeError];
            return;
        }

        NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:outputFileURL.path error:nil];
        
        NSNumber *fileSizeNumber = [fileAttributes objectForKey:NSFileSize];
        long long fileSize = [fileSizeNumber longLongValue];
        
        DLog(@"file size: %lld", fileSize);
        
        [self.currentRecordingURLs addObject:outputFileURL];
        
        if(!self.cancelledRecording){
            if (![self.recording boolValue]) {
                if ([self.currentRecordingURLs count] > 1) {
                    [[YAAssetsCreator sharedCreator] createVideoFromSequenceOfURLs:self.currentRecordingURLs addToGroup:[YAUser currentUser].currentGroup];
                } else {
                    [[YAAssetsCreator sharedCreator] createVideoFromRecodingURL:outputFileURL addToGroup:[YAUser currentUser].currentGroup];
                }
            }
        } else {
            self.cancelledRecording = NO;
        }
    } else {
        [YAUtils showNotification:[NSString stringWithFormat:@"Unable to save recording, %@", error.localizedDescription] type:YANotificationTypeError];
    }
    
}

- (void)switchCamera:(id)sender { //switch cameras front and rear camerashiiegor@gmail.com
    if(self.openSettingsButton)
        return;
    

    if([self.recording boolValue]){
        [self stopRecordingVideo];
    }
    
    if(self.flash){
        [self switchFlashMode:nil];
    }
    
    AVCaptureDevice *currentVideoDevice = [[self videoInput] device];
    AVCaptureDevicePosition preferredPosition = AVCaptureDevicePositionUnspecified;
    AVCaptureDevicePosition currentPosition = [currentVideoDevice position];
    
    switch (currentPosition)
    {
        case AVCaptureDevicePositionUnspecified:
            preferredPosition = AVCaptureDevicePositionFront;
            break;
        case AVCaptureDevicePositionBack:
            preferredPosition = AVCaptureDevicePositionFront;
            break;
        case AVCaptureDevicePositionFront:
            preferredPosition = AVCaptureDevicePositionBack;
            break;
    }
    
    //[self addAudioInput];
    
    AVCaptureDevice *videoDevice = [self deviceWithMediaType:AVMediaTypeVideo preferringPosition:preferredPosition];
    AVCaptureDeviceInput *videoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:nil];
    
    if([videoDevice lockForConfiguration:nil]){
        if([videoDevice isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus]){
            [videoDevice setFocusMode:AVCaptureFocusModeContinuousAutoFocus];
        }
        
        if([videoDevice isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure]){
            [videoDevice setExposureMode:AVCaptureExposureModeContinuousAutoExposure];
        }
        [videoDevice unlockForConfiguration];
        [self.cameraView switchCamera:preferredPosition];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self configureFlashButton:NO];
    });
    
    [[self session] beginConfiguration];
    
    [[self session] removeInput:[self videoInput]];
    if ([[self session] canAddInput:videoDeviceInput]) {
        [[self session] addInput:videoDeviceInput];
        [self setVideoInput:videoDeviceInput];
    }
    else
    {
        [[self session] addInput:[self videoInput]];
    }
    
    
    [[self session] commitConfiguration];
    
//    [UIView transitionWithView:self.cameraView
//                      duration:0.5
//                       options:UIViewAnimationOptionTransitionFlipFromRight|UIViewAnimationOptionCurveEaseInOut
//                    animations:^{
//                    }
//                    completion:^(BOOL finished) {
//                        if (finished) {
//                            //DO Stuff
//                        }
//                    }];
    
    if([self.recording boolValue]){
        [self performSelector:@selector(startRecordingVideo) withObject:self afterDelay:.25];
    }
    
    //    [self.session beginConfiguration];
    //    [self.session commitConfiguration];
    
}


- (AVCaptureDevice *)deviceWithMediaType:(NSString *)mediaType preferringPosition:(AVCaptureDevicePosition)position
{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:mediaType];
    AVCaptureDevice *captureDevice = [devices firstObject];
    
    for (AVCaptureDevice *device in devices)
    {
        if ([device position] == position)
        {
            captureDevice = device;
            break;
        }
    }
    
    return captureDevice;
}

- (void)switchFlashMode:(id)sender {
    
    DLog(@"switching flash mode");
    AVCaptureDevice *currentVideoDevice = [[self videoInput] device];
    
    if([currentVideoDevice position] == AVCaptureDevicePositionBack){
        // back camera
        [currentVideoDevice lockForConfiguration:nil];
        if(self.flash){
            //turn flash off
            if([currentVideoDevice isTorchModeSupported:AVCaptureTorchModeOff]){
                [currentVideoDevice setTorchMode:AVCaptureTorchModeOff];
            }
            [self configureFlashButton:NO];
        } else {
            //turn flash on
            NSError *error = nil;
            if([currentVideoDevice isTorchModeSupported:AVCaptureTorchModeOn]){
                [currentVideoDevice setTorchModeOnWithLevel:0.8 error:&error];
            }
            if(error){
                DLog(@"error: %@", error);
            }
            
            [self configureFlashButton:YES];
        }
        [currentVideoDevice unlockForConfiguration];
        
    } else if([currentVideoDevice position] == AVCaptureDevicePositionFront) {
        //front camera
        if(self.flash){
            // turn flash off
            if(self.previousBrightness){
                [[UIScreen mainScreen] setBrightness:[self.previousBrightness floatValue]];
            }
            [self.white removeFromSuperview];
            [self configureFlashButton:NO];
        } else {
            // turn flash on
            self.previousBrightness = [NSNumber numberWithFloat: [[UIScreen mainScreen] brightness]];
            [[UIScreen mainScreen] setBrightness:1.0];
            [self.view addSubview:self.white];
            
            [self.view bringSubviewToFront:self.cameraView];
            [self showCameraAccessories:YES];
            [self configureFlashButton:YES];
        }
    }
    
}

- (void)configureFlashButton:(BOOL)flash {
    self.flash = flash;
    if(flash){
        [self.flashButton setImage:[UIImage imageNamed:@"TorchOn"] forState:UIControlStateNormal];
    } else {
        [self.flashButton setImage:[UIImage imageNamed:@"TorchOff"] forState:UIControlStateNormal];
    }
}

- (void)toggleGroups:(id)sender {
    [self.delegate toggleGroups];
}

- (void)didEnterBackground {
    if(self.flash){
        [self switchFlashMode:nil];
    }
    [self closeCamera];
}

- (void)willEnterForeground {
    // init camera if selfs view is visible
    if (self.isViewLoaded && self.view.window){
        [self initCamera];
    }
}

- (void)showCameraAccessories:(BOOL)show {
    for(UIView *v in self.cameraAccessories){
        [v setAlpha:show ? 1 : 0];
        if(show)
            [self.view bringSubviewToFront:v];
    }
}

- (void)showRecordingAccessories:(BOOL)show {
    for(UIView *v in self.recordingAccessories){
        [v setAlpha:show ? 1 : 0];
        if(show)
            [self.view bringSubviewToFront:v];
    }
}

- (void)openGroupOptions:(id)sender {
    [self.delegate openGroupOptions];
}

#pragma mark -

- (void)updateCurrentGroupName {
    [self.groupButton setTitle:[YAUser currentUser].currentGroup.name forState:UIControlStateNormal];
}

- (void)updateUviewedViedeosBadge {
    self.unviewedVideosBadge.hidden = ![[YAUser currentUser] hasUnviewedVideosInGroups];
}

#pragma mark Group Notifications
- (void)groupDidRefresh:(NSNotification*)notification {
    [self updateUviewedViedeosBadge];
}

- (void)groupDidChange:(NSNotification*)notification {
    [self updateCurrentGroupName];
}

#pragma mark Settings
- (void)addOpenSettingsButton {
    if(!self.openSettingsButton) {
        CGRect r = self.cameraView.bounds;
        r.size.height /= 2;
        r.size.width *= .6;
        r.origin.x = (self.view.frame.size.width - r.size.width)/2;
        r.origin.y = 100;
        
        self.openSettingsButton = [[UIButton alloc] initWithFrame:r];
        [self.openSettingsButton setTitle:NSLocalizedString(@"Enable Camera", @"") forState:UIControlStateNormal];
        [self.openSettingsButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        self.openSettingsButton.titleLabel.font = [UIFont fontWithName:BOLD_FONT size:24];
        [self.openSettingsButton addTarget:self action:@selector(openSettings:) forControlEvents:UIControlEventTouchUpInside];
        [self.openSettingsButton.titleLabel setTextAlignment:NSTextAlignmentCenter];
        [self.openSettingsButton.titleLabel setNumberOfLines:0];
        self.openSettingsButton.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
        [self.cameraView addSubview:self.openSettingsButton];
        
        [self.recordTooltipLabel removeFromSuperview];
        self.recordTooltipLabel = nil;
    }
}

- (void)removeOpenSettingsButton {
    if(self.openSettingsButton) {
        [self.openSettingsButton removeFromSuperview];
        self.openSettingsButton = nil;
    }
}

- (void)openSettings:(id)sender {
    NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
    [[UIApplication sharedApplication] openURL:url];
}

- (void)enableScrollToTop:(BOOL)enable {
    if(enable && ! self.scrollToTopTapRecognizer) {
        self.scrollToTopTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(cameraViewTapped:)];
        [self.cameraView addGestureRecognizer:self.scrollToTopTapRecognizer];
    }
    else {
        [self.cameraView removeGestureRecognizer:self.scrollToTopTapRecognizer];
        self.scrollToTopTapRecognizer = nil;
    }
}

- (void)showBottomShadow {
    if (self.view.layer.shadowOpacity != 0.35f) {
        CABasicAnimation *borderAnimation = [CABasicAnimation animationWithKeyPath:@"shadowOpacity"];
        borderAnimation.fromValue = @(0.f);
        borderAnimation.toValue = @(0.35f);
        borderAnimation.duration = 0.25f;
        
        [self.view.layer addAnimation:borderAnimation forKey:@"shadowOpacity"];
        self.view.layer.shadowOpacity = 0.35f;
    }
}

- (void)removeBottomShadow {
    if (self.view.layer.shadowOpacity != 0.f) {
        CABasicAnimation *borderAnimation = [CABasicAnimation animationWithKeyPath:@"shadowOpacity"];
        borderAnimation.fromValue = @(self.view.layer.shadowOpacity);
        borderAnimation.toValue = @(0.f);
        borderAnimation.duration = 0.25f;
        
        [self.view.layer addAnimation:borderAnimation forKey:@"shadowOpacity"];
        self.view.layer.shadowOpacity = 0.f;
    }
}

@end
