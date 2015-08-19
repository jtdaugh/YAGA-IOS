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
#define FIREBASE_ROOT (@"https://yagadev.firebaseio.com/")
#else
#define FIREBASE_ROOT (@"https://yaga.firebaseio.com/")
#endif

#define FIREBASE_VIDEO_VC_PATH (@"view_counts")
#define FIREBASE_GROUP_VC_ROOT (@"group_view_counts")
#define FIREBASE_USER_VC_ROOT (@"user_view_counts")

@interface YAViewCountManager ()

@property (nonatomic, strong) NSString *monitoringVideoId;
@property (nonatomic, strong) NSString *monitoringGroupId;
@property (nonatomic, strong) NSString *monitoringUserName;

@property (nonatomic, strong) NSString *myUsername;

@property (nonatomic, strong) Firebase *videoViewCountRoot;
@property (nonatomic, strong) Firebase *userViewCountRoot;
@property (nonatomic, strong) Firebase *groupViewCountRoot;

@property (nonatomic, strong) Firebase *currentMonitoringVideoRef;
@property (nonatomic, strong) Firebase *currentMonitoringUserRef;
@property (nonatomic, strong) Firebase *currentMonitoringGroupRef;

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
        _videoViewCountRoot = [[Firebase alloc] initWithUrl:[FIREBASE_ROOT stringByAppendingString:FIREBASE_VIDEO_VC_PATH]];
        _userViewCountRoot = [[Firebase alloc] initWithUrl:[FIREBASE_ROOT stringByAppendingString:FIREBASE_USER_VC_ROOT]];
        _groupViewCountRoot = [[Firebase alloc] initWithUrl:[FIREBASE_ROOT stringByAppendingString:FIREBASE_GROUP_VC_ROOT]];

        _myUsername = [YAUser currentUser].username; // thread issues with realm who knows!!!
    }
    return self;
}

- (void)monitorVideoWithId:(NSString *)videoId {
    if ([videoId isEqualToString:self.monitoringVideoId]) return; // Video id didnt change
    DLog(@"view count Switched video id");
    self.monitoringVideoId = videoId;
    [self.currentMonitoringVideoRef removeAllObservers];
    self.currentMonitoringVideoRef = nil;
    
    if (![videoId length]) return;
    
    self.currentMonitoringVideoRef = [self.videoViewCountRoot childByAppendingPath:videoId];
    __weak YAViewCountManager *weakSelf = self;
    [self.currentMonitoringVideoRef observeEventType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
        NSUInteger othersCount = 0;
        NSUInteger myViewCount = 0;
        for (FDataSnapshot *child in snapshot.children) {
            NSUInteger val = [child.value unsignedIntValue];
            NSString *username = child.key;
            if ([username isEqualToString:weakSelf.myUsername]) {
                myViewCount = val;
            } else {
                othersCount += val;
            }
        }
        [weakSelf.videoViewCountDelegate videoUpdatedWithMyViewCount:myViewCount otherViewCount:othersCount];
    }];
}

- (void)monitorGroupWithId:(NSString *)groupId {
    if ([groupId isEqualToString:self.monitoringGroupId]) return; // Video id didnt change
    DLog(@"view count Switched video id");
    self.monitoringGroupId = groupId;
    [self.currentMonitoringGroupRef removeAllObservers];
    self.currentMonitoringGroupRef = nil;
    
    if (![groupId length]) return;
    
    self.currentMonitoringGroupRef = [self.groupViewCountRoot childByAppendingPath:groupId];
    __weak YAViewCountManager *weakSelf = self;
    [self.currentMonitoringGroupRef observeEventType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
        NSUInteger othersCount = 0;
        NSUInteger myViewCount = 0;
        for (FDataSnapshot *child in snapshot.children) {
            NSUInteger val = [child.value unsignedIntValue];
            NSString *username = child.key;
            if ([username isEqualToString:weakSelf.myUsername]) {
                myViewCount = val;
            } else {
                othersCount += val;
            }
        }
        [weakSelf.groupViewCountDelegate groupUpdatedWithMyViewCount:myViewCount otherViewCount:othersCount];
    }];
}

- (void)monitorUser:(NSString *)username {
    if ([username isEqualToString:self.monitoringUserName]) return; // Video id didnt change
    DLog(@"view count Switched video id");
    self.monitoringUserName = username;
    [self.currentMonitoringUserRef removeAllObservers];
    self.currentMonitoringUserRef = nil;
    
    if (![username length]) return;
    
    self.currentMonitoringUserRef = [self.userViewCountRoot childByAppendingPath:username];
    __weak YAViewCountManager *weakSelf = self;
    [self.currentMonitoringUserRef observeEventType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
        NSUInteger othersCount = 0;
        NSUInteger myViewCount = 0;
        for (FDataSnapshot *child in snapshot.children) {
            NSUInteger val = [child.value unsignedIntValue];
            NSString *username = child.key;
            if ([username isEqualToString:weakSelf.myUsername]) {
                myViewCount = val;
            } else {
                othersCount += val;
            }
        }
        [weakSelf.userViewCountDelegate userUpdatedWithMyViewCount:myViewCount otherViewCount:othersCount];
    }];
}


- (void)addViewToVideoWithId:(NSString *)videoId groupId:(NSString *)groupId user:(NSString *)user {
    if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateBackground) return;
    
    if ([videoId length]) {
        // Increment counter for video
        [[[self.videoViewCountRoot childByAppendingPath:videoId] childByAppendingPath:self.myUsername]
            runTransactionBlock:^FTransactionResult *(FMutableData *currentData) {
            NSNumber *value = currentData.value;
            if (currentData.value == [NSNull null]) {
                value = nil;
            }
            [currentData setValue:[NSNumber numberWithInt:(1 + [value intValue])]];
            return [FTransactionResult successWithValue:currentData];
        }];
    }
    
    // Increment counter for group
    if ([groupId length]) {
        [[[self.groupViewCountRoot childByAppendingPath:groupId] childByAppendingPath:self.myUsername]
         runTransactionBlock:^FTransactionResult *(FMutableData *currentData) {
             NSNumber *value = currentData.value;
             if (currentData.value == [NSNull null]) {
                 value = nil;
             }
             [currentData setValue:[NSNumber numberWithInt:(1 + [value intValue])]];
             return [FTransactionResult successWithValue:currentData];
         }];
    }

    // Increment counter for user profile
    if ([user length]) {
        [[[self.userViewCountRoot childByAppendingPath:user] childByAppendingPath:self.myUsername]
         runTransactionBlock:^FTransactionResult *(FMutableData *currentData) {
             NSNumber *value = currentData.value;
             if (currentData.value == [NSNull null]) {
                 value = nil;
             }
             [currentData setValue:[NSNumber numberWithInt:(1 + [value intValue])]];
             return [FTransactionResult successWithValue:currentData];
         }];
    }
}

- (void)killAllMonitoring {
    [self.currentMonitoringVideoRef removeAllObservers];
    [self.currentMonitoringGroupRef removeAllObservers];
    [self.currentMonitoringUserRef removeAllObservers];
}

@end
