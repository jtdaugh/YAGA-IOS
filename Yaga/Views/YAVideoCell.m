//
//  TiCell.m
//  MyVideoPlayer
//
//  Created by valentinkovalski on 12/18/14.
//
//

#import "YAVideoCell.h"

@implementation YAVideoCell

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if(self) {
        self.gifView = [[FLAnimatedImageView alloc] initWithFrame:self.bounds];
        self.gifView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        
        self.contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self.contentView addSubview:self.gifView];
    }
    return self;
}

- (void)setGifImage:(FLAnimatedImage *)gifImage {
    if(_gifImage == gifImage)
        return;
    _gifImage = gifImage;
    
    self.gifView.animatedImage = gifImage;
}

- (void)dealloc {
}

@end
