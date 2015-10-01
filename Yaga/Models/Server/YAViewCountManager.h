//
//  YAViewCountManager.h
//  Yaga
//
//  Created by Jesse on 6/15/15.
//  Copyright (c) 2015 Raj Vir. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol YAVideoViewCountDelegate <NSObject>
- (void)videoUpdatedWithMyViewCount:(NSUInteger)myViewCount otherViewCount:(NSUInteger)othersViewCount;
@end

@protocol YAGroupViewCountDelegate <NSObject>
- (void)groupUpdatedWithMyViewCount:(NSUInteger)myViewCount otherViewCount:(NSUInteger)othersViewCount;
@end

@protocol YAUserViewCountDelegate <NSObject>
- (void)userUpdatedWithMyViewCount:(NSUInteger)myViewCount otherViewCount:(NSUInteger)othersViewCount;
@end

@interface YAViewCountManager : NSObject

+ (instancetype)sharedManager;

@property (nonatomic, weak) id<YAVideoViewCountDelegate> videoViewCountDelegate;
@property (nonatomic, weak) id<YAGroupViewCountDelegate> groupViewCountDelegate;
@property (nonatomic, weak) id<YAUserViewCountDelegate> userViewCountDelegate;

- (void)monitorVideoWithId:(NSString *)videoId;
- (void)monitorGroupWithId:(NSString *)groupId;
- (void)monitorUser:(NSString *)username;

- (void)killAllMonitoring;

- (void)addViewToVideoWithId:(NSString *)videoId groupId:(NSString *)groupId user:(NSString *)user;

@end
