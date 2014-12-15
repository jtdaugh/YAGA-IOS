//
//  GroupInfo.h
//  Pic6
//
//  Created by Raj Vir on 8/15/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MTLModel.h"
#import "MTLJSONAdapter.h"

@interface GroupInfo : MTLModel <MTLJSONSerializing>
@property (strong, nonatomic) NSString *name;
@property (strong, nonatomic) NSString *groupId;
@property (strong, nonatomic) NSMutableArray *members;
@end
