//
//  YAShareViewController.h
//  Yaga
//
//  Created by valentinkovalski on 6/12/15.
//  Copyright (c) 2015 Raj Vir. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "YAVideo.h"

@interface YASharingViewController : UIViewController<UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) YAVideo *video;
@end
