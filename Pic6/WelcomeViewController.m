//
//  SplashViewController.m
//  Pic6
//
//  Created by Raj Vir on 7/15/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import "WelcomeViewController.h"
#import "LoginViewController.h"
#import "SignupViewController.h"
#import "AVPlayer+AVPlayer_Async.h"
#import "TileCell.h"
#import "NSString+Hash.h"

@implementation WelcomeViewController

- (void)viewWillAppear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:YES animated:YES];
}

- (void)viewDidLoad {

    NSLog(@"yooo splashery, %@", [@"+13107753248" crypt]);
    
    [self.view setBackgroundColor:[UIColor whiteColor]];
    
    UIView *plaque = [[UIView alloc] initWithFrame:CGRectMake(0, TILE_HEIGHT, TILE_WIDTH, TILE_HEIGHT)];
    [plaque setBackgroundColor:PRIMARY_COLOR];
    [self.view addSubview:plaque];
    
    UILabel *logo = [[UILabel alloc] init];
    [logo setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
    logo.translatesAutoresizingMaskIntoConstraints = NO;
    [logo setText:APP_NAME];
    [logo setFont:[UIFont fontWithName:BIG_FONT size:28]];
    [logo setTextColor:[UIColor whiteColor]];
    [logo setTextAlignment:NSTextAlignmentCenter];
    [plaque addSubview:logo];
    
    UILabel *slogan = [[UILabel alloc] init];
    [slogan setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
    slogan.translatesAutoresizingMaskIntoConstraints = NO;
    [slogan setText:@"Wacky videos with groups of friends"];
    [slogan setFont:[UIFont fontWithName:BIG_FONT size:16]];
    [slogan setTextColor:[UIColor whiteColor]];
    [slogan setTextAlignment:NSTextAlignmentCenter];
    [slogan setNumberOfLines:0];
    [plaque addSubview:slogan];
    
    NSDictionary *views = NSDictionaryOfVariableBindings(logo, slogan);
    [plaque addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[logo]|" options:0 metrics:nil views:views]];
    [plaque addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-5-[slogan]-5-|" options:0 metrics:nil views:views]];
    [plaque addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-20-[logo]-12-[slogan]" options:0 metrics:nil views:views]];

    self.container = [[UIView alloc] initWithFrame:CGRectMake(0, 0, VIEW_WIDTH, VIEW_HEIGHT)];
    [self.view addSubview:self.container];

    UIButton *loginButton = [UIButton buttonWithType:UIButtonTypeSystem];
    loginButton.frame = CGRectMake(0, TILE_HEIGHT*2, TILE_WIDTH, TILE_HEIGHT);
    [loginButton addTarget:self action:@selector(loginPressed) forControlEvents:UIControlEventTouchUpInside];
    [loginButton setTitle:@"Log In" forState:UIControlStateNormal];
    [loginButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [loginButton.titleLabel setFont:[UIFont fontWithName:BIG_FONT size:28]];
    [loginButton setBackgroundColor:SECONDARY_COLOR];
    [self.view addSubview:loginButton];
    
    UIButton *signupButton = [UIButton buttonWithType:UIButtonTypeSystem];
    signupButton.frame = CGRectMake(TILE_WIDTH, TILE_HEIGHT*2, TILE_WIDTH, TILE_HEIGHT);
    [signupButton addTarget:self action:@selector(signupPressed) forControlEvents:UIControlEventTouchUpInside];
    [signupButton setTitle:@"Sign Up" forState:UIControlStateNormal];
    [signupButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
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
    LoginViewController *vc = [[LoginViewController alloc] init];
    [vc setTitle:@"Log In"];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)signupPressed {
    SignupViewController *vc = [[SignupViewController alloc] init];
    [vc setTitle:@"Sign Up"];
//    [self.navigationController pushViewController:vc animated:YES];
    [self.navigationController pushViewController:vc animated:YES];
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
