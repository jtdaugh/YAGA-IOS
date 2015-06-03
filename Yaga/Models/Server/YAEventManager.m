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
@property (strong, nonatomic) NSString *groupId;
@property (strong, nonatomic) NSString *videoIdWaitingToMonitor;
@property (strong, nonatomic) NSString *videoIdMonitoring;

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
    self.videoIdWaitingToMonitor = nil;
    self.videoIdMonitoring = nil;
    [self.currentChildAddedQuery removeAllObservers];

    if (![[self getEventsForVideo:video] count]) {
        // Inital event fetch hasnt returned or hasnt been called yet.
        self.videoIdWaitingToMonitor = video.serverId;
        [self prefetchEventsForVideo:video];
    } else {
        [self startChildAddedQueryForVideo:video];
    }
}

- (void)startChildAddedQueryForVideo:(YAVideo *)video {
    NSString *videoId = video.serverId;
    self.videoIdMonitoring = videoId;
    YAEvent *lastEvent = [self.eventsByVideoId[videoId] lastObject];
    __weak YAEventManager *weakSelf = self;
    self.currentChildAddedQuery = [self.firebaseRoot childByAppendingPath:videoId];
    if (lastEvent.key) {
        self.currentChildAddedQuery = [[self.currentChildAddedQuery queryOrderedByKey] queryStartingAtValue:lastEvent.key];
    }
    [self.currentChildAddedQuery observeEventType:FEventTypeChildAdded withBlock:^(FDataSnapshot *snapshot) {
        if ([lastEvent.key isEqual:snapshot.key]) {
            return;
        }
        YAEvent *newEvent = [YAEvent eventWithSnapshot:snapshot];
        [weakSelf.eventsByVideoId[videoId] addObject:newEvent];
        [weakSelf.eventReceiver video:video didReceiveNewEvent:newEvent];
        [weakSelf.eventCountReceiver video:video eventCountUpdated:[weakSelf.eventsByVideoId[videoId] count]];
    }];
}

- (void)groupChanged {
    if (![[YAUser currentUser].currentGroup.serverId isEqualToString:self.groupId]) {
        self.eventsByVideoId = [NSMutableDictionary dictionary];
        [self.currentChildAddedQuery removeAllObservers];
        self.videoIdMonitoring = nil;
        self.videoIdWaitingToMonitor = nil;
    }
    self.groupId = [YAUser currentUser].currentGroup.serverId;
}

- (void)killPrefetchForVideo:(YAVideo *)video {
    NSString *vidId = video.serverId;
    if (![vidId length]) return;
    if ([vidId isEqualToString:self.videoIdMonitoring] ||
        [vidId isEqualToString:self.videoIdWaitingToMonitor]) {
        return; // Don't want to kill a prefetch that an enlarged video is waiting on.
    }
    [[self.firebaseRoot childByAppendingPath:video.serverId] removeAllObservers];
}

- (void)prefetchEventsForVideo:(YAVideo *)video {
    NSString *groupId = [YAUser currentUser].currentGroup.serverId;
    NSString *videoId = video.serverId;
    
    if (![videoId length]) return; // No server id will cause Firebase crash
    if ([self.eventsByVideoId[videoId] count]) return; // Already prefetched this video's events
    if ([self.videoIdMonitoring isEqualToString:videoId]) return; // Already monitoring child added for this video
    
    __weak YAEventManager *weakSelf = self;
    [[self.firebaseRoot childByAppendingPath:video.serverId] observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
        if (![groupId isEqualToString:[YAUser currentUser].currentGroup.serverId]) {
            // if group changed while this request was pending, discard its response.
            return;
        }
        if ([weakSelf.videoIdMonitoring isEqualToString:videoId]) {
            return; // Already monitoring childAdded. Don't mess with it.
        }
        NSMutableArray *events = [NSMutableArray array];
        [events addObject:[YAEvent eventForCreationOfVideo:video]];
        for (FDataSnapshot *eventSnapshot in snapshot.children) {
            [events addObject:[YAEvent eventWithSnapshot:eventSnapshot]];
        }
        [weakSelf.eventsByVideoId setObject:events forKey:videoId];
        [weakSelf.eventReceiver video:video receivedInitialEvents:events];
        [weakSelf.eventCountReceiver video:video eventCountUpdated:events.count];
        
        if ([weakSelf.videoIdWaitingToMonitor isEqualToString:videoId]) {
            [weakSelf startChildAddedQueryForVideo:video];
        }
//        NSLog(@"Firebase initial events loaded for video: %@", video.serverId);
    }];
}

- (void)addEvent:(YAEvent *)event toVideo:(YAVideo *)video {
    [[[self.firebaseRoot childByAppendingPath:video.serverId] childByAutoId] setValue:[event toDictionary]];
}

@end
