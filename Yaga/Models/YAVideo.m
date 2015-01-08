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
    return @{@"jpgFilename":@"", @"gifFilename":@"", @"movFilename":@"", @"caption":@"", @"createdAt":[NSDate date], @"url":@"", @"serverId":@""};
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
    
    [[RLMRealm defaultRealm] beginWriteTransaction];
    [[RLMRealm defaultRealm] deleteObject:self];
    [[RLMRealm defaultRealm] commitWriteTransaction];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:VIDEO_DID_DELETE_NOTIFICATION object:videoId];
    
    NSLog(@"video deleted");
}

- (void)generateGIF {
    if(self.movFilename.length)
        [[YAAssetsCreator sharedCreator] createJPGAndGIFForVideo:self];
}

@end
