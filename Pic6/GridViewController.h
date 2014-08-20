//
//  GridViewController.h
//  Pic6
//
//  Created by Raj Vir on 8/18/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import <UIKit/UIKit.h>
@class CameraViewController;

@protocol CameraReceiver <NSObject>
- (void)uploadData:(NSData *)data withType:(NSString *)type withOutputURL:(NSURL *)outputURL;
@end

@interface GridViewController : UIViewController
@property (strong, nonatomic) GridViewController *previousViewController;
@property (strong, nonatomic) CameraViewController *cameraViewController;
- (void)uploadData:(NSData *)data withType:(NSString *)type withOutputURL:(NSURL *)outputURL;
@end