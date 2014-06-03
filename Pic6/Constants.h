//
//  Constants.h
//  Pic6
//
//  Created by Raj Vir on 4/30/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#ifndef Pic6_Constants_h
#define Pic6_Constants_h

#define NUM_TILES 12
#define TILE_WIDTH 640/4
#define TILE_HEIGHT 1136/8

#define ENLARGED_MULTIPLIER 1.85

#define ENLARGED_WIDTH TILE_WIDTH*ENLARGED_MULTIPLIER
#define ENLARGED_HEIGHT TILE_HEIGHT*ENLARGED_MULTIPLIER

#define CAROUSEL_MULTIPLIER ENLARGED_MULTIPLIER //1.75

#define CAROUSEL_WIDTH TILE_WIDTH*CAROUSEL_MULTIPLIER
#define CAROUSEL_HEIGHT TILE_HEIGHT*CAROUSEL_MULTIPLIER

#define CAROUSEL_MARGIN 5
#define CAROUSEL_GUTTER (VIEW_WIDTH - ENLARGED_WIDTH - CAROUSEL_MARGIN*2)/2

#define VIEW_HEIGHT [[UIScreen mainScreen] applicationFrame].size.height //568 //self.view.frame.size.height
#define VIEW_WIDTH [[UIScreen mainScreen] applicationFrame].size.width //320 //self.view.frame.size.width

#define LOADER_WIDTH 4
#define LOADER_HEIGHT 4

//emerald: rgb(26, 188, 156)
//sunflower: rgb(241, 196, 15)
//pomegranite: rgb(192, 57, 43)
//wisteria: rgba(142, 68, 173)
//amethyst: rgb(155, 89, 182)

#define PRIMARY_COLOR [UIColor colorWithRed: 142.0f/255.0f green: 68.0f/255.0f blue:173.0f/255.0f alpha:1.0]
#define SECONDARY_COLOR [UIColor colorWithRed: 241.0f/255.0f green: 196.0f/255.0f blue:15.0f/255.0f alpha:1.0]

#define NODE_NAME @"production4"
#define MEDIA @"media"
#define DATA @"data"
#define REACTIONS @"reactions"
#define TEMP @"temp"

#define MediaTypePhoto @"photo"
#define MediaTypeVideo @"video"

#define ARC4RANDOM_MAX 0x100000000

#endif
