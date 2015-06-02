//
//  NSArray+Reverse.h
//  Yaga
//
//  Created by Jesse on 6/1/15.
//  Copyright (c) 2015 Raj Vir. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSArray (Reverse)
- (NSArray *)reversedArray;
@end

@interface NSMutableArray (Reverse)
- (void)reverse;
@end