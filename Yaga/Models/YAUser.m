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
#import "YAImageCache.h"
#import "YAUtils.h"

#define YA_CURRENT_GROUP_ID @"current_group_id"

@implementation YAUser

+ (YAUser*)currentUser {
    static YAUser *sharedUser = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedUser = [[self alloc] init];
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
        
        NSString *selectedGroupId = [[NSUserDefaults standardUserDefaults] objectForKey:YA_CURRENT_GROUP_ID];
        if(selectedGroupId) {
            self.currentGroup = [YAGroup objectInRealm:[RLMRealm defaultRealm] forPrimaryKey:selectedGroupId];
        }
        
        //create phonebook
        [self importContactsWithCompletion:nil excludingPhoneNumbers:nil];
    }
    return self;
}

- (void)setCurrentGroup:(YAGroup *)group {
    if(self.currentGroup) {
        //thumbnails cache will clean itself automatically        
        //stop all jobs for current group
        [[YAAssetsCreator sharedCreator] stopAllJobsForGroup:self.currentGroup];
    }
    
    [[NSUserDefaults standardUserDefaults] setObject:group.localId forKey:YA_CURRENT_GROUP_ID];
    _currentGroup = group;
    
    [[YAAssetsCreator sharedCreator] createAssetsForGroup:self.currentGroup];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:REFRESH_GROUP_NOTIFICATION object:[self currentGroup]];
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
    
    [addressBook loadContactsOnQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0) completion:^(NSArray *contacts, NSError *error) {
        if (!error){
            NSMutableArray *result = [NSMutableArray new];
            _phonebook = [NSMutableDictionary new];
            
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
                    
                    if(![excludePhonesSet containsObject:num])
                        [result addObject:item];
                    
                    [self.phonebook setObject:item forKey:num];
                }
            }
            if(completion)
                completion(nil, result);
        }
        else
        {
            if(completion)
                completion([NSError errorWithDomain:@"NO DOMAIN" code:0 userInfo:nil], nil);
        }
    }];
}


- (NSString*)formatDate:(NSDate*)date {
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

- (NSString*)deviceToken {
    return [[YAUser currentUser] objectForKey:YA_DEVICE_TOKEN];
}

#pragma mark - iMessage
- (void)iMessageWithFriends:(NSArray*)friendNumbers withCompletion:(completionBlock)presentedBlock {
    if(![MFMessageComposeViewController canSendText]) {
        if(presentedBlock) {
            NSError *error = [NSError errorWithDomain:@"YAGA" code:0 userInfo:nil];
            presentedBlock(error);
        }
        
        return;
    }
    
    NSString *message = [NSString stringWithFormat:NSLocalizedString(@"iMESSAGE_COME_JOIN_ME_TEXT", @""), self.currentGroup.name];
    
    MFMessageComposeViewController *messageController = [[MFMessageComposeViewController alloc] init];
    messageController.messageComposeDelegate = self;
    [messageController setRecipients:friendNumbers];
    [messageController setBody:message];
    [messageController setSubject:@"Yaga"];
    
    // Present message view controller on screen
    [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:messageController animated:YES completion:^{
        if(presentedBlock)
            presentedBlock(nil);
    }];
}

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult) result
{
    switch (result) {
        case MessageComposeResultCancelled:
            break;
            
        case MessageComposeResultFailed:
        {
            [YAUtils showNotification:@"failed to send message" type:AZNotificationTypeError];
            break;
        }
            
        case MessageComposeResultSent:
            [YAUtils showNotification:@"message sent" type:AZNotificationTypeSuccess];
            break;
            
        default:
            break;
    }
    
    [[UIApplication sharedApplication].keyWindow.rootViewController dismissViewControllerAnimated:YES completion:nil];
}

@end
