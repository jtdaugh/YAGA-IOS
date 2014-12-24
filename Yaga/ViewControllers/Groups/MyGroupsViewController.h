//
//  MyCrewsViewController.h
//  Pic6
//
//  Created by Raj Vir on 10/3/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol MyGroupsViewControllerDelegate <NSObject>
- (void)closeGroups;
@end


@interface MyGroupsViewController : UIViewController<UITableViewDataSource, UITableViewDelegate, UIGestureRecognizerDelegate> {
    NSUInteger editingIndex;
}
@property (nonatomic, strong) UITableView *tableView;

@property (nonatomic, copy) NSString *titleText;
@property (nonatomic, strong) UIColor *backgroundColor;
@property (nonatomic, assign) BOOL showEditButton;
@property (nonatomic, assign) BOOL showCreateGroupButton;
@property (nonatomic, weak) id<MyGroupsViewControllerDelegate> delegate;
@end
