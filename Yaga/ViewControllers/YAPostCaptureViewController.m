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
#import "YAUtils.h"
#import "YAPopoverView.h"
#import "MSAlertController.h"

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
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dismissDueToNewGroup:)  name:DID_CREATE_GROUP_FROM_VIDEO_NOTIFICATION object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(videoDidChange:) name:VIDEO_CHANGED_NOTIFICATION object:nil];

    [self initVideoPage];

    // Do any additional setup after loading the view.
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (self.video.invalidated) return;
    if (self.destinationGroup) {
        if (self.destinationGroup.publicGroup) {
            if (![YAUtils hasRecordedPublicVideo]) {
                [self showFirstPublicVideoTooltip];
                [YAUtils setRecordedPublicVideo];
            }
        } else {
            if (![YAUtils hasRecordedPrivateVideo]) {
                [self showFirstPrivateVideoTooltip];
                [YAUtils setRecordedPrivateVideo];
            }
        }
    } else {
        if (![YAUtils hasRecordedUngroupedVideo]) {
            [self showFirstUngroupedVideoTooltip];
            [YAUtils setRecordedUngroupedVideo];
        }
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:VIDEO_DID_DELETE_NOTIFICATION object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:DID_CREATE_GROUP_FROM_VIDEO_NOTIFICATION object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:VIDEO_CHANGED_NOTIFICATION object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
}


- (void)willEnterForeground:(NSNotification *)notif {
    if (!self.video || [self.video isInvalidated]) return;
    [[YAEventManager sharedManager] setCurrentVideoServerId:self.video.serverId localId:self.video.localId serverIdStatus:[YAVideo serverIdStatusForVideo:self.video]];
    [[YAEventManager sharedManager] fetchEventsForVideoWithServerId:self.video.serverId
                                                            localId:self.video.localId
                                                            inGroup:self.video.group.serverId
                                                 withServerIdStatus:[YAVideo serverIdStatusForVideo:self.video]];
}

- (void)videoDidChange:(NSNotification *)notification {
    // Only act if this notification is for video on visible page
    if (!self.video || [self.video isInvalidated]) return;
    
    if([notification.object isEqual:self.video] && self.destinationGroup) {
        if ([YAVideo serverIdStatusForVideo:self.video] == YAVideoServerIdStatusConfirmed) {
            [[YAViewCountManager sharedManager] switchVideoId:self.video.serverId];
        } else {
            [[YAViewCountManager sharedManager] switchVideoId:nil];
        }
        
        // Reload comments, which will initialize with firebase if serverID just became ready.
        [[YAEventManager sharedManager] setCurrentVideoServerId:self.video.serverId localId:self.video.localId serverIdStatus:[YAVideo serverIdStatusForVideo:self.video]];
        [[YAEventManager sharedManager] fetchEventsForVideoWithServerId:self.video.serverId
                                                                localId:self.video.localId
                                                                inGroup:self.video.group.serverId
                                                     withServerIdStatus:[YAVideo serverIdStatusForVideo:self.video]];
        
    }
}

- (void)initVideoPage {
    YAVideoPage *page = [[YAVideoPage alloc] initWithFrame:self.view.bounds];
    page.presentingVC = self;
    [self.view addSubview:page];
    
    if (self.destinationGroup) {
        // Only monitor comments if this is a video going straight to a group, not a multipost
        [YAEventManager sharedManager].eventReceiver = page;
        [[YAEventManager sharedManager] setCurrentVideoServerId:self.video.serverId localId:self.video.localId serverIdStatus:[YAVideo serverIdStatusForVideo:self.video]];
        [[YAEventManager sharedManager] fetchEventsForVideoWithServerId:self.video.serverId localId:self.video.localId inGroup:self.video.group.serverId withServerIdStatus:[YAVideo serverIdStatusForVideo:self.video]];
    
        YAVideoServerIdStatus status = [YAVideo serverIdStatusForVideo:page.video];
        [[YAViewCountManager sharedManager] switchVideoId:(status == YAVideoServerIdStatusConfirmed) ? self.video.serverId : nil];
        [YAViewCountManager sharedManager].viewCountDelegate = page;

    } else {
        [[YAViewCountManager sharedManager] switchVideoId:nil];
        [YAViewCountManager sharedManager].viewCountDelegate = page;
    }
    [page setVideo:self.video shouldPreload:YES];
    page.playerView.playWhenReady = YES;
    self.videoPage = page;
}

- (void)dismissDueToNewGroup:(id)sender {
    
    [self dismissAnimated];
}

- (void)didDeleteVideo:(id)sender {
    // Need to dismiss the alert delete confirmation first.
    if ([[self presentedViewController] isKindOfClass:[MSAlertController class]]) {
        __weak YAPostCaptureViewController *weakSelf = self;
        [self dismissViewControllerAnimated:NO completion:^{
            [weakSelf dismissAnimated];
        }];
    } else {
        [self dismissAnimated];
    }
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

#pragma mark - tooltips

- (void)showFirstPrivateVideoTooltip {
    [[[YAPopoverView alloc] initWithTitle:NSLocalizedString(@"FIRST_GROUP_POST_TITLE", @"") bodyText:[NSString stringWithFormat:NSLocalizedString(@"FIRST_GROUP_POST_BODY", @""), [YAUser currentUser].currentGroup.name] dismissText:@"Got it" addToView:self.videoPage] show];
}

- (void)showFirstPublicVideoTooltip {
    [[[YAPopoverView alloc] initWithTitle:NSLocalizedString(@"FIRST_HUMANITY_POST_TITLE", @"") bodyText:[NSString stringWithFormat:NSLocalizedString(@"FIRST_HUMANITY_POST_BODY", @""), [YAUser currentUser].currentGroup.name] dismissText:@"Got it" addToView:self.videoPage] show];
}

- (void)showFirstUngroupedVideoTooltip {
    [[[YAPopoverView alloc] initWithTitle:NSLocalizedString(@"FIRST_NOGROUP_POST_TITLE", @"") bodyText:NSLocalizedString(@"FIRST_NOGROUP_POST_BODY", @"") dismissText:@"Got it" addToView:self.videoPage] show];
}


@end
