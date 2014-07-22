//
//  SplashViewController.m
//  Pic6
//
//  Created by Raj Vir on 7/15/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import "SplashViewController.h"
#import "LoginViewController.h"
#import "SignupViewController.h"
#import "AVPlayer+AVPlayer_Async.h"
#import "TileCell.h"

@implementation SplashViewController

- (void)viewWillAppear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:YES animated:YES];
}

- (void)viewDidLoad {
    NSLog(@"yooo splashery");
    
    [self.view setBackgroundColor:[UIColor whiteColor]];
    
    self.title = @" ";
    
    UIView *plaque = [[UIView alloc] initWithFrame:CGRectMake(0, TILE_HEIGHT, TILE_WIDTH, TILE_HEIGHT)];
    [plaque setBackgroundColor:PRIMARY_COLOR];
    
    UILabel *logo = [[UILabel alloc] initWithFrame:CGRectMake(20, 12, TILE_WIDTH - 40, 50)];
    [logo setText:APP_NAME];
    [logo setFont:[UIFont fontWithName:BIG_FONT size:28]];
    [logo setTextColor:[UIColor whiteColor]];
    [logo setTextAlignment:NSTextAlignmentCenter];
    [plaque addSubview:logo];
    
    UILabel *slogan = [[UILabel alloc] initWithFrame:CGRectMake(30, 48, TILE_WIDTH - 60, 80)];
    [slogan setText:@"Share your life with your inner circle"];
    [slogan setFont:[UIFont fontWithName:BIG_FONT size:16]];
    [slogan setTextColor:[UIColor whiteColor]];
    [slogan setTextAlignment:NSTextAlignmentCenter];
    [slogan setNumberOfLines:0];
    [plaque addSubview:slogan];
    
    [self.view addSubview:plaque];

    self.container = [[UIView alloc] initWithFrame:CGRectMake(0, 0, VIEW_WIDTH, VIEW_HEIGHT)];
    [self.view addSubview:self.container];

    UIButton *loginButton = [[UIButton alloc] initWithFrame:CGRectMake(0, TILE_HEIGHT*2, TILE_WIDTH, TILE_HEIGHT)];
    [loginButton addTarget:self action:@selector(loginPressed) forControlEvents:UIControlEventTouchUpInside];
    [loginButton setTitle:@"Log In" forState:UIControlStateNormal];
    [loginButton.titleLabel setFont:[UIFont fontWithName:BIG_FONT size:28]];
    [loginButton setBackgroundColor:SECONDARY_COLOR];
    [self.view addSubview:loginButton];
    
    UIButton *signupButton = [[UIButton alloc] initWithFrame:CGRectMake(TILE_WIDTH, TILE_HEIGHT*2, TILE_WIDTH, TILE_HEIGHT)];
    [signupButton addTarget:self action:@selector(signupPressed) forControlEvents:UIControlEventTouchUpInside];
    [signupButton setTitle:@"Sign Up" forState:UIControlStateNormal];
    [signupButton.titleLabel setFont:[UIFont fontWithName:BIG_FONT size:28]];
    [signupButton setBackgroundColor:TERTIARY_COLOR];
    [self.view addSubview:signupButton];
    
    NSArray *positions = @[@0, @1, @3, @6, @7];
    for(int i = 0; i < [positions count]; i++){
        int position = [(NSNumber *)positions[i] intValue];
        TileCell *tile = [[TileCell alloc] initWithFrame:CGRectMake(position%2 * TILE_WIDTH, (position/2) * TILE_HEIGHT, TILE_WIDTH, TILE_HEIGHT)];

        NSString *filename = [NSString stringWithFormat:@"%i", i];
        
        NSString *path = [[NSBundle mainBundle] pathForResource:filename ofType:@"mp4"];
        
        tile.uid = path;
        
        [tile playLocal:path];
        [self.container addSubview:tile];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(willEnterForeground)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(willResignActive)
                                                 name:UIApplicationWillResignActiveNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didBecomeActive)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didEnterBackground)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];

}

- (void)loginPressed {
    NSLog(@"login pressed");
}

- (void)signupPressed {
    [self.navigationController pushViewController:[SignupViewController new] animated:YES];
    NSLog(@"signup pressed");
}

- (void)willResignActive {
    //    [self removeAudioInput];
    // remove microphone
    
}

- (void)didBecomeActive {
    //    [self addAudioInput];
    // add microphone
}

- (void)didEnterBackground {
    //    NSLog(@"did enter background");
}

- (void)willEnterForeground {
    NSLog(@"will enter foreground");
    
    for(TileCell *tile in self.container.subviews){
        NSLog(@"yoo tiles");
        if([[tile class] isSubclassOfClass:[TileCell class]]){
            [tile playLocal:tile.uid];
        }
    }
}

@end
