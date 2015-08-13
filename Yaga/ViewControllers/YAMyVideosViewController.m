//
//  YAAllMyVideosViewController.m
//  
//
//  Created by valentinkovalski on 8/10/15.
//
//

#import "YAMyVideosViewController.h"
#import "YAStandardFlexibleHeightBar.h"

@interface YAMyVideosViewController ()

@property (nonatomic, strong) YAStandardFlexibleHeightBar *flexibleNavBar;

@end

@implementation YAMyVideosViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.flexibleNavBar = [YAStandardFlexibleHeightBar emptyStandardFlexibleBar];
    self.flexibleNavBar.titleLabel.text = @"My Videos";
    [self.view addSubview:self.flexibleNavBar];
    
    // Do any additional setup after loading the view.
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
