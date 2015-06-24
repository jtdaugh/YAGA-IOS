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
@property (nonatomic, assign) BOOL dismissed;
@property (nonatomic, strong) YAGroup *destinationGroup;

@end

#define kDismissalTreshold 400.0f

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
    self.panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGesture:)];
    [self.view addGestureRecognizer:self.panGesture];
    
    [self initVideoPage];

    // Do any additional setup after loading the view.
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
    
}

#pragma mark - Animated dismissal
- (void)panGesture:(UIPanGestureRecognizer *)rec
{
    if(self.dismissed)
        return;
    
    CGPoint vel = [rec velocityInView:self.view];
    CGPoint tr = [rec translationInView:self.view];
    
    
    if(tr.y > 0) {
        CGFloat f = tr.y / [UIScreen mainScreen].bounds.size.height;
        if(f < 1) {
            CGRect r = self.view.frame;
            r.origin.y = tr.y;
            r.origin.x = tr.x;
            self.view.frame = r;
        }
        else {
            [self dismissAnimated];
            return;
        }
    }
    else {
        [self restoreAnimated];
    }
    
    if(rec.state == UIGestureRecognizerStateEnded) {
        if(vel.y > kDismissalTreshold) {
            [self dismissAnimated];
            return;
        }
        
        //put back
        [self restoreAnimated];
    }
    
}

- (void)dismissAnimated {
    
    self.dismissed = YES;
    
    //dismiss
    [UIView animateWithDuration:0.5 delay:0.0 usingSpringWithDamping:0.7 initialSpringVelocity:0.5 options:0 animations:^{
        self.view.frame = CGRectMake(0, [UIScreen mainScreen].bounds.size.height * .5, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
        self.view.alpha = 0.0;
        self.view.transform = CGAffineTransformMakeScale(0.5,0.5);
    } completion:^(BOOL finished) {
        if(finished)
            [self dismissViewControllerAnimated:NO completion:nil];
    }];
}

- (void)restoreAnimated {
    [UIView animateWithDuration:0.5 delay:0.0 usingSpringWithDamping:0.7 initialSpringVelocity:0.5 options:0 animations:^{
        self.view.transform = CGAffineTransformMakeScale(1.0f, 1.0f);
        self.view.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
    } completion:nil];
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
