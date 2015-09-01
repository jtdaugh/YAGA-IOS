//
//  YAChannelsViewController.h
//  Yaga
//
//  Created by valentinkovalski on 8/28/15.
//  Copyright © 2015 Raj Vir. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "YAStandardFlexibleHeightBar.h"

@interface YAChannelsViewController : UIViewController<UISearchBarDelegate, UITableViewDataSource>
@property (nonatomic, readonly) YAStandardFlexibleHeightBar *flexibleNavBar;

@property (nonatomic, readonly) UISegmentedControl *segmentedControl;

- (void)setupNavbar;
- (void)setupSegments;
@end
