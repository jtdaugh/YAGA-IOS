//
//  NSDictionary+ResponseObject.h
//  Yaga
//
//  Created by Iegor on 12/17/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDictionary (ResponseObject)
+ (NSDictionary *)dictionaryFromResponseObject:(id)responseObject withError:(NSError *)error;
@end
