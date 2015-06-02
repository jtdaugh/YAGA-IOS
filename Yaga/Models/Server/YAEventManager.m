//
//  YAEventManager.m
//  Yaga
//
//  Created by Jesse on 6/1/15.
//  Copyright (c) 2015 Raj Vir. All rights reserved.
//

#import "YAEventManager.h"
#import <Firebase/Firebase.h>
#import "YAUser.h"

#define FIREBASE_EVENTS_ROOT (@"https://yaga.firebaseio.com/events")

@interface YAEventManager ()

@property (strong, nonatomic) Firebase *firebaseRoot;
@property (strong, nonatomic) NSMutableDictionary *eventsByVideoId;
@property (strong, nonatomic) FQuery *currentChildAddedQuery;

@property (strong, nonatomic) NSString *videoIdWaitingForPushes;

@end

@implementation YAEventManager

+ (instancetype)sharedManager {
    static YAEventManager *sharedInstance = nil;
    static dispatch_once_t once_token;
    dispatch_once(&once_token, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [Firebase defaultConfig].persistenceEnabled = YES;
        self.firebaseRoot = [[Firebase alloc] initWithUrl:FIREBASE_EVENTS_ROOT];
        [self groupChanged];
    }
    return self;
}

- (NSMutableArray *)getEventsForVideo:(YAVideo *)video {
    return [self.eventsByVideoId objectForKey:video.serverId];
}

- (void)beginMonitoringForNewEventsOnVideo:(YAVideo *)video {
    self.videoIdWaitingForPushes = nil;
    [self.currentChildAddedQuery removeAllObservers];

    if (![[self getEventsForVideo:video] count]) {
        // Inital event fetch hasnt returned yet.
        self.videoIdWaitingForPushes = video.serverId;
        return;
    }
    [self startChildAddedQueryForVideo:video];
    
}

- (void)startChildAddedQueryForVideo:(YAVideo *)video {
    NSString *videoId = video.serverId;
    YAEvent *lastEvent = [self.eventsByVideoId[videoId] lastObject];
    __weak YAEventManager *weakSelf = self;
    self.currentChildAddedQuery = [[self.firebaseRoot childByAppendingPath:videoId] queryStartingAtValue:lastEvent.key];
    [self.currentChildAddedQuery observeEventType:FEventTypeChildAdded withBlock:^(FDataSnapshot *snapshot) {
         YAEvent *newEvent = [YAEvent eventWithSnapshot:snapshot];
         [weakSelf.eventsByVideoId[videoId] addObject:newEvent];
         [weakSelf.eventReceiver video:video didReceiveNewEvent:newEvent];
    }];
}

- (void)groupChanged {
    [self.currentChildAddedQuery removeAllObservers];
    self.videoIdWaitingForPushes = nil;
    self.eventsByVideoId = [NSMutableDictionary dictionary];
    for (YAVideo *video in [YAUser currentUser].currentGroup.videos) {
        [self fetchInitalEventsForVideo:video];
    }
}

- (void)fetchInitalEventsForVideo:(YAVideo *)video {
    NSString *groupId = [YAUser currentUser].currentGroup.serverId;
    NSString *videoId = video.serverId;
    __weak YAEventManager *weakSelf = self;
    
    [[self.firebaseRoot childByAppendingPath:video.serverId] observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
        if ([groupId isEqualToString:[YAUser currentUser].currentGroup.serverId]) {
            // if group changed while this request was pending, discard its response.
            NSMutableArray *events = [NSMutableArray array];
            [events addObject:[YAEvent eventForCreationOfVideo:video]];
            for (FDataSnapshot *eventSnapshot in snapshot.children) {
                [events addObject:[YAEvent eventWithSnapshot:eventSnapshot]];
            }
            [weakSelf.eventsByVideoId setObject:events forKey:videoId];
            [weakSelf.eventReceiver video:video receivedInitialEvents:events];
            if ([weakSelf.videoIdWaitingForPushes isEqualToString:videoId]) {
                [weakSelf startChildAddedQueryForVideo:video];
            }
        }
    }];
}

- (void)addEvent:(YAEvent *)event toVideo:(YAVideo *)video {
    [[[self.firebaseRoot childByAppendingPath:video.serverId] childByAutoId] setValue:[event toDictionary]];
}

@end
