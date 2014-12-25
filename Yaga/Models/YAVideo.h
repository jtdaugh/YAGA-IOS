//
//  YAVideo.h
//  Yaga
//
//  Created by valentinkovalski on 12/17/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import <Realm/Realm.h>

@class YAVideo;

typedef void (^videoCreatedCompletionHandler)(NSError *error,  YAVideo *video);
typedef void (^jpgCreatedCompletionHandler)(NSError *error, YAVideo *video);
typedef void (^gifCreatedCompletionHandler)(NSError *error);
typedef void (^uploadCompletionHandler)(NSError *error);

@interface YAVideo : RLMObject
@property NSString *movFilename;
@property NSString *gifFilename;
@property NSString *jpgFilename;
@property BOOL uploaded;

+ (void)crateVideoAndAddToCurrentGroupFromRecording:(NSURL*)recordingUrl completionHandler:(videoCreatedCompletionHandler)handler jpgCreatedHandler:(jpgCreatedCompletionHandler)jpgHandler;
@end

// This protocol enables typed collections. i.e.:
// RLMArray<YAVideo>
RLM_ARRAY_TYPE(YAVideo)

