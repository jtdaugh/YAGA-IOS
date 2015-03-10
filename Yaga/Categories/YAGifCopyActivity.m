//
//  YAGifCopyActivity.m
//  Yaga
//
//  Created by Iegor on 3/10/15.
//  Copyright (c) 2015 Raj Vir. All rights reserved.
//
#import "YAUtils.h"
#import "YAGifCopyActivity.h"
@interface YAGifCopyActivity()
@property (nonatomic, strong) NSArray *items;
@end
@implementation YAGifCopyActivity
- (NSString *)activityType
{
    return @"yaga.copy.gif";
}

- (NSString *)activityTitle
{
#warning implement this
    return NSLocalizedString(@"Copy GIF", nil);
}

- (UIImage *)activityImage
{
    return [UIImage imageNamed:@"AppIcon"];
}

- (BOOL)canPerformWithActivityItems:(NSArray *)activityItems
{
    NSLog(@"%s", __FUNCTION__);
    return YES;
}

- (void)prepareWithActivityItems:(NSArray *)activityItems
{
    NSLog(@"%s",__FUNCTION__);
    self.items = activityItems;
}

- (UIViewController *)activityViewController
{
    NSLog(@"%s",__FUNCTION__);
    return nil;
}

- (void)performActivity
{
    // This is where you can do anything you want, and is the whole reason for creating a custom
    // UIActivity
    YAVideo *video = self.items.lastObject;
    
    [YAUtils copyVideoToClipboard:video];
    [self activityDidFinish:YES];
}
@end
