//
//  AssetsCatalogue.m
//  MyVideoPlayer
//
//  Created by valentinkovalski on 12/21/14.
//
//

#import "AssetsCatalogue.h"
#import "VideoPlayerViewController.h"

#define vidsCount 12
#define movsCount 22


@interface AssetsCatalogue ()
@property (nonatomic, strong) NSMutableDictionary *tempPlayersByUrl;
@property (nonatomic, strong) AssetBrowserSource *assetSource;

@end

@implementation AssetsCatalogue

+ (AssetsCatalogue *)sharedInstance {
    static dispatch_once_t pred;
    static AssetsCatalogue *shared = nil;
    
    dispatch_once(&pred, ^{
        shared = [[AssetsCatalogue alloc] init];
        shared.playersByUrl = [[NSMutableDictionary alloc] init];
        shared.tempPlayersByUrl = [[NSMutableDictionary alloc] init];
        shared.compAssets = [NSMutableArray new];
    });
    return shared;
}

- (id)init {
    self = [super init];
    if(self) {
        self.assetSource = [[AssetBrowserSource alloc] initWithSourceType:AssetBrowserSourceTypeCameraRoll];
        self.assetSource.delegate = self;
        
        [self.assetSource buildSourceLibrary];
        
    }
    return self;
}

#pragma mark - AssetBrowserDelegate 
- (void)assetBrowserSourceItemsDidChange:(AssetBrowserSource*)source {
    self.cameraRollItems = source.items;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"didReadCameraRoll" object:nil];
}

@end
