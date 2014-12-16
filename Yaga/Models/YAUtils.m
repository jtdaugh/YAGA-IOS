//
//  YAUtils.m
//  Yaga
//
//  Created by valentinkovalski on 12/16/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import "YAUtils.h"
#import "NBPhoneNumberUtil.h"

@implementation YAUtils

+ (NSString *)readableNumberFromString:(NSString*)input {
    NBPhoneNumberUtil *phoneUtil = [NBPhoneNumberUtil sharedInstance];
    NSError *aError = nil;
    NBPhoneNumber *myNumber = [phoneUtil parse:input defaultRegion:@"US" error:&aError];
    NSString *num = [phoneUtil format:myNumber numberFormat:NBEPhoneNumberFormatNATIONAL error:&aError];
    return num;
}
@end
