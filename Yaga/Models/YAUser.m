//
//  CNetworking.m
//  Pic6
//
//  Created by Raj Vir on 7/24/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import "YAUser.h"
#import "YAContact.h"
#import "NSString+Hash.h"
#import <AFNetworking/AFHTTPRequestOperationManager.h>
#import "APAddressBook.h"
#import "APContact.h"
#import "NBPhoneNumberUtil.h"

@implementation YAUser

+ (YAUser*)currentUser {
    static YAUser *sharedCNetworking = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedCNetworking = [[self alloc] init];
    });
    return sharedCNetworking;
}

- (id)init {
    self = [super init];
    if(self) {
        _userData = [NSMutableDictionary new];
    }
    return self;
}
/**
    AFNetworking Code is here
 **/

- (void)registerUserWithCompletionBlock:(void (^)())block {
    NSLog(@"signing up");
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    
    NSString *username = (NSString *)[self userDataForKey:nUsername];
    NSString *phone = (NSString *)[self userDataForKey:nPhone];
    NSString *countryCode = [[NSLocale currentLocale] objectForKey: NSLocaleCountryCode];
    
    NSDictionary *params = @{
                             @"phone":phone,
                             @"name": username,
                             @"password":@"test",
                             @"country":countryCode
                             };
    
    
    NSLog(@"params: %@", params);
    
    NSLog(@"phone: %@", phone);
    
    NSLog(@"phone hash: %@", [phone md5]);
    
    [manager POST:[NSString stringWithFormat:@"%@/token", BASE_API_URL] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSString *token = [responseObject objectForKey:@"token"];
        NSString *userId = [responseObject objectForKey:@"user_id"];
        [self saveUserData:token forKey:@"token"];
        [self saveUserData:userId forKey:nUserId];
        NSLog(@"/token response: %@", responseObject);

        block();
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"register user Error: %@", [operation responseString]);
    }];
}

- (void)createCrew:(NSString *)name withMembers:(NSArray *)hashes withCompletionBlock:(void (^)())block {
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    [manager.requestSerializer setValue:[NSString stringWithFormat:@"Clique key=\"%@\"", [self userDataForKey:@"token"]] forHTTPHeaderField:@"Authorization"];
    
    NSDictionary *params = @{
                             @"name":name,
                             @"initial_members":hashes
                             };
    
//    NSLog(@"params: %@", params);
    
    [manager POST:[NSString stringWithFormat:@"%@/crew/create", BASE_API_URL] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        NSLog(@"%@", responseObject);
        block();
        //        NSLog(@"%@", [responseObject objectForKey:@"crew_id"]);
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"create crew Error: %@", [operation responseString]);
        
    }];
}

- (void)meInfo {
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    [manager.requestSerializer setValue:[NSString stringWithFormat:@"Clique key=\"%@\"", [self userDataForKey:@"token"]] forHTTPHeaderField:@"Authorization"];
    
    
    [manager GET:[NSString stringWithFormat:@"%@/me", BASE_API_URL] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        NSLog(@"meInfo: %@", responseObject);
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", [operation responseString]);
    }];
    
}

- (void)myCrews {
    [self myCrewsWithCompletion:nil];
}

- (void)myCrewsWithCompletion:(void (^)())block {
    //val TODO:
    block();//no crews for now
//    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
//    manager.requestSerializer = [AFJSONRequestSerializer serializer];
//    [manager.requestSerializer setValue:[NSString stringWithFormat:@"Clique key=\"%@\"", [self userDataForKey:@"token"]] forHTTPHeaderField:@"Authorization"];
//    
//    [manager GET:[NSString stringWithFormat:@"%@/me/crews", BASE_API_URL] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
//        
//        self.YAGroup = [[NSMutableArray alloc] init];
//        
//        NSArray *items = [responseObject objectForKey:@"items"];
//        for(id item in items){
//            YAGroup *YAGroup = [[YAGroup alloc] init];
//            YAGroup.groupId = [item objectForKey:@"crew_id"];
//            YAGroup.name = [item objectForKey:@"name"];
//            YAGroup.members = [[NSMutableArray alloc] initWithObjects:@"rjvir", @"b9speed", @"kyle", nil];
//            
//            [self.YAGroup addObject:YAGroup];
//        }
//        
//        NSData *groupData = [NSKeyedArchiver archivedDataWithRootObject:self.YAGroup];
//        [self saveObject:groupData forKey:nYAGroup];
////        [self saveUserData:self.YAGroup forKey:nYAGroup];
//        
//        NSLog(@"groups: %@", responseObject);
//        NSLog(@"YAGroup count: %lu", [self.YAGroup count]);
//        block();
//        
//        
//    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
//        NSLog(@"my crews Error: %@", error);
//        
//    }];
}

- (void)addToCrew:(NSString *)crewId withCompletionBlock:(void (^)())block {
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    [manager.requestSerializer setValue:[NSString stringWithFormat:@"Clique key=\"%@\"", [self userDataForKey:@"token"]] forHTTPHeaderField:@"Authorization"];
    
    NSString *userId = (NSString *) [self userDataForKey:nUserId];
    // bb72f20e-0051-4e85-8e12-e7a37cf77f37
    
    [manager POST:[NSString stringWithFormat:@"%@/crew/%@/member/%@", BASE_API_URL, crewId, userId] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //
        NSLog(@"added to crew! %@", responseObject);
        block();
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        //
        NSLog(@"here it is: %@", error);
        block();
    }];
    
}

- (void)findFriends:(NSArray *)numbers withCompletionBlock:(void (^)())block {
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    [manager.requestSerializer setValue:[NSString stringWithFormat:@"Clique key=\"%@\"", [self userDataForKey:@"token"]] forHTTPHeaderField:@"Authorization"];
    
    NSDictionary *params = @{
                             @"hashes":numbers
                             };
    
    //NSLog(@"hashes params: %@", params);
    
    [manager POST:[NSString stringWithFormat:@"%@/match", BASE_API_URL] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //
        NSLog(@"matches: %@", responseObject);
        block();
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        //
        NSLog(@"here's the damn error: %@", error);
        block();
    }];
}

- (BOOL)loggedIn {
    if([self userDataForKey:nUsername]){
        return YES;
    } else {
        return NO;
    }
}

- (void)logout {
    [[NSUserDefaults standardUserDefaults] setPersistentDomain:[NSDictionary dictionary] forName:[[NSBundle mainBundle] bundleIdentifier]];
    [self.userData removeAllObjects];
}

- (void)trySomething {
    [self.delegate test];
}

- (void)saveUserData:(NSObject *)value forKey:(NSString *)key {
    [self.userData setObject:value forKey:key];
    [self saveObject:value forKey:key];
}

- (void)saveObject:(NSObject *)value forKey:(NSString *)key {
    [[NSUserDefaults standardUserDefaults] setObject:value forKey:key];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSObject *)userDataForKey:(NSString *)key {
    return [self.userData objectForKey:key];
}

- (NSString *)humanName {
    
    NSString *deviceName = [[UIDevice currentDevice].name lowercaseString];
    for (NSString *string in @[@"’s iphone", @"’s ipad", @"’s ipod touch", @"’s ipod",
                               @"'s iphone", @"'s ipad", @"'s ipod touch", @"'s ipod",
                               @"s iphone", @"s ipad", @"s ipod touch", @"s ipod", @"iphone"]) {
        NSRange ownershipRange = [deviceName rangeOfString:string];
        
        if (ownershipRange.location != NSNotFound) {
            return [[[deviceName substringToIndex:ownershipRange.location] componentsSeparatedByString:@" "][0]
                    stringByReplacingCharactersInRange:NSMakeRange(0,1)
                    withString:[[deviceName substringToIndex:1] capitalizedString]];
        }
    }
    
    return [UIDevice currentDevice].name;
}

- (NSMutableArray *)gridDataForGroupId:(NSString *)groupId {
    if(!groupId){
        return [@[] mutableCopy];
    }
    if(!self.messages[groupId]){
        self.messages[groupId] = [@[] mutableCopy];
    }
    return (NSMutableArray *) self.messages[groupId];
}

- (NSUInteger) groupIndexForGroupId:(NSString *)groupId {
    NSUInteger index = 0;
    for(YAGroup *group in self.groups){
        if([group.groupId isEqualToString: groupId]){
            return index;
        }
        index++;
    }
    return -1;
}

#pragma mark - Refactored - <delete me later
- (void)importContactsWithCompletion:(contactsImportedBlock)completion {
    
    APAddressBook *addressBook = [[APAddressBook alloc] init];
    addressBook.fieldsMask = APContactFieldCompositeName | APContactFieldPhones | APContactFieldFirstName;
    addressBook.filterBlock = ^BOOL(APContact *contact){
        return
        // has a #
        (contact.phones.count > 0) &&
        
        // has a name
        contact.compositeName &&
        
        // name does not contain "GroupMe"
        ([contact.compositeName rangeOfString:@"GroupMe:"].location == NSNotFound);
    };
    
    addressBook.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"compositeName" ascending:YES]];
    
    __block NSMutableArray *result = [NSMutableArray new];
    
    [addressBook loadContacts:^(NSArray *contacts, NSError *error){
        if (!error){
            for(int i = 0; i<[contacts count]; i++){
                APContact *contact = contacts[i];
                for(int j = 0; j<[contact.phones count]; j++){
                    NBPhoneNumberUtil *phoneUtil = [NBPhoneNumberUtil sharedInstance];
                    NSError *aError = nil;
                    NBPhoneNumber *myNumber = [phoneUtil parse:contact.phones[j] defaultRegion:@"US" error:&aError];
                    NSString *num = [phoneUtil format:myNumber numberFormat:NBEPhoneNumberFormatE164 error:&aError];
                    
                    NSDictionary *item = @{nCompositeName:contact.compositeName, nPhone:num, nFirstname:[NSString stringWithFormat:@"%@", contact.firstName], nRegistered:[NSNumber numberWithBool:NO]};
                    [result addObject:item];
                }
            }
            completion(nil, result);
        }
        else
        {
            completion([NSError errorWithDomain:@"NO DOMAIN" code:0 userInfo:nil], nil);
        }
    }];
}

@end
