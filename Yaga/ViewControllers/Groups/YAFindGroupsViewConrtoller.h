//
//  YAFindGroupsViewConrtoller.h
//  
//
//  Created by valentinkovalski on 6/18/15.
//
//

#import <UIKit/UIKit.h>
#import "YAFlexibleNavbarExtending.h"

@interface YAFindGroupsViewConrtoller : UIViewController<UISearchBarDelegate, YAFlexibleNavbarExtending>

@property (nonatomic, strong) YAStandardFlexibleHeightBar *flexibleNavBar;
@end
