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

- (void)video:(YAVideo *)video didReceiveNewEvent:(YAEvent *)event;
- (void)video:(YAVideo *)video receivedInitialEvents:(NSArray *)events;

@end

@interface YAEventManager : NSObject

+ (instancetype)sharedManager;

@property (nonatomic, weak) id<YAEventReceiver> eventReceiver;

// Returns an NSArray of YAEvents
- (NSMutableArray *)getEventsForVideo:(YAVideo *)video;

// Start monitoring childAdded
- (void)beginMonitoringForNewEventsOnVideo:(YAVideo *)video;

// Observe value once then kill observer
- (void)prefetchEventsForVideo:(YAVideo *)video;

// Stops the request for initial data on given video if it hasnt returned yet.
- (void)killPrefetchForVideo:(YAVideo *)video;

// If group changed or first call, clears any memory and pulls events data for new group.
- (void)groupChanged;

- (void)addEvent:(YAEvent *)event toVideo:(YAVideo *)video;

@end
