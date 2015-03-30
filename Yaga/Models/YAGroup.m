//
//  YAGroup.m
//  Yaga
//
//  Created by valentinkovalski on 12/16/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import "YAGroup.h"
#import "YAServer.h"
#import "NSDictionary+ResponseObject.h"
#import "YAUtils.h"
#import "YAServerTransactionQueue.h"
#import "YAUser.h"
#import "YAAssetsCreator.h"

@interface YAGroup ()
@property (atomic, assign) BOOL videosUpdateInProgress;
@end

@implementation YAGroup

+ (RLMPropertyAttributes)attributesForProperty:(NSString *)propertyName {
    RLMPropertyAttributes attributes = [super attributesForProperty:propertyName];
    if ([propertyName isEqualToString:@"localId"] || [propertyName isEqualToString:@"serverId"]) {
        attributes |= RLMPropertyAttributeIndexed;
    }
        
    return attributes;
}

+ (NSArray *)ignoredProperties {
    return @[@"videosUpdateInProgress"];
}

+ (NSString *)primaryKey {
    return @"localId";
}

+ (NSDictionary *)defaultPropertyValues
{
    return @{@"serverId":@"", @"updatedAt":[NSDate dateWithTimeIntervalSince1970:0]};
}

- (NSString*)membersString {
    if(!self.members.count) {
        return NSLocalizedString(@"No members", @"");
    }
    
    NSString *results = @"";
    
    NSUInteger countOfNonames = 0;
    for(int i = 0; i < self.members.count; i++) {
        YAContact *contact = (YAContact*)[self.members objectAtIndex:i];
        
        if([[contact displayName] isEqualToString:kDefaultUsername] || ! [contact displayName])
            countOfNonames++;
        else {
            if(!results.length)
                results = [contact displayName];
            else
                results = [results stringByAppendingFormat:@", %@", [contact displayName]];
        }
    }

    if(countOfNonames == 1) {
        if(results.length)
            results = [results stringByAppendingString:NSLocalizedString(@" and 1 more", @"")];
        else
            results = NSLocalizedString(@"ONE_UNKOWN_USER", @"");
    }
    else if(countOfNonames > 1) {
        if(!results.length) {
            results = [results stringByAppendingFormat:NSLocalizedString(@"N_UNKOWN_USERS_TEMPLATE", @""), countOfNonames];
        }
        else {
            results = [results stringByAppendingFormat:NSLocalizedString(@"OTHER_CONTACTS_TEMPLATE", @""), countOfNonames];
        }
       
    }
    return results;
}

- (NSSet*)phonesSet {
    NSMutableSet *result = [NSMutableSet set];
    for(YAContact *contact in self.members)
        [result addObject:contact.number];
    
    return result;
}

+ (YAGroup*)group {
    YAGroup *result = [YAGroup new];
    result.localId = [YAUtils uniqueId];
    
    return result;
}

#pragma mark - Server synchronisation: update from server
- (void)updateFromServerResponeDictionarty:(NSDictionary*)dictionary {
    self.serverId = dictionary[YA_RESPONSE_ID];
    self.name = dictionary[YA_RESPONSE_NAME];
    
    NSTimeInterval timeInterval = [dictionary[YA_GROUP_UPDATED_AT] integerValue];
    self.updatedAt = [NSDate dateWithTimeIntervalSince1970:timeInterval];
    NSArray *members = dictionary[YA_RESPONSE_MEMBERS];
    
    for(NSDictionary *memberDic in members){
        NSString *phoneNumber = memberDic[YA_RESPONSE_USER][YA_RESPONSE_MEMBER_PHONE];
        
        //skip myself
        if([phoneNumber isEqualToString:[YAUser currentUser].phoneNumber])
            continue;
        
        NSString *predicate = [NSString stringWithFormat:@"number = '%@'", phoneNumber];
        RLMResults *existingContacts = [YAContact objectsWhere:predicate];
        
        YAContact *contact;
        if(existingContacts.count) {
            contact = existingContacts[0];
        }
        else {
            contact = [YAContact new];
        }
        
        [contact updateFromDictionary:memberDic];
        
        if([self.members indexOfObject:contact] == NSNotFound)
            [self.members addObject:contact];

    }
    
    //delete local contacts which do not exist on server anymore
    NSArray *serverContactIds = [[dictionary[@"members"] valueForKey:@"user"] valueForKey:@"id"];
    NSMutableSet *contactsTorRemove = [NSMutableSet set];
    for (YAContact *contact in self.members) {
        if(![serverContactIds containsObject:contact.serverId] && ![[YAServerTransactionQueue sharedQueue] hasPendingAddTransactionForContact:contact])
            [contactsTorRemove addObject:contact];
        
    }
    
    for(YAContact *contactToRemove in contactsTorRemove)
        [self removeMember:contactToRemove];
}

+ (void)updateGroupsFromServerWithCompletion:(completionBlock)block {
    DLog(@"updating groups from server...");
    
    [[YAServer sharedServer] getGroupsWithCompletion:^(id response, NSError *error) {
        if(error) {
            DLog(@"can't fetch remove groups, error: %@", error.localizedDescription);
            
            if(block)
                block(error);
            
            return;
            
        }
        else {
            DLog(@"updated.");
            NSAssert([response isKindOfClass:[NSArray class]], @"unexpected server result");
            
            [[RLMRealm defaultRealm] beginWriteTransaction];
            
            NSArray *groups = (NSArray*)response;
            
            for (id d in groups) {
                
                NSDictionary *dict = [NSDictionary dictionaryFromResponseObject:d withError:nil];
                
                NSString *serverGroupId = dict[YA_RESPONSE_ID];
                NSString *predicate = [NSString stringWithFormat:@"serverId = '%@'", serverGroupId];
                RLMResults *existingGroups = [YAGroup objectsWhere:predicate];
                
                YAGroup *group;
                if(existingGroups.count) {
                    group = existingGroups[0];
                }
                else {
                    group = [YAGroup group];
                }
                
                [group updateFromServerResponeDictionarty:dict];
                
                if(!existingGroups.count)
                    [[RLMRealm defaultRealm] addObject:group];
            }
            
            //delete local contacts which do not exist on server anymore
            NSArray *serverGroupIds = [groups valueForKey:@"id"];
            NSMutableSet *groupsToDelete = [NSMutableSet set];
            
            for (YAGroup *group in [YAGroup allObjects]) {
                if(![serverGroupIds containsObject:group.serverId] && ![[YAServerTransactionQueue sharedQueue] hasPendingAddTransactionForGroup:group]) {
                    BOOL currentGroupToRemove = [[YAUser currentUser].currentGroup.localId isEqualToString:group.localId];
                    
                    NSMutableArray *videosToRemove = [NSMutableArray new];
                    
                    for(YAVideo *videoToRemove in group.videos)
                        [videosToRemove addObject:videoToRemove];
                    
                    for(YAVideo *videoToRemove in [videosToRemove copy]) {
                        [videoToRemove purgeLocalAssets];
                        [[RLMRealm defaultRealm] deleteObject:videoToRemove];
                    }
                    
                    [groupsToDelete addObject:group];
                    
                    if(currentGroupToRemove) {
                        [YAUser currentUser].currentGroup = [[YAGroup allObjects] firstObject];
                    }
                }
            }

            for(YAGroup *group in [groupsToDelete copy])
                [[RLMRealm defaultRealm] deleteObject:group];
            
            [[RLMRealm defaultRealm] commitWriteTransaction];
            
            if(block)
                block(nil);
            
            [[YAUser currentUser].currentGroup refresh];
        }
    }];
}

#pragma mark - Server synchronisation: send updates to server

+ (YAGroup*)groupWithName:(NSString*)name {
    [[RLMRealm defaultRealm] beginWriteTransaction];
    
    YAGroup *group = [YAGroup group];
    group.name = name;
    [[RLMRealm defaultRealm] addObject:group];
    
    [[RLMRealm defaultRealm] commitWriteTransaction];
    
    [[YAServerTransactionQueue sharedQueue] addCreateTransactionForGroup:group];
    
    return group;
}

- (void)rename:(NSString*)newName {
    [[RLMRealm defaultRealm] beginWriteTransaction];
    self.name = newName;
    [[RLMRealm defaultRealm] commitWriteTransaction];
    
    [[YAServerTransactionQueue sharedQueue] addRenameTransactionForGroup:self];
}

- (void)addMembers:(NSArray*)contacts {
    [[RLMRealm defaultRealm] beginWriteTransaction];
    
    NSMutableArray *phones = [NSMutableArray new];
    NSMutableArray *usernames = [NSMutableArray new];
    
    for(NSDictionary *contactDic in contacts) {
        [self.members addObject:[YAContact contactFromDictionary:contactDic]];
        if([[contactDic objectForKey:nPhone] length])
            [phones addObject:contactDic[nPhone]];
        else
            [usernames addObject:contactDic[nUsername]];
    }
    
    [[RLMRealm defaultRealm] commitWriteTransaction];
    
    [[YAServerTransactionQueue sharedQueue] addAddMembersTransactionForGroup:self phones:phones usernames:usernames];
}

- (void)removeMember:(YAContact *)contact {
    NSString *memberPhone = contact.number;
    
    [self.members removeObjectAtIndex:[self.members indexOfObject:contact]];
    
    [[YAServerTransactionQueue sharedQueue] addRemoveMemberTransactionForGroup:self memberPhoneToRemove:memberPhone];
}


- (void)leave {
    NSAssert(self.serverId, @"Can't leave group which doesn't exist");
    
    [[YAServerTransactionQueue sharedQueue] addLeaveGroupTransactionForGroupId:self.serverId];
    
    [[RLMRealm defaultRealm] beginWriteTransaction];
    [[RLMRealm defaultRealm] deleteObject:self];
    [[RLMRealm defaultRealm] commitWriteTransaction];
}

- (void)muteUnmute {
    [[RLMRealm defaultRealm] beginWriteTransaction];
    self.muted = !self.muted;
    [[RLMRealm defaultRealm] commitWriteTransaction];
    
    [[YAServerTransactionQueue sharedQueue] addMuteUnmuteTransactionForGroup:self];
}

#pragma mark - Videos
- (void)refresh {
    if(self.videosUpdateInProgress)
        return;

    self.videosUpdateInProgress = YES;

    //since
    NSMutableDictionary *groupsUpdatedAt = [NSMutableDictionary dictionaryWithDictionary:[[NSUserDefaults standardUserDefaults] objectForKey:YA_GROUPS_UPDATED_AT]];
    NSDate *lastUpdateDate = nil;
    if([groupsUpdatedAt objectForKey:[YAUser currentUser].currentGroup.localId]) {
        lastUpdateDate = [groupsUpdatedAt objectForKey:[YAUser currentUser].currentGroup.localId];
    }
    
    [[YAServer sharedServer] groupInfoWithId:self.serverId since:lastUpdateDate withCompletion:^(id response, NSError *error) {
        if(self.isInvalidated)
            return;
        
        self.videosUpdateInProgress = NO;
        if(error) {
            DLog(@"can't get group %@ info, error %@", self.name, [error localizedDescription]);
            [[NSNotificationCenter defaultCenter] postNotificationName:GROUP_DID_REFRESH_NOTIFICATION object:self userInfo:nil];
            return;
        }
        else {
            [groupsUpdatedAt setObject:[NSDate date] forKey:[YAUser currentUser].currentGroup.localId];
            [[NSUserDefaults standardUserDefaults] setObject:groupsUpdatedAt forKey:YA_GROUPS_UPDATED_AT];
            
            [self.realm beginWriteTransaction];
            [self updateFromServerResponeDictionarty:response];
            [self.realm commitWriteTransaction];
            
            NSArray *videoDictionaries = response[YA_VIDEO_POSTS];
            DLog(@"received %lu videos for %@ group", (unsigned long)videoDictionaries.count, self.name);
            
            NSArray *newVideos = [self updateVideosFromDictionaries:videoDictionaries];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:GROUP_DID_REFRESH_NOTIFICATION object:self userInfo:@{kVideos:newVideos}];
        }
    }];
}

- (NSSet*)videoIds {
    NSMutableSet *existingIds = [NSMutableSet set];
    for (YAVideo *video in self.videos) {
        if(video.serverId){
            [existingIds addObject:video.serverId];
        }
    }
    return existingIds;
}

- (NSArray*)updateVideosFromDictionaries:(NSArray*)videoDictionaries {
    NSSet *existingIds = [self videoIds];
    NSSet *newIds = [NSSet setWithArray:[videoDictionaries valueForKey:YA_RESPONSE_ID]];
    
    NSMutableSet *idsToAdd = [NSMutableSet setWithSet:newIds];
    [idsToAdd minusSet:existingIds];
    
    NSMutableArray *newVideos = [NSMutableArray new];
    
    videoDictionaries = [videoDictionaries sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:YA_VIDEO_READY_AT ascending:YES]]];
    
    [[RLMRealm defaultRealm] beginWriteTransaction];
    
    for(NSDictionary *videoDic in videoDictionaries) {
        
        //video exists? update name
        if([existingIds containsObject:videoDic[YA_RESPONSE_ID]]) {
            RLMResults *videos = [YAVideo objectsWhere:[NSString stringWithFormat:@"serverId = '%@'", videoDic[YA_RESPONSE_ID]]];
            if(videos.count) {
                YAVideo *video = [videos firstObject];
                BOOL deleted = [videoDic[YA_VIDEO_DELETED] boolValue];
                
                if(deleted) {
                    [video removeFromCurrentGroup];
                }
                else {
                    
                    if (![videoDic[YA_RESPONSE_NAME] isEqual:[NSNull null]]) {
                        video.caption = videoDic[YA_RESPONSE_NAME];
                        video.font = [videoDic[YA_RESPONSE_FONT] integerValue];
                        video.namer = videoDic[YA_RESPONSE_NAMER][YA_RESPONSE_NAME];
                    }
                    NSArray *likers = videoDic[YA_RESPONSE_LIKERS];
                    if (likers.count) {
                        [video updateLikersWithArray:likers];
                    }
                }
            }
        }
        else {
            NSString *videoId = videoDic[YA_RESPONSE_ID];
            
            //skip deleted vids
            if([videoDic[YA_VIDEO_DELETED] boolValue]) {
                DLog(@"skipping deleted videos");
                continue;
            }
            
            //skip not ready yet vids
            if([videoDic[YA_VIDEO_READY_AT] isEqual:[NSNull null]])
                continue;
            
            YAVideo *video = [YAVideo video];
            video.serverId = videoId;
            video.creator = videoDic[YA_RESPONSE_USER][YA_RESPONSE_NAME];
            NSArray *likers = videoDic[YA_RESPONSE_LIKERS];
            [video updateLikersWithArray:likers];
            NSTimeInterval timeInterval = [videoDic[YA_VIDEO_READY_AT] integerValue];
            video.createdAt = [NSDate dateWithTimeIntervalSince1970:timeInterval];
            video.url = videoDic[YA_VIDEO_ATTACHMENT];
            
            id gifUrl = videoDic[YA_VIDEO_ATTACHMENT_PREVIEW];
            if(gifUrl) {
                video.gifUrl = ![gifUrl isKindOfClass:[NSNull class]] ? gifUrl : @"";
            }
            video.caption = ![videoDic[YA_RESPONSE_NAME] isKindOfClass:[NSNull class]] ? videoDic[YA_RESPONSE_NAME] : @"";
            if(![videoDic[YA_RESPONSE_NAMER] isKindOfClass:[NSNull class]]){
                video.namer = videoDic[YA_RESPONSE_NAMER][YA_RESPONSE_NAME];
            } else {
                video.namer = @"";
            }
            video.font = ![videoDic[YA_RESPONSE_FONT] isKindOfClass:[NSNull class]] ? [videoDic[YA_RESPONSE_FONT] integerValue] : 0;
            video.group = self;
            [self.videos insertObject:video atIndex:0];
            
            [newVideos addObject:video];
        }
    }
    [[RLMRealm defaultRealm] commitWriteTransaction];
    
    return newVideos;
}
@end
