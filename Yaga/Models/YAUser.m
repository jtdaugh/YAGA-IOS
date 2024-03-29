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
#import "YAAssetsCreator.h"
#import "YAUtils.h"
#import "YAServer.h"

#define YA_CURRENT_GROUP_ID @"current_group_id"

#define kContactsAccessWasRequested @"kContactsAccessWasRequested"

@interface YAUser ()

@property (nonatomic, strong, readwrite) NSMutableDictionary *phonebook;

@end

@implementation YAUser

+ (YAUser*)currentUser {
    static YAUser *sharedUser = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedUser = [[self alloc] init];

        sharedUser.countryCode = [[NSUserDefaults standardUserDefaults] objectForKey:kCountryCode];
        if(!sharedUser.countryCode)
            sharedUser.countryCode = [[NSLocale currentLocale] objectForKey: NSLocaleCountryCode];

        sharedUser->dateFormatter = [[NSDateFormatter alloc] init];
        sharedUser->timeFormatter = [[NSDateFormatter alloc] init];
        [sharedUser->dateFormatter setDateFormat:@"MM/dd"];
        [sharedUser->timeFormatter setDateFormat:@"h:mma"];
        [sharedUser->timeFormatter setAMSymbol:@"am"];
        [sharedUser->timeFormatter setPMSymbol:@"pm"];
    });
    return sharedUser;
}

- (id)init {
    self = [super init];
    if(self) {
        _userData = [NSMutableDictionary new];
        
        //request an access to the contacts first time in Groups list(because we need to show correct member names)
        //next times phonebook is loaded on app start
        if([[NSUserDefaults standardUserDefaults] boolForKey:kContactsAccessWasRequested]) {
            [self importContactsWithCompletion:nil excludingPhoneNumbers:nil];
        }
    }
    return self;
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

#pragma mark - Refactored
- (void)importContactsWithCompletion:(contactsImportedBlock)completion excludingPhoneNumbers:(NSSet*)excludePhonesSet {
    
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
    
    //using last requested yaga users
    NSDictionary *yagaUsersData = [[NSUserDefaults standardUserDefaults] objectForKey:kYagaUsersRequested];
    
    [addressBook loadContactsOnQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0) completion:^(NSArray *contacts, NSError *error) {
        if (!error){
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kContactsAccessWasRequested];
            
            NSMutableArray *phoneResults = [NSMutableArray new];
            self.phonebook = [NSMutableDictionary new];
            
            NBPhoneNumberUtil *phoneUtil = [NBPhoneNumberUtil new];
            
            NSMutableArray *usersResults = [NSMutableArray new];
            NSMutableArray *nonUsersResults = [NSMutableArray new];
            
            for(int i = 0; i<[contacts count]; i++){
                APContact *contact = contacts[i];
                
                for(int j = 0; j<[contact.phones count]; j++){
                    
                    NSError *aError = nil;

                    NBPhoneNumber *myNumber = [phoneUtil parse:contact.phones[j]
                                                 defaultRegion:[YAUser currentUser].countryCode
                                                         error:&aError];
                    if(aError)
                        continue;
                    
                    NSString *num = [phoneUtil format:myNumber numberFormat:NBEPhoneNumberFormatE164 error:&aError];
                    
                    if(!num.length && aError)
                        continue;
                    
                    NSDictionary *yagaUserData = yagaUsersData[num];
                    
                    NSMutableDictionary *item = [NSMutableDictionary dictionaryWithDictionary:
                                                 @{nCompositeName:[NSString stringWithFormat:@"%@", contact.compositeName],
                                                   nPhone    : num,
                                                   nFirstname: [NSString stringWithFormat:@"%@", contact.firstName],
                                                   nLastname : [NSString stringWithFormat:@"%@", contact.lastName],
                                                   nYagaUser : [NSNumber numberWithBool:yagaUserData != nil]}];
                                                   
                    if(yagaUserData && yagaUserData[nName] != [NSNull null]) {
                        [item setObject:yagaUserData[nName] forKey:nUsername];
                    }

                    if(![excludePhonesSet containsObject:num])
                    {
                        if (yagaUserData) {
                            [usersResults addObject:item];
                        } else {
                            [nonUsersResults addObject:item];
                        }
                        
                        [phoneResults addObject:num];
                    }
                    
                    [self.phonebook setObject:item forKey:num];
                }
            }
            if(completion)
            {
                NSMutableArray *orderedResults = [[usersResults arrayByAddingObjectsFromArray:nonUsersResults] mutableCopy];
                
                completion(nil, orderedResults, NO);
                
                NSDate *lastRequested = [[NSUserDefaults standardUserDefaults] objectForKey:kLastYagaUsersRequestDate];
                //request yaga users once per hour, or far more often when debugging.
                if(!lastRequested || [[NSDate date] compare:[lastRequested dateByAddingTimeInterval:(DEBUG ? 5 : 60*60)]] == NSOrderedDescending) {
                    [[YAServer sharedServer] getYagaUsersFromPhonesArray:phoneResults withCompletion:^(id response, NSError *error) {
                        if(error) {
                            if (completion)
                                completion(error, nil, NO);
                        }
                        else {
                            NSMutableDictionary *yagaUserDictionary = [NSMutableDictionary new];
                            
                            for(NSDictionary *yagaUserDic in response) {
                                NSString *phone = yagaUserDic[nPhone];
                                
                                if(!phone.length)
                                    continue;
                                
                                NSMutableDictionary *phonebookItem = [self.phonebook objectForKey:phone];
                                
                                if(phonebookItem) {
                                    [phonebookItem setObject:[NSNumber numberWithBool:YES] forKey:nYagaUser];
                                    NSString *username = yagaUserDic[nName];
                                    if([username isKindOfClass:[NSString class]] && username.length != 0)
                                        [phonebookItem setObject:username forKey:nUsername];
                                    
                                    [self.phonebook setObject:phonebookItem forKey:phone];
                                }
                                NSPredicate *phoneNumPredicate = [NSPredicate predicateWithFormat:@"%K == %@", nPhone, phone];
                                    @try {
                                        if ([[usersResults filteredArrayUsingPredicate:phoneNumPredicate] count]) {
                                            // already in yaga users array, do nothing. Should update entry maybe?
                                        } else {
                                            NSArray *newUser = [nonUsersResults filteredArrayUsingPredicate:phoneNumPredicate];
                                            if ([newUser count]) {
                                                [nonUsersResults removeObjectsInArray:newUser];
                                                [usersResults addObjectsFromArray:newUser];
                                            }
                                        }
                                    }
                                    @catch (NSException *exception) {
                                        DLog(@"Address book exception");
                                    }
                                [yagaUserDictionary setObject:yagaUserDic forKey:phone];
                            }

                            [usersResults sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:nCompositeName ascending:YES]]];
                            
                            [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:kLastYagaUsersRequestDate];
                            [[NSUserDefaults standardUserDefaults] setObject:yagaUserDictionary forKey:kYagaUsersRequested];
                           
                            if(completion) {
                                NSMutableArray *orderedResults = [[usersResults arrayByAddingObjectsFromArray:nonUsersResults] mutableCopy];
                                completion(nil, orderedResults, YES);
                            }
                        }

                    }];
                }
            }
        }
        else
        {
            if(completion)
                completion([NSError errorWithDomain:@"NO DOMAIN" code:0 userInfo:nil], nil, NO);
        }
    }];
}


- (NSString*)formatDate:(NSDate*)date {
    if(!date)
        return @"";
    
    NSDateComponents *dateComponents = [[NSCalendar currentCalendar] components:NSCalendarUnitDay | NSCalendarUnitWeekOfYear | NSCalendarUnitWeekday fromDate:date];
    NSDateComponents *todayComponents = [[NSCalendar currentCalendar] components:NSCalendarUnitDay | NSCalendarUnitWeekOfYear fromDate:[NSDate date]];
    
    NSString *dayString;
    
    // if same week
    if(todayComponents.weekOfYear == dateComponents.weekOfYear){
        // if same day
        if(todayComponents.day == dateComponents.day){
            dayString = @"Today";
        } else if(todayComponents.weekOfYear == dateComponents.weekOfYear){ // same week but not same day
            dayString = [[dateFormatter shortWeekdaySymbols] objectAtIndex:dateComponents.weekday-1];
        }
    } else {
        dayString = [dateFormatter stringFromDate:date];
    }
    
    return [NSString stringWithFormat:@"%@ %@", dayString, [timeFormatter stringFromDate:date]];
}

- (NSString*)username {
    return [[YAUser currentUser] objectForKey:nUsername];
}

- (NSString*)phoneNumber {
    return [[YAUser currentUser] objectForKey:nPhone];
}

- (NSString*)serverId {
    return [[YAUser currentUser] objectForKey:nUserId];
}

- (NSString*)deviceToken {
    return [[YAUser currentUser] objectForKey:YA_DEVICE_TOKEN];
}

#pragma mark - iMessage
- (void)iMessageWithFriends:(NSArray*)friendNumbers group:(YAGroup*)group withCompletion:(completionBlock)completion {
    if(!friendNumbers.count && completion) {
        completion(nil);
        return;
    }
    if(![MFMessageComposeViewController canSendText]) {
        if(completion) {
            NSError *error = [NSError errorWithDomain:@"YAGA" code:0 userInfo:nil];
            completion(error);
        }
        return;
    }
    
    NSString *message = [NSString stringWithFormat:NSLocalizedString(@"iMESSAGE_COME_JOIN_ME_TEXT", @""), group.name];
    
    MFMessageComposeViewController *messageController = [[MFMessageComposeViewController alloc] init];
    messageController.messageComposeDelegate = self;
    [messageController setRecipients:friendNumbers];
    [messageController setBody:message];
    
    // Present message view controller on screen
    [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:messageController animated:YES completion:^{
        if(completion)
            completion(nil);
    }];
}

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult) result
{
    switch (result) {
        case MessageComposeResultCancelled: {
            [[Mixpanel sharedInstance] track:@"iMessage cancelled"];
            break;
        }
        case MessageComposeResultFailed:
        {
            [[Mixpanel sharedInstance] track:@"iMessage failed"];
            [YAUtils showNotification:@"failed to send message" type:YANotificationTypeError];
            break;
        }
            
        case MessageComposeResultSent:
            [[Mixpanel sharedInstance] track:@"iMessage sent"];
            [YAUtils showNotification:@"message sent" type:YANotificationTypeSuccess];
            break;
            
        default:
            break;
    }
    
    [[UIApplication sharedApplication].keyWindow.rootViewController dismissViewControllerAnimated:YES completion:nil];
}

- (BOOL)assetsFolderSizeExceeded {
    return [self sizeOfCachesFolder] > 500 * 1024 * 1024;
}

- (void)purgeOldVideos {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        RLMResults *videos = [YAVideo objectsWhere:@"mp4Filename != '' OR gifFilename != '' OR jpgFilename != ''"];
        RLMResults *videosByDate = [videos sortedResultsUsingProperty:@"localCreatedAt" ascending:YES];
        
        while([self assetsFolderSizeExceeded]) {

            [[RLMRealm defaultRealm] beginWriteTransaction];
            
            if(!videosByDate.count) {
                [self purgeUnusedAssets];
                return;
            }
            
            //RLMResults are updated live so no need to read them again
            YAVideo *videoToPurge = [videosByDate objectAtIndex:0];
            [videoToPurge purgeLocalAssets];
            
            DLog(@"assets deleted for old video from: %@", videoToPurge.localCreatedAt);
            
            [[RLMRealm defaultRealm] commitWriteTransaction];
        }
    });
}

- (unsigned long long)sizeOfCachesFolder {
    NSString *cachesDir = [YAUtils cachesDirectory];
    NSArray *files = [[NSFileManager defaultManager] subpathsOfDirectoryAtPath:cachesDir error:nil];
    NSEnumerator *enumerator = [files objectEnumerator];
    NSString *fileName;
    unsigned long long size = 0;
    while (fileName = [enumerator nextObject]) {
        NSError *error;
        size += [[[NSFileManager defaultManager] attributesOfItemAtPath:[cachesDir stringByAppendingPathComponent:fileName] error:&error] fileSize];
    }
    return size;
}

- (void)purgeUnusedAssets {
    NSString *cachesDir = [YAUtils cachesDirectory];
    NSArray *files = [[NSFileManager defaultManager] subpathsOfDirectoryAtPath:cachesDir error:nil];
    NSEnumerator *enumerator = [files objectEnumerator];
    NSString *fileName;
    NSFileManager *fileMgr = [NSFileManager defaultManager];
    
    while (fileName = [enumerator nextObject]) {
        if([fileName.pathExtension isEqualToString:@"mp4"] || [fileName.pathExtension isEqualToString:@"gif"] || [fileName.pathExtension isEqualToString:@"jpg"]) {
            NSError *error;
            NSURL *url = [NSURL fileURLWithPath:cachesDir];
            url = [url URLByAppendingPathComponent:fileName];
            [fileMgr removeItemAtURL:url error:&error];
        }
    }
}

#pragma mark -
- (BOOL)hasUnviewedVideosInGroups {
    for(YAGroup *group in [YAGroup allObjects]) {
        if(group.hasUnviewedVideos)
            return YES;
    }
    return NO;
}
@end
