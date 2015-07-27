//
//  ShareViewController.h
//  YAVideoShareExtension
//
//  Created by Christopher Wendel on 7/16/15.
//  Copyright (c) 2015 Raj Vir. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface YAShareVideoViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UITextViewDelegate, UIGestureRecognizerDelegate>

@property (nonatomic, strong) NSItemProvider *itemProvider;

@property (nonatomic, strong) NSArray *groups;

@end
