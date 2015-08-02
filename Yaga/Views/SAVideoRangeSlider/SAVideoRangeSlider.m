//
//  SAVideoRangeSlider.m
//
// This code is distributed under the terms and conditions of the MIT license.
//
// Copyright (c) 2013 Andrei Solovjev - http://solovjev.com/
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "SAVideoRangeSlider.h"

@interface SAVideoRangeSlider ()

@property (nonatomic, strong) AVAssetImageGenerator *imageGenerator;
@property (nonatomic, strong) UIView *bgView;
@property (nonatomic, strong) UIView *centerView;
@property (nonatomic, strong) NSURL *videoUrl;
@property (nonatomic, strong) SASliderLeft *leftThumb;
@property (nonatomic, strong) SASliderRight *rightThumb;
@property (nonatomic, strong) UIView *currentPositionView;

@property (nonatomic) CGFloat leftPosition;
@property (nonatomic) CGFloat rightPosition;

@property (nonatomic) CGFloat frame_width;
@property (nonatomic) NSTimeInterval durationSeconds;

@property (nonatomic, strong) UIView *darkenLeftView;
@property (nonatomic, strong) UIView *darkenRightView;

@property (nonatomic, readonly) CGFloat thumbnailFrameWidth;
@property (nonatomic, readonly) CGFloat framesCount;
@end

@implementation SAVideoRangeSlider

- (id)initWithFrame:(CGRect)frame videoUrl:(NSURL *)videoUrl duration:(NSTimeInterval)duration leftSeconds:(NSTimeInterval)leftSeconds rightSeconds:(NSTimeInterval)rightSeconds{
    
    self = [super initWithFrame:frame];
    if (self) {
        
        _frame_width = frame.size.width;
        
        int thumbWidth = ceil(frame.size.width*0.05);
        
        _bgView = [[UIControl alloc] initWithFrame:CGRectMake(thumbWidth, 0, frame.size.width-(thumbWidth*2), frame.size.height)];
        _bgView.layer.cornerRadius = 0;
        _bgView.clipsToBounds = YES;
        [self addSubview:_bgView];
        
        _darkenLeftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, _bgView.frame.size.height)];
        _darkenLeftView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.7];
        _darkenLeftView.layer.zPosition = 100;
        [_bgView addSubview:_darkenLeftView];

        _darkenRightView = [[UIView alloc] initWithFrame:CGRectMake(_bgView.frame.origin.x, 0, 0, _bgView.frame.size.height)];
        _darkenRightView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.7];
        _darkenRightView.layer.zPosition = 100;
        [_bgView addSubview:_darkenRightView];

        _videoUrl = videoUrl;
        
        _currentPositionView = [[UIView alloc] initWithFrame:CGRectMake(thumbWidth-1, -2, 2, self.bounds.size.height + 4)];
        _currentPositionView.backgroundColor = [UIColor whiteColor];
        [self addSubview:_currentPositionView];
        
        _leftThumb = [[SASliderLeft alloc] initWithFrame:CGRectMake(0, 0, thumbWidth, frame.size.height)];
        _leftThumb.contentMode = UIViewContentModeLeft;
        _leftThumb.userInteractionEnabled = YES;
        _leftThumb.clipsToBounds = YES;
        _leftThumb.backgroundColor = [UIColor clearColor];
        _leftThumb.layer.borderWidth = 0;
        [self addSubview:_leftThumb];
        
        UIPanGestureRecognizer *leftPan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleLeftPan:)];
        [_leftThumb addGestureRecognizer:leftPan];
        
        _rightThumb = [[SASliderRight alloc] initWithFrame:CGRectMake(0, 0, thumbWidth, frame.size.height)];
        
        _rightThumb.contentMode = UIViewContentModeRight;
        _rightThumb.userInteractionEnabled = YES;
        _rightThumb.clipsToBounds = YES;
        _rightThumb.backgroundColor = [UIColor clearColor];
        [self addSubview:_rightThumb];
        
        UIPanGestureRecognizer *rightPan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleRightPan:)];
        [_rightThumb addGestureRecognizer:rightPan];
        
        _durationSeconds = duration;
        _rightPosition = MIN(_bgView.frame.size.width * (rightSeconds / duration), _bgView.frame.size.width );
        _leftPosition = _bgView.frame.size.width  * (leftSeconds / duration);
        
        _centerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
        _centerView.backgroundColor = [UIColor clearColor];
        [self addSubview:_centerView];
        
//        UIPanGestureRecognizer *centerPan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleCenterPan:)];
//        [_centerView addGestureRecognizer:centerPan];
        
        _thumbnailFrameWidth = ceil(frame.size.height * (9.f/16.f));
        _framesCount = ceil(self.bgView.frame.size.width / self.thumbnailFrameWidth);
        
        [self generateThumbsAsync];
    }
    
    return self;
}


- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

#pragma mark - Gestures

- (void)handleLeftPan:(UIPanGestureRecognizer *)gesture
{
    if (gesture.state == UIGestureRecognizerStateBegan || gesture.state == UIGestureRecognizerStateChanged) {
        
        CGPoint translation = [gesture translationInView:self];
        
        _leftPosition += translation.x;
        if (_leftPosition < 0) {
            _leftPosition = 0;
        }
        
        if ((self.maxInterval > 0) && (self.rightSliderPositionSeconds-self.leftSliderPositionSeconds > self.maxInterval)) {
            // Pan the whole trim view if they want to pan left beyond the max range
            _rightPosition += translation.x;
        } else if ((self.minInterval > 0) && (self.rightSliderPositionSeconds-self.leftSliderPositionSeconds < self.minInterval)) {
            _leftPosition -= translation.x;
            return;
        }
        
        [gesture setTranslation:CGPointZero inView:self];
        
        [self setPlayerProgress:0]; // since player will start over from dragged position.
        [self setNeedsLayout];

        if ([_delegate respondsToSelector:@selector(rangeSliderDidMoveLeftSlider:)]){
            [_delegate rangeSliderDidMoveLeftSlider:self];
        }
        
    }
    
    //_popoverBubble.alpha = 1;
    
    [self setTimeLabel];
    
    if (gesture.state == UIGestureRecognizerStateEnded){
        if ([_delegate respondsToSelector:@selector(rangeSliderDidEndMoving:)]){
            [_delegate rangeSliderDidEndMoving:self];
        }
    }
}


- (void)handleRightPan:(UIPanGestureRecognizer *)gesture
{
    if (gesture.state == UIGestureRecognizerStateBegan || gesture.state == UIGestureRecognizerStateChanged) {
        
        
        CGPoint translation = [gesture translationInView:self];
        _rightPosition += translation.x;
        if (_rightPosition < 0) {
            _rightPosition = 0;
        }
        
        if (_rightPosition > _bgView.frame.size.width){
            _rightPosition = _bgView.frame.size.width;
        }
        
        if (_rightPosition-_leftPosition <= 0){
            _rightPosition -= translation.x;
            return;
        }
        
        if ((self.maxInterval > 0) && (self.rightSliderPositionSeconds-self.leftSliderPositionSeconds > self.maxInterval)){
            // Pan the whole trim view if they want to pan right beyond the max range
            _leftPosition += translation.x;
        } else if ((self.minInterval > 0) && (self.rightSliderPositionSeconds-self.leftSliderPositionSeconds < self.minInterval)) {
            _rightPosition -= translation.x;
            return;
        }
        
        
        [gesture setTranslation:CGPointZero inView:self];
        
        [self setPlayerProgress:0]; // since player will start over from dragged position.
        [self setNeedsLayout];

        if ([_delegate respondsToSelector:@selector(rangeSliderDidMoveRightSlider:)]){
            [_delegate rangeSliderDidMoveRightSlider:self];
        }
    }
    
    [self setTimeLabel];
    
    if (gesture.state == UIGestureRecognizerStateEnded){
        if ([_delegate respondsToSelector:@selector(rangeSliderDidEndMoving:)]){
            [_delegate rangeSliderDidEndMoving:self];
        }
    }
}


- (void)handleCenterPan:(UIPanGestureRecognizer *)gesture
{
    if (gesture.state == UIGestureRecognizerStateBegan || gesture.state == UIGestureRecognizerStateChanged) {
        
        CGPoint translation = [gesture translationInView:self];
        
        _leftPosition += translation.x;
        _rightPosition += translation.x;
        
        if (_rightPosition > _frame_width || _leftPosition < 0){
            _leftPosition -= translation.x;
            _rightPosition -= translation.x;
        }
        
        
        [gesture setTranslation:CGPointZero inView:self];
        
        [self setNeedsLayout];
        
        if ([_delegate respondsToSelector:@selector(rangeSliderDidMoveLeftSlider:)]){
            [_delegate rangeSliderDidMoveLeftSlider:self];
        }
        
    }
    
    [self setTimeLabel];
    
    if (gesture.state == UIGestureRecognizerStateEnded){
        if ([_delegate respondsToSelector:@selector(rangeSliderDidEndMoving:)]){
            [_delegate rangeSliderDidEndMoving:self];
        }
    }
}

- (void)layoutSubviews
{
    CGFloat inset = _leftThumb.frame.size.width / 2;
    
    _leftThumb.center = CGPointMake(_leftThumb.frame.size.width + _leftPosition-inset, _leftThumb.frame.size.height/2);
    
    _rightThumb.center = CGPointMake(_leftThumb.frame.size.width + _rightPosition+inset, _rightThumb.frame.size.height/2);
    
    _centerView.frame = CGRectMake(_leftThumb.frame.origin.x + _leftThumb.frame.size.width, _centerView.frame.origin.y, _rightThumb.frame.origin.x - _leftThumb.frame.origin.x - _leftThumb.frame.size.width, _centerView.frame.size.height);
    
    _darkenLeftView.frame = CGRectMake(0, 0, _leftPosition, _bgView.frame.size.height);
    _darkenRightView.frame = CGRectMake(_rightPosition, 0, _bgView.frame.size.width - _rightPosition, _bgView.frame.size.height);
}

#pragma mark - Video

-(void)generateThumbsAsync{
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        AVAsset *myAsset = [[AVURLAsset alloc] initWithURL:weakSelf.videoUrl options:nil];
        weakSelf.imageGenerator = [AVAssetImageGenerator assetImageGeneratorWithAsset:myAsset];
        
        if ([weakSelf isRetina]){
            weakSelf.imageGenerator.maximumSize = CGSizeMake(weakSelf.bgView.frame.size.width*[UIScreen mainScreen].scale, weakSelf.bgView.frame.size.height*[UIScreen mainScreen].scale);
        } else {
            weakSelf.imageGenerator.maximumSize = CGSizeMake(weakSelf.bgView.frame.size.width, weakSelf.bgView.frame.size.height);
        }
        
        __block NSError *error;
        for (NSUInteger i = 0; i < self.framesCount; i++) {
            
            CGFloat currentTime = i * self.thumbnailFrameWidth;
            CMTime timeFrame = CMTimeMakeWithSeconds(weakSelf.durationSeconds*currentTime/weakSelf.bgView.frame.size.width, 600);
            
            CGImageRef imageRef = [weakSelf.imageGenerator copyCGImageAtTime:timeFrame actualTime:nil error:&error];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf addThumbnail:imageRef atIndex:i];
                CGImageRelease(imageRef);
                if (i == weakSelf.framesCount - 1) {
                    [weakSelf setNeedsLayout];
                }
            });
        }
    });
}

- (void)addThumbnail:(CGImageRef)imageRef atIndex:(NSUInteger)index {
    UIImage *image;
    
    if ([self isRetina]){
        image = [[UIImage alloc] initWithCGImage:imageRef scale:[UIScreen mainScreen].scale orientation:UIImageOrientationUp];
    } else {
        image = [[UIImage alloc] initWithCGImage:imageRef];
    }
    
    UIImageView *thumbImageView = [[UIImageView alloc] initWithImage:image];
    
    CGRect currentFrame = thumbImageView.frame;
    currentFrame.origin.x = index * self.thumbnailFrameWidth;
    
    currentFrame.size.width = self.thumbnailFrameWidth;
    
    if( index == self.framesCount - 1){
        currentFrame.size.width -= 6;
    }
    thumbImageView.frame = currentFrame;
    int all = (index + 1) * thumbImageView.frame.size.width;
    
    if (all > self.bgView.frame.size.width){
        int delta = all - self.bgView.frame.size.width;
        currentFrame.size.width -= delta;
    }
    
    thumbImageView.contentMode = UIViewContentModeScaleAspectFill;
    thumbImageView.layer.masksToBounds = YES;
    
    [self.bgView addSubview:thumbImageView];
    
    //add darken view
    UIView *view = [[UIView alloc] initWithFrame:thumbImageView.bounds];
    view.backgroundColor = [UIColor blackColor];
    view.alpha = 0;
    [thumbImageView addSubview:view];
}

#pragma mark - Properties

- (CGFloat)leftSliderPositionSeconds
{
    return (_leftPosition / _bgView.frame.size.width) * _durationSeconds;
}


- (CGFloat)rightSliderPositionSeconds
{
    return (_rightPosition / _bgView.frame.size.width) * _durationSeconds;
}

- (void)setLeftSliderPositionSeconds:(CGFloat)leftPositionSeconds {
    _leftPosition = _durationSeconds ? (leftPositionSeconds / _durationSeconds) * _bgView.frame.size.width : 0;
    [self setNeedsLayout];
}

- (void)setRightSliderPositionSeconds:(CGFloat)rightPositionSeconds {
    _rightPosition = MIN((_durationSeconds ? (rightPositionSeconds / _durationSeconds) : 1) * _bgView.frame.size.width, _bgView.frame.size.width);
    [self setNeedsLayout];
}

-(void) setTimeLabel{
    self.bubleText.text = [self trimIntervalStr];
    //NSLog([self timeDuration1]);
    //NSLog([self timeDuration]);
}


-(NSString *)trimDurationStr{
    int delta = floor(self.rightPosition - self.leftPosition);
    return [NSString stringWithFormat:@"%d", delta];
}


-(NSString *)trimIntervalStr{
    
    NSString *from = [self timeToStr:self.leftPosition];
    NSString *to = [self timeToStr:self.rightPosition];
    return [NSString stringWithFormat:@"%@ - %@", from, to];
}

- (void)setPlayerProgress:(CGFloat)progress {
    CGFloat totalWidth = self.rightThumb.frame.origin.x - self.leftThumb.frame.origin.x - self.leftThumb.frame.size.width - 1;
    CGFloat currentPositionX = self.leftThumb.frame.origin.x + self.leftThumb.frame.size.width + totalWidth * progress;
    self.currentPositionView.frame = CGRectMake(currentPositionX, self.currentPositionView.frame.origin.y, self.currentPositionView.frame.size.width, self.currentPositionView.frame.size.height);
}

#pragma mark - Helpers

- (NSString *)timeToStr:(CGFloat)time
{
    // time - seconds
    NSInteger min = floor(time / 60);
    NSInteger sec = floor(time - min * 60);
    NSString *minStr = [NSString stringWithFormat:min >= 10 ? @"%lu" : @"0%lu", min];
    NSString *secStr = [NSString stringWithFormat:sec >= 10 ? @"%lu" : @"0%lu", sec];
    return [NSString stringWithFormat:@"%@:%@", minStr, secStr];
}


-(BOOL)isRetina{
    return ([[UIScreen mainScreen] respondsToSelector:@selector(displayLinkWithTarget:selector:)] &&
            
            ([UIScreen mainScreen].scale >= 2.0));
}


@end
