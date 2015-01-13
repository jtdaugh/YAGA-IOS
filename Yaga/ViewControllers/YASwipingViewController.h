//
//  ViewController.h
//  testReuse
//
//  Created by valentinkovalski on 1/9/15.
//  Copyright (c) 2015 test. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Realm/Realm.h>

@interface YASwipingViewController : UIViewController<UIScrollViewDelegate>
@property (nonatomic, strong) UIScrollView *scrollView;

- (id)initWithVideos:(RLMResults*)videos andInitialIndex:(NSUInteger)initialIndex;
@end

