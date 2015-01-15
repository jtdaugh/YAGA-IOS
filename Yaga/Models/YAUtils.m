//
//  YAUtils.m
//  Yaga
//
//  Created by valentinkovalski on 12/16/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import "YAUtils.h"
#import "NBPhoneNumberUtil.h"
#import <CommonCrypto/CommonDigest.h>
#import "YAUser.h"

@implementation YAUtils

+ (NSString *)readableNumberFromString:(NSString*)input {
    NBPhoneNumberUtil *phoneUtil = [NBPhoneNumberUtil sharedInstance];
    NSError *aError = nil;
    NBPhoneNumber *myNumber = [phoneUtil parse:input defaultRegion:@"US" error:&aError];
    NSString *num = [phoneUtil format:myNumber numberFormat:NBEPhoneNumberFormatNATIONAL error:&aError];
    return num;
}

+ (UIColor*)inverseColor:(UIColor*)color {
    CGFloat r,g,b,a;
    [color getRed:&r green:&g blue:&b alpha:&a];
    return [UIColor colorWithRed:1.-r green:1.-g blue:1.-b alpha:a];
}

+ (NSString*)cachesDirectory {
    NSArray *cachePaths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    return cachePaths[0];
}

+ (NSString *)uniqueId {
    NSString *input = [[NSUUID UUID] UUIDString];
    const char *cstr = [input cStringUsingEncoding:NSUTF8StringEncoding];
    NSData *data = [NSData dataWithBytes:cstr length:input.length];
    uint8_t digest[CC_SHA256_DIGEST_LENGTH];
    
    // This is an iOS5-specific method.
    // It takes in the data, how much data, and then output format, which in this case is an int array.
    CC_SHA256(data.bytes, (CC_LONG)data.length, digest);
    
    NSMutableString* output = [NSMutableString stringWithCapacity:CC_SHA256_DIGEST_LENGTH * 2];
    
    // Parse through the CC_SHA256 results (stored inside of digest[]).
    for(int i = 0; i < CC_SHA256_DIGEST_LENGTH; i++) {
        [output appendFormat:@"%02x", digest[i]];
    }
    
    return output;
}

+ (NSURL*)urlFromFileName:(NSString*)fileName {
    if(!fileName.length)
        return nil;
    
    NSString *path = [[YAUtils cachesDirectory] stringByAppendingPathComponent:fileName];
    return [NSURL fileURLWithPath:path];
}

+ (void)showNotification:(NSString*)message type:(AZNotificationType)type {
    [AZNotification showNotificationWithTitle:message controller:[UIApplication sharedApplication].keyWindow.rootViewController
                             notificationType:type
                                 startedBlock:nil];
}

+ (BOOL)validatePhoneNumber:(NSString*)value error:(NSError **)error {
    NBPhoneNumberUtil *phoneUtil = [NBPhoneNumberUtil sharedInstance];

    NBPhoneNumber *myNumber = [phoneUtil parse:value
                                 defaultRegion:[YAUser currentUser].countryCode error:error];
    
    if(error && *error)
        return NO;
//
//    
//    [phoneUtil format:myNumber numberFormat:NBEPhoneNumberFormatE164 error:error];
//    
//    if(*error)
//        return NO;
    
    
    return [phoneUtil isValidNumber:myNumber];
}

+ (UIView*)createBackgroundViewWithFrame:(CGRect)frame alpha:(CGFloat)alpha {
    UIView *bkgView = [[UIView alloc] initWithFrame:frame];
    bkgView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    bkgView.backgroundColor = [PRIMARY_COLOR colorWithAlphaComponent:alpha];
    return bkgView;
}


+ (UIImage *)imageWithColor:(UIColor *)color {
    CGRect rect = CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

@end
