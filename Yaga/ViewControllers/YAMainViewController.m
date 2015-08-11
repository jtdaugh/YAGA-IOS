//
//  YAMainViewController.m
//  
//
//  Created by valentinkovalski on 8/10/15.
//
//

#import "YAMainViewController.h"
#import "YAUtils.h"
#import "YAGroupsNavigationController.h"

@interface YAMainViewController ()

@end

@implementation YAMainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
//    [YAUtils randomQuoteWithCompletion:^(NSString *quote, NSError *error) {
//        self.navigationItem.prompt = quote;
//    }];
    
    [self addCameraButton];

    self.tabBar.itemSpacing = VIEW_WIDTH/2;
    self.tabBar.tintColor = PRIMARY_COLOR;
    self.tabBar.barTintColor = [UIColor whiteColor];

    self.tabBar.backgroundImage = [YAUtils imageWithColor:[UIColor whiteColor]];
    self.tabBar.shadowImage = [UIImage imageNamed:@"BarShadow"];
}

//- (void)viewWillAppear:(BOOL)animated {
//    
//    
//    if(self.navigationController.viewControllers.count == 1)
//        [self.navigationController setNavigationBarHidden:YES animated:YES];
//    [super viewWillAppear:animated];
//}

- (void)addCameraButton {
    
    UIButton *cameraButton = [[UIButton alloc] initWithFrame:CGRectMake((VIEW_WIDTH - CAMERA_BUTTON_SIZE)/2,
                                                                   self.view.frame.size.height -(CAMERA_BUTTON_SIZE/2),
                                                                   CAMERA_BUTTON_SIZE, CAMERA_BUTTON_SIZE)];
    cameraButton.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
    cameraButton.backgroundColor = [UIColor colorWithWhite:0.1 alpha:0.7]; // So its not clear on iOS 7
    [cameraButton setImage:[[UIImage imageNamed:@"Camera"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    cameraButton.imageView.tintColor = [UIColor whiteColor];
    cameraButton.imageEdgeInsets = UIEdgeInsetsMake(-55, 0, 0, 0);
    cameraButton.layer.cornerRadius = CAMERA_BUTTON_SIZE/2;
    cameraButton.layer.borderColor = [[UIColor whiteColor] CGColor];
    cameraButton.layer.borderWidth = 2.f;
    cameraButton.layer.masksToBounds = YES;
    [cameraButton addTarget:self action:@selector(cameraButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    
    UIVisualEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight]; // Will still be dark because of translucent black background.
    UIVisualEffectView *cameraButtonBlur = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
    cameraButtonBlur.frame = cameraButton.frame;
    cameraButtonBlur.layer.cornerRadius = CAMERA_BUTTON_SIZE/2;
    cameraButtonBlur.layer.masksToBounds = YES;
    
    [self.view addSubview:cameraButtonBlur];
    [self.view addSubview:cameraButton];
}

- (void)cameraButtonPressed {
    [(YAGroupsNavigationController*)self.navigationController presentCameraAnimated:YES];
}



@end
