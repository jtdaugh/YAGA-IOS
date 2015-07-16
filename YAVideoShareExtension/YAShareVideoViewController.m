//
//  ShareViewController.m
//  YAVideoShareExtension
//
//  Created by Christopher Wendel on 7/16/15.
//  Copyright (c) 2015 Raj Vir. All rights reserved.
//

#import "YAShareVideoViewController.h"
#import "YAVideoPlayerView.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "YACrosspostCell.h"
#import "Constants.h"

@interface YAShareVideoViewController ()

@property (nonatomic, weak) IBOutlet YAVideoPlayerView *playerView;
@property (nonatomic, strong) NSMutableArray *groups;
@property (nonatomic, strong) UITableView *groupsList;

@end

@implementation YAShareVideoViewController

#pragma mark - View setup

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self loadExtensionItem];
    
    _groups = [NSMutableArray array];
    
    CGFloat topGap = 20;
    CGFloat shareBarHeight = 60;
    CGFloat topBarHeight = 80;
    
    CGFloat totalRowsHeight = XPCellHeight * ([self.groups count] + 1);
    if (![self.groups count]) totalRowsHeight = 0;
    
    CGRect frame = self.view.frame;
    
    CGFloat maxTableViewHeight = (frame.size.height * VIEW_HEIGHT_PROPORTION) - topGap - XPCellHeight;
    
    CGFloat tableHeight = MIN(maxTableViewHeight, totalRowsHeight);
    
    CGFloat gradientHeight = tableHeight + topBarHeight + topGap;
    UIView *bgGradient = [[UIView alloc] initWithFrame:CGRectMake(0, frame.size.height - gradientHeight, frame.size.width, gradientHeight)];
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.frame = bgGradient.bounds;
    ;
    gradient.colors = [NSArray arrayWithObjects:
                       (id)[[UIColor colorWithWhite:0.0 alpha:.0] CGColor],
                       (id)[[UIColor colorWithWhite:0.0 alpha:.6] CGColor],
                       (id)[[UIColor colorWithWhite:0.0 alpha:.7] CGColor],
                       (id)[[UIColor colorWithWhite:0.0 alpha:.7] CGColor],
                       (id)[[UIColor colorWithWhite:0.0 alpha:.8] CGColor],
                       nil];
    
    [bgGradient.layer insertSublayer:gradient atIndex:0];
    [self.view addSubview:bgGradient];
    
    
    CGFloat tableOrigin = frame.size.height - tableHeight;
    
    self.groupsList = [[UITableView alloc] initWithFrame:CGRectMake(0, tableOrigin, VIEW_WIDTH, tableHeight)];
    [self.groupsList setBackgroundColor:[UIColor clearColor]];
    [self.groupsList registerClass:[YACrosspostCell class] forCellReuseIdentifier:kCrosspostCellId];
    [self.groupsList registerClass:[UITableViewCell class] forCellReuseIdentifier:kNewGroupCellId];
    self.groupsList.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.groupsList.allowsSelection = YES;
    self.groupsList.allowsMultipleSelection = YES;
    self.groupsList.delegate = self;
    self.groupsList.dataSource = self;
    [self.view addSubview:self.groupsList];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

#pragma mark - Extensions

- (void)loadExtensionItem {
    if ([self.itemProvider hasItemConformingToTypeIdentifier:(NSString *)kUTTypeMovie]) {
        [self.itemProvider loadItemForTypeIdentifier:(NSString *)kUTTypeMovie options:nil completionHandler:^(NSURL *movieURL, NSError *error) {
            
            if (movieURL) {
                [self prepareVideoForPlaying:movieURL];
                
                self.playerView.playWhenReady = YES;
            }
        }];
    }
}

#pragma mark - Video

- (void)prepareVideoForPlaying:(NSURL *)movUrl {
    self.playerView.URL = movUrl;
}

#pragma mark - UITableViewDataSource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    YACrosspostCell *cell = [tableView dequeueReusableCellWithIdentifier:kCrosspostCellId forIndexPath:indexPath];
    //YAGroup *group = [self.groups objectAtIndex:indexPath.row];
    //[cell setGroupTitle:group.name];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return XPCellHeight;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.groups count];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self renderButton:[[tableView indexPathsForSelectedRows] count]];
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self renderButton:[[tableView indexPathsForSelectedRows] count]];
}

#pragma mark - UITableViewDelegate

#pragma mark - UI helpers

- (void)renderButton:(NSUInteger) count {
    if(count > 0){
        NSString *title;
        if(count == 1){
            title = @"Post to 1 group";
        } else {
            title = [NSString stringWithFormat:@"Post to %lu groups", (unsigned long)count];
        }
//        [self.confirmCrosspost setTitle:title forState:UIControlStateNormal];
//        [UIView animateWithDuration:0.2 delay:0.0 options:UIViewAnimationOptionAllowAnimatedContent animations:^{
//            [self.confirmCrosspost setTransform:CGAffineTransformIdentity];
//        } completion:^(BOOL finished) {
            //
//        }];
    } else {
//        [UIView animateWithDuration:0.2 delay:0.0 options:UIViewAnimationOptionAllowAnimatedContent animations:^{
//            [self.confirmCrosspost setTransform:CGAffineTransformMakeTranslation(0, self.confirmCrosspost.frame.size.height)];
//        } completion:^(BOOL finished) {
            //
//        }];
    }
}

@end
