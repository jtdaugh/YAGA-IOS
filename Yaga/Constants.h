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
#define THIN_FONT @"HelveticaNeue-UltraLight"

//notifications
#define VIDEO_ADDED_NOTIFICATION            @"VIDEO_ADDED_NOTIFICATION"
#define VIDEO_CHANGED_NOTIFICATION          @"VIDEO_CHANGED_NOTIFICATION"
#define VIDEO_WILL_DELETE_NOTIFICATION      @"VIDEO_WILL_DELETE_NOTIFICATION"
#define VIDEO_DID_DELETE_NOTIFICATION       @"VIDEO_DID_DELETE_NOTIFICATION"

#define defaultUsername @"Yaga user"

#endif
