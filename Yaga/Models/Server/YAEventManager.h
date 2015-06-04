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

- (void)videoId:(NSString *)videoId didReceiveNewEvent:(YAEvent *)event;
- (void)videoId:(NSString *)video receivedInitialEvents:(NSArray *)events;

@end

@protocol YAEventCountReceiver <NSObject>

- (void)videoId:(NSString *)videoId eventCountUpdated:(NSUInteger)eventCount;

@end

@interface YAEventManager : NSObject

+ (instancetype)sharedManager;

@property (nonatomic, weak) id<YAEventReceiver> eventReceiver;
@property (nonatomic, weak) id<YAEventCountReceiver> eventCountReceiver;

// Returns an NSArray of YAEvents
- (NSMutableArray *)getEventsForVideoId:(NSString *)videoId;

- (NSUInteger)getEventCountForVideoId:(NSString *)videoId;

// Start monitoring childAdded
- (void)beginMonitoringForNewEventsOnVideoId:(NSString *)videoId inGroup:(NSString *)groupId;

// Observe value once then kill observer
- (void)prefetchEventsForVideoId:(NSString *)videoId inGroup:(NSString *)groupId;

// Stops the request for initial data on given video if it hasnt returned yet.
- (void)killPrefetchForVideoId:(NSString *)videoId;

// If group changed or first call, clears any memory and pulls events data for new group.
- (void)groupChanged;

- (void)addEvent:(YAEvent *)event toVideoId:(NSString *)videoId;

@end
