//
//  ShareViewController.m
//  YAVideoShareExtension
//
//  Created by Christopher Wendel on 7/16/15.
//  Copyright (c) 2015 Raj Vir. All rights reserved.
//

#import "YAShareVideoViewController.h"
#import "YAVideoPlayerView.h"
#import <MobileCoreServices/MobileCoreServices.h>

@interface YAShareVideoViewController ()

@property (nonatomic, weak) IBOutlet YAVideoPlayerView *playerView;

@end

@implementation YAShareVideoViewController

#pragma mark - View setup

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self loadExtensionItem];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

#pragma mark - Extensions

- (void)loadExtensionItem {
    NSExtensionItem *item = self.extensionContext.inputItems[0];
    NSItemProvider *itemProvider = item.attachments[0];
    
    if ([itemProvider hasItemConformingToTypeIdentifier:(NSString *)kUTTypeMovie]) {
        [itemProvider loadItemForTypeIdentifier:(NSString *)kUTTypeMovie options:nil completionHandler:^(NSURL *movieURL, NSError *error) {
            
            if (movieURL) {
                [self prepareVideoForPlaying:movieURL];
                
                self.playerView.playWhenReady = YES;
            }
        }];
    }
}

#pragma mark - Video

- (void)prepareVideoForPlaying:(NSURL *)movUrl {
    self.playerView.URL = movUrl;
}

@end
