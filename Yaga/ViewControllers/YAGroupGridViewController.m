//
//  YAGroupGridViewController.m
//  Yaga
//
//  Created by Jesse on 8/12/15.
//  Copyright (c) 2015 Raj Vir. All rights reserved.
//

#import "YAGroupGridViewController.h"
#import "YAGroup.h"
#import "BLKFlexibleHeightBar.h"
#import "YAProfileFlexibleHeightBar.h"

@interface YAGroupGridViewController ()

@property (nonatomic,strong) UILabel *groupNameLabel;
@property (nonatomic,strong) UILabel *groupDescriptionLabel;
@property (nonatomic,strong) UILabel *groupViewsLabel;
@property (nonatomic,strong) UIButton *followButton;
@property (nonatomic,strong) UIButton *backButton;

@end

@implementation YAGroupGridViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)backPressed {
    [self.navigationController popViewControllerAnimated:YES];
}

- (BLKFlexibleHeightBar *)createNavBar {
    YAProfileFlexibleHeightBar *bar = [YAProfileFlexibleHeightBar emptyProfileBar];
    bar.nameLabel.text = self.group.name;
    bar.descriptionLabel.text = @"Hosted by Arauh";
    bar.viewsLabel.text = @"456 followers      123,543 views";
    [bar.backButton addTarget:self action:@selector(backPressed) forControlEvents:UIControlEventTouchUpInside];
    [bar.moreButton addTarget:self action:@selector(openGroupOptions) forControlEvents:UIControlEventTouchUpInside];
    
    return bar;
}

//- (CGSize)collectionView:(UICollectionView *)collectionView
//                  layout:(UICollectionViewLayout*)collectionViewLayout
//    referenceSizeForHeaderInSection:(NSInteger)section{
//    return CGSizeMake(VIEW_WIDTH, 200);
//}

//- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
//    [super scrollViewDidScroll:scrollView];
//    if ([scrollView isEqual:self.collectionView]) {
//        CGFloat offset = scrollView.contentOffset.y;
//        CGFloat headerScrollProgress;
//        DLog(@"ContentOffset: %f", offset);
//        if (offset < 0) {
//            // header is expanded. do nothing
//            headerScrollProgress = 1;
//        } else if (offset < (kHeaderHeight - kNavBarHeight)) {
//            // stuff needs to be adjusted
//            headerScrollProgress = 1.0 - (offset / (kHeaderHeight - kNavBarHeight));
//        } else {
//            headerScrollProgress = 0;
//        }
//        [self updateHeaderViewsWithProgress:headerScrollProgress];
//    }
//}
//
//// 0.0 means fully collapsed, 1.0 means fully expanded
//- (void)updateHeaderViewsWithProgress:(CGFloat)progress {
//    self.followButton.alpha = pow(progress, 20); // higher pow fades earlier
//    self.groupViewsLabel.alpha = pow(progress, 6);
//    self.groupDescriptionLabel.alpha = pow(progress, 3);
//    CGRect frame = self.groupNameLabel.frame;
//    frame.origin.y = kTitleOriginCollapsed + (progress * (kTitleOriginExpanded - kTitleOriginCollapsed));
//    self.groupNameLabel.frame = frame;
//    self.groupNameLabel.font = [UIFont fontWithName:BIG_FONT size:(kTitleMaxFont - 10 + (10.0 * progress))];
//    
//}


@end
