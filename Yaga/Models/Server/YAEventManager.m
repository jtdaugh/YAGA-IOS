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

#if (DEBUG && DEBUG_SERVER)
#define FIREBASE_EVENTS_ROOT (@"https://yagadev.firebaseio.com/events")
#else
#define FIREBASE_EVENTS_ROOT (@"https://yaga.firebaseio.com/events")
#endif

@interface YAEventManager ()

@property (strong, nonatomic) Firebase *firebaseRoot;
@property (strong) NSMutableDictionary *initialEventsLoadedForId;
@property (strong) NSMutableDictionary *unsentEventsByLocalVideoId; // To keep track events before serverId is set
@property (strong) NSMutableDictionary *eventsByServerVideoId;
@property (strong) NSMutableDictionary *queriesByVideoId;
@property (strong) NSString *groupId;
@property (strong) NSString *currentVideoServerId;
@property (strong) NSString *currentVideoLocalId;
@property YAVideoServerIdStatus currentVideoServerIdStatus;

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
        self.firebaseRoot = [[Firebase alloc] initWithUrl:FIREBASE_EVENTS_ROOT];
        self.unsentEventsByLocalVideoId = [NSMutableDictionary dictionary];
        self.eventsByServerVideoId = [NSMutableDictionary dictionary];
        self.queriesByVideoId = [NSMutableDictionary dictionary];
        self.initialEventsLoadedForId = [NSMutableDictionary dictionary];
        [self groupChanged];
    }
    return self;
}

- (void)setCurrentVideoServerId:(NSString *)serverId
                        localId:(NSString *)localId
                 serverIdStatus:(YAVideoServerIdStatus)serverIdStatus {
    _currentVideoServerId = serverId;
    _currentVideoLocalId = localId;
    _currentVideoServerIdStatus = serverIdStatus;
}

- (NSMutableArray *)getEventsForVideoWithServerId:(NSString *)serverId
                                          localId:(NSString *)localId
                                   serverIdStatus:(YAVideoServerIdStatus)serverIdStatus {
    
    if (serverIdStatus == YAVideoServerIdStatusConfirmed) {
        return [self.eventsByServerVideoId objectForKey:serverId];
    } else {
        return [self.unsentEventsByLocalVideoId objectForKey:localId];
    }
}

- (NSUInteger)getEventCountForVideoWithServerId:(NSString *)videoId
                                        localId:(NSString *)localId
                                 serverIdStatus:(YAVideoServerIdStatus)serverIdStatus {
    return [[self getEventsForVideoWithServerId:videoId localId:localId serverIdStatus:serverIdStatus] count];
}

- (void)fetchEventsForVideoWithServerId:(NSString *)serverId
                                localId:(NSString *)localId
                                inGroup:(NSString *)groupId
                     withServerIdStatus:(YAVideoServerIdStatus)serverIdStatus {
    if (serverIdStatus == YAVideoServerIdStatusConfirmed) {
        if (!self.queriesByVideoId || ![serverId length]) return;
        if (self.queriesByVideoId[serverId]) {
            return; // already observing this on firebase.
        }
        // If serverIdStatus is CONFIRMED:
        //   Check for local events in memory and prepend them to firebase & remove locally
        //   Then start childAdded firebase query for video by serverId

        Firebase *videoRef = [self.firebaseRoot childByAppendingPath:serverId];
        [self.queriesByVideoId setObject:videoRef forKey:serverId];
        
        NSArray *locallyStoredEvents = [self.unsentEventsByLocalVideoId objectForKey:localId];
        if (locallyStoredEvents) {
            NSMutableDictionary *eventsToPrepend = [NSMutableDictionary dictionary];
            for (int i = 0; i < [locallyStoredEvents count]; i++) {
                NSString *key = [NSString stringWithFormat:@"%d", i];
                YAEvent *event = locallyStoredEvents[i];
                eventsToPrepend[key] = [event toDictionary];
            }
            [self.unsentEventsByLocalVideoId removeObjectForKey:localId];
            if ([eventsToPrepend count]) {
                [videoRef updateChildValues:eventsToPrepend];
            }
        }
        __weak YAEventManager *weakSelf = self;
        [[videoRef queryLimitedToLast:kMaxEventsFetchedPerVideo] observeEventType:FEventTypeChildAdded
                                                                        withBlock:^(FDataSnapshot *snapshot) {
            if (weakSelf.initialEventsLoadedForId[serverId]) {
                YAEvent *newEvent = [YAEvent eventWithSnapshot:snapshot];
                NSMutableArray *eventsArray = weakSelf.eventsByServerVideoId[serverId];
                [eventsArray addObject:newEvent];
                if ([weakSelf.currentVideoServerId isEqualToString:serverId]) {
                    [weakSelf.eventReceiver videoWithServerId:serverId localId:localId didReceiveNewEvent:newEvent];
                }
                [weakSelf.eventCountReceiver videoWithServerId:serverId localId:localId eventCountUpdated:[eventsArray count]];
            }
        }];
        [[videoRef queryLimitedToLast:kMaxEventsFetchedPerVideo] observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
            weakSelf.initialEventsLoadedForId[serverId] = @(YES);
            NSMutableArray *eventsArray = [NSMutableArray array];
            for (FDataSnapshot *eventSnapshot in snapshot.children) {
                [eventsArray addObject:[YAEvent eventWithSnapshot:eventSnapshot]];
            }
            weakSelf.eventsByServerVideoId[serverId] = eventsArray;
            if ([weakSelf.currentVideoServerId isEqualToString:serverId]) {
                [weakSelf.eventReceiver videoWithServerId:serverId localId:localId receivedInitialEvents:eventsArray];
            }
            [weakSelf.eventCountReceiver videoWithServerId:serverId localId:localId eventCountUpdated:[eventsArray count]];
        }];
    } else {
        // If serverIdStatus is NIL or UNSTABLE:
        //   No new requests needed. Local events already loaded into @unsentVideosByLocalVideoId
    }
}

- (void)addEvent:(YAEvent *)event toVideoWithServerId:(NSString *)serverId localId:(NSString *)localId
  serverIdStatus:(YAVideoServerIdStatus)serverIdStatus {
    if (serverIdStatus == YAVideoServerIdStatusConfirmed) {
        // Just add the event to firebase. No need to notify since firebase block will
        [[[self.firebaseRoot childByAppendingPath:serverId] childByAutoId] setValue:[event toDictionary]];
    } else {
        // Add the local event to memory, and notify receivers
        NSMutableArray *events = self.unsentEventsByLocalVideoId[localId];
        if (!events) events = [NSMutableArray array];
        [events addObject:event];
        self.unsentEventsByLocalVideoId[localId] = events;
        [self.eventCountReceiver videoWithServerId:serverId localId:localId eventCountUpdated:[events count]];
        if ([self.currentVideoLocalId isEqualToString:localId]) {
            [self.eventReceiver videoWithServerId:serverId localId:localId didReceiveNewEvent:event];
        }
    }
}

- (void)groupChanged {
    if (![[YAUser currentUser].currentGroup.serverId isEqualToString:self.groupId]) {
        [self.eventsByServerVideoId removeAllObjects];
        if (self.queriesByVideoId) {
            for (id key in self.queriesByVideoId) {
                if (self.queriesByVideoId[key]) {
                    Firebase *ref = self.queriesByVideoId[key];
                    [ref removeAllObservers];
                }
            }
        }
        [self.queriesByVideoId removeAllObjects];
        [self.initialEventsLoadedForId removeAllObjects];
    }
    self.groupId = [YAUser currentUser].currentGroup.serverId;
}

@end
