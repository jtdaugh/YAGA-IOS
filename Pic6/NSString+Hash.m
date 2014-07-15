//
//  NSString+File.m
//  Pic6
//
//  Created by Raj Vir on 7/5/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import "NSString+Hash.h"
#import <CommonCrypto/CommonHMAC.h>

@implementation NSString (Hash)

- (NSString *)sha1 {
    return [self hashString:self withSalt:SALT];
}

-(NSString *) hashString :(NSString *) data withSalt: (NSString *) salt {
    
    const char *cKey  = [salt cStringUsingEncoding:NSUTF8StringEncoding];
    const char *cData = [data cStringUsingEncoding:NSUTF8StringEncoding];
    unsigned char cHMAC[CC_SHA256_DIGEST_LENGTH];
    CCHmac(kCCHmacAlgSHA256, cKey, strlen(cKey), cData, strlen(cData), cHMAC);
    
    NSString *hash;
    
    NSMutableString* output = [NSMutableString stringWithCapacity:CC_SHA256_DIGEST_LENGTH * 2];
    
    for(int i = 0; i < CC_SHA256_DIGEST_LENGTH; i++)
        [output appendFormat:@"%02x", cHMAC[i]];
    hash = output;
    return hash;
    
}

@end
