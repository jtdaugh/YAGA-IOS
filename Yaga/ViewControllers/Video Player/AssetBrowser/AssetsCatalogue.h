//
//  AssetsCatalogue.h
//  MyVideoPlayer
//
//  Created by valentinkovalski on 12/21/14.
//
//

#import <Foundation/Foundation.h>
#import "AssetBrowserSource.h"

@interface AssetsCatalogue : NSObject<AssetBrowserSourceDelegate>

+ (AssetsCatalogue *)sharedInstance;

@property (nonatomic, strong) NSMutableDictionary *playersByUrl;
@property (nonatomic, strong) NSMutableArray *compAssets;

//camera roll
@property (nonatomic, strong) NSArray *cameraRollItems;

@property (nonatomic, assign) BOOL cameraRoll;
@end

