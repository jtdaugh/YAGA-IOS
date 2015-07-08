//
//  YAShareViewController.h
//  Yaga
//
//  Created by valentinkovalski on 6/12/15.
//  Copyright (c) 2015 Raj Vir. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "YAVideo.h"
#import "YAVideoPage.h"

@interface YASharingView : UIView<UITableViewDataSource, UITableViewDelegate>
@property (weak, nonatomic) YAVideoPage *page;
@property (nonatomic, strong) UITapGestureRecognizer *crosspostTapOutRecognizer;

- (id)initWithFrame:(CGRect)frame video:(YAVideo *)video;

- (void)setTopButtonsHidden:(BOOL)hidden animated:(BOOL)animated;

@end
