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
#import "SquareCashStyleBehaviorDefiner.h"

#define kNavBarHeight 44.0
#define kHeaderHeight 200.0
#define kTitleOriginCollapsed 20.0
#define kTitleOriginExpanded 40.0
#define kTitleMaxFont 30.0

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
    [self.navigationController setNavigationBarHidden:YES animated:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)backPressed {
    [self.navigationController popViewControllerAnimated:YES];
}

- (BLKFlexibleHeightBar *)createNavBar {
    BLKFlexibleHeightBar *bar = [[BLKFlexibleHeightBar alloc] initWithFrame:CGRectMake(0.0, 0.0, self.view.frame.size.width, kHeaderHeight)];
    bar.minimumBarHeight = 60;
    bar.backgroundColor = SECONDARY_COLOR;
    bar.behaviorDefiner = [SquareCashStyleBehaviorDefiner new];
    
    UILabel *groupNameLabel = [UILabel new];
    groupNameLabel.font = [UIFont fontWithName:BIG_FONT size:kTitleMaxFont];
    groupNameLabel.textColor = [UIColor whiteColor];
    groupNameLabel.textAlignment = NSTextAlignmentCenter;
    [bar addSubview:groupNameLabel];
    BLKFlexibleHeightBarSubviewLayoutAttributes *nameExpanded = [BLKFlexibleHeightBarSubviewLayoutAttributes new];
    nameExpanded.frame = CGRectMake(20, kTitleOriginExpanded, VIEW_WIDTH-40, 30);
    [groupNameLabel addLayoutAttributes:nameExpanded forProgress:0.0];
    BLKFlexibleHeightBarSubviewLayoutAttributes *nameCollapsed = [BLKFlexibleHeightBarSubviewLayoutAttributes new];
    nameCollapsed.frame = CGRectMake(20, kTitleOriginCollapsed, VIEW_WIDTH-40, 30);
    nameCollapsed.transform = CGAffineTransformMakeScale(0.6, 0.6);
    [groupNameLabel addLayoutAttributes:nameCollapsed forProgress:1.0];
    
    
    UILabel *descriptionLabel = [UILabel new];
    descriptionLabel.font = [UIFont fontWithName:BIG_FONT size:16];
    descriptionLabel.textColor = [UIColor whiteColor];
    descriptionLabel.textAlignment = NSTextAlignmentCenter;
    [bar addSubview:descriptionLabel];
    BLKFlexibleHeightBarSubviewLayoutAttributes *descriptionExpanded = [BLKFlexibleHeightBarSubviewLayoutAttributes new];
    descriptionExpanded.frame = CGRectMake(20, kTitleOriginExpanded + 30, VIEW_WIDTH-40, 30);
    descriptionExpanded.alpha = 1;
    [descriptionLabel addLayoutAttributes:descriptionExpanded forProgress:0.0];
    BLKFlexibleHeightBarSubviewLayoutAttributes *descriptionCollapsed = [[BLKFlexibleHeightBarSubviewLayoutAttributes alloc] initWithExistingLayoutAttributes:descriptionExpanded];
    descriptionCollapsed.alpha = 0.0;
    [descriptionLabel addLayoutAttributes:descriptionCollapsed forProgress:1.0];
//    
//    UILabel *viewsLabel = [UILabel new];
//    viewsLabel.font = [UIFont fontWithName:BIG_FONT size:16];
//    viewsLabel.textColor = [UIColor whiteColor];
//    viewsLabel.textAlignment = NSTextAlignmentCenter;
//    [bar addSubview:viewsLabel];
//    
//    CGFloat btnWidth = 140;
//    UIButton *followButton = [UIButton new];
//    followButton.backgroundColor = [UIColor clearColor];
//    [followButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
//    [followButton setTitle:@"Follow" forState:UIControlStateNormal];
//    followButton.layer.borderColor = [[UIColor whiteColor] CGColor];
//    followButton.titleLabel.font = [UIFont fontWithName:BIG_FONT size:18];
//    followButton.layer.borderWidth = 2;
//    followButton.layer.cornerRadius = 10;
//    [bar addSubview:followButton];
//    
//    UIButton *backButton = [UIButton new];
//    backButton.imageEdgeInsets = UIEdgeInsetsMake(10, 10, 10, 10);
//    backButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
//    [backButton setImage:[UIImage imageNamed:@"Back"] forState:UIControlStateNormal];
//    [backButton addTarget:self action:@selector(backPressed) forControlEvents:UIControlEventTouchUpInside];
//    [bar addSubview:backButton];
//    
    groupNameLabel.text = self.group.name;
    descriptionLabel.text = @"Hosted by Arauh";
//    viewsLabel.text = @"456 followers      123,543 views";
    
    self.groupNameLabel = groupNameLabel;
    self.groupDescriptionLabel = descriptionLabel;
//    self.groupViewsLabel = viewsLabel;
//    self.followButton = followButton;
//    self.backButton = backButton;
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
