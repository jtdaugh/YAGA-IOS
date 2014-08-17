//
//  PlaqueView.m
//  Pic6
//
//  Created by Raj Vir on 8/14/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import "PlaqueView.h"

@implementation PlaqueView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        
        [self setBackgroundColor:PRIMARY_COLOR];
        
        UILabel *logo = [[UILabel alloc] initWithFrame:CGRectMake(8, 8, TILE_WIDTH-16, 36)];
        [logo setText:APP_NAME]; // 🔥
        [logo setTextColor:[UIColor whiteColor]];
        [logo setFont:[UIFont fontWithName:BIG_FONT size:30]];
        //    [self.plaque addSubview:logo];
        
        UILabel *instructions = [[UILabel alloc] initWithFrame:CGRectMake(10, 30+8+4, TILE_WIDTH-16, 60)];
        [instructions setText:@"📹 Hold to record 👉"];
        [instructions setNumberOfLines:0];
        [instructions sizeToFit];
        [instructions setTextColor:[UIColor whiteColor]];
        [instructions setFont:[UIFont fontWithName:BIG_FONT size:13]];
        //    [self.cameraAccessories addObject:instructions];
        //    [self.plaque addSubview:instructions];
        
        UIButton *switchButton = [[UIButton alloc] initWithFrame:CGRectMake(TILE_WIDTH/2, TILE_HEIGHT/2, TILE_WIDTH/2, TILE_HEIGHT/2)];
        [switchButton addTarget:self action:@selector(switchCamera:) forControlEvents:UIControlEventTouchUpInside];
        //    [self.switchButton setTitle:@"🔃" forState:UIControlStateNormal];
        //    [self.switchButton.titleLabel setFont:[UIFont systemFontOfSize:48]];
        [switchButton setImage:[UIImage imageNamed:@"Switch"] forState:UIControlStateNormal];
        [switchButton.imageView setContentMode:UIViewContentModeScaleAspectFit];
        [self.cameraAccessories addObject:switchButton];
        [self addSubview:switchButton];
        
        UIButton *cliqueButton = [[UIButton alloc] initWithFrame:CGRectMake(0, TILE_HEIGHT/2, TILE_WIDTH/2, TILE_HEIGHT/2)];
        [cliqueButton addTarget:self action:@selector(manageClique:) forControlEvents:UIControlEventTouchUpInside];
        //    [cliqueButton setTitle:@"👥" forState:UIControlStateNormal]; //🔃
        //    [cliqueButton.titleLabel setFont:[UIFont systemFontOfSize:48]];
        [cliqueButton setImage:[UIImage imageNamed:@"Clique"] forState:UIControlStateNormal];
        [cliqueButton.imageView setContentMode:UIViewContentModeScaleAspectFit];
        [self addSubview:cliqueButton];
        
        UIButton *flashButton = [[UIButton alloc] initWithFrame:CGRectMake(TILE_WIDTH/2, 0, TILE_WIDTH/2, TILE_HEIGHT/2)];
        [flashButton addTarget:self action:@selector(switchFlashMode:) forControlEvents:UIControlEventTouchUpInside];
        [flashButton setImage:[UIImage imageNamed:@"TorchOff"] forState:UIControlStateNormal];
        [flashButton.imageView setContentMode:UIViewContentModeScaleAspectFit];
        [self.cameraAccessories addObject:flashButton];
        [self addSubview:flashButton];
        
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
