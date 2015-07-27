//
//  YAEventManager.h
//  Yaga
//
//  Created by Jesse on 6/1/15.
//  Copyright (c) 2015 Raj Vir. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YAEvent.h"

@protocol YAEventReceiver <NSObject>

- (void)videoWithServerId:(NSString *)serverId localId:(NSString *)localId didReceiveNewEvent:(YAEvent *)event;
- (void)videoWithServerId:(NSString *)serverId localId:(NSString *)localId didRemoveEvent:(YAEvent *)event;
- (void)videoWithServerId:(NSString *)serverId localId:(NSString *)localId receivedInitialEvents:(NSArray *)events;

@end

@protocol YAEventCountReceiver <NSObject>

- (void)videoWithServerId:(NSString *)serverId
                  localId:(NSString *)localId
        eventCountUpdated:(NSUInteger)eventCount;

@end

@interface YAEventManager : NSObject

+ (instancetype)sharedManager;

@property (nonatomic, weak) id<YAEventReceiver> eventReceiver;
@property (nonatomic, weak) id<YAEventCountReceiver> eventCountReceiver;

// Call this when the video page video changes so event manager knows whether to notify
- (void)setCurrentVideoServerId:(NSString *)serverId
                        localId:(NSString *)localId
                 serverIdStatus:(YAVideoServerIdStatus)serverIdStatus;

// Returns an NSArray of YAEvents.
- (NSMutableArray *)getEventsForVideoWithServerId:(NSString *)serverId
                                          localId:(NSString *)localId
                                   serverIdStatus:(YAVideoServerIdStatus)serverIdStatus;
// Returns the count of events for the video.
- (NSUInteger)getEventCountForVideoWithServerId:(NSString *)serverId
                                        localId:(NSString *)localId
                                 serverIdStatus:(YAVideoServerIdStatus)serverIdStatus;

// Asynchronous. If the serverIdStatus is NIL or UNSTABLE, saves comments locally.
// If serverIdStatus is confirmed, Checks if there are any events at the local data store
// for localId, which would only happen if these events were created before the serverIdStatus was confirmed.
// If localId events are found, this method will prepend them to the existing events list for the new serverId on firebase.
- (void)fetchEventsForVideoWithServerId:(NSString *)serverId
                                localId:(NSString *)localId
                                inGroup:(NSString *)groupId
                     withServerIdStatus:(YAVideoServerIdStatus)serverIdStatus;

// If serverIdStatus is NIL or UNSTABLE, the event will be written locally.
// If serverIdStatus is CONFIRMED, event will be sent to firebase
- (void)addEvent:(YAEvent *)event toVideoWithServerId:(NSString *)serverId localId:(NSString *)localId
    serverIdStatus:(YAVideoServerIdStatus)serverIdStatus;


- (void)updateEvent:(YAEvent *)event toVideoWithServerId:(NSString *)serverId localId:(NSString *)localId serverIdStatus:(YAVideoServerIdStatus)serverIdStatus;

- (void)removeEvent:(YAEvent *)event toVideoWithServerId:(NSString *)serverId localId:(NSString *)localId serverIdStatus:(YAVideoServerIdStatus)serverIdStatus;

// If group changed or first call, clears out any memory.
- (void)groupChanged;

@end
