//
//  UIImage+Resize.m
//  Pic6
//
//  Created by Raj Vir on 4/27/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import "UIImage+Colors.h"

@implementation UIImage (Colors)

- (NSArray *) getColors {
    CFDataRef pixelData = CGDataProviderCopyData(CGImageGetDataProvider(self.CGImage));
    CGFloat width = self.size.width;
    CGFloat height = self.size.height;
    const UInt8* data = CFDataGetBytePtr(pixelData);
    
    NSLog(@"width: %f, height:%f", width, height);
    
    NSMutableArray *colors = [[NSMutableArray alloc] init];
    for(int i = 0; i < 16; i++){
        int col = i % 4;
        int row = i / 4;
        
        CGFloat x = col * (width/4) + width/8;
        CGFloat y = row * (height/4) + height/8;
        
        NSLog(@"x: %f, y: %f", x, y);
        
        int pixelInfo = (int) ((width * y) + x) * 4;
        
        UInt8 blue = data[pixelInfo];         // If you need this info, enable it
        UInt8 green = data[(pixelInfo + 1)]; // If you need this info, enable it
        UInt8 red = data[pixelInfo + 2];    // If you need this info, enable it
        
        UIColor* color = [UIColor colorWithRed:red/255.0f green:green/255.0f blue:blue/255.0f alpha:255.0f/255.0f]; // The pixel color info
        
        [colors addObject:[color hexStringValue]];
        NSLog(@"color as string: %@", [color closestColorName]);
    }
    
    return colors;
}

@end
