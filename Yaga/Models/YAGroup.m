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
    return @{@"serverId":@""};
}

// Specify properties to ignore (Realm won't persist these)

//+ (NSArray *)ignoredProperties
//{
//    return @[];
//}

- (NSString*)membersString {
    if(!self.members.count) {
        return NSLocalizedString(@"No members", @"");
    }
    
    NSString *results = @"";
    
    for(int i = 0; i < self.members.count; i++) {
        YAContact *contact = (YAContact*)[self.members objectAtIndex:i];
        results = [results stringByAppendingFormat:@"%@%@", contact.name, (i < self.members.count - 1 ? @", " : @"")];
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

- (RLMResults*)sortedVideos {
    return [self.videos sortedResultsUsingProperty:@"createdAt" ascending:NO];
}

#pragma mark - Server synchronisation: update from server
- (void)updateFromServerResponeDictionarty:(NSDictionary*)dictionary {
    self.serverId = dictionary[YA_RESPONSE_ID];
    self.name = dictionary[YA_RESPONSE_NAME];
    
    [self.members removeAllObjects];
    
    NSArray *members = dictionary[YA_RESPONSE_MEMBERS];
    
    for(NSDictionary *memberDic in members){
        NSString *phoneNumber = memberDic[YA_RESPONSE_USER][YA_RESPONSE_MEMBER_PHONE];
        
        //skip myself
        if([phoneNumber isEqualToString:[YAUser currentUser].phoneNumber])
            continue;
        
        YAContact *contact = [YAContact contactFromPhoneNumber:phoneNumber];
        
        contact.registered = [memberDic objectForKey:YA_RESPONSE_MEMBER_JOINED_AT] != nil;
        
        [self.members addObject:contact];
    }
}

static BOOL groupsUpdateInProgress;
+ (void)updateGroupsFromServerWithCompletion:(completionBlock)block {
    if(groupsUpdateInProgress)
        return;
    groupsUpdateInProgress = YES;
    
    [[YAServer sharedServer] getGroupsWithCompletion:^(id response, NSError *error) {
        groupsUpdateInProgress = NO;
        if(error) {
            NSLog(@"can't fetch remove groups, error: %@", error.localizedDescription);
            
            if(block)
                block(error);
            
            return;
            
        }
        else {
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
            
            [[RLMRealm defaultRealm] commitWriteTransaction];
            if(block)
                block(nil);
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

- (void)addMembers:(NSArray*)membersDictionaries {
    [[RLMRealm defaultRealm] beginWriteTransaction];
    
    for(NSDictionary *memberDic in membersDictionaries) {
        [self.members addObject:[YAContact contactFromDictionary:memberDic]];
    }
    
    [[RLMRealm defaultRealm] commitWriteTransaction];
    
    [[YAServerTransactionQueue sharedQueue] addAddMembersTransactionForGroup:self memberPhonesToAdd:[membersDictionaries valueForKey:nPhone]];
}

- (void)removeMember:(YAContact *)contact {
    NSString *memberPhone = contact.number;
    
    [[RLMRealm defaultRealm] beginWriteTransaction];
    [self.members removeObjectAtIndex:[self.members indexOfObject:contact]];
    [[RLMRealm defaultRealm] commitWriteTransaction];
    
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
- (void)updateVideos {
    if(self.videosUpdateInProgress)
        return;
    self.videosUpdateInProgress = YES;

    [[YAServer sharedServer] groupInfoWithId:self.serverId withCompletion:^(id response, NSError *error) {
        self.videosUpdateInProgress = NO;
        if(error) {
            NSLog(@"can't get group %@ info, error %@", self.name, [error localizedDescription]);
        }
        else {
            NSArray *videoDictionaries = response[YA_VIDEO_POSTS];
            NSLog(@"received %lu videos for %@ group", videoDictionaries.count, self.name);
            [self updateVideosFromDictionaries:videoDictionaries];
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

- (void)updateVideosFromDictionaries:(NSArray*)videoDictionaries {
    NSSet *existingIds = [self videoIds];
    
    //remove deleted videos first
    NSMutableSet *idsToDelete = [NSMutableSet setWithSet:existingIds];
    NSSet *newIds = [NSSet setWithArray:[videoDictionaries valueForKey:YA_RESPONSE_ID]];
    [idsToDelete minusSet:newIds];
    
    for(NSString *idToDelete in idsToDelete) {
        RLMResults *videosToDelete = [YAVideo objectsWhere:[NSString stringWithFormat:@"serverId = '%@'", idToDelete]];
        if(videosToDelete.count) {
            YAVideo *videoToDelete = [videosToDelete firstObject];
            [[NSNotificationCenter defaultCenter] postNotificationName:DELETE_VIDEO_NOTIFICATION object:videoToDelete];
        }
    }
    
    for(NSDictionary *videoDic in videoDictionaries) {
        //video exists?
        if([existingIds containsObject:videoDic[YA_RESPONSE_ID]]) {
#warning TODO: apply new name when we have that parameter in json
            
            continue;
        }
        
        [YAVideo createVideoFromRemoteDictionary:videoDic addToGroup:[YAUser currentUser].currentGroup];
    }
    
}

- (BOOL)updateInProgress {
    @synchronized(self) {
        return self.videosUpdateInProgress || groupsUpdateInProgress;
    }
}
@end
