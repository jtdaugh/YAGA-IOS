//
//  Constants.h
//  Pic6
//
//  Created by Raj Vir on 4/30/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#ifndef Pic6_Constants_h
#define Pic6_Constants_h

#define APP_NAME @"Yaga"

#define NUM_TILES 96
#define TILE_WIDTH ([[UIScreen mainScreen] bounds].size.width)/2
#define TILE_HEIGHT ([[UIScreen mainScreen] bounds].size.height)/4

#define ENLARGED_MULTIPLIER 1.85

#define ENLARGED_WIDTH TILE_WIDTH*ENLARGED_MULTIPLIER
#define ENLARGED_HEIGHT TILE_HEIGHT*ENLARGED_MULTIPLIER

#define VIEW_HEIGHT ([[UIScreen mainScreen] bounds].size.height)
#define VIEW_WIDTH ([[UIScreen mainScreen] bounds].size.width)

#define LOADER_WIDTH 4
#define LOADER_HEIGHT 4

//emerald: rgb(26, 188, 156)
//sunflower: rgb(241, 196, 15)
//pomegranite: rgb(192, 57, 43)
//wisteria: rgba(142, 68, 173)
//amethyst: rgb(155, 89, 182)

#define PRIMARY_COLOR [UIColor colorWithRed: 255.0f/255.0f green: 168.0f/255.0f blue:0.0f/255.0f alpha:1.0]
#define SECONDARY_COLOR [UIColor colorWithRed: 5.0f/255.0f green: 135.0f/255.0f blue:195.0f/255.0f alpha:1.0]
#define TERTIARY_COLOR [UIColor colorWithRed: 139.0f/255.0f green: 5.0f/255.0f blue:195.0f/255.0f alpha:1.0]

#define BIG_FONT @"Avenir-Light"

#define VERSION @"2"
#define NODE_NAME [NSString stringWithFormat: @"v%@/%@", VERSION, @"production"]
#define MEDIA @"media"
#define DATA @"data"
#define STREAM @"stream"
#define REACTIONS @"reactions"
#define TEMP @"temp"

#define ARC4RANDOM_MAX 0x100000000

#define MIXPANEL_TOKEN @"YOUR_TOKEN"

#endif
