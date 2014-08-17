//
//  NSString+Hash.h
//  Pic6
//
//  Created by Raj Vir on 7/5/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//
#define SALT @"CliqueMotherFucker"
@interface NSString (Hash)
+ (NSString *) hashString :(NSString *) data withSalt: (NSString *) salt;
- (NSString *) crypt;
@end