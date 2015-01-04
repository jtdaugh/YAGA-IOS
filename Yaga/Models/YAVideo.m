//
//  YAVideo.m
//  Yaga
//
//  Created by valentinkovalski on 12/17/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import "YAVideo.h"
#import "YAUtils.h"
#import "YAUser.h"

#import "AZNotification.h"
#import "YAServerTransactionQueue.h"
#import "YAServer.h"
#import "YAAssetsCreator.h"

@implementation YAVideo

#pragma mark - Realm

+ (RLMPropertyAttributes)attributesForProperty:(NSString *)propertyName {
    RLMPropertyAttributes attributes = [super attributesForProperty:propertyName];
    if ([propertyName isEqualToString:@"localId"] || [propertyName isEqualToString:@"serverId"]) {
        attributes |= RLMPropertyAttributeIndexed;
    }
    return attributes;
}

+ (NSDictionary *)defaultPropertyValues{
    return @{@"jpgFilename":@"", @"gifFilename":@"", @"caption":@"", @"createdAt":[NSDate date], @"url":@"", @"serverId":@""};
}

+ (NSString *)primaryKey {
    return @"localId";
}

+ (YAVideo*)video {
    YAVideo *result = [YAVideo new];
    result.localId = [YAUtils uniqueId];
    
    return result;
}

- (void)removeFromCurrentGroup {
    NSAssert(self.serverId, @"Can't delete remote video with non existing id");
    
    //notify server if it's deleted by me, others should just delete vidoe locally without notifying serve
    if([self.creator isEqualToString:[YAUser currentUser].username]) {
        [[YAServerTransactionQueue sharedQueue] addDeleteVideoTransaction:self.serverId forGroupId:[YAUser currentUser].currentGroup.serverId];
    }
    
    [[RLMRealm defaultRealm] beginWriteTransaction];
    [[RLMRealm defaultRealm] deleteObject:self];
    [[RLMRealm defaultRealm] commitWriteTransaction];
    
    NSLog(@"video deleted");
}

+ (void)createVideoFromRecodingURL:(NSURL*)recordingUrl addToGroup:(YAGroup*)group {
 
    NSString *hashStr = [YAUtils uniqueId];
    NSString *moveFilename = [hashStr stringByAppendingPathExtension:@"mov"];
    NSString *movPath = [[YAUtils cachesDirectory] stringByAppendingPathComponent:moveFilename];
    NSURL    *movURL = [NSURL fileURLWithPath:movPath];
    
    NSError *error;
    [[NSFileManager defaultManager] moveItemAtURL:recordingUrl toURL:movURL error:&error];
    if(error) {
        NSLog(@"Error in createVideoFromRecodingURL, can't move recording, %@", error);
        return;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [group.realm beginWriteTransaction];
        YAVideo *video = [YAVideo video];
        video.creator = [[YAUser currentUser] username];
        video.createdAt = [NSDate date];
        video.movFilename = moveFilename;
        
        [group.videos insertObject:video atIndex:0];
        [group.realm commitWriteTransaction];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:NEW_VIDEO_TAKEN_NOTIFICATION object:video];
        
        //start uploading while generating gif
        [[YAServerTransactionQueue sharedQueue] addUploadVideoTransaction:video];
        
        [video generateGIF];
    });
}

+ (void)createVideoFromRemoteDictionary:(NSDictionary*)videoDic addToGroup:(YAGroup*)group {
    NSString *hashStr = [YAUtils uniqueId];
    NSString *moveFilename = [hashStr stringByAppendingPathExtension:@"mov"];
    NSString *movPath = [[YAUtils cachesDirectory] stringByAppendingPathComponent:moveFilename];
    NSURL    *movURL = [NSURL fileURLWithPath:movPath];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSURL *remoteURL = [NSURL URLWithString:videoDic[YA_VIDEO_ATTACHMENT]];
        NSData *data = [NSData dataWithContentsOfURL:remoteURL];
        BOOL result = [data writeToURL:movURL atomically:YES];
        if(!result) {
            
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            NSString *videoId = videoDic[YA_RESPONSE_ID];
            
            [group.realm beginWriteTransaction];
            
            YAVideo *video = [YAVideo video];
            video.serverId = videoId;
            video.creator = videoDic[YA_RESPONSE_USER][YA_RESPONSE_NAME];
            NSTimeInterval timeInterval = [videoDic[YA_VIDEO_READY_AT] integerValue];
            video.createdAt = [NSDate dateWithTimeIntervalSince1970:timeInterval];
            video.url = videoDic[YA_VIDEO_ATTACHMENT];
            video.movFilename = moveFilename;
            [group.videos insertObject:video atIndex:0];
            
            [group.realm commitWriteTransaction];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:NEW_VIDEO_TAKEN_NOTIFICATION object:video];
            
            [video generateGIF];
        });
    });
}

- (void)generateGIF {
    [[YAAssetsCreator sharedCreator] createJPGAndGIFForVideo:self];
}



@end
