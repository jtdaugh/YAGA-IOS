//
//  YAShareServer.h
//  Yaga
//
//  Created by Christopher Wendel on 7/16/15.
//  Copyright (c) 2015 Raj Vir. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^responseBlock)(id response, NSError* error);
typedef void(^YAUploadVideoResponseBlock)(id response, NSString *videoServerID, NSError *error);

/*!
 *  Lightweight server object based on \c YAServer that is just used for getting a user's groups
 */
@interface YAShareServer : NSObject

+ (YAShareServer *)sharedServer;

- (void)getGroupsWithCompletion:(responseBlock)completion publicGroups:(BOOL)publicGroups;

- (void)uploadVideo:(NSData *)movieData toGroupWithId:(NSString*)serverGroupId withCompletion:(YAUploadVideoResponseBlock)completion;

@end
