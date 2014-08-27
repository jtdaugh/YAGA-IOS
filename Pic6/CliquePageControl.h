//
//  CliquePageControl.h
//  Pic6
//
//  Created by Veeral Patel on 8/24/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CliquePageControl : UIView

@property (nonatomic, strong) NSString *groupTitle;
@property (nonatomic) NSInteger currentPage;
@property (nonatomic) NSInteger numberOfPages;

@end
