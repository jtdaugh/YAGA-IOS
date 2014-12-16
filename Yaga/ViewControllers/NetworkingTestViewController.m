//
//  NetworkingTestViewController.m
//  Pic6
//
//  Created by Raj Vir on 9/24/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import "NetworkingTestViewController.h"
#import "YAUser.h"

@interface NetworkingTestViewController ()
@property int index;
@end

@implementation NetworkingTestViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Add the appropriate function from CNetworking.h that gets called when tapping the button
    [self newButtonWithTitle:@"/token" withTarget:@selector(registerUser)];
    [self newButtonWithTitle:@"/crew/create" withTarget:@selector(createCrew)];
    [self newButtonWithTitle:@"/me" withTarget:@selector(meInfo)];
    [self newButtonWithTitle:@"/me/crews" withTarget:@selector(myCrews)];
}

- (UIButton *)newButtonWithTitle:(NSString *)title withTarget:(SEL)sel {
    int width = 200;
    int height = 40;
    int padding = 10;
    
    if(!self.index){ self.index = 0; }
    
    UIButton *newButton = [[UIButton alloc] initWithFrame:CGRectMake(20, 10 + (height+padding)*self.index++, width, height)];
    [newButton setTitle:title forState:UIControlStateNormal];
    [newButton addTarget:[YAUser currentUser] action:sel forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:newButton];
    return newButton;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
