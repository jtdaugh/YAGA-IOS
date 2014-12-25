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
        self.gifView.alpha = 0;
        playerVC.view.alpha = 0;
        
        playerVC.view.frame = self.bounds;

        [self.contentView addSubview:playerVC.view];
       // playerVC.view.transform = CGAffineTransformMakeScale(1.1, 1.1);
        [UIView animateWithDuration:0.3 animations:^{
           // playerVC.view.transform = CGAffineTransformIdentity;

            playerVC.view.alpha = 1;
        }];
        
    }
    else {
        [_playerVC.view removeFromSuperview];
        [self.contentView addSubview:self.gifView];
        [UIView animateWithDuration:0.3 animations:^{
            self.gifView.alpha = 1;
        }];
    }
    
    _playerVC = playerVC;
}
@end

