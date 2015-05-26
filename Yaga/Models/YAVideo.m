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

+ (NSArray *)indexedProperties {
    return @[@"gifUrl", @"url"];
}

+ (NSString *)primaryKey {
    return @"localId";
}

+ (YAVideo*)video {
    YAVideo *result = [YAVideo new];
    result.localId = [YAUtils uniqueId];
    
    return result;
}

- (void)removeFromCurrentGroupWithCompletion:(completionBlock)completion removeFromServer:(BOOL)removeFromServer {
    void (^deleteBlock)(void) = ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:VIDEO_WILL_DELETE_NOTIFICATION object:self];
        
        NSString *videoId = self.localId;
        [[RLMRealm defaultRealm] beginWriteTransaction];
        
        [self purgeLocalAssets];
        [self.group.videos removeObjectAtIndex:[self.group.videos indexOfObject:self]];
        [[RLMRealm defaultRealm] deleteObject:self];
        
        [[RLMRealm defaultRealm] commitWriteTransaction];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:VIDEO_DID_DELETE_NOTIFICATION object:videoId];
        
        DLog(@"video with id:%@ deleted successfully", videoId);
    };
    
    if(removeFromServer) {
        deleteBlock();
        return;
    }
        
    
    NSAssert(self.serverId, @"Can't delete remote video with non existing id");

    NSString *videoServerId = self.serverId;
    
    [[YAServer sharedServer] deleteVideoWithId:videoServerId fromGroup:self.group.serverId withCompletion:^(id response, NSError *error) {
        if(error) {
            DLog(@"unable to delete video with id:%@, error %@", videoServerId, error.localizedDescription);
            if(completion)
                completion(error);
        }
        else {
            deleteBlock();
            
            if(completion)
                completion(nil);
        }
        
    }];
    
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
    if(self.invalidated)
        return;
    
    NSMutableArray *urlsToDelete = [NSMutableArray new];
    if(self.mp4Filename.length)
        [urlsToDelete addObject:[YAUtils urlFromFileName:self.mp4Filename]];
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

    self.mp4Filename = @"";
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
