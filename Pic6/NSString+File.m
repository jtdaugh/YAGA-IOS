//
//  NSString+File.m
//  Pic6
//
//  Created by Raj Vir on 7/5/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import "NSString+File.h"

@implementation NSString (File)

- (NSURL *) movieUrl {
    NSString *moviePath = [[NSString alloc] initWithFormat:@"%@%@.mov", NSTemporaryDirectory(), self];
    NSURL *movieURL = [[NSURL alloc] initFileURLWithPath:moviePath];
    return movieURL;
}

- (NSURL *) imageUrl {
    NSString *imagePath = [[NSString alloc] initWithFormat:@"%@%@.jpg", NSTemporaryDirectory(), self];
    NSURL *imageURL = [[NSURL alloc] initFileURLWithPath:imagePath];
    return imageURL;
}

@end
