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

- (void)prepareForReuse
{
    [super prepareForReuse];
    
    self.playerVC = nil;
    //self.gifView.alpha = 0;
    //self.gifView.animatedImage = nil;
    self.movFilename = nil;
}

//- (void)layoutSubviews {
//    [super layoutSubviews];
//    if(self.layoutIndex != 0 && !self.playerVC) {
//        self.gifView.alpha = 0;
//        AVPlaybackViewController* vc = [[AVPlaybackViewController alloc] init];
//        
//        [vc setURL:[YAUtils urlFromFileName:self.movFilename]];
//        self.playerVC = vc;
//        
//        [self.playerVC playWhenReady];
//    }
//}
//
//- (void)applyLayoutAttributes:(UICollectionViewLayoutAttributes *)layoutAttributes
//{
//    [super applyLayoutAttributes:layoutAttributes];
//    [self layoutIfNeeded];
//}

@end

