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

- (NSMutableArray *)getEventsForVideoId:(NSString *)videoId {
    
    return videoId ? [self.eventsByVideoId objectForKey:videoId] : nil;
}

- (NSUInteger)getEventCountForVideoId:(NSString *)videoId {
    return videoId ? [[self.eventsByVideoId objectForKey:videoId] count] : 0;
}


- (void)beginMonitoringForNewEventsOnVideoId:(NSString *)videoId inGroup:(NSString *)groupId{

    self.videoIdWaitingToMonitor = nil;
    self.videoIdMonitoring = nil;
    [self.currentChildAddedQuery removeAllObservers];

    if (![[self getEventsForVideoId:videoId] count]) {
        // Inital event fetch hasnt returned or hasnt been called yet.
        self.videoIdWaitingToMonitor = videoId;
        [self prefetchEventsForVideoId:videoId inGroup:groupId];
    } else {
        [self startChildAddedQueryForVideoId:videoId];
    }
}

- (void)startChildAddedQueryForVideoId:(NSString *)videoId {
    if (![videoId length]) return;
    
    self.videoIdMonitoring = videoId;
    YAEvent *lastEvent = [self.eventsByVideoId[videoId] lastObject];
    __weak YAEventManager *weakSelf = self;
    self.currentChildAddedQuery = [self.firebaseRoot childByAppendingPath:videoId];
    if (lastEvent.key) {
        self.currentChildAddedQuery = [[self.currentChildAddedQuery queryOrderedByKey] queryStartingAtValue:lastEvent.key];
    }
    [self.currentChildAddedQuery observeEventType:FEventTypeChildAdded withBlock:^(FDataSnapshot *snapshot) {
        if ([lastEvent.key isEqualToString:snapshot.key]) {
            return;
        }
        YAEvent *newEvent = [YAEvent eventWithSnapshot:snapshot];
        [weakSelf.eventsByVideoId[videoId] addObject:newEvent];
        [weakSelf.eventReceiver videoId:videoId didReceiveNewEvent:newEvent];
        [weakSelf.eventCountReceiver videoId:videoId eventCountUpdated:[weakSelf.eventsByVideoId[videoId] count]];
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

- (void)killPrefetchForVideoId:(NSString *)videoId {
    
    if (![videoId length]) return;
    if ([videoId isEqualToString:self.videoIdMonitoring] ||
        [videoId isEqualToString:self.videoIdWaitingToMonitor]) {
        return; // Don't want to kill a prefetch that an enlarged video is waiting on.
    }
    [[self.firebaseRoot childByAppendingPath:videoId] removeAllObservers];
}

- (void)prefetchEventsForVideoId:(NSString *)videoId inGroup:(NSString *)groupId {
    
    if (![videoId length]) {
        NSLog(@"Not prefetching due to empty video serverId");
        return; // No server id will cause Firebase crash
    }
    if ([self.eventsByVideoId[videoId] count]) return; // Already prefetched this video's events
    if ([self.videoIdMonitoring isEqualToString:videoId]) return; // Already monitoring child added for this video
    
    __weak YAEventManager *weakSelf = self;
    [[self.firebaseRoot childByAppendingPath:videoId] observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
        if ([weakSelf.videoIdMonitoring isEqualToString:videoId]) {
            return; // Already monitoring childAdded. Don't mess with it.
        }
        NSMutableArray *events = [NSMutableArray array];
        for (FDataSnapshot *eventSnapshot in snapshot.children) {
            [events addObject:[YAEvent eventWithSnapshot:eventSnapshot]];
        }
        [weakSelf.eventsByVideoId setObject:events forKey:videoId];
        [weakSelf.eventReceiver videoId:videoId receivedInitialEvents:events];
        [weakSelf.eventCountReceiver videoId:videoId eventCountUpdated:events.count];
        
        if ([weakSelf.videoIdWaitingToMonitor isEqualToString:videoId]) {
            [weakSelf startChildAddedQueryForVideoId:videoId];
            }
    }];
}

- (void)addEvent:(YAEvent *)event toVideoId:(NSString *)videoId {
    if ([videoId length]) {
        [[[self.firebaseRoot childByAppendingPath:videoId] childByAutoId] setValue:[event toDictionary]];
    }
}

@end
