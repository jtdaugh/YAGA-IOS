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

@interface YAGroup ()

@property BOOL needsToUpdateNameOnServer;
@property BOOL needsToUpdateMembersOnServer;

@end

@implementation YAGroup

+ (RLMPropertyAttributes)attributesForProperty:(NSString *)propertyName {
    RLMPropertyAttributes attributes = [super attributesForProperty:propertyName];
    if ([propertyName isEqualToString:@"localId"] || [propertyName isEqualToString:@"serverId"]) {
        attributes |= RLMPropertyAttributeIndexed;
    }
    return attributes;
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
    NSString *results = @"";
    for(int i = 0; i < self.members.count; i++) {
        YAContact *contact = (YAContact*)[self.members objectAtIndex:i];
        results = [results stringByAppendingFormat:@"%@%@", contact.name, (i < self.members.count - 1 ? @", " : @"")];
    }
    
    return results;
}

+ (YAGroup*)group {
    YAGroup *result = [YAGroup new];
    result.localId = [YAUtils uniqueId];
    
    return result;
}

- (void)updateFromDictionary:(NSDictionary*)dictionary {
    self.serverId = dictionary[YA_RESPONSE_ID];
    self.name = dictionary[YA_RESPONSE_NAME];
    
    [self.members removeAllObjects];
    
    NSArray *members = dictionary[YA_RESPONSE_MEMBERS];
    
    for(NSDictionary *memberDic in members){
        YAContact *contact = [YAContact new];
        NSString *name = memberDic[YA_RESPONSE_USER][YA_RESPONSE_NAME];
        if ([name isKindOfClass:[NSNull class]]){
            contact.name = @"Null";
        }
        else {
            contact.name = name;
        }
        contact.number = memberDic[YA_RESPONSE_USER][YA_RESPONSE_MEMBER_PHONE];
    
        contact.registered = [memberDic objectForKey:YA_RESPONSE_MEMBER_JOINED_AT] != nil;
        
        [self.members addObject:contact];
    }
}

+ (void)synchronizeAllGroupsWithServer {
    for (YAGroup *group in [YAGroup allObjects]) {
        if(!group.synchronized)
            [group synchronizeWithServer];
    }
}

- (void)synchronizeWithServer {
    if(self.synchronized)
        return;
    
    //create group on server
    if(!self.serverId.length) {
        [[YAServer sharedServer] createGroupWithName:self.name withCompletion:^(NSDictionary *responseDictionary, NSError *error) {
            if(error) {
                NSLog(@"can't create group with name %@, error %@", self.name, error.localizedDescription);
            }
            else {
                [self.realm beginWriteTransaction];
                
                self.serverId = [responseDictionary objectForKey:YA_RESPONSE_ID];
                self.synchronized = YES;
                
                [self.realm commitWriteTransaction];
                
                NSLog(@"group: %@ created on server with id: %@", self.name, self.serverId);
            }
        }];
    }
    //update existing group
    else {
        if(self.needsToUpdateNameOnServer) {
            [[YAServer sharedServer] renameGroup:self newName:self.name withCompletion:^(id response, NSError *error) {
                if(error) {
                    NSLog(@"can't rename group with name %@, error %@", self.name, error.localizedDescription);
                }
                else {
                    self.needsToUpdateNameOnServer = NO;
                    if(!self.needsToUpdateMembersOnServer)
                        self.synchronized = YES;
                }
            }];
        }
        
        if(self.needsToUpdateMembersOnServer) {
            [[YAServer sharedServer] updateGroupMembers:self withCompletion:^(id response, NSError *error) {
                if(error) {
                    NSLog(@"can't update members in group %@, error %@", self.name, error.localizedDescription);
                }
                else {
                    self.needsToUpdateMembersOnServer = NO;
                    if(!self.needsToUpdateNameOnServer)
                        self.synchronized = YES;
                }
            }];
        }
    }
}

- (void)setNeedUpdateNameOnNextSync {
    self.needsToUpdateNameOnServer = YES;
    self.synchronized = NO;
}

- (void)setNeedUpdateMembersOnNext {
    self.needsToUpdateMembersOnServer = YES;
    self.synchronized = NO;
}

+ (void)updateGroupsFromServerWithCompletion:(completionBlock)block {
    [[YAServer sharedServer] getGroupsWithCompletion:^(id response, NSError *error) {
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

                [group updateFromDictionary:dict];
                
                if(!existingGroups.count)
                    [[RLMRealm defaultRealm] addObject:group];
            }
            
            [[RLMRealm defaultRealm] commitWriteTransaction];
            if(block)
                block(nil);
        }
    }];
}

@end
