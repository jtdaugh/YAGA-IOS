//
//  TiCell.m
//  MyVideoPlayer
//
//  Created by valentinkovalski on 12/18/14.
//
//

#import "YAVideoCell.h"
#import "YAUtils.h"

@implementation YAVideoCell

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if(self) {
        _gifView = [[FLAnimatedImageView alloc] initWithFrame:self.bounds];
        _gifView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        
        [self.contentView addSubview:self.gifView];
        self.contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    }
    return self;
}

- (void)dealloc {

}

- (void)setPlayerVC:(AVPlaybackViewController *)playerVC {
    if(_playerVC == playerVC)
        return;
    
    if(playerVC) {
        playerVC.view.frame = self.bounds;
        [self.contentView addSubview:playerVC.view];
        [self.gifView removeFromSuperview];
    }
    else {
        [_playerVC.view removeFromSuperview];
        [self.contentView addSubview:self.gifView];
    }
    
    _playerVC = playerVC;
}
@end

