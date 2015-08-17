//
//  AddMembersViewController.h
//  Pic6
//
//  Created by Raj Vir on 10/14/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "YAUser.h"
#import "VENTokenField.h"

@interface YAGroupAddMembersViewController : UIViewController<UITableViewDataSource, UITableViewDelegate, VENTokenFieldDelegate, VENTokenFieldDataSource>

@property (strong, nonatomic) YAGroup *existingGroup;
@property (readonly, nonatomic) NSMutableArray *selectedContacts;

@property (nonatomic, assign) BOOL inCreateGroupFlow;
@property (nonatomic, assign) BOOL publicGroup;
@property (nonatomic, copy) NSString *groupName;

@property (nonatomic, assign) YAVideo *initialVideo;

- (BOOL)blockCameraPresentationOnBackground;

@end
