//
//  YACopyVideoToClipboardActivity.m
//  Yaga
//
//  Created by Iegor on 4/15/15.
//  Copyright (c) 2015 Raj Vir. All rights reserved.
//

#import "YACopyVideoToClipboardActivity.h"
@interface YACopyVideoToClipboardActivity()
@property (nonatomic, strong) NSArray *items;
@end
@implementation YACopyVideoToClipboardActivity

- (NSString *)activityType
{
    return @"yaga.copy.video";
}

- (NSString *)activityTitle
{
    return NSLocalizedString(@"Copy Video", nil);
}

- (UIImage *)activityImage
{
    return [UIImage imageNamed:@"rsz_copyicon"];
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
    NSURL *video = self.items.lastObject;
    
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    [pasteboard setData:[[NSData alloc] initWithContentsOfURL:video] forPasteboardType:@"public.mpeg-4"];
    
    [self activityDidFinish:YES];
}
@end
