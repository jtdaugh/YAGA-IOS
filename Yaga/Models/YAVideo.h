//
//  YAVideo.h
//  Yaga
//
//  Created by valentinkovalski on 12/17/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//
#import "YAContact.h"
#import <Realm/Realm.h>

typedef enum {
    YAGifCreationNormalQuality = 0,
    YAGifCreationHighQuality
} YAGifCreationQuality;

@class YAGroup;
@class YAVideo;

typedef void (^videoCreatedCompletionHandler)(NSError *error,  YAVideo *video);
typedef void (^jpgCreatedCompletionHandler)(NSError *error, YAVideo *video);
typedef void (^gifCreatedCompletionHandler)(NSError *error);
typedef void (^uploadCompletionHandler)(NSError *error);
typedef void(^completionBlock)(NSError *error);

@interface YAVideo : RLMObject
@property NSString *mp4Filename;
@property NSString *gifFilename;
@property NSString *highQualityGifFilename;
@property NSString *jpgFilename;
@property NSString *jpgFullscreenFilename;

@property NSInteger name_x;
@property NSInteger name_y;

@property NSInteger font;

@property NSString *creator;
@property NSString *caption;
@property NSString *namer;
@property NSDate *createdAt;
@property NSDate *localCreatedAt;

//likes
@property BOOL like;
@property NSInteger likes;
@property RLMArray<YAContact> *likers;

@property NSString *localId;
@property NSString *serverId;
@property NSString *url;
@property NSString *gifUrl;
@property YAGroup *group;

+ (YAVideo*)video;
- (void)removeFromCurrentGroupWithCompletion:(completionBlock)completion;
- (void)rename:(NSString*)newName withFont:(NSInteger)font;

- (void)updateLikersWithArray:(NSArray *)likers;

- (void)purgeLocalAssets;
@end

// This protocol enables typed collections. i.e.:
// RLMArray<YAVideo>
RLM_ARRAY_TYPE(YAVideo)

