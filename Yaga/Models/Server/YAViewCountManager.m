//
//  YAViewCountManager.m
//  Yaga
//
//  Created by Jesse on 6/15/15.
//  Copyright (c) 2015 Raj Vir. All rights reserved.
//

#import "YAViewCountManager.h"

#import <Firebase/Firebase.h>

#import "YAUser.h"
#import "YAWeakTimerTarget.h"

#if (DEBUG && DEBUG_SERVER)
#define FIREBASE_VC_ROOT (@"https://yagadev.firebaseio.com/view_counts")
#else
#define FIREBASE_VC_ROOT (@"https://yaga.firebaseio.com/view_counts")
#endif

@interface YAViewCountManager ()

@property (nonatomic, strong) NSString *videoId;
@property (nonatomic, strong) NSString *username;

@property (nonatomic, readwrite) NSUInteger myViewCount;
@property (nonatomic, readwrite) NSUInteger othersViewCount;

@property (nonatomic, strong) Firebase *viewCountRoot;
@property (nonatomic, strong) Firebase *currentVideoRef;

@property (nonatomic, strong) NSTimer *addViewTimer;

@end

@implementation YAViewCountManager

+ (instancetype)sharedManager {
    static YAViewCountManager *sharedInstance = nil;
    static dispatch_once_t once_token;
    dispatch_once(&once_token, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _viewCountRoot = [[Firebase alloc] initWithUrl:FIREBASE_VC_ROOT];
        _myViewCount = 0;
        _othersViewCount = 0;
        _videoId = nil;
        _username = [YAUser currentUser].username; // thread issues with realm who knows!!!
    }
    return self;
}

- (void)switchVideoId:(NSString *)videoId {
    if ([videoId isEqualToString:_videoId]) return; // Video id didnt change
    _videoId = videoId;
    self.myViewCount = 0;
    self.othersViewCount = 0;
    [self.currentVideoRef removeAllObservers];
    self.currentVideoRef = nil;
    
    if (![videoId length]) return;

    self.currentVideoRef = [self.viewCountRoot childByAppendingPath:videoId];
    __weak YAViewCountManager *weakSelf = self;
    [self.currentVideoRef observeEventType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
        int othersCount = 0;
        for (FDataSnapshot *child in snapshot.children) {
            NSUInteger val = [child.value unsignedIntValue];
            NSString *username = child.key;
            if ([username isEqualToString:weakSelf.username]) {
                weakSelf.myViewCount = val;
            } else {
                othersCount += val;
            }
        }
        weakSelf.othersViewCount = othersCount;
        [weakSelf.viewCountDelegate updatedWithMyViewCount:weakSelf.myViewCount
                                            otherViewCount:weakSelf.othersViewCount];
    }];
}

- (void)didBeginWatchingVideoWithInterval:(NSTimeInterval)interval {
    [self.addViewTimer invalidate];
    if (interval > 0.1) {
        [self addViewToCurrentVideo];
        self.addViewTimer = [YAWeakTimerTarget scheduledTimerWithTimeInterval:interval target:self selector:@selector(addViewToCurrentVideo) userInfo:nil repeats:YES];
    }
}

- (void)stoppedWatchingVideo {
    [self.addViewTimer invalidate];
}

- (void)addViewToCurrentVideo {
    if (!self.currentVideoRef || ([[UIApplication sharedApplication] applicationState] == UIApplicationStateBackground)) return;
    [[self.currentVideoRef childByAppendingPath:self.username]
        runTransactionBlock:^FTransactionResult *(FMutableData *currentData) {
        NSNumber *value = currentData.value;
        if (currentData.value == [NSNull null]) {
            value = 0;
        }
        [currentData setValue:[NSNumber numberWithInt:(1 + [value intValue])]];
        return [FTransactionResult successWithValue:currentData];
    }];
}

- (void)killMonitoring {
    [self.currentVideoRef removeAllObservers];
}

@end
