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
    return @{@"highQualityGifFilename":@"", @"jpgFilename":@"", @"gifFilename":@"", @"movFilename":@"", @"caption":@"", @"createdAt":[NSDate date], @"url":@"", @"serverId":@"", @"localCreatedAt":[NSDate date]};
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
    
    [[NSNotificationCenter defaultCenter] postNotificationName:VIDEO_WILL_DELETE_NOTIFICATION object:self];
    
    NSString *videoId = self.localId;
    
    [self purgeLocalAssets];
    
    [[RLMRealm defaultRealm] beginWriteTransaction];
    [self.group.videos removeObjectAtIndex:[self.group.videos indexOfObject:self]];
    [[RLMRealm defaultRealm] deleteObject:self];
    [[RLMRealm defaultRealm] commitWriteTransaction];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:VIDEO_DID_DELETE_NOTIFICATION object:videoId];
    
    NSLog(@"video deleted");
}

- (void)rename:(NSString*)newName {
    [[RLMRealm defaultRealm] beginWriteTransaction];
    self.caption = newName;
    [[RLMRealm defaultRealm] commitWriteTransaction];
    
    [[YAServerTransactionQueue sharedQueue] addUpdateVideoCaptionTransaction:self];
}

- (void)updateLikersWithArray:(NSArray *)likers {
    self.likes = likers.count;
    self.likers = nil;
    YAUser *user = [YAUser currentUser];
    for (NSDictionary *dict in likers)
    {
        YAContact *contact = [YAContact contactFromDictionary:dict];
        if ([[user username] isEqualToString:dict[nName]]) {
            self.like = YES;
        }
        [self.likers addObject:contact];
    }
}

- (void)purgeLocalAssets {
    NSMutableArray *urlsToDelete = [NSMutableArray new];
    if(self.movFilename.length)
        [urlsToDelete addObject:[YAUtils urlFromFileName:self.movFilename]];
    if(self.gifFilename.length)
        [urlsToDelete addObject:[YAUtils urlFromFileName:self.gifFilename]];
    if(self.jpgFilename.length)
        [urlsToDelete addObject:[YAUtils urlFromFileName:self.jpgFilename]];
    
    NSFileManager *fileMgr = [NSFileManager defaultManager];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        for(NSURL *urlToDelete in urlsToDelete) {
            NSError *error;
            [fileMgr removeItemAtURL:urlToDelete error:&error];
        }
    });
    
    [[RLMRealm defaultRealm] beginWriteTransaction];
    self.movFilename = @"";
    self.gifFilename = @"";
    self.jpgFilename = @"";
    [[RLMRealm defaultRealm] commitWriteTransaction];
}
@end
