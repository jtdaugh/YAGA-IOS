//
//  YAGroupCreator.m
//  Yaga
//
//  Created by Iegor on 12/24/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import "YAGroupCreator.h"
#import "YAContact.h"

@interface User : NSObject
@property (nonatomic, strong) NSString *phone;
@property (nonatomic, strong) NSString *name;
@end@implementation User@end

@implementation YAGroupCreator
+ (instancetype)sharedCreator {
    static YAGroupCreator *sCreator = nil;
    static dispatch_once_t once_token;
    dispatch_once(&once_token, ^{
        sCreator = [[self alloc] init];
    });
    return sCreator;
}

+ (YAGroup*)createGroupWithDictionary:(NSDictionary*)dictionary
{
    YAGroup *group = [YAGroup new];
    group.groupId = [YAGroup generateGroupId];
    group.tempGroupId = [dictionary[@"id"] integerValue];
    group.name = dictionary[@"name"];
    
    NSArray *members = dictionary[@"members"];
    
    for(NSDictionary *memberDic in members){
        YAContact *contact = [YAContact new];
        User *user = [self userFromDict:memberDic[@"user"]];
        contact.name = user.name;
        contact.firstName = user.name;
        contact.number = user.phone;
        contact.registered = memberDic[@"joined_at"];
        
        [group.members addObject:contact];
    }
    return group;
}

+ (User*)userFromDict:(NSDictionary*)dict
{
    User* user = [User new];
    user.name = dict[@"name"];
    user.phone = dict[@"phone"];
    
    return user;
}
@end
