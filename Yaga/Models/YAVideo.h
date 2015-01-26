//
//  YAVideo.h
//  Yaga
//
//  Created by valentinkovalski on 12/17/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//
#import "YAContact.h"
#import <Realm/Realm.h>

@class YAGroup;
@class YAVideo;

typedef void (^videoCreatedCompletionHandler)(NSError *error,  YAVideo *video);
typedef void (^jpgCreatedCompletionHandler)(NSError *error, YAVideo *video);
typedef void (^gifCreatedCompletionHandler)(NSError *error);
typedef void (^uploadCompletionHandler)(NSError *error);

@interface YAVideo : RLMObject
@property NSString *movFilename;
@property NSString *gifFilename;
@property NSString *jpgFilename;

@property NSString *creator;
@property NSString *caption;
@property NSDate *createdAt;

//likes
@property BOOL like;
@property NSInteger likes;
@property RLMArray<YAContact> *likers;

@property NSString *localId;
@property NSString *serverId;
@property NSString *url;
@property YAGroup *group;

+ (YAVideo*)video;
- (void)removeFromCurrentGroup;
- (void)rename:(NSString*)newName;

- (void)updateLikersWithArray:(NSArray *)likers;
@end

// This protocol enables typed collections. i.e.:
// RLMArray<YAVideo>
RLM_ARRAY_TYPE(YAVideo)

