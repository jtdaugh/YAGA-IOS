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
#import "NameGroupViewController.h"

#define BUTTON_SIZE (VIEW_WIDTH / 7)
#define HEADER_HEIGHT 60.f


#define INFO_PADDING 10.f
#define INFO_SIZE 30.f

#define kUnviwedBadgeWidth 10

typedef enum {
    YATouchDragStateInsideTrash,
    YATouchDragStateInsideFlip,
    YATouchDragStateOutside
} YATouchDragState;

@interface YACameraViewController () <YACameraManagerDelegate>

@property (nonatomic, strong) YACameraView *cameraView;

@property (nonatomic) YACameraButtonMode cameraButtonsMode;

@property (strong, nonatomic) UIView *indicator;
@property (strong, nonatomic) UILabel *indicatorText;
@property (strong, nonatomic) UIView *white;
@property (strong, nonatomic) NSDate *recordingTime;
@property (nonatomic) BOOL cancelledRecording;
@property (nonatomic) BOOL flash;

@property (strong, nonatomic) NSNumber *previousBrightness;

@property (strong, nonatomic) NSMutableArray *cameraAccessories;
@property (strong, nonatomic) NSMutableArray *recordingAccessories;
@property (strong, nonatomic) UIButton *switchCameraButton;
@property (strong, nonatomic) UIImageView *unviewedVideosBadge;
@property (strong, nonatomic) UIButton *groupButton;
@property (strong, nonatomic) UIImageView *logo;

@property (strong, nonatomic) UIButton *flashButton;
@property (strong, nonatomic) UIButton *recordButton;
@property (strong, nonatomic) UIButton *leftBottomButton;

@property (strong, nonatomic) UIButton *rightBottomButton;

@property (strong, nonatomic) UILongPressGestureRecognizer *longPressFullScreenGestureRecognizer;
@property (strong, nonatomic) UILongPressGestureRecognizer *longPressRedButtonGestureRecognizer;
@property (nonatomic) BOOL audioInputAdded;

@property (nonatomic, strong) UILabel *recordTooltipLabel;

@property (nonatomic, strong) UIButton *openSettingsButton;

@property (nonatomic, strong) CTCallCenter *callCenter;

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
@property double animationStartTime;

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
        self.view.frame = CGRectMake(0, -0, VIEW_WIDTH, VIEW_HEIGHT / 2 + recordButtonWidth/2);
        
        self.cameraView = [[YACameraView alloc] initWithFrame:CGRectMake(0, 0, VIEW_WIDTH, VIEW_HEIGHT/2)];
        [self.cameraView setBackgroundColor:[UIColor blackColor]];
        [self.view addSubview:self.cameraView];
        [self.cameraView setUserInteractionEnabled:YES];
        self.cameraView.clipsToBounds = YES;
        self.cameraView.autoresizingMask = UIViewAutoresizingNone;
        
        self.cameraAccessories = [@[] mutableCopy];
        self.recordingAccessories = [@[] mutableCopy];
        
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
        
        self.rightBottomButton = [[UIButton alloc] initWithFrame:CGRectMake(VIEW_WIDTH - INFO_SIZE - INFO_PADDING*2,
                                                                     (VIEW_HEIGHT/2 - INFO_SIZE - INFO_PADDING*2),
                                                                     INFO_SIZE+INFO_PADDING*2, INFO_SIZE+INFO_PADDING*2)];
        //    switchButton.translatesAutoresizingMaskIntoConstraints = NO;
        self.rightBottomButton.imageEdgeInsets = UIEdgeInsetsMake(INFO_PADDING, INFO_PADDING, INFO_PADDING, INFO_PADDING);
        [self.rightBottomButton addTarget:self action:@selector(rightBottomButtonPressed) forControlEvents:UIControlEventTouchUpInside];
        [self.rightBottomButton setImage:[UIImage imageNamed:@"InfoWhite"] forState:UIControlStateNormal];
        [self.rightBottomButton.imageView setContentMode:UIViewContentModeScaleAspectFit];
        self.rightBottomButton.titleLabel.font = [UIFont fontWithName:BIG_FONT size:16];
        [self.cameraAccessories addObject:self.rightBottomButton];
        [self.view addSubview:self.rightBottomButton];

        //current group
        self.groupButton = [[UIButton alloc] initWithFrame:CGRectMake((VIEW_WIDTH - 200)/2, 0, 200, HEADER_HEIGHT)];
        [self.groupButton addTarget:self action:@selector(openGroupOptions) forControlEvents:UIControlEventTouchUpInside];
        [self.groupButton setTitle:[YAUser currentUser].currentGroup.name forState:UIControlStateNormal];
        [self.groupButton.titleLabel setFont:[UIFont fontWithName:BIG_FONT size:18]];
        self.groupButton.layer.shadowColor = [[UIColor blackColor] CGColor];
        self.groupButton.layer.shadowRadius = 1.0f;
        self.groupButton.layer.shadowOpacity = 1.0;
        self.groupButton.layer.shadowOffset = CGSizeZero;
        [self.cameraAccessories addObject:self.groupButton];
        [self.view addSubview:self.groupButton];

        CGFloat logoWidth = VIEW_WIDTH/6;
        CGFloat logoHeight = VIEW_HEIGHT/12;
        self.logo = [[UIImageView alloc] initWithFrame:CGRectMake(VIEW_WIDTH/2 - logoWidth/2, 8, logoWidth, logoHeight)];
        [self.logo setContentMode:UIViewContentModeScaleAspectFit];
        [self.logo setImage:[UIImage imageNamed:@"Logo"]];
        [self.cameraAccessories addObject:self.logo];
        [self.view addSubview:self.logo];
        
        //record button
        self.recordButton = [[UIButton alloc] initWithFrame:CGRectMake(self.cameraView.frame.size.width/2.0 - recordButtonWidth/2.0, self.cameraView.frame.size.height - recordButtonWidth/2.0, recordButtonWidth, recordButtonWidth)];
        [self.recordButton setBackgroundColor:[UIColor redColor]];
        [self.recordButton.layer setCornerRadius:recordButtonWidth/2.0];
        [self.recordButton.layer setBorderColor:[UIColor whiteColor].CGColor];
        [self.recordButton.layer setBorderWidth:4.0f];
        [self.cameraAccessories addObject:self.recordButton];
        [self.view addSubview:self.recordButton];
        
        
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
        [self.view addSubview:self.countdownLabel];
    
        self.leftBottomButton = [[UIButton alloc] initWithFrame:CGRectMake(10, VIEW_HEIGHT/2 - 30, 100, 30)];
        self.leftBottomButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
//        [self.leftBottomButton setTitle:NSLocalizedString(@"Find Groups", @"") forState:UIControlStateNormal];
        self.leftBottomButton.titleLabel.font = [UIFont fontWithName:BIG_FONT size:16];
        [self.leftBottomButton addTarget:self action:@selector(leftBottomButtonPressed) forControlEvents:UIControlEventTouchUpInside];
        [self.cameraAccessories addObject:self.leftBottomButton];
        [self.view addSubview:self.leftBottomButton];
        
        self.unviewedVideosBadge = [[UIImageView alloc] initWithFrame:CGRectMake(self.leftBottomButton.frame.origin.x + self.leftBottomButton.frame.size.width, self.leftBottomButton.frame.origin.y + self.leftBottomButton.frame.size.height/2.0f - kUnviwedBadgeWidth/2.0f, kUnviwedBadgeWidth, kUnviwedBadgeWidth)];
        self.unviewedVideosBadge.image = [YAUtils imageWithColor:[PRIMARY_COLOR colorWithAlphaComponent:0.5]];
        self.unviewedVideosBadge.clipsToBounds = YES;
        self.unviewedVideosBadge.layer.cornerRadius = kUnviwedBadgeWidth/2;
        [self.cameraAccessories addObject:self.unviewedVideosBadge];
        [self.view addSubview:self.unviewedVideosBadge];
        
        [self setCameraButtonMode:[YAUser currentUser].currentGroup ? YACameraButtonModeBackAndInfo : YACAmeraButtonModeFindAndCreate];
        
        CGFloat width = 48;
        self.recordingIndicator = [[UIView alloc] initWithFrame:CGRectMake(self.view.frame.size.width/2 - width/2, 20, width, width)];
        UIImageView *monkeyIndicator = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, width, width)];
        [monkeyIndicator setImage:[UIImage imageNamed:@"Monkey_Pink"]];
        [self.recordingIndicator addSubview:monkeyIndicator];
        self.recordingIndicator.alpha = 0.0;
        [self.view addSubview:self.recordingIndicator];
        
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
        [self.view addSubview:self.switchCamZone];
        
        
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
        [self.view addSubview:self.trashZone];
        
        [self showRecordingAccessories:NO];
        
        [self enableScrollToTop:YES];
                
        self.previousViewFrame = CGRectMake(0, 0, VIEW_WIDTH, VIEW_HEIGHT/2 + recordButtonWidth/2);

        self.swipeCameraLeft = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipedCameraLeft:)];
        self.swipeCameraLeft.direction = UISwipeGestureRecognizerDirectionLeft;
//        [self.cameraView addGestureRecognizer:self.swipeCameraLeft];
        
        self.swipeCameraRight = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipedCameraRight:)];
        self.swipeCameraRight.direction = UISwipeGestureRecognizerDirectionRight;
//        [self.cameraView addGestureRecognizer:self.swipeCameraRight];

        self.swipeEnlargeCamera = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(enlargeCamera:)];
        self.swipeEnlargeCamera.direction = UISwipeGestureRecognizerDirectionDown;
        [self.cameraView addGestureRecognizer:self.swipeEnlargeCamera];
        
        self.swipeCollapseCamera = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(collapseCamera:)];
        self.swipeCollapseCamera.direction = UISwipeGestureRecognizerDirectionUp;
        [self.cameraView addGestureRecognizer:self.swipeCollapseCamera];
        
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
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(showVideoPage:)
                                                     name:RECORDED_VIDEO_IS_SHOWABLE_NOTIFICAITON
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(openGroupOptions)
                                                     name:OPEN_GROUP_OPTIONS_NOTIFICATION
                                                   object:nil];
        
        [self updateUnviewedVideosBadge];
        
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
        
        self.filters = @[@"#nofilter"];
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

- (void)leftBottomButtonPressed {
    if([YAUser currentUser].currentGroup) {
        [self.delegate backPressed];
    }
    else {
        YAGroupsNavigationController *navController = [[YAGroupsNavigationController alloc] initWithRootViewController:[YAFindGroupsViewConrtoller new]];
        [self presentViewController:navController animated:YES completion:nil];
    }
}

- (void)rightBottomButtonPressed {
    if([YAUser currentUser].currentGroup) {
        [self openGroupOptions];
    }
    else {
        [self.navigationController pushViewController:[NameGroupViewController new] animated:YES];
    }
}

- (void)cameraViewTapped:(id)sender {
    [self.delegate scrollToTop];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self updateUnviewedVideosBadge];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[YACameraManager sharedManager] initCamera];

    dispatch_async(dispatch_get_main_queue(), ^{
        [YACameraManager sharedManager].delegate = self;
        [[YACameraManager sharedManager] setCameraView:self.cameraView];
        
        [self enableRecording:YES];
    });
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self enableRecording:NO];
    });
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [YACameraManager sharedManager].delegate = self;
    //2 px view in the bottom
    UIView *v = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height/2, self.view.bounds.size.width, 2)];
    v.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    v.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:v];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:RECORDED_VIDEO_IS_SHOWABLE_NOTIFICAITON object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:GROUP_DID_REFRESH_NOTIFICATION object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:GROUP_DID_CHANGE_NOTIFICATION object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:OPEN_GROUP_OPTIONS_NOTIFICATION object:nil];

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
    DLog(@"swiped right");
    [self removeFilterAtIndex:self.filterIndex];
    
    self.filterIndex--;
    if(self.filterIndex == -1){
        self.filterIndex = [self.filters count] - 1;
    }
    
    [self addFilterAtIndex:self.filterIndex];
    
    [self showFilterLabel:self.filters[self.filterIndex]];

}

- (void)swipedCameraLeft:(UISwipeGestureRecognizer *)recognizer {
    DLog(@"swiped left");
    
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
    
    [self.view addSubview:self.filterLabel];
    
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
            DLog(@"case 0");
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
//        CGRect flashFrame = self.flashButton.frame;
//        flashFrame.origin.y = VIEW_HEIGHT/2 - flashFrame.size.height - 14;
//        CGRect switchCamFrame = self.switchCameraButton.frame;
//        switchCamFrame.origin.y = VIEW_HEIGHT/2 - switchCamFrame.size.height - 10;

        [self animateToOriginalCameraFrame];
        
        self.largeCamera = NO;
    }
}

- (void)enlargeCamera:(UISwipeGestureRecognizer *)recognizer {
    if(!self.largeCamera){
        if(self.recordTooltipLabel){
            [self.recordTooltipLabel removeFromSuperview];
        }
        
        self.previousViewFrame = self.view.frame;
        
//        [self startEnlargeAnimation];
//        CGRect flashFrame = self.flashButton.frame;
//        flashFrame.origin.y = VIEW_HEIGHT - flashFyasrame.size.height - 14;
//        CGRect switchCamFrame = self.switchCameraButton.frame;
//        switchCamFrame.origin.y = VIEW_HEIGHT - switchCamFrame.size.height - 10;
        [UIView animateWithDuration:0.2 delay:0.0 options:0 animations:^{
            //
            self.view.frame = CGRectMake(0, 0, VIEW_HEIGHT * 3/4, VIEW_HEIGHT);
            self.cameraView.frame = CGRectMake(-(VIEW_HEIGHT * 3/4 - VIEW_WIDTH)/2, 0, VIEW_HEIGHT * 3/4, VIEW_HEIGHT);
            [self.rightBottomButton setAlpha:0.0];
//            [self.groupButton setAlpha:0.0];
            [self.unviewedVideosBadge setAlpha:0.0];
            [self.leftBottomButton setAlpha:0.0];
//            self.flashButton.frame = flashFrame;
//            self.switchCameraButton.frame = switchCamFrame;
            
//            self.recordButton.transform = CGAffineTransformMakeScale(1.5, 1.5);
            self.recordButton.center = CGPointMake(VIEW_WIDTH/2, VIEW_HEIGHT - recordButtonWidth);
        } completion:^(BOOL finished) {
        }];
        
        self.largeCamera = YES;
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
                DLog(@"inside trash?");
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
    
    self.cancelledRecording = NO;
    self.recording = [NSNumber numberWithBool:YES];
    self.indicator = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, VIEW_HEIGHT/32.f)];
    [self.indicator setBackgroundColor:PRIMARY_COLOR];
    [self.indicator setUserInteractionEnabled:NO];
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
//        [self.view setFrame:CGRectMake(0, 0, VIEW_WIDTH, VIEW_HEIGHT)];
    } completion:^(BOOL finished) {
        
    }];
    
    [self enlargeCamera:nil];
    
    [UIView animateWithDuration:MAX_VIDEO_DURATION delay:0.0 options:UIViewAnimationOptionCurveLinear animations:^{
        [self.indicator setFrame:CGRectMake(self.view.frame.size.width, 0, 0, self.indicator.frame.size.height)];
    } completion:^(BOOL finished) {
        if(finished){
            [self endHold];
        }
    }];

    [self startRecordingVideo];
    DLog(@"starting something...");
    
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
            [UIView addKeyframeWithRelativeStartTime:0.0 relativeDuration:0.33 animations:^{
                self.countdownLabel.transform = CGAffineTransformMakeScale(1.5, 1.5);
                self.countdownLabel.alpha = 1.0;
            }];
            
            [UIView addKeyframeWithRelativeStartTime:0.66 relativeDuration:0.33 animations:^{
                self.countdownLabel.transform = CGAffineTransformIdentity;
                self.countdownLabel.alpha = 0.0;
            }];
        } completion:^(BOOL finished) {

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
//        CGRect flashFrame = self.flashButton.frame;
//        flashFrame.origin.y = VIEW_HEIGHT/2 - flashFrame.size.height - 10;
//        CGRect switchCamFrame = self.switchCameraButton.frame;
//        switchCamFrame.origin.y = VIEW_HEIGHT/2 - switchCamFrame.size.height - 10;

        [self.indicatorText setText:NSLocalizedString(@"RECORD_TIP", @"")];
        [self.indicator removeFromSuperview];
        // Do Whatever You want on End of Gesture
        self.recording = [NSNumber numberWithBool:NO];
        
        [self.recordingIndicator.layer removeAllAnimations];
        
        if(self.flash){
            [self setFlashMode:NO];
        }
        
        [self.countdown invalidate];
        self.countdown = nil;

        NSDate *recordingFinished = [NSDate date];
        NSTimeInterval executionTime = [recordingFinished timeIntervalSinceDate:self.recordingTime];
        
        if((executionTime < 0.5) || self.cancelledRecording){
            self.cancelledRecording = YES;
            [self animateToOriginalCameraFrame];
        } else {
            [self performSelector:@selector(animateToOriginalCameraFrame) withObject:self afterDelay:0.5];
//            [self animateToOriginalCameraFrame];
        }
        
        [self stopRecordingVideo];
    }

}

- (void)animateToOriginalCameraFrame {
    [UIView animateWithDuration:0.2 delay:0.0 options:UIViewAnimationOptionAllowAnimatedContent animations:^{
        self.view.frame = self.previousViewFrame;
        [self.cameraView setFrame:CGRectMake(0, 0, VIEW_WIDTH, VIEW_HEIGHT/2)];
        [self showCameraAccessories:YES];
        [self showRecordingAccessories:0];
        self.recordButton.transform = CGAffineTransformIdentity;
        self.recordButton.frame = CGRectMake(VIEW_WIDTH/2 - recordButtonWidth/2, VIEW_HEIGHT/2 - recordButtonWidth/2, recordButtonWidth, recordButtonWidth);
    } completion:^(BOOL finished) {
        self.largeCamera = NO;
    }];
}

- (void)showVideoPage:(NSNotification*)notification {
    YAVideo *video = (YAVideo *)notification.object;
    if (video.createdAt && ([[NSDate date] timeIntervalSinceDate:video.createdAt] < 0.2)) {
        
    }
    [self.delegate presentNewlyRecordedVideo:video];
}

- (void) startRecordingVideo {
    [[YACameraManager sharedManager] startRecording];
}

- (void) stopRecordingVideo {
    __weak YACameraViewController *weakSelf = self;
    DLog(@"yo 1");
    [[YACameraManager sharedManager] stopRecordingWithCompletion:^(NSURL *recordedURL) {
        DLog(@"got here");
        if (!weakSelf.cancelledRecording) {
            if ([YAUser currentUser].currentGroup) {
                [[YAAssetsCreator sharedCreator] createVideoFromRecodingURL:recordedURL
                                                                 addToGroup:[YAUser currentUser].currentGroup
                                                isImmediatelyAfterRecording:YES];
            } else {
                [[YAAssetsCreator sharedCreator] createUnsentVideoFromRecodingURL:recordedURL];
            }
        }
    }];
}

- (void)switchCamera:(id)sender {
    [self setFlashMode:NO];
    [[YACameraManager sharedManager] switchCamera];
}

- (YACameraView *)currentCameraView {
    return self.cameraView;
}

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

- (void)openGroupOptions {
    [self.delegate openGroupOptions];
}

#pragma mark -

- (void)updateUnviewedVideosBadge {
    BOOL hidden = ![YAUser currentUser].currentGroup || ![[YAUser currentUser] hasUnviewedVideosInGroups];
    self.unviewedVideosBadge.alpha = hidden ? 0 : 1;
    self.unviewedVideosBadge.frame = CGRectMake(self.leftBottomButton.frame.origin.x + self.leftBottomButton.frame.size.width + 5, self.leftBottomButton.frame.origin.y + self.leftBottomButton.frame.size.height/2.0f - kUnviwedBadgeWidth/2.0f + 1, kUnviwedBadgeWidth, kUnviwedBadgeWidth);
}

#pragma mark Group Notifications
- (void)groupDidRefresh:(NSNotification*)notification {
    [self updateUnviewedVideosBadge];
}


- (void)groupDidChange:(NSNotification *)notification {
    [self.groupButton setTitle:[YAUser currentUser].currentGroup.name forState:UIControlStateNormal];
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
        [self.view addSubview:self.openSettingsButton];
        
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

- (void)setCameraButtonMode:(YACameraButtonMode)mode {
    if (mode == self.cameraButtonsMode) {
        return;
    }
    self.cameraButtonsMode = mode;
    [self updateCameraButtonsWithMode:mode];
}

- (void)updateCameraButtonsWithMode:(YACameraButtonMode)mode {
    self.rightBottomButton.alpha = 0;
    
    if(mode == YACAmeraButtonModeFindAndCreate) {
        
        //left button
//        [self.leftBottomButton setImage:nil forState:UIControlStateNormal];
//        [self.leftBottomButton setTitle:NSLocalizedString(@"Find Groups", @"") forState:UIControlStateNormal];
//        self.leftBottomButton.frame = CGRectMake(10, VIEW_HEIGHT/2 - 35, 100, 30);
        
        //right button
        [self.rightBottomButton setImage:nil forState:UIControlStateNormal];
        self.rightBottomButton.frame = CGRectMake(VIEW_WIDTH - 110, VIEW_HEIGHT/2 - 35, 100, 30);
        [self.rightBottomButton setTitle:NSLocalizedString(@"Create Group", @"") forState:UIControlStateNormal];
        self.logo.hidden = NO;

        [UIView animateWithDuration:0.2 animations:^{
            self.leftBottomButton.alpha = 0;
            self.rightBottomButton.alpha = 1;
            self.groupButton.alpha = 0;
            self.logo.alpha = 1;
            self.unviewedVideosBadge.alpha = 0;
            self.unviewedVideosBadge.frame = CGRectMake(self.leftBottomButton.frame.origin.x + self.leftBottomButton.frame.size.width + 5, self.leftBottomButton.frame.origin.y + self.leftBottomButton.frame.size.height/2.0f - kUnviwedBadgeWidth/2.0f + 1, kUnviwedBadgeWidth, kUnviwedBadgeWidth);
        } completion:^(BOOL finished) {
            //
            self.leftBottomButton.hidden = YES;
            self.unviewedVideosBadge.hidden = YES;
        }];
    }
    else {
        //left button
        UIImage *backImage = [UIImage imageNamed:@"Back"];
        backImage = [UIImage imageWithCGImage:[backImage CGImage] scale:(backImage.scale * 3) orientation:(backImage.imageOrientation)];
        
        self.leftBottomButton.hidden = NO;
        [self.leftBottomButton setImage:backImage forState:UIControlStateNormal];
        self.leftBottomButton.imageEdgeInsets = UIEdgeInsetsMake(0, -5, 0, 0);
        [self.leftBottomButton setTitle:NSLocalizedString(@"Groups", @"") forState:UIControlStateNormal];
        self.leftBottomButton.frame = CGRectMake(5, VIEW_HEIGHT/2 - 35, 80, 30);
        self.leftBottomButton.layer.shadowColor = [[UIColor blackColor] CGColor];
        self.leftBottomButton.layer.shadowRadius = 1.0f;
        self.leftBottomButton.layer.shadowOpacity = 1.0;
        self.leftBottomButton.layer.shadowOffset = CGSizeZero;

        //right button
        self.rightBottomButton.frame = CGRectMake(VIEW_WIDTH - INFO_SIZE - INFO_PADDING*2, (VIEW_HEIGHT/2 - INFO_SIZE - INFO_PADDING*2) + 5, INFO_SIZE+INFO_PADDING*2, INFO_SIZE+INFO_PADDING*2);
        [self.rightBottomButton addTarget:self action:@selector(rightBottomButtonPressed) forControlEvents:UIControlEventTouchUpInside];
        [self.rightBottomButton setImage:[UIImage imageNamed:@"InfoWhite"] forState:UIControlStateNormal];
        [self.rightBottomButton.imageView setContentMode:UIViewContentModeScaleAspectFit];
        self.rightBottomButton.layer.shadowColor = [[UIColor blackColor] CGColor];
        self.rightBottomButton.layer.shadowRadius = 1.0f;
        self.rightBottomButton.layer.shadowOpacity = 1.0;
        self.rightBottomButton.layer.shadowOffset = CGSizeZero;

        self.leftBottomButton.hidden = NO;
        self.unviewedVideosBadge.hidden = NO;

        [UIView animateWithDuration:0.2 animations:^{
            self.rightBottomButton.alpha = 1;
            self.leftBottomButton.alpha = 1;
            self.groupButton.alpha = 1;
            self.logo.alpha = 0;
            [self updateUnviewedVideosBadge];

        } completion:^(BOOL finished) {
            self.logo.hidden = YES;
        }];
    }

    
}

@end
