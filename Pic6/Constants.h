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

#define VIEW_HEIGHT ([[UIScreen mainScreen] applicationFrame].size.height + (([UIApplication sharedApplication].statusBarHidden)?0:20))
#define VIEW_WIDTH [[UIScreen mainScreen] applicationFrame].size.width

#define NUM_TILES 96
#define TILE_WIDTH (VIEW_WIDTH/2)
#define TILE_HEIGHT VIEW_HEIGHT/4

#define ENLARGED_MULTIPLIER 1.85

#define ENLARGED_WIDTH TILE_WIDTH*ENLARGED_MULTIPLIER
#define ENLARGED_HEIGHT TILE_HEIGHT*ENLARGED_MULTIPLIER

#define LOADER_WIDTH 4
#define LOADER_HEIGHT 4

#define MAX_VIDEO_DURATION 10.0 

//emerald: rgb(26, 188, 156)
//sunflower: rgb(241, 196, 15)
//pomegranite: rgb(192, 57, 43)
//wisteria: rgba(142, 68, 173)
//amethyst: rgb(155, 89, 182)

#define PRIMARY_COLOR [UIColor colorWithRed: 236.0f/255.0f green: 0.0f/255.0f blue:140.0f/255.0f alpha:1.0]
#define PRIMARY_COLOR_ACCENT [UIColor blackColor]
#define SECONDARY_COLOR [UIColor colorWithRed: 5.0f/255.0f green: 135.0f/255.0f blue:195.0f/255.0f alpha:1.0]
#define TERTIARY_COLOR [UIColor colorWithRed: 139.0f/255.0f green: 5.0f/255.0f blue:195.0f/255.0f alpha:1.0]

#define BIG_FONT @"Avenir"

#define VERSION @"3"
#define NODE_NAME [NSString stringWithFormat: @"v%@/%@", VERSION, @"production"]
#define MEDIA @"media"
#define DATA @"data"
#define STREAM @"stream"
#define REACTIONS @"reactions"
#define TEMP @"temp"

#define ARC4RANDOM_MAX 0x100000000

#define MIXPANEL_TOKEN @"YOUR_TOKEN"

#define BASE_API_URL @"http://10.0.1.164:5000"
//#define BASE_API_URL @"http://54.68.135.210:5000"

#define RECORD_INSTRUCTION @"Tap and hold to record"

#endif
