//
//  YACreateGroupNavigationController.m
//  Yaga
//
//  Created by Christopher Wendel on 7/12/15.
//  Copyright (c) 2015 Raj Vir. All rights reserved.
//

#import "YACreateGroupNavigationController.h"

@interface YACreateGroupNavigationController ()

@end

@implementation YACreateGroupNavigationController

- (void)viewDidLoad {
    [super viewDidLoad];
 
    // Do any additional setup after loading the view.
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self.view endEditing:YES];
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
}

@end
