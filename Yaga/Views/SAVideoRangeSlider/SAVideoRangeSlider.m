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

@property (nonatomic) CGFloat frame_width;
@property (nonatomic) Float64 durationSeconds;

@property (nonatomic, strong) NSMutableArray *darkenViews;

@end

@implementation SAVideoRangeSlider


#define SLIDER_BORDERS_SIZE 6.0f
#define BG_VIEW_BORDERS_SIZE 3.0f


- (id)initWithFrame:(CGRect)frame videoUrl:(NSURL *)videoUrl{
    
    self = [super initWithFrame:frame];
    if (self) {
        
        _frame_width = frame.size.width;
        
        int thumbWidth = ceil(frame.size.width*0.05);
        
        _bgView = [[UIControl alloc] initWithFrame:CGRectMake(thumbWidth-BG_VIEW_BORDERS_SIZE, 0, frame.size.width-(thumbWidth*2)+BG_VIEW_BORDERS_SIZE*2, frame.size.height)];
        //        _bgView.layer.borderColor = [UIColor grayColor].CGColor;
        //        _bgView.layer.borderWidth = BG_VIEW_BORDERS_SIZE;
        _bgView.layer.cornerRadius = 5;
        _bgView.clipsToBounds = YES;
        [self addSubview:_bgView];
        
        _videoUrl = videoUrl;
        
        _currentPositionView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 2, self.bounds.size.height)];
        _currentPositionView.backgroundColor = [UIColor whiteColor];
        [self addSubview:_currentPositionView];
        
        
        _topBorder = [[UIView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, SLIDER_BORDERS_SIZE)];
        _topBorder.backgroundColor = [UIColor colorWithRed: 0.996 green: 0.951 blue: 0.502 alpha: 1];
        //[self addSubview:_topBorder];
        
        
        _bottomBorder = [[UIView alloc] initWithFrame:CGRectMake(0, frame.size.height-SLIDER_BORDERS_SIZE, frame.size.width, SLIDER_BORDERS_SIZE)];
        _bottomBorder.backgroundColor = [UIColor colorWithRed: 0.992 green: 0.902 blue: 0.004 alpha: 1];
        //[self addSubview:_bottomBorder];
        
        
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
        
        _rightPosition = frame.size.width;
        _leftPosition = 0;
        
        _centerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
        _centerView.backgroundColor = [UIColor clearColor];
        [self addSubview:_centerView];
        
        UIPanGestureRecognizer *centerPan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleCenterPan:)];
        [_centerView addGestureRecognizer:centerPan];
        
        
        //        _popoverBubble = [[SAResizibleBubble alloc] initWithFrame:CGRectMake(0, -50, 100, 50)];
        //        _popoverBubble.alpha = 0;
        //        _popoverBubble.backgroundColor = [UIColor clearColor];
        //        [self addSubview:_popoverBubble];
        //
        //
        //        _bubleText = [[UILabel alloc] initWithFrame:_popoverBubble.frame];
        //        _bubleText.font = [UIFont boldSystemFontOfSize:20];
        //        _bubleText.backgroundColor = [UIColor clearColor];
        //        _bubleText.textColor = [UIColor blackColor];
        //        _bubleText.textAlignment = UITextAlignmentCenter;
        //
        //        [_popoverBubble addSubview:_bubleText];
        
        [self getMovieFrame];
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


-(void)setPopoverBubbleSize: (CGFloat) width height:(CGFloat)height{
    
    //    CGRect currentFrame = _popoverBubble.frame;
    //    currentFrame.size.width = width;
    //    currentFrame.size.height = height;
    //    currentFrame.origin.y = -height;
    //    _popoverBubble.frame = currentFrame;
    //
    //    currentFrame.origin.x = 0;
    //    currentFrame.origin.y = 0;
    //    _bubleText.frame = currentFrame;
    //
}


-(void)setMaxGap:(NSInteger)maxGap{
    _leftPosition = 0;
    _rightPosition = _frame_width*maxGap/_durationSeconds;
    _maxGap = maxGap;
}

-(void)setMinGap:(NSInteger)minGap{
    _leftPosition = 0;
    _rightPosition = _frame_width*minGap/_durationSeconds;
    _minGap = minGap;
}


- (void)delegateNotification
{
    if ([_delegate respondsToSelector:@selector(videoRange:didChangeLeftPosition:rightPosition:)]){
        [_delegate videoRange:self didChangeLeftPosition:self.leftPosition rightPosition:self.rightPosition];
    }
    
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
        
        if (
            (_rightPosition-_leftPosition <= _leftThumb.frame.size.width+_rightThumb.frame.size.width) ||
            ((self.maxGap > 0) && (self.rightPosition-self.leftPosition > self.maxGap)) ||
            ((self.minGap > 0) && (self.rightPosition-self.leftPosition < self.minGap))
            ){
            _leftPosition -= translation.x;
        }
        
        [gesture setTranslation:CGPointZero inView:self];
        
        [self setNeedsLayout];
        
        [self delegateNotification];
        
    }
    
    //_popoverBubble.alpha = 1;
    
    [self setTimeLabel];
    
    if (gesture.state == UIGestureRecognizerStateEnded){
        if ([_delegate respondsToSelector:@selector(videoRange:didGestureStateEndedLeftPosition:rightPosition:)]){
            [_delegate videoRange:self didGestureStateEndedLeftPosition:self.leftPosition rightPosition:self.rightPosition];
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
        
        if (_rightPosition > _frame_width){
            _rightPosition = _frame_width;
        }
        
        if (_rightPosition-_leftPosition <= 0){
            _rightPosition -= translation.x;
        }
        
        if ((_rightPosition-_leftPosition <= _leftThumb.frame.size.width+_rightThumb.frame.size.width) ||
            ((self.maxGap > 0) && (self.rightPosition-self.leftPosition > self.maxGap)) ||
            ((self.minGap > 0) && (self.rightPosition-self.leftPosition < self.minGap))){
            _rightPosition -= translation.x;
        }
        
        
        [gesture setTranslation:CGPointZero inView:self];
        
        [self setNeedsLayout];
        
        [self delegateNotification];
        
    }
    
    [self setTimeLabel];
    
    if (gesture.state == UIGestureRecognizerStateEnded){
        if ([_delegate respondsToSelector:@selector(videoRange:didGestureStateEndedLeftPosition:rightPosition:)]){
            [_delegate videoRange:self didGestureStateEndedLeftPosition:self.leftPosition rightPosition:self.rightPosition];
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
        
        [self delegateNotification];
        
    }
    
    [self setTimeLabel];
    
    if (gesture.state == UIGestureRecognizerStateEnded){
        if ([_delegate respondsToSelector:@selector(videoRange:didGestureStateEndedLeftPosition:rightPosition:)]){
            [_delegate videoRange:self didGestureStateEndedLeftPosition:self.leftPosition rightPosition:self.rightPosition];
        }
    }
    
}

- (void)layoutSubviews
{
    CGFloat inset = _leftThumb.frame.size.width / 2;
    
    _leftThumb.center = CGPointMake(_leftPosition+inset, _leftThumb.frame.size.height/2);
    
    _rightThumb.center = CGPointMake(_rightPosition-inset, _rightThumb.frame.size.height/2);
    
    _topBorder.frame = CGRectMake(_leftThumb.frame.origin.x + _leftThumb.frame.size.width, 0, _rightThumb.frame.origin.x - _leftThumb.frame.origin.x - _leftThumb.frame.size.width/2, SLIDER_BORDERS_SIZE);
    
    _bottomBorder.frame = CGRectMake(_leftThumb.frame.origin.x + _leftThumb.frame.size.width, _bgView.frame.size.height-SLIDER_BORDERS_SIZE, _rightThumb.frame.origin.x - _leftThumb.frame.origin.x - _leftThumb.frame.size.width/2, SLIDER_BORDERS_SIZE);
    
    
    _centerView.frame = CGRectMake(_leftThumb.frame.origin.x + _leftThumb.frame.size.width, _centerView.frame.origin.y, _rightThumb.frame.origin.x - _leftThumb.frame.origin.x - _leftThumb.frame.size.width, _centerView.frame.size.height);
    
    
    //    CGRect frame = _popoverBubble.frame;
    //    frame.origin.x = _centerView.frame.origin.x+_centerView.frame.size.width/2-frame.size.width/2;
    //    _popoverBubble.frame = frame;
    
    //darken left and right
    for (UIImageView *previewImageView in self.darkenViews) {
        if(previewImageView.superview.frame.origin.x < _leftThumb.frame.origin.x - _leftThumb.frame.size.width || previewImageView.superview.frame.origin.x > _rightThumb.frame.origin.x - _rightThumb.frame.size.width) {
            previewImageView.alpha = 0.7;
        }
        else
            previewImageView.alpha = 0;
    }
}

#pragma mark - Video

-(void)getMovieFrame{
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        AVAsset *myAsset = [[AVURLAsset alloc] initWithURL:weakSelf.videoUrl options:nil];
        weakSelf.imageGenerator = [AVAssetImageGenerator assetImageGeneratorWithAsset:myAsset];
        
        if ([weakSelf isRetina]){
            weakSelf.imageGenerator.maximumSize = CGSizeMake(weakSelf.bgView.frame.size.width*[UIScreen mainScreen].scale, weakSelf.bgView.frame.size.height*[UIScreen mainScreen].scale);
        } else {
            weakSelf.imageGenerator.maximumSize = CGSizeMake(weakSelf.bgView.frame.size.width, weakSelf.bgView.frame.size.height);
        }
        
        __block int picWidth = 20;
        
        weakSelf.darkenViews = [NSMutableArray new];
        
        // First image
        __block NSError *error;
        __block CMTime actualTime;
        CGImageRef halfWayImage = [weakSelf.imageGenerator copyCGImageAtTime:kCMTimeZero actualTime:&actualTime error:&error];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            if (halfWayImage != NULL) {
                
                UIImage *videoScreen;
                if ([weakSelf isRetina]){
                    videoScreen = [[UIImage alloc] initWithCGImage:halfWayImage scale:[UIScreen mainScreen].scale orientation:UIImageOrientationUp];
                } else {
                    videoScreen = [[UIImage alloc] initWithCGImage:halfWayImage];
                }
                UIImageView *tmp = [[UIImageView alloc] initWithImage:videoScreen];
                CGRect rect=tmp.frame;
                rect.size.width=picWidth;
                tmp.frame=rect;
                tmp.contentMode = UIViewContentModeScaleAspectFill;
                tmp.layer.masksToBounds = YES;
                [weakSelf.bgView addSubview:tmp];
                picWidth = tmp.frame.size.width;
                CGImageRelease(halfWayImage);
                
                [weakSelf addDarkenViewToImageView:tmp];
            }
            
            weakSelf.durationSeconds = CMTimeGetSeconds([myAsset duration]);
            
            int picsCnt = ceil(weakSelf.bgView.frame.size.width / picWidth);
            
            NSMutableArray *allTimes = [[NSMutableArray alloc] init];
            
            
            int time4Pic = 0;
            // Bug iOS7 - generateCGImagesAsynchronouslyForTimes
            __block int prefreWidth=0;
            for (__block int i=1, ii=1; i<picsCnt; i++){
                time4Pic = i*picWidth;
                
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    CMTime timeFrame = CMTimeMakeWithSeconds(weakSelf.durationSeconds*time4Pic/weakSelf.bgView.frame.size.width, 600);
                    
                    [allTimes addObject:[NSValue valueWithCMTime:timeFrame]];
                    
                    
                    CGImageRef halfWayImage = [weakSelf.imageGenerator copyCGImageAtTime:timeFrame actualTime:&actualTime error:&error];
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        UIImage *videoScreen;
                        if ([weakSelf isRetina]){
                            videoScreen = [[UIImage alloc] initWithCGImage:halfWayImage scale:[UIScreen mainScreen].scale orientation:UIImageOrientationUp];
                        } else {
                            videoScreen = [[UIImage alloc] initWithCGImage:halfWayImage];
                        }
                        
                        UIImageView *tmp = [[UIImageView alloc] initWithImage:videoScreen];
                        
                        CGRect currentFrame = tmp.frame;
                        currentFrame.origin.x = ii*picWidth;
                        
                        currentFrame.size.width=picWidth;
                        prefreWidth+=currentFrame.size.width;
                        
                        if( i == picsCnt-1){
                            currentFrame.size.width-=6;
                        }
                        tmp.frame = currentFrame;
                        int all = (ii+1)*tmp.frame.size.width;
                        
                        if (all > weakSelf.bgView.frame.size.width){
                            int delta = all - weakSelf.bgView.frame.size.width;
                            currentFrame.size.width -= delta;
                        }
                        
                        ii++;
                        
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [weakSelf.bgView addSubview:tmp];
                        });
                        tmp.contentMode = UIViewContentModeScaleAspectFill;
                        tmp.layer.masksToBounds = YES;
                        [self addDarkenViewToImageView:tmp];
                        
                        CGImageRelease(halfWayImage);
                    });
                });
            }
            
        });
    });
}

#pragma mark - Properties

- (CGFloat)leftPosition
{
    return _leftPosition * _durationSeconds / _frame_width;
}


- (CGFloat)rightPosition
{
    return _rightPosition * _durationSeconds / _frame_width;
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
    CGFloat totalWidth = self.rightThumb.frame.origin.x + self.rightThumb.frame.size.width - self.leftThumb.frame.origin.x;
    CGFloat currentPositionX = self.leftThumb.frame.origin.x + totalWidth * progress;
    self.currentPositionView.frame = CGRectMake(currentPositionX, 0, self.currentPositionView.frame.size.width, self.currentPositionView.frame.size.height);
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

- (void)addDarkenViewToImageView:(UIImageView*)imageView {
    UIView *view = [[UIView alloc] initWithFrame:imageView.bounds];
    view.backgroundColor = [UIColor blackColor];
    view.alpha = 0;
    [imageView addSubview:view];
    
    [self.darkenViews addObject:view];
}


@end
