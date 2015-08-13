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

typedef NS_ENUM(NSUInteger, YAVideoServerIdStatus) {
    YAVideoServerIdStatusNil,           // Server has not responded with a serverId for the video yet.
    YAVideoServerIdStatusUnconfirmed,   // ServerId is set, but upload to Amazon is unfinished, so serverId still could change.
    YAVideoServerIdStatusConfirmed      // ServerId is set and upload is finished. ServerId can't possibly change :)
};

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

@property CGFloat caption_x;
@property CGFloat caption_y;
@property CGFloat caption_scale;
@property CGFloat caption_rotation;

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
@property BOOL uploadedToAmazon;
@property BOOL pending;

+ (YAVideo*)video;
- (void)removeFromGroupAndStreamsWithCompletion:(completionBlock)completion removeFromServer:(BOOL)removeFromServer;

- (void)updateCaption:(NSString*)caption
        withXPosition:(CGFloat)xPosition
            yPosition:(CGFloat)yPosition
                scale:(CGFloat)scale
             rotation:(CGFloat)rotation;

- (void)updateLikersWithArray:(NSArray *)likers;

- (void)purgeLocalAssets;

+ (YAVideoServerIdStatus)serverIdStatusForVideo:(YAVideo *)video;

@end

// This protocol enables typed collections. i.e.:
// RLMArray<YAVideo>
RLM_ARRAY_TYPE(YAVideo)

