//
//  CContact.h
//  Pic6
//
//  Created by Raj Vir on 7/14/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MTLModel.h"
#import "MTLJSONAdapter.h"

@interface CContact : MTLModel <MTLJSONSerializing>
@property (strong, nonatomic) NSString *name;
@property (strong, nonatomic) NSString *firstName;
@property (strong, nonatomic) NSString *number;
@property (strong, nonatomic) NSNumber *registered;
- (NSString *) readableNumber;
@end