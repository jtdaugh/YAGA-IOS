//
//  YAPostCaptureViewController.m
//  Yaga
//
//  Created by Jesse on 6/23/15.
//  Copyright (c) 2015 Raj Vir. All rights reserved.
//

#import "YAPostCaptureViewController.h"
#import "YAVideoPage.h"
#import "YAUser.h"

@interface YAPostCaptureViewController ()

@property (nonatomic, strong) YAVideoPage *videoPage;
@property (nonatomic, strong) YAVideo *video;
@property (nonatomic, strong) YAGroup *destinationGroup;

@end


@implementation YAPostCaptureViewController

- (id)initWithVideo:(YAVideo *)video {
    self = [super init];
    if (self) {
        _video = video;
        _destinationGroup = video.group;
    }
    return self;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.clipsToBounds = YES;
    self.view.backgroundColor = [UIColor blackColor];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didDeleteVideo:)  name:VIDEO_DID_DELETE_NOTIFICATION  object:nil];

    [self initVideoPage];

    // Do any additional setup after loading the view.
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:VIDEO_DID_DELETE_NOTIFICATION object:nil];
}

- (void)initVideoPage {
    YAVideoPage *page = [[YAVideoPage alloc] initWithFrame:self.view.bounds];
    page.presentingVC = self;
    [self.view addSubview:page];
    
    if (self.destinationGroup) {
        // Only monitor comments if this is a video going straight to a group, not a multipost
        [YAEventManager sharedManager].eventReceiver = page;
        [[YAEventManager sharedManager] beginMonitoringForNewEventsOnVideoId:page.video.serverId
                                                                     inGroup:[[YAUser currentUser].currentGroup.serverId copy]];
    }
    [page setVideo:self.video shouldPreload:YES];
    page.playerView.playWhenReady = YES;
    self.videoPage = page;
}

- (void)didDeleteVideo:(id)sender {
    [self dismissAnimated];
}


- (void)suspendAllGestures:(id)sender {
    // prevent non-visible pages from sending stray calls
    if ([sender isEqual:self.videoPage]) {
        self.panGesture.enabled = NO;
    }
}

- (void)restoreAllGestures:(id)sender  {
    // prevent non-visible pages from sending stray calls
    if ([sender isEqual:self.videoPage]) {
        self.panGesture.enabled = YES;
    }
}

@end
