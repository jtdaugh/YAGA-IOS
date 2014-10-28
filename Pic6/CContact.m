//
//  CContact.m
//  Pic6
//
//  Created by Raj Vir on 7/14/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import "CContact.h"
#import "NBPhoneNumberUtil.h"

@implementation CContact

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    
    return @{
             @"name": @"name",
             @"firstName": @"firstName",
             @"number": @"number",
             @"registered": @"registered"
             };
}

- (NSString *)readableNumber {
    NBPhoneNumberUtil *phoneUtil = [NBPhoneNumberUtil sharedInstance];
    NSError *aError = nil;
    NBPhoneNumber *myNumber = [phoneUtil parse:self.number
                                 defaultRegion:@"US" error:&aError];
    NSString *num = [phoneUtil format:myNumber numberFormat:NBEPhoneNumberFormatNATIONAL error:&aError];
    return num;
}

@end
