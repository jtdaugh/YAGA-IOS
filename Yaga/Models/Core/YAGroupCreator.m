//
//  YAGroupCreator.m
//  Yaga
//
//  Created by Iegor on 12/24/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import "YAGroupCreator.h"
#import "YAContact.h"

#define ID      @"id"
#define USER    @"user"
#define NAME    @"name"
#define PHONE   @"phone"
#define MEMBERS @"members"

#define DATABASE_DEFAULT_VALUE @"Null"

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
    group.tempGroupId = [dictionary[ID] integerValue];
    group.name = dictionary[NAME];
    
    NSArray *members = dictionary[MEMBERS];
    
    for(NSDictionary *memberDic in members){
        YAContact *contact = [YAContact new];
        User *user = [self userFromDict:memberDic[USER]];
        contact.name = user.name;
        contact.firstName = user.name;
        contact.number = user.phone;
        contact.registered = [memberDic objectForKey:@"joined_at"] != nil;
        
        [group.members addObject:contact];
    }
    return group;
}

+ (User*)userFromDict:(NSDictionary*)dict
{
    User* user = [User new];
    NSString *name = dict[NAME];
    if ([name isKindOfClass:[NSNull class]]){
        user.name = DATABASE_DEFAULT_VALUE;
    }
    else {
        user.name = name;
    }
    user.phone = dict[PHONE];
    
    return user;
}
@end
