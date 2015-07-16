//
//  ShareViewController.m
//  YAVideoShareExtension
//
//  Created by Christopher Wendel on 7/16/15.
//  Copyright (c) 2015 Raj Vir. All rights reserved.
//

#import "YAShareVideoViewController.h"
#import "YAVideoPlayerView.h"

@interface YAShareVideoViewController ()

@property (nonatomic, strong) YAVideoPlayerView *playerView;

@end

@implementation YAShareVideoViewController

#pragma mark - View setup

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _playerView = [YAVideoPlayerView new];
    [self.view addSubview:self.playerView];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

#pragma mark - Video

- (void)prepareVideoForPlaying:(NSString *)filename {
    NSURL *movUrl = [YAShareVideoViewController urlFromFileName:filename];
    
    if (filename.length) {
        self.playerView.URL = movUrl;
    } else {
        self.playerView.URL = nil;
    }
    
    self.playerView.frame = self.view.bounds;
}

+ (NSURL *)urlFromFileName:(NSString *)fileName {
    if(!fileName.length)
        return nil;
    
    NSString *path = [[YAShareVideoViewController cachesDirectory] stringByAppendingPathComponent:fileName];
    return [NSURL fileURLWithPath:path];
}

+ (NSString *)cachesDirectory {
    NSArray *cachePaths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    return cachePaths[0];
}
@end
