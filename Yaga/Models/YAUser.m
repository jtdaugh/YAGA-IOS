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
        sharedCNetworking.countryCode = [[NSLocale currentLocale] objectForKey: NSLocaleCountryCode];
        sharedCNetworking->dateFormatter = [[NSDateFormatter alloc] init];
        [sharedCNetworking->dateFormatter setDateFormat:@"MM/dd hh:mma"];
    });
    return sharedCNetworking;
}

- (id)init {
    self = [super init];
    if(self) {
        _userData = [NSMutableDictionary new];
        
        NSString *selectedGroupId = [[NSUserDefaults standardUserDefaults] objectForKey:nCurrentGroupId];
        if(selectedGroupId) {
            self.currentGroup = [YAGroup objectInRealm:[RLMRealm defaultRealm] forPrimaryKey:selectedGroupId];
        }
    }
    return self;
}

- (void)setCurrentGroup:(YAGroup *)currentGroup {
    [self saveObject:currentGroup.groupId forKey:nCurrentGroupId];
    _currentGroup = currentGroup;
}

- (BOOL)loggedIn {
    if([self objectForKey:nUsername]){
        return YES;
    } else {
        return NO;
    }
}

- (void)logout {
    [[NSUserDefaults standardUserDefaults] setPersistentDomain:[NSDictionary dictionary] forName:[[NSBundle mainBundle] bundleIdentifier]];
    [self.userData removeAllObjects];
}

- (void)saveUserData:(NSObject *)value forKey:(NSString *)key {
    [self.userData setObject:value forKey:key];
    [self saveObject:value forKey:key];
}

- (NSObject *)userDataForKey:(NSString *)key {
    return [self.userData objectForKey:key];
}

- (void)saveObject:(NSObject *)value forKey:(NSString *)key {
    [[NSUserDefaults standardUserDefaults] setObject:value forKey:key];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (id)objectForKey:(NSString*)key {
    return [[NSUserDefaults standardUserDefaults] objectForKey:key];
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

#pragma mark - Refactored - <delete me later
- (void)importContactsWithCompletion:(contactsImportedBlock)completion {
    
    APAddressBook *addressBook = [[APAddressBook alloc] init];
    addressBook.fieldsMask = APContactFieldCompositeName | APContactFieldPhones | APContactFieldFirstName | APContactFieldLastName;
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
    
    [addressBook loadContacts:^(NSArray *contacts, NSError *error){
        if (!error){
            NSMutableArray *result = [NSMutableArray new];

            for(int i = 0; i<[contacts count]; i++){
                APContact *contact = contacts[i];
                for(int j = 0; j<[contact.phones count]; j++){
                    NBPhoneNumberUtil *phoneUtil = [NBPhoneNumberUtil sharedInstance];
                    NSError *aError = nil;
                    NBPhoneNumber *myNumber = [phoneUtil parse:contact.phones[j] defaultRegion:@"US" error:&aError];
                    NSString *num = [phoneUtil format:myNumber numberFormat:NBEPhoneNumberFormatE164 error:&aError];
                    
                    if(!num.length)
                        continue;
                    
                    NSDictionary *item = @{nCompositeName:[NSString stringWithFormat:@"%@", contact.compositeName],
                                           nPhone:num,
                                           nFirstname: [NSString stringWithFormat:@"%@", contact.firstName],
                                           nLastname:  [NSString stringWithFormat:@"%@", contact.lastName],
                                           nRegistered:[NSNumber numberWithBool:NO]};
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

- (NSString*)formatDate:(NSDate*)date {
    return [dateFormatter stringFromDate:date];
}

- (NSString*)username {
    return [[YAUser currentUser] objectForKey:nUsername];
}
@end
