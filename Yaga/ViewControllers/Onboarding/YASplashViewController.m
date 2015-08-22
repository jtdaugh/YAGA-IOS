//
//  YASplashViewController.m
//  Yaga
//
//  Created by Raj Vir on 8/21/15.
//  Copyright (c) 2015 Raj Vir. All rights reserved.
//

#import "YASplashViewController.h"

@interface YASplashViewController ()<UIScrollViewDelegate>

@property (strong, nonatomic) UIButton *nextButton;

@property (strong, nonatomic) UIScrollView *scrollView;
@property (strong, nonatomic) UIPageControl *pageControl;
@property (strong, nonatomic) UIImageView *logo;


@end

@implementation YASplashViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self.navigationItem setHidesBackButton:YES];
    [self.navigationController setNavigationBarHidden:YES];
    
    CGFloat scrollViewOrigin = (VIEW_HEIGHT - VIEW_WIDTH)/2;
    self.scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, scrollViewOrigin, VIEW_WIDTH, VIEW_WIDTH)];
    [self.scrollView setContentSize:CGSizeMake(self.scrollView.frame.size.width * 3, self.scrollView.frame.size.height)];
    [self.scrollView setPagingEnabled:YES];
    self.scrollView.delegate = self;
    [self.scrollView setShowsHorizontalScrollIndicator:NO];
    [self.view addSubview:self.scrollView];

    
    [self.view setBackgroundColor:PRIMARY_COLOR];
    
    CGFloat buttonHeight = VIEW_HEIGHT * .1;
    CGFloat buttonPadding = 48;
    CGFloat buttonWidth = VIEW_WIDTH - buttonPadding*2;
    CGFloat origin = self.view.frame.origin.y;
    
    self.nextButton = [[UIButton alloc] initWithFrame:CGRectMake((VIEW_WIDTH-buttonWidth)/2, VIEW_HEIGHT - origin - buttonPadding - buttonHeight, buttonWidth, buttonHeight)];
    
    CGFloat scrollViewBottom = self.scrollView.frame.origin.y + self.scrollView.frame.size.height;
    self.nextButton.center = CGPointMake(VIEW_WIDTH/2, scrollViewBottom + (VIEW_HEIGHT - scrollViewBottom)/2);
    
    [self.nextButton addTarget:self action:@selector(nextStep) forControlEvents:UIControlEventTouchUpInside];
    [self.nextButton.titleLabel setFont:[UIFont fontWithName:BOLD_FONT size:28]];
    [self.nextButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [self.nextButton setBackgroundColor:[UIColor whiteColor]];
    
    self.nextButton.layer.cornerRadius = buttonHeight/2;
    self.nextButton.layer.masksToBounds = YES;
    
    [self.nextButton setTitle:@"Get Started" forState:UIControlStateNormal];

    [self.view addSubview:self.nextButton];
    
    self.logo = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, VIEW_WIDTH, scrollViewOrigin * .8)];
    
    self.logo.center = CGPointMake(VIEW_WIDTH/2, scrollViewOrigin/2);
    
    [self.logo setImage:[UIImage imageNamed:@"Logo"]];
    [self.logo setContentMode:UIViewContentModeScaleAspectFit];
    [self.view addSubview:self.logo];
    
    NSMutableArray *views = [[NSMutableArray alloc] init];
    
    for(int i = 0; i<3; i++){
        CGRect frame = self.scrollView.bounds;
        frame.origin.x = i*frame.size.width;
        
        UIImageView *v = [[UIImageView alloc] initWithFrame:frame];
        [v setContentMode:UIViewContentModeScaleAspectFit];
        [v setImage:[UIImage imageNamed:[NSString stringWithFormat:@"o%i", i+1]]];
        
//        [v setBackgroundColor:[UIColor colorWithWhite:i*.5 alpha:1.0]];
        
        [views addObject:v];
        [self.scrollView addSubview:v];
        
    }
    
    self.pageControl = [[UIPageControl alloc] initWithFrame:CGRectMake(0, self.scrollView.frame.origin.y + self.scrollView.frame.size.height + 5, VIEW_WIDTH, 30)];
    self.pageControl.currentPage = 0;
    self.pageControl.numberOfPages = 3;
    [self.pageControl setUserInteractionEnabled:NO];
    [self.view addSubview:self.pageControl];
}

- (void)viewDidAppear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:YES animated:YES];
}

- (void)nextStep {
    [self performSegueWithIdentifier:@"PhoneNumberViewController" sender:self];
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat width = scrollView.frame.size.width;
    float xPos = scrollView.contentOffset.x+10;
    
    //Calculate the page we are on based on x coordinate position and width of scroll view
    self.pageControl.currentPage = (int)xPos/width;
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
