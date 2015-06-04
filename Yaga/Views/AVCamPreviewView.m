/*
     File: AVCamPreviewView.m
 Abstract: Application preview view.
  Version: 3.1
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
 Inc. ("Apple") in consideration of your agreement to the following
 terms, and your use, installation, modification or redistribution of
 this Apple software constitutes acceptance of these terms.  If you do
 not agree with these terms, please do not use, install, modify or
 redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc. may
 be used to endorse or promote products derived from the Apple Software
 without specific prior written permission from Apple.  Except as
 expressly stated in this notice, no other rights or licenses, express or
 implied, are granted by Apple herein, including but not limited to any
 patent rights that may be infringed by your derivative works or by other
 works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 
 */

#import "AVCamPreviewView.h"
#import <AVFoundation/AVFoundation.h>
#import "YACameraFocusSquare.h"

@interface AVCamPreviewView () <UIGestureRecognizerDelegate>
@property (nonatomic, strong) YACameraFocusSquare *camFocus;
@property (nonatomic, strong) UIPinchGestureRecognizer *pinchZoomGesture;
@property (nonatomic, strong) AVCaptureDevice *captureDevice;
@property (nonatomic, assign) CGFloat effectiveScale;
@property (nonatomic, assign) CGFloat beginGestureScale;
@end
@implementation AVCamPreviewView

+ (Class)layerClass
{
	return [AVCaptureVideoPreviewLayer class];
}

- (AVCaptureSession *)session
{
	return [(AVCaptureVideoPreviewLayer *)[self layer] session];
}

- (void)setSession:(AVCaptureSession *)session
{
	[(AVCaptureVideoPreviewLayer *)[self layer] setSession:session];
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if(self) {
//        self.tapToFocusRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(zoom:)];
//        self.tapToFocusRecognizer.enabled = YES;
//        [self addGestureRecognizer:self.tapToFocusRecognizer];
        self.pinchZoomGesture = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinchFrom:)];
        self.pinchZoomGesture.delegate = self;
        [self addGestureRecognizer:self.pinchZoomGesture];
        self.effectiveScale = 1.f;
        self.captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    }
    return self;
}

- (void)handleTap:(UITapGestureRecognizer*)sender {
    CGPoint touchPoint = [sender locationInView:self];

    [self focus:touchPoint];
    
    if (self.camFocus)
    {
        [self.camFocus removeFromSuperview];
    }
    
    self.camFocus = [[YACameraFocusSquare alloc]initWithFrame:CGRectMake(touchPoint.x-40, touchPoint.y-40, 80, 80)];
    [self.camFocus setBackgroundColor:[UIColor clearColor]];
    [self addSubview:self.camFocus];
    [self.camFocus setNeedsDisplay];
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:1.5];
    [self.camFocus setAlpha:0.0];
    [UIView commitAnimations];
}

- (void)handlePinchFrom:(UIPinchGestureRecognizer *)pinchZoomGesture {
    BOOL allTouchesAreOnThePreviewLayer = YES;
    NSUInteger numTouches = [pinchZoomGesture numberOfTouches], i;
    AVCaptureVideoPreviewLayer *captureVideoPreviewLayer = (AVCaptureVideoPreviewLayer *)[self layer];
    for ( i = 0; i < numTouches; ++i ) {
        CGPoint location = [pinchZoomGesture locationOfTouch:i inView:self];
        CGPoint convertedLocation = [captureVideoPreviewLayer convertPoint:location fromLayer:captureVideoPreviewLayer.superlayer];
        if ( ! [captureVideoPreviewLayer containsPoint:convertedLocation] ) {
            allTouchesAreOnThePreviewLayer = NO;
            break;
        }
    }
    
    if ( allTouchesAreOnThePreviewLayer ) {
        self.effectiveScale = self.beginGestureScale * pinchZoomGesture.scale;
        [self applyZoom];
    }
}

- (void)applyZoom {
    if (self.effectiveScale >= 1 && self.effectiveScale <= self.captureDevice.activeFormat.videoMaxZoomFactor) {
        NSNumber *DefaultZoomFactor = [[NSNumber alloc] initWithFloat:self.effectiveScale];
        NSError *error = nil;
        if ([self.captureDevice lockForConfiguration:&error]) {
            [self.captureDevice setVideoZoomFactor:[DefaultZoomFactor floatValue]];
            [self.captureDevice unlockForConfiguration];
        } else {
            NSLog(@"%@", error);
        }
    }
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    if ( [gestureRecognizer isKindOfClass:[UIPinchGestureRecognizer class]] ) {
        self.beginGestureScale = self.effectiveScale;
    }
    return YES;
}

//- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
//{
//    UITouch *touch = [[event allTouches] anyObject];
//    CGPoint touchPoint = [touch locationInView:touch.view];
//    [self focus:touchPoint];
//    
//    if (self.camFocus)
//    {
//        [self.camFocus removeFromSuperview];
//    }
//    if ([[touch view] isKindOfClass:[self class]])
//    {
//        self.camFocus = [[YACameraFocusSquare alloc]initWithFrame:CGRectMake(touchPoint.x-40, touchPoint.y-40, 80, 80)];
//        [self.camFocus setBackgroundColor:[UIColor clearColor]];
//        [self addSubview:self.camFocus];
//        [self.camFocus setNeedsDisplay];
//        
//        [UIView beginAnimations:nil context:NULL];
//        [UIView setAnimationDuration:1.5];
//        [self.camFocus setAlpha:0.0];
//        [UIView commitAnimations];
//    }
//}

- (void)focus:(CGPoint) aPoint;
{
    Class captureDeviceClass = NSClassFromString(@"AVCaptureDevice");
    if (captureDeviceClass != nil) {
        AVCaptureDevice *device = [captureDeviceClass defaultDeviceWithMediaType:AVMediaTypeVideo];
        if([device isFocusPointOfInterestSupported] &&
           [device isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
            CGRect screenRect = [[UIScreen mainScreen] bounds];
            double screenWidth = screenRect.size.width;
            double screenHeight = screenRect.size.height;
            double focus_x = aPoint.x/screenWidth;
            double focus_y = aPoint.y/screenHeight;
            if([device lockForConfiguration:nil]) {
                [device setFocusPointOfInterest:CGPointMake(focus_x,focus_y)];
                [device setFocusMode:AVCaptureFocusModeContinuousAutoFocus];
                if ([device isExposureModeSupported:AVCaptureExposureModeAutoExpose]){
                    [device setExposureMode:AVCaptureExposureModeAutoExpose];
                }
                [device unlockForConfiguration];
            }
        }
    }
}

@end
