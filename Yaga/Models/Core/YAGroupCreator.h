//
//  YAGroupCreator.h
//  Yaga
//
//  Created by Iegor on 12/24/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YAGroup.h"

@interface YAGroupCreator : NSObject
+ (instancetype)sharedCreator;
@property (nonatomic, strong) NSNumber* groupId;

+ (YAGroup*)createGroupWithDictionary:(NSDictionary*)dictionary;
@end
