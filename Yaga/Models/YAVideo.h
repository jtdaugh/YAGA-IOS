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

@property CGFloat caption_x; // 0 to 1000
@property CGFloat caption_y; // 0 to 1000
@property CGFloat caption_scale; // 0 to 1000
@property CGFloat caption_rotation; // 0 to 1000

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
- (void)removeFromCurrentGroupWithCompletion:(completionBlock)completion removeFromServer:(BOOL)removeFromServer;

- (void)updateCaption:(NSString*)caption
        withXPosition:(CGFloat)xPosition
            yPosition:(CGFloat)yPosition
                scale:(CGFloat)scale
             rotation:(CGFloat)rotation;

- (void)updateLikersWithArray:(NSArray *)likers;

- (void)purgeLocalAssets;
@end

// This protocol enables typed collections. i.e.:
// RLMArray<YAVideo>
RLM_ARRAY_TYPE(YAVideo)

