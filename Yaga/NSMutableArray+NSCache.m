//
//  NSMutableArray+NSCache.h
//  Yaga
//
//  Created by Jesse on 6/30/15.
//  Copyright (c) 2015 Raj Vir. All rights reserved.
//

#import "NSMutableArray+NSCache.h"

@implementation NSMutableArray (NSCache)

- (void)discardContentIfPossible {
    // do nothing
}

- (BOOL)beginContentAccess {
    return YES;
}

- (void)endContentAccess {
    // do nothing
}

- (BOOL)isContentDiscarded {
    return NO;
}

@end
