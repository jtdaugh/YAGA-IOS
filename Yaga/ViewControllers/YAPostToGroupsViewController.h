//
//  YAPostToGroupsViewController.h
//  Yaga
//
//  Created by valentinkovalski on 8/14/15.
//  Copyright © 2015 Raj Vir. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface YAPostToGroupsViewController : UIViewController<UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) NSDictionary *settings;

- (void)addNewlyCreatedGroupToList:(YAGroup *)group;
- (BOOL)blockCameraPresentationOnBackground;

@end
