//
//  CollectionViewController.h
//  MyVideoPlayer
//
//  Created by valentinkovalski on 12/18/14.
//
//

#import <UIKit/UIKit.h>
#import "AssetBrowserSource.h"

@interface YACollectionViewController : UIViewController<UICollectionViewDataSource, UICollectionViewDelegate, AssetBrowserSourceDelegate> {
    CGPoint lastOffset;
    NSTimeInterval lastOffsetCapture;
    BOOL isScrollingFast;
}

@property (strong, nonatomic) UICollectionView *collectionView;
@property (nonatomic) BOOL scrolling;

@end
