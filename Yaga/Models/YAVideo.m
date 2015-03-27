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
    return @{@"highQualityGifFilename":@"",
             @"jpgFilename":@"",
             @"jpgFullscreenFilename":@"",
             @"gifFilename":@"",
             @"movFilename":@"",
             @"mp4Filename":@"",
             @"caption":@"",
             @"namer":@"",
             @"font": @0,
             @"createdAt":[NSDate date],
             @"url":@"",
             @"gifUrl":@"",
             @"serverId":@"",
             @"localCreatedAt":[NSDate date]};
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
    [self.group.videos removeObjectAtIndex:[self.group.videos indexOfObject:self]];
    [[RLMRealm defaultRealm] deleteObject:self];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:VIDEO_DID_DELETE_NOTIFICATION object:videoId];
    
    DLog(@"video deleted");
}

- (void)rename:(NSString*)newName withFont:(NSInteger) font{
    [[RLMRealm defaultRealm] beginWriteTransaction];
    self.caption = newName;
    self.font = font;
    self.namer = [YAUser currentUser].username;
    
    DLog(@"renaming... %@", [YAUser currentUser].username);
    
    [[RLMRealm defaultRealm] commitWriteTransaction];
    [[NSNotificationCenter defaultCenter] postNotificationName:VIDEO_CHANGED_NOTIFICATION object:self];
    
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

    self.movFilename = @"";
    self.gifFilename = @"";
    self.jpgFilename = @"";
}
#pragma mark - UIActivity 
- (id)activityViewController:(UIActivityViewController*) activityViewController itemForActivityType:(NSString *)activityType
{
    return self;
}

- (id)activityViewControllerPlaceholderItem:(UIActivityViewController *)activityViewController
{
    return @"";
}
@end
