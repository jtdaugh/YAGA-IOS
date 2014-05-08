//
//  Constants.h
//  Pic6
//
//  Created by Raj Vir on 4/30/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#ifndef Pic6_Constants_h
#define Pic6_Constants_h

#define NUM_TILES 6
#define TILE_WIDTH 640/4
#define TILE_HEIGHT 1136/8

#define ENLARGED_MULTIPLIER 1.75

#define ENLARGED_WIDTH TILE_WIDTH*ENLARGED_MULTIPLIER
#define ENLARGED_HEIGHT TILE_HEIGHT*ENLARGED_MULTIPLIER

#define CAROUSEL_MULTIPLIER 1.25

#define CAROUSEL_WIDTH TILE_WIDTH*CAROUSEL_MULTIPLIER
#define CAROUSEL_HEIGHT TILE_HEIGHT*CAROUSEL_MULTIPLIER

#define VIEW_HEIGHT self.view.frame.size.height
#define VIEW_WIDTH self.view.frame.size.width

#define LOADER_WIDTH 4
#define LOADER_HEIGHT 4

//rgb(26, 188, 156)
#define PRIMARY_COLOR [UIColor colorWithRed: 26.0f/255.0f green: 188.0f/255.0f blue:156.0f/255.0f alpha:1.0]

#define NODE_NAME @"dev"
#define DATA @"data"
#define POSTS @"posts"

#define ARC4RANDOM_MAX 0x100000000

#endif
