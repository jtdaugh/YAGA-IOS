//
//  YAGIFOperation.h
//  Yaga
//
//  Created by valentinkovalski on 1/2/15.
//  Copyright (c) 2015 Raj Vir. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import "YAVideo.h"
#import "YAGroup.h"

@interface YAAssetsCreator : NSObject

+ (instancetype)sharedCreator;
- (void)createJPGAndGIFForVideo:(YAVideo*)video;

- (void)addBumberToVideoAtURLAndSaveToCameraRoll:(NSURL*)videoURL;

- (void)createVideoFromRecodingURL:(NSURL*)recordingUrl addToGroup:(YAGroup*)group;
- (void)createVideoFromRemoteDictionary:(NSDictionary*)videoDic addToGroup:(YAGroup*)group;
@end
