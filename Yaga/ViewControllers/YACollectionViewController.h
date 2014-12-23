//
//  CollectionViewController.h
//  MyVideoPlayer
//
//  Created by valentinkovalski on 12/18/14.
//
//

#import <UIKit/UIKit.h>
#import "AssetBrowserSource.h"
#import "FICImageCache.h"

@interface YACollectionViewController : UIViewController<UICollectionViewDataSource, UICollectionViewDelegate, AssetBrowserSourceDelegate, FICImageCacheDelegate> {
    CGPoint lastOffset;
    NSTimeInterval lastOffsetCapture;
    BOOL isScrollingFast;
}

@property (nonatomic, strong) NSArray *cameraRollItems;

@property (strong, nonatomic) UICollectionView *collectionView;
@property (nonatomic) BOOL scrolling;

@end
