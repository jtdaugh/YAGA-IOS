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
#define TILE_HEIGHT (VIEW_HEIGHT/4)

#define ENLARGED_MULTIPLIER 1.85

#define ENLARGED_WIDTH TILE_WIDTH*ENLARGED_MULTIPLIER
#define ENLARGED_HEIGHT TILE_HEIGHT*ENLARGED_MULTIPLIER

#define LOADER_WIDTH 4
#define LOADER_HEIGHT 4

#define MAX_VIDEO_DURATION 8.0 

#define ELEVATOR_MARGIN 50.0

#define PRIMARY_COLOR [UIColor colorWithRed: 236.0f/255.0f green: 0.0f/255.0f blue:140.0f/255.0f alpha:1.0]
#define PRIMARY_COLOR_ACCENT [UIColor blackColor]
#define SECONDARY_COLOR [UIColor colorWithRed: 5.0f/255.0f green: 135.0f/255.0f blue:195.0f/255.0f alpha:1.0]
#define TERTIARY_COLOR [UIColor colorWithRed: 139.0f/255.0f green: 5.0f/255.0f blue:195.0f/255.0f alpha:1.0]

#define BIG_FONT @"Avenir"

//notifications
#define NEW_VIDEO_TAKEN_NOTIFICATION @"NEW_VIDEO_TAKEN_NOTIFICATION"
#define RELOAD_VIDEO_NOTIFICATION @"RELOAD_VIDEO_NOTIFICATION"
#define DELETE_VIDEO_NOTIFICATION @"DELETE_VIDEO_NOTIFICATION"

#endif
