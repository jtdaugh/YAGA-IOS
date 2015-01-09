//
//  YAServer+HostManagment.m
//  Yaga
//
//  Created by Iegor on 1/4/15.
//  Copyright (c) 2015 Raj Vir. All rights reserved.
//

#import "YAServer+HostManagment.h"
#include <arpa/inet.h>


@implementation YAServer (HostManagment)
+ (unsigned int)sockAddrFromHost:(NSString*)host
{
    Boolean result;
    CFHostRef hostRef;
    CFArrayRef addresses;
    NSString *hostname;
    if ([host hasPrefix:@"https://"]) hostname = [host substringFromIndex:8];
    if ([host hasPrefix:@"http://"]) hostname = [host substringFromIndex:7];
    //hostname = @"apple.com";
    CFStreamError error;
    hostRef = CFHostCreateWithName(kCFAllocatorDefault, (__bridge CFStringRef)hostname);
    if (hostRef) {
        result = CFHostStartInfoResolution(hostRef, kCFHostAddresses, &error); // pass an error instead of NULL here to find out why it failed
        if (result == TRUE) {
            addresses = CFHostGetAddressing(hostRef, &result);
            
            CFDataRef saData = (CFDataRef)CFArrayGetValueAtIndex(addresses, 0);
            struct sockaddr_in* remoteAddr = (struct sockaddr_in*)CFDataGetBytePtr(saData);

            if(remoteAddr != NULL){
                // Extract the ip address
                unsigned int intIP41 = remoteAddr->sin_addr.s_addr;
                NSLog(@"HOST IP ADDRESS IS: %s", inet_ntoa(remoteAddr->sin_addr));
                CFRelease(hostRef);
                return intIP41;
            }
            CFRelease(hostRef);
            return 0;
        }
        CFRelease(hostRef);
        return 0;
    }
    return 0;
}
@end
