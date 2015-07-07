//
//  YAViewCountManager.h
//  Yaga
//
//  Created by Jesse on 6/15/15.
//  Copyright (c) 2015 Raj Vir. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol YAViewCountDelegate <NSObject>

- (void)updatedWithMyViewCount:(NSUInteger)myViewCount otherViewCount:(NSUInteger)othersViewCount;

@end

@interface YAViewCountManager : NSObject

+ (instancetype)sharedManager;

@property (nonatomic, weak) id<YAViewCountDelegate> viewCountDelegate;
@property (nonatomic, readonly) NSUInteger myViewCount;
@property (nonatomic, readonly) NSUInteger othersViewCount;

- (void)switchVideoId:(NSString *)videoId;
- (void)addViewToCurrentVideo;
- (void)killMonitoring;

- (void)didBeginWatchingVideoWithInterval:(NSTimeInterval)interval;
- (void)stoppedWatchingVideo;

@end
