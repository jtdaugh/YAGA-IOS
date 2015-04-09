//
//  YASaveToCameraRollActivity.m
//  Yaga
//
//  Created by Iegor on 4/7/15.
//  Copyright (c) 2015 Raj Vir. All rights reserved.
//

#import "YASaveToCameraRollActivity.h"
@interface YASaveToCameraRollActivity()
@property (nonatomic, strong) NSArray *items;
@end
@implementation YASaveToCameraRollActivity
- (NSString *)activityType
{
    return @"yaga.save.video";
}

- (NSString *)activityTitle
{
    return NSLocalizedString(@"Save to Camera Roll", nil);
}

- (UIImage *)activityImage
{
    return nil;
}

- (BOOL)canPerformWithActivityItems:(NSArray *)activityItems
{
    DLog(@"%s", __FUNCTION__);
    return YES;
}

- (void)prepareWithActivityItems:(NSArray *)activityItems
{
    DLog(@"%s",__FUNCTION__);
    self.items = activityItems;
}

- (UIViewController *)activityViewController
{
    DLog(@"%s",__FUNCTION__);
    return nil;
}

- (void)performActivity
{
    // This is where you can do anything you want, and is the whole reason for creating a custom
    // UIActivity
    YAVideo *video = self.items.lastObject;
    
    [YAUtils saveVideoToCameraRoll:video];
    [self activityDidFinish:YES];
}
@end
