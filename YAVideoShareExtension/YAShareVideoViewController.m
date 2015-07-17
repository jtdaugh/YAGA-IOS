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
#import "YAShareServer.h"
#import "YAShareGroup.h"

@interface YAShareVideoViewController ()

@property (nonatomic, weak) IBOutlet YAVideoPlayerView *playerView;
@property (nonatomic, strong) UITableView *groupsList;
@property (nonatomic, strong) UIButton *confirmCrosspost;
@property (nonatomic, strong) UIButton *XButton;
@property (nonatomic, strong) UIButton *captionButton;
@property (nonatomic, strong) UILabel *crossPostPrompt;

@end

@implementation YAShareVideoViewController

#pragma mark - View setup

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self loadExtensionItem];
    
    CGFloat topGap = 20;
    CGFloat shareBarHeight = 60;
    CGFloat topBarHeight = 80;
    CGFloat buttonRadius = 22.f, padding = 15.f;
    
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
    self.groupsList.contentInset = UIEdgeInsetsMake(0, 0, XPCellHeight, 0);
    [self.view addSubview:self.groupsList];
    
    self.confirmCrosspost = [[UIButton alloc] initWithFrame:CGRectMake(0, frame.size.height - shareBarHeight, VIEW_WIDTH, shareBarHeight)];
    self.confirmCrosspost.backgroundColor = SECONDARY_COLOR;
    self.confirmCrosspost.titleLabel.font = [UIFont fontWithName:BOLD_FONT size:20];
    self.confirmCrosspost.titleLabel.textColor = [UIColor whiteColor];
    [self.confirmCrosspost setContentHorizontalAlignment:UIControlContentHorizontalAlignmentLeft];
    [self.confirmCrosspost setImage:[UIImage imageNamed:@"Disclosure"] forState:UIControlStateNormal];
    self.confirmCrosspost.imageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.confirmCrosspost setContentEdgeInsets:UIEdgeInsetsZero];
    [self.confirmCrosspost setImageEdgeInsets:UIEdgeInsetsMake(0, self.confirmCrosspost.frame.size.width - 48 - 16, 0, 48)];
    [self.confirmCrosspost setTitleEdgeInsets:UIEdgeInsetsMake(0, 8, 0, 48 - 16)];
    [self.confirmCrosspost setTransform:CGAffineTransformMakeTranslation(0, self.confirmCrosspost.frame.size.height)];
    [self.confirmCrosspost addTarget:self action:@selector(confirmCrosspost:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.confirmCrosspost];
    
    self.crossPostPrompt = [[UILabel alloc] initWithFrame:CGRectMake(24, tableOrigin - topGap, VIEW_WIDTH-24, 24)];
    self.crossPostPrompt.font = [UIFont fontWithName:BOLD_FONT size:20];
    self.crossPostPrompt.textColor = [UIColor whiteColor];
    NSString *title = @"Post to Groups";
    self.crossPostPrompt.text = title;
    self.crossPostPrompt.layer.shadowRadius = 0.5f;
    self.crossPostPrompt.layer.shadowColor = [UIColor blackColor].CGColor;
    self.crossPostPrompt.layer.shadowOffset = CGSizeMake(0.5f, 0.5f);
    self.crossPostPrompt.layer.shadowOpacity = 1.0;
    self.crossPostPrompt.layer.masksToBounds = NO;
    
    [self.view addSubview:self.crossPostPrompt];
    
    self.XButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, buttonRadius*2, buttonRadius*2)];
    self.XButton.center = CGPointMake(frame.size.width - buttonRadius - padding, padding + buttonRadius);
    [self.XButton setBackgroundImage:[UIImage imageNamed:@"X"] forState:UIControlStateNormal];
    self.XButton.transform = CGAffineTransformMakeScale(0.85, 0.85);
    self.XButton.alpha = 0.7;
    [self.XButton addTarget:self action:@selector(closeButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.XButton];
    
    self.captionButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, buttonRadius * 2, buttonRadius * 2)];
    [self.captionButton setBackgroundImage:[UIImage imageNamed:@"Text"] forState:UIControlStateNormal];
    self.captionButton.center = CGPointMake(buttonRadius + padding, padding + buttonRadius);
    [self.captionButton addTarget:self action:@selector(captionButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.captionButton];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

#pragma mark - Extensions

- (void)loadExtensionItem {
    if ([self.itemProvider hasItemConformingToTypeIdentifier:@"public.movie"]) {
        [self.itemProvider loadItemForTypeIdentifier:@"public.movie" options:nil completionHandler:^(id response, NSError *error) {
            NSURL *movieURL = (NSURL *)response;
            NSData *videoData = [NSData dataWithContentsOfURL:movieURL];
            
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
    YAShareGroup *group = [self.groups objectAtIndex:indexPath.row];
    [cell setGroupTitle:group.name];
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
        [self.confirmCrosspost setTitle:title forState:UIControlStateNormal];
        [UIView animateWithDuration:0.2 delay:0.0 options:UIViewAnimationOptionAllowAnimatedContent animations:^{
            [self.confirmCrosspost setTransform:CGAffineTransformIdentity];
        } completion:^(BOOL finished) {
            
        }];
    } else {
        [UIView animateWithDuration:0.2 delay:0.0 options:UIViewAnimationOptionAllowAnimatedContent animations:^{
            [self.confirmCrosspost setTransform:CGAffineTransformMakeTranslation(0, self.confirmCrosspost.frame.size.height)];
        } completion:^(BOOL finished) {
            
        }];
    }
}

#pragma mark - Actions

- (void)confirmCrosspost:(id)sender {
    
}

- (void)closeButtonPressed:(id)sender {
    
}

- (void)captionButtonPressed:(id)sender {
    
}

@end
