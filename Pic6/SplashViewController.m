//
//  SplashViewController.m
//  Pic6
//
//  Created by Raj Vir on 7/15/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import "SplashViewController.h"
#import "LoginViewController.h"
#import "AVPlayer+AVPlayer_Async.h"
#import "TileCell.h"

@implementation SplashViewController

- (void)viewDidAppear:(BOOL)animated {
    NSLog(@"yooo splashery");
    
    [self.view setBackgroundColor:[UIColor whiteColor]];
    
    UIView *plaque = [[UIView alloc] initWithFrame:CGRectMake(0, TILE_HEIGHT, TILE_WIDTH, TILE_HEIGHT)];
    [plaque setBackgroundColor:PRIMARY_COLOR];
    [self.view addSubview:plaque];
    
    UIButton *loginButton = [[UIButton alloc] initWithFrame:CGRectMake(0, TILE_HEIGHT*2, TILE_WIDTH, TILE_HEIGHT)];
    [loginButton addTarget:self action:@selector(loginPressed) forControlEvents:UIControlEventTouchUpInside];
    [loginButton setTitle:@"Log In" forState:UIControlStateNormal];
    [loginButton.titleLabel setFont:[UIFont fontWithName:BIG_FONT size:28]];
//    [loginButton setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [loginButton setBackgroundColor:SECONDARY_COLOR];
    [self.view addSubview:loginButton];
    
    UIButton *signupButton = [[UIButton alloc] initWithFrame:CGRectMake(TILE_WIDTH, TILE_HEIGHT*2, TILE_WIDTH, TILE_HEIGHT)];
    [signupButton addTarget:self action:@selector(signupPressed) forControlEvents:UIControlEventTouchUpInside];
    [signupButton setTitle:@"Sign Up" forState:UIControlStateNormal];
    [signupButton.titleLabel setFont:[UIFont fontWithName:BIG_FONT size:28]];
    [signupButton setBackgroundColor:TERTIARY_COLOR];
    [self.view addSubview:signupButton];
    
    UIView *container = [[UIView alloc] initWithFrame:CGRectMake(0, 0, VIEW_WIDTH, VIEW_HEIGHT)];
    [self.view addSubview:container];
    
    NSArray *positions = @[@0, @1, @3, @6, @7];
    for(int i = 0; i < [positions count]; i++){
        int position = [(NSNumber *)positions[i] intValue];
        TileCell *tile = [[TileCell alloc] initWithFrame:CGRectMake(position%2 * TILE_WIDTH, (position/2) * TILE_HEIGHT, TILE_WIDTH, TILE_HEIGHT)];

        NSString *filename = [NSString stringWithFormat:@"%i", i];
        NSString *path = [[NSBundle mainBundle] pathForResource:filename ofType:@"mov"];
        
        NSLog(@"path: %@", path);
        
        [container addSubview:tile];
        
        [tile playLocal:path];
    }
}

- (void)loginPressed {
//    LoginViewController *vc = [LoginViewController new];
//    [self presentViewController:vc animated:YES completion:^{
//        //
//    }];
    [self.collectionView reloadData];
    NSLog(@"login pressed");
}

- (void)signupPressed {
    NSLog(@"signup pressed");
}

@end
