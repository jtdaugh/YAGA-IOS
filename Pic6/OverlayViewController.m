//
//  OverlayViewController.m
//  Pic6
//
//  Created by Raj Vir on 7/3/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import "OverlayViewController.h"

@interface OverlayViewController ()

@end

@implementation OverlayViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    [self.view addSubview:self.tile];
    [self.tile.player setVolume:1.0];

    self.userLabel = [[UILabel alloc] initWithFrame:CGRectMake(8, TILE_HEIGHT*3 + 16, TILE_WIDTH, 48)];
    [self.userLabel setTextAlignment:NSTextAlignmentLeft];
    [self.userLabel setTextColor:[UIColor whiteColor]];
    [self.userLabel setFont:[UIFont systemFontOfSize:36]];
    [self.userLabel setText:self.tile.username];
    [self.userLabel setAlpha:0.0];
    [self.view addSubview:self.userLabel];
    
    [UIView animateWithDuration:0.5 delay:0 usingSpringWithDamping:0.7 initialSpringVelocity:0.7 options:0 animations:^{
        [self.userLabel setAlpha:1.0];
    } completion:^(BOOL finished) {
        //
    }];
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapped:)];
    [self.view addGestureRecognizer:tap];
    // Do any additional setup after loading the view.
}

- (void)tapped:(UITapGestureRecognizer *)gesture {
    [self.tile.player setVolume:0.0];
    [self.previousViewController.overlay addSubview:self.tile];
    [self dismissViewControllerAnimated:NO completion:^{
        [self.previousViewController collapse:self.tile];
    }];
    
}

- (void)willEnterForeground {
    [self dismissViewControllerAnimated:NO completion:^{
        [self.previousViewController collapse:self.tile];
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
