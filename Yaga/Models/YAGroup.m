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

//+ (NSString *)primaryKey {
//    return @"groupId";
//}

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
    CFUUIDRef theUUID = CFUUIDCreate(NULL);
    CFStringRef string = CFUUIDCreateString(NULL, theUUID);
    CFRelease(theUUID);
    
    YAGroup *result = [YAGroup new];
    result.localId = [NSString stringWithFormat:@"group_%@", (__bridge NSString *)string];
    
    return result;
}

- (void)updateFromDictionary:(NSDictionary*)dictionary {
    self.serverId = [dictionary[YA_RESPONSE_ID] stringValue];
    self.name = dictionary[YA_RESPONSE_NAME];
    
    NSArray *members = dictionary[YA_RESPONSE_MEMBERS];
    
#warning TODO: add/remove members
    for(NSDictionary *memberDic in members){
        YAContact *contact = [YAContact new];
        NSString *name = memberDic[YA_RESPONSE_NAME];
        if ([name isKindOfClass:[NSNull class]]){
            contact.name = @"Null";
        }
        else {
            contact.name = name;
        }
        contact.number = memberDic[YA_RESPONSE_MEMBER_PHONE];

        NSArray *nameComponents = [name componentsSeparatedByString:@" "];
        if(nameComponents.count) {
            contact.firstName = nameComponents[0];
            if(nameComponents.count > 1)
                contact.firstName = nameComponents[1];
        }
    
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
    if(!self.serverId) {
        [[YAServer sharedServer] createGroupWithName:self.name withCompletion:^(NSDictionary *responseDictionary, NSError *error) {
            if(error) {
                NSLog(@"can't create group with name %@, error %@", self.name, error.localizedDescription);
            }
            else {
                [self.realm beginWriteTransaction];
                
                self.serverId = [[responseDictionary objectForKey:YA_RESPONSE_ID] stringValue];
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
            [[YAServer sharedServer] updateGroupMembersForGroup:self withCompletion:^(id response, NSError *error) {
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
            block(error);
            return;

        }
        else {
            NSAssert([response isKindOfClass:[NSArray class]], @"unexpected server result");
            
            [[RLMRealm defaultRealm] beginWriteTransaction];
            
            NSArray *groups = (NSArray*)response;
            
            for (id d in groups) {
                
                NSDictionary *dict = [NSDictionary dictionaryFromResponseObject:d withError:nil];
                
                NSString *serverGroupId = [dict[YA_RESPONSE_ID] stringValue];
                NSString *predicate = [NSString stringWithFormat:@"serverId = %@", serverGroupId];
                RLMResults *existingGroups = [YAGroup objectsWhere:predicate];
                
                YAGroup *group;
                if(existingGroups.count) {
                    group = existingGroups[0];
                }
                else {
                    group = [YAGroup group];
                    [[RLMRealm defaultRealm] addObject:group];
                }

                [group updateFromDictionary:dict];
            }
            
            [[RLMRealm defaultRealm] commitWriteTransaction];
            block(nil);
        }
    }];
}

@end
