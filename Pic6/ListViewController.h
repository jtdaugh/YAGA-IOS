//
//  ListViewController.h
//  Pic6
//
//  Created by Raj Vir on 8/14/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GridViewController.h"

@interface ListViewController : GridViewController <UICollectionViewDataSource, UICollectionViewDelegate>
@property (strong, nonatomic) NSNumber *appeared;
@property (strong, nonatomic) NSNumber *setup;
@property (strong, nonatomic) UICollectionView *groups;
@property (strong, nonatomic) NSNumber *scrolling;

@end
