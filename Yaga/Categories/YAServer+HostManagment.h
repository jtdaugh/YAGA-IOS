//
//  YAServer+HostManagment.h
//  Yaga
//
//  Created by Iegor on 1/4/15.
//  Copyright (c) 2015 Raj Vir. All rights reserved.
//

#import "YAServer.h"

@interface YAServer (HostManagment)
+ (unsigned int)sockAddrFromHost:(NSString*)host;
@end
