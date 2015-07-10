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

+ (NSArray *)indexedProperties {
    return @[@"localId", @"serverId"];
}

+ (NSArray *)ignoredProperties {
    return @[@"videosUpdateInProgress"];
}

+ (NSString *)primaryKey {
    return @"localId";
}

+ (NSDictionary *)defaultPropertyValues
{
    return @{@"serverId":@"", @"updatedAt":[NSDate dateWithTimeIntervalSince1970:0], @"refreshedAt":[NSDate dateWithTimeIntervalSince1970:0], @"hasUnviewedVideos" : [NSNumber numberWithBool:NO]};
}

- (NSString*)membersString {
    if(self.publicGroup) {
        return @"All Yaga Users";
    }
    
    if(!self.members.count) {
        return NSLocalizedString(@"No members", @"");
    }
    
    NSString *results = @"";
    
    NSUInteger andMoreCount = 0;
    for(int i = 0; i < self.members.count; i++) {
        if (i >= kMaxUsersShownInList) {
            andMoreCount += self.members.count - kMaxUsersShownInList;
            break;
        }
        YAContact *contact = (YAContact*)[self.members objectAtIndex:i];
        
        if([[contact displayName] isEqualToString:kDefaultUsername] || ! [contact displayName])
            andMoreCount++;
        else {
            if(!results.length)
                results = [contact displayName];
            else
                results = [results stringByAppendingFormat:@", %@", [contact displayName]];
        }
    }
    
    if(andMoreCount == 1) {
        if(results.length)
            results = [results stringByAppendingString:NSLocalizedString(@" and 1 more", @"")];
        else
            results = NSLocalizedString(@"ONE_UNKOWN_USER", @"");
    }
    else if(andMoreCount > 1) {
        if(!results.length) {
            results = [results stringByAppendingFormat:NSLocalizedString(@"N_UNKOWN_USERS_TEMPLATE", @""), andMoreCount];
        }
        else {
            results = [results stringByAppendingFormat:NSLocalizedString(@"OTHER_CONTACTS_TEMPLATE", @""), andMoreCount];
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
    
    BOOL hasPendingChanges = YES;
    
    if([self.refreshedAt compare:[NSDate dateWithTimeIntervalSince1970:0]] != NSOrderedSame)
        hasPendingChanges = [self.refreshedAt compare:self.updatedAt] != NSOrderedSame;
    
    if(hasPendingChanges) {
        if(dictionary[YA_GROUP_LAST_FOREIGN_POST_ID] != [NSNull null]) {
            NSString *predicate = [NSString stringWithFormat:@"serverId = '%@'", dictionary[YA_GROUP_LAST_FOREIGN_POST_ID]];
            
            RLMResults *newVideosLocally = [YAVideo objectsWhere:predicate];
            
            //new videos do not exist locally? set needsRefresh to YES
            self.hasUnviewedVideos = newVideosLocally.count == 0;
        }
    }
    else {
        self.hasUnviewedVideos = NO;
    }
    
    NSArray *members = dictionary[YA_RESPONSE_MEMBERS];
    NSArray *pending_members = dictionary[YA_RESPONSE_PENDING_MEMBERS];
    
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
    
    for(YAContact *contactToRemove in contactsTorRemove) {
        NSInteger indexToRemove = [self.members indexOfObject:contactToRemove];
        if(indexToRemove >= 0)
            [self.members removeObjectAtIndex:indexToRemove];
    }
    
    //pending members
    for(NSDictionary *memberDic in pending_members){
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
        
        if([self.pending_members indexOfObject:contact] == NSNotFound)
            [self.pending_members addObject:contact];
        
    }
    
    
    //delete local pendning members which do not exist on server anymore
    serverContactIds = [[dictionary[@"pending_members"] valueForKey:@"user"] valueForKey:@"id"];
    contactsTorRemove = [NSMutableSet set];
    for (YAContact *contact in self.pending_members) {
        if(![serverContactIds containsObject:contact.serverId])
            [contactsTorRemove addObject:contact];
    }
    
    for(YAContact *contactToRemove in contactsTorRemove) {
        NSInteger indexToRemove = [self.pending_members indexOfObject:contactToRemove];
        if(indexToRemove >= 0)
            [self.pending_members removeObjectAtIndex:indexToRemove];
    }
}

+ (void)updateGroupsFromServerWithCompletion:(completionBlock)block {
    void (^successBlock)(id, BOOL) = ^void(id response, BOOL publicGroups) {
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
            
            group.publicGroup = publicGroups;
            
            [group updateFromServerResponeDictionarty:dict];
            
            if(!existingGroups.count)
                [[RLMRealm defaultRealm] addObject:group];
        }
        //delete local contacts which do not exist on server anymore
        NSArray *serverGroupIds = [groups valueForKey:@"id"];
        NSMutableSet *groupsToDelete = [NSMutableSet set];
        
        NSString *predicate = [NSString stringWithFormat:@"publicGroup = %d", publicGroups];
        
        for (YAGroup *group in [[YAGroup allObjects] objectsWhere:predicate]) {
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
        
        BOOL deletedGroupWasActive = NO;
        for(YAGroup *group in [groupsToDelete copy]) {
            if([group isEqual:[YAUser currentUser].currentGroup])
                deletedGroupWasActive = YES;
            [[RLMRealm defaultRealm] deleteObject:group];
        }
        
        [[RLMRealm defaultRealm] commitWriteTransaction];
        
        if(deletedGroupWasActive) {
            if([YAGroup allObjects].count)
                [YAUser currentUser].currentGroup = [YAGroup allObjects][0];
            else
                [YAUser currentUser].currentGroup = nil;
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:GROUPS_REFRESHED_NOTIFICATION object:nil];
        
        //do not call completion block for public groups request
        if(!publicGroups) {
            if(block)
                block(nil);
        }
    };

    [[YAServer sharedServer] getGroupsWithCompletion:^(id response, NSError *error) {
        if(error) {
            if(block)
                block(error);
            return;
        }
        else {
            successBlock(response, NO);
            
            //shall we request publc groups
            NSDate *lastRequested = [[NSUserDefaults standardUserDefaults] objectForKey:kLastPublicGroupsRequestDate];
            
            //request yaga users once per 6 hours
            if(lastRequested && [[NSDate date] compare:[lastRequested dateByAddingTimeInterval:60*60*6]] == NSOrderedAscending) {
                DLog(@"6 hours hasn't passed yet, exiting");
                block(nil);
                return;
            }
            else {
                [[YAServer sharedServer] getGroupsWithCompletion:^(id response, NSError *error) {
                    [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:kLastPublicGroupsRequestDate];
                    
                    if(error) {
                        if(block)
                            block(error);
                        
                        return;
                    }
                    else {
                        successBlock(response, YES);
                    }
                } publicGroups:YES];
            }
            
        }
    } publicGroups:NO];
}

#pragma mark - Server synchronisation: send updates to server

+ (void)groupWithName:(NSString*)name withCompletion:(completionBlockWithResult)completion {
    [[YAServer sharedServer] createGroupWithName:name withCompletion:^(NSDictionary *responseDictionary, NSError *error) {
        if(error) {
            DLog(@"can't create remote group with name %@, error %@", name, error.localizedDescription);
            completion(error, nil);
        }
        else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [[RLMRealm defaultRealm] beginWriteTransaction];
                
                YAGroup *group = [YAGroup group];
                group.name = name;
                group.serverId = [responseDictionary objectForKey:YA_RESPONSE_ID];
                [[RLMRealm defaultRealm] addObject:group];
                
                [[RLMRealm defaultRealm] commitWriteTransaction];
                
                DLog(@"remote group: %@ created on server with id: %@", group.name, group.serverId);
                
                completion(nil, group);
            });
        }
    }];
}

- (void)rename:(NSString*)newName withCompletion:(completionBlock)completion {
    [[YAServer sharedServer] renameGroupWithId:self.serverId newName:(NSString*)newName withCompletion:^(id response, NSError *error) {
        if(error) {
            DLog(@"can't rename group with name %@, error %@", self.name, response);
            completion(error);
        }
        else {
            [[RLMRealm defaultRealm] beginWriteTransaction];
            self.name = newName;
            [[RLMRealm defaultRealm] commitWriteTransaction];
            
            DLog(@"group renamed");
            completion(nil);
        }
    }];
}

- (void)addMembers:(NSArray*)contacts withCompletion:(completionBlock)completion {
    NSMutableArray *phones = [NSMutableArray new];
    NSMutableArray *usernames = [NSMutableArray new];
    
    for(NSDictionary *contactDic in contacts) {
        
        // merging in no_transactions:
        
//        YAContact *contactToAdd = [YAContact contactFromDictionary:contactDic];
//        NSInteger oldIndex = [self.members indexOfObject:contactToAdd];
//        if(oldIndex != NSNotFound)
//            [self.members removeObjectAtIndex:oldIndex];
//        [self.members addObject:contactToAdd];
        
        if([[contactDic objectForKey:nPhone] length])
            [phones addObject:contactDic[nPhone]];
        else
            [usernames addObject:contactDic[nUsername]];
    }
    
    [[YAServer sharedServer] addGroupMembersByPhones:phones andUsernames:usernames toGroupWithId:self.serverId withCompletion:^(id response, NSError *error) {
        if(error) {
            DLog(@"can't add members to the group with name %@, error %@", self.name, response);
            completion(error);
        }
        else {
            [[RLMRealm defaultRealm] beginWriteTransaction];
            for(NSDictionary *contactDic in contacts) {
                NSString *phoneNumber = contactDic[nPhone];
                NSString *username = contactDic[nUsername];
                
                NSPredicate *pred;
                if(phoneNumber.length)
                    pred = [NSPredicate predicateWithFormat:@"number = %@", phoneNumber];
                else
                    pred = [NSPredicate predicateWithFormat:@"username = %@", username];
                
                RLMResults *existingContacts = [YAContact objectsWithPredicate:pred];
                YAContact *contactToAdd;
                if(existingContacts.count) {
                    contactToAdd = existingContacts.firstObject;
                }
                else {
                    contactToAdd = [YAContact contactFromDictionary:contactDic];
                }
                if([self.members indexOfObject:contactToAdd] == NSNotFound)
                    [self.members addObject:contactToAdd];
            }
            [[RLMRealm defaultRealm] commitWriteTransaction];
            
            DLog(@"members %@ added to the group: %@", phones, self.name);
            completion(nil);
        }
    }];
}

- (void)removeMember:(YAContact *)contact withCompletion:(completionBlock)completion {
    NSString *memberPhone = contact.number;
    
    [[YAServer sharedServer] removeGroupMemberByPhone:memberPhone fromGroupWithId:self.serverId withCompletion:^(id response, NSError *error) {
        if(error) {
            DLog(@"can't remove member from the group with name %@, error %@", self.name, error.localizedDescription);
            if(completion)
                completion(error);
        }
        else {
            [[RLMRealm defaultRealm] beginWriteTransaction];
            [self.members removeObjectAtIndex:[self.members indexOfObject:contact]];
            [[RLMRealm defaultRealm] commitWriteTransaction];
            DLog(@"member %@ removed from the group: %@", memberPhone, self.name);
            if(completion)
                completion(nil);
        }
    }];

}

- (void)leaveWithCompletion:(completionBlock)completion {
    [[YAServer sharedServer] leaveGroupWithId:self.serverId withCompletion:^(id response, NSError *error) {
        if(error) {
            DLog(@"can't leave group with name: %@, error %@", self.name, error.localizedDescription);
            completion(error);
        }
        else {
            NSString *name = self.name;
            [[RLMRealm defaultRealm] beginWriteTransaction];
            [[RLMRealm defaultRealm] deleteObject:self];
            [[RLMRealm defaultRealm] commitWriteTransaction];
            
            //will force groups list to update
            [[NSNotificationCenter defaultCenter] postNotificationName:GROUP_DID_REFRESH_NOTIFICATION object:nil userInfo:nil];
            
            DLog(@"successfully left group with name: %@", name);
            completion(nil);
        }
    }];
}

- (void)muteUnmuteWithCompletion:(completionBlock)completion {
    [[YAServer sharedServer] muteGroupWithId:self.serverId mute:!self.muted withCompletion:^(id response, NSError *error) {
        if(error) {
            DLog(@"mute/unmute group with name %@, error %@", self.name, error.localizedDescription);
            completion(error);
        }
        else {
            [[RLMRealm defaultRealm] beginWriteTransaction];
            self.muted = !self.muted;
            [[RLMRealm defaultRealm] commitWriteTransaction];
            
            DLog(@"%@ group %@", self.name, self.muted ? @"muted" : @"unmuted");
            completion(nil);
        }
    }];

}

#pragma mark - Videos

- (void)refresh:(BOOL)showPullDownToRefresh {
    if(self.videosUpdateInProgress)
        return;
    
    self.videosUpdateInProgress = YES;
    
    //since
    NSDictionary *userInfo = @{kShowPullDownToRefreshWhileRefreshingGroup:[NSNumber numberWithBool:showPullDownToRefresh]};

    [[NSNotificationCenter defaultCenter] postNotificationName:GROUP_WILL_REFRESH_NOTIFICATION object:self userInfo:userInfo];
    
    [[YAServer sharedServer] groupInfoWithId:self.serverId since:self.refreshedAt
                              withCompletion:^(id response, NSError *error) {
        if(self.isInvalidated)
            return;
        
        self.videosUpdateInProgress = NO;
        if(error) {
            DLog(@"can't get group %@ info, error %@", self.name, [error localizedDescription]);
            [[NSNotificationCenter defaultCenter] postNotificationName:GROUP_DID_REFRESH_NOTIFICATION object:self userInfo:nil];
            return;
        }
        else {
            [self.realm beginWriteTransaction];
            self.refreshedAt = self.updatedAt;
            [self updateFromServerResponeDictionarty:response];
            [self.realm commitWriteTransaction];
            
            NSArray *videoDictionaries = response[YA_VIDEO_POSTS];
            DLog(@"received %lu videos for %@ group", (unsigned long)videoDictionaries.count, self.name);
            
            NSDictionary *updatedAndNew = [self updateVideosFromDictionaries:videoDictionaries];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:GROUP_DID_REFRESH_NOTIFICATION object:self userInfo:updatedAndNew];
        }
    }];
}

- (void)refresh {
    [self refresh:NO];
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

- (NSDictionary*)updateVideosFromDictionaries:(NSArray*)videoDictionaries {
    NSSet *existingIds = [self videoIds];
    NSSet *newIds = [NSSet setWithArray:[videoDictionaries valueForKey:YA_RESPONSE_ID]];
    
    NSMutableSet *idsToAdd = [NSMutableSet setWithSet:newIds];
    [idsToAdd minusSet:existingIds];
    
    NSMutableArray *newVideos = [NSMutableArray new];
    NSMutableArray *updatedVideos = [NSMutableArray new];
    
    videoDictionaries = [videoDictionaries sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:YA_VIDEO_READY_AT ascending:YES]]];
    
    [[RLMRealm defaultRealm] beginWriteTransaction];
    
    NSMutableSet *videosToDelete = [NSMutableSet set];
    
    for(NSDictionary *videoDic in videoDictionaries) {
        
        //video exists? update name
        if([existingIds containsObject:videoDic[YA_RESPONSE_ID]]) {
            RLMResults *videos = [YAVideo objectsWhere:[NSString stringWithFormat:@"serverId = '%@'", videoDic[YA_RESPONSE_ID]]];
            if(videos.count) {
                YAVideo *video = [videos firstObject];
                BOOL deleted = [videoDic[YA_VIDEO_DELETED] boolValue];
                
                if(deleted) {
                    [videosToDelete addObject:video];
                }
                else {
                    if (![videoDic[YA_RESPONSE_NAME] isEqual:[NSNull null]]) {
                        video.caption = videoDic[YA_RESPONSE_NAME];
                        video.font = (videoDic[YA_RESPONSE_FONT] == [NSNull null]) ? 0 : [videoDic[YA_RESPONSE_FONT] integerValue];
                        video.namer = videoDic[YA_RESPONSE_NAMER][YA_RESPONSE_NAME];
                        video.caption_x = ![videoDic[YA_RESPONSE_NAME_X] isKindOfClass:[NSNull class]] ? [videoDic[YA_RESPONSE_NAME_X] floatValue] : 0.5;
                        video.caption_y = ![videoDic[YA_RESPONSE_NAME_Y] isKindOfClass:[NSNull class]] ? [videoDic[YA_RESPONSE_NAME_Y] floatValue] : 0.25;
                        video.caption_scale = ![videoDic[YA_RESPONSE_SCALE] isKindOfClass:[NSNull class]] ? [videoDic[YA_RESPONSE_SCALE] floatValue] : 1;
                        video.caption_rotation = ![videoDic[YA_RESPONSE_ROTATION] isKindOfClass:[NSNull class]] ? [videoDic[YA_RESPONSE_ROTATION] floatValue] : 0;
                    }
                    
                    video.pending = ![videoDic[YA_RESPONSE_APPROVED] boolValue];
                    
                    NSArray *likers = videoDic[YA_RESPONSE_LIKERS];
                    if (likers.count) {
                        [video updateLikersWithArray:likers];
                    }
                    
                    //update created at
                    if(![videoDic[YA_VIDEO_READY_AT] isEqual:[NSNull null]]) {
                        NSTimeInterval timeInterval = [videoDic[YA_VIDEO_READY_AT] integerValue];
                        video.createdAt = [NSDate dateWithTimeIntervalSince1970:timeInterval];
                        video.uploadedToAmazon = YES;
                    }
                    
                    [updatedVideos addObject:video];
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
            video.creator = ![videoDic[YA_RESPONSE_USER][YA_RESPONSE_NAME] isKindOfClass:[NSNull class]] ? videoDic[YA_RESPONSE_USER][YA_RESPONSE_NAME] : @"";
            NSArray *likers = videoDic[YA_RESPONSE_LIKERS];
            [video updateLikersWithArray:likers];
            NSTimeInterval timeInterval = [videoDic[YA_VIDEO_READY_AT] integerValue];
            video.createdAt = [NSDate dateWithTimeIntervalSince1970:timeInterval];
            video.uploadedToAmazon = YES;
            video.url = videoDic[YA_VIDEO_ATTACHMENT];
            
            id gifUrl = videoDic[YA_VIDEO_ATTACHMENT_PREVIEW];
            if(gifUrl) {
                video.gifUrl = ![gifUrl isKindOfClass:[NSNull class]] ? gifUrl : @"";
            }
            video.caption = ![videoDic[YA_RESPONSE_NAME] isKindOfClass:[NSNull class]] ? videoDic[YA_RESPONSE_NAME] : @"";
            if(![videoDic[YA_RESPONSE_NAMER] isKindOfClass:[NSNull class]] && ![videoDic[YA_RESPONSE_NAMER][YA_RESPONSE_NAME] isKindOfClass:[NSNull class]]){
                video.namer = videoDic[YA_RESPONSE_NAMER][YA_RESPONSE_NAME];
            } else {
                video.namer = @"";
            }
            video.font = ![videoDic[YA_RESPONSE_FONT] isKindOfClass:[NSNull class]] ? [videoDic[YA_RESPONSE_FONT] integerValue] : 0;
            video.group = self;
            video.caption_x = ![videoDic[YA_RESPONSE_NAME_X] isKindOfClass:[NSNull class]] ? [videoDic[YA_RESPONSE_NAME_X] floatValue] : 0.5;
            video.caption_y = ![videoDic[YA_RESPONSE_NAME_Y] isKindOfClass:[NSNull class]] ? [videoDic[YA_RESPONSE_NAME_Y] floatValue] : 0.25;
            video.caption_scale = ![videoDic[YA_RESPONSE_SCALE] isKindOfClass:[NSNull class]] ? [videoDic[YA_RESPONSE_SCALE] floatValue] : 1;
            video.caption_rotation = ![videoDic[YA_RESPONSE_ROTATION] isKindOfClass:[NSNull class]] ? [videoDic[YA_RESPONSE_ROTATION] floatValue] : 0;
            video.pending = ![videoDic[YA_RESPONSE_APPROVED] boolValue];

            [self.videos insertObject:video atIndex:0];
            
            [newVideos addObject:video];
        }
    }
    
    [[RLMRealm defaultRealm] commitWriteTransaction];
    
    for(YAVideo *video in [videosToDelete copy]) {
        [video removeFromCurrentGroupWithCompletion:nil removeFromServer:NO];
    }
    
    return @{kUpdatedVideos:updatedVideos, kNewVideos:newVideos, kDeletedVideos:videosToDelete};
}

@end
