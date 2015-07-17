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
#import "YAPanGestureRecognizer.h"
#import "YAApplyCaptionView.h"

#import <Firebase/Firebase.h>
#import <MBProgressHUD/MBProgressHUD.h>

@interface YAShareVideoCaption : NSObject

@property (nonatomic, strong) NSString *text;
@property (nonatomic, assign) CGFloat x;
@property (nonatomic, assign) CGFloat y;
@property (nonatomic, assign) CGFloat scale;
@property (nonatomic, assign) CGFloat rotation;

@end

@implementation YAShareVideoCaption

@end

@interface YAShareVideoViewController ()

@property (nonatomic) BOOL editingCaption;

@property (nonatomic, weak) IBOutlet YAVideoPlayerView *playerView;
@property (nonatomic, strong) UITableView *groupsList;
@property (nonatomic, strong) UIButton *confirmCrosspost;
@property (nonatomic, strong) UIButton *XButton;
@property (nonatomic, strong) UIButton *captionButton;
@property (nonatomic, strong) UILabel *crossPostPrompt;
@property (nonatomic, strong) UITapGestureRecognizer *captionTapRecognizer;

// Caption stuff
@property (strong, nonatomic) UIView *serverCaptionWrapperView;
@property (strong, nonatomic) UITextView *serverCaptionTextView;
@property (strong, nonatomic) FDataSnapshot *currentCaptionSnapshot;
@property (strong, nonatomic) YAShareVideoCaption *videoCaption;

@end

@implementation YAShareVideoViewController

#pragma mark - View setup

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [YAShareServer sharedServer];
    
    [[[NSUserDefaults alloc] initWithSuiteName:@"group.com.yaga.yagaapp"] synchronize];
    
    NSExtensionItem *item = self.extensionContext.inputItems[0];
    NSItemProvider *itemProvider = item.attachments[0];
    self.itemProvider = itemProvider;
    
    __block MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.labelText = @"Loading...";
    
    [[YAShareServer sharedServer] getGroupsWithCompletion:^(id response, NSError *error){
        if (error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [hud hide:NO];
            });
        } else {
            NSMutableArray *privateGroups = [NSMutableArray arrayWithArray:[self shareGroupsFromResponse:response]];
            
            [[YAShareServer sharedServer] getGroupsWithCompletion:^(id response, NSError *error) {
                [[[NSUserDefaults alloc] initWithSuiteName:@"group.com.yaga.yagaapp"] setObject:[NSDate date] forKey:kLastPublicGroupsRequestDate];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [hud hide:NO];
                });
                
                if(error) {
                    
                }
                else {
                    NSArray *publicGroups = [self shareGroupsFromResponse:response];
                    NSMutableArray *mutableGroups = [NSMutableArray arrayWithArray:publicGroups];
                    [mutableGroups addObjectsFromArray:privateGroups];
                    self.groups = [NSArray arrayWithArray:mutableGroups];
                    [self.groupsList reloadData];
                    [self loadExtensionItem];
                }
            } publicGroups:YES];
        }
    } publicGroups:NO];
}

- (void)setupExtensionViews {
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
    
    UIView *tapCaptionTarget = [[UIView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:tapCaptionTarget];
    
    self.captionTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    [tapCaptionTarget addGestureRecognizer:self.captionTapRecognizer];
    
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
    
    [self toggleEditingCaption:NO];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

#pragma mark - Model

- (NSArray *)shareGroupsFromResponse:(id)response {
    NSArray *responseArray = (NSArray *)response;
    NSMutableArray *shareGroupsMutable = [NSMutableArray array];
    for (NSDictionary *group in responseArray) {
        YAShareGroup *shareGroup = [YAShareGroup new];
        shareGroup.name = group[@"name"];
        shareGroup.serverId = group[@"id"];
        [shareGroupsMutable addObject:shareGroup];
    }
    return [NSArray arrayWithArray:shareGroupsMutable];
}

#pragma mark - Extensions

- (void)loadExtensionItem {
    self.view.alpha = 0.0;
    if ([self.itemProvider hasItemConformingToTypeIdentifier:@"public.movie"]) {
        [self.itemProvider loadItemForTypeIdentifier:@"public.movie" options:nil completionHandler:^(id response, NSError *error) {
            NSURL *movieURL = (NSURL *)response;
            NSData *videoData = [NSData dataWithContentsOfURL:movieURL];
            
            if (movieURL) {
                [self prepareVideoForPlaying:movieURL];
                
                self.playerView.playWhenReady = YES;
                
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self setupExtensionViews];
                    
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        [UIView animateWithDuration:0.3f animations:^{
                            self.view.alpha = 1.f;
                        }];
                    });
                });
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

- (void)toggleEditingCaption:(BOOL)editing {
    self.editingCaption = editing;
    if (editing) {
        self.captionButton.hidden = YES;
        self.groupsList.hidden = YES;
        self.crossPostPrompt.hidden = YES;
        self.confirmCrosspost.hidden = YES;
        self.serverCaptionTextView.hidden = YES;
        self.captionTapRecognizer.enabled = NO;
    } else {
        self.captionButton.hidden = NO;
        self.groupsList.hidden = NO;
        self.crossPostPrompt.hidden = NO;
        self.confirmCrosspost.hidden = NO;
        self.serverCaptionTextView.hidden = NO;
        self.captionTapRecognizer.enabled = YES;
    }
}

#pragma mark - Actions

- (void)confirmCrosspost:(id)sender {
    // Upload video and on completion handler upload caption
}

- (void)closeButtonPressed:(id)sender {
    [self dismissExtension];
}

- (void)captionButtonPressed:(id)sender {
    float randomX = ((float)rand() / RAND_MAX) * 100;
    float randomY = ((float)rand() / RAND_MAX) * 200;
    CGPoint loc = CGPointMake(self.view.frame.size.width/2 - 50 + randomX, self.view.frame.size.height/2 - randomY);
    
    [self addCaptionOverlays:loc];
}

- (void)handleTap:(UITapGestureRecognizer *)tapGestureRecognizer {
    CGPoint loc = [tapGestureRecognizer locationInView:self.view];
    
    [self addCaptionOverlays:loc];
}

- (void)addCaptionOverlays:(CGPoint)loc {
    [self toggleEditingCaption:YES];
    
    float randomRotation = ((float)rand() / RAND_MAX) * .4;
    CGAffineTransform t = CGAffineTransformConcat(CGAffineTransformMakeScale(CAPTION_DEFAULT_SCALE * CAPTION_SCREEN_MULTIPLIER,
                                                                             CAPTION_DEFAULT_SCALE * CAPTION_SCREEN_MULTIPLIER), CGAffineTransformMakeRotation(-.2 + randomRotation));
    
    
    YAApplyCaptionView *applyCaptionView = [[YAApplyCaptionView alloc] initWithFrame:self.view.bounds captionPoint:loc initialText:@"" initialTransform:t];
    
    __weak YAApplyCaptionView *weakApplyCaptionView = applyCaptionView;
    applyCaptionView.completionHandler = ^(BOOL completed, UIView *captionView, UITextView *captionTextView, NSString *text, CGFloat x, CGFloat y, CGFloat scale, CGFloat rotation) {
        self.serverCaptionWrapperView = captionView;
        self.serverCaptionTextView = captionTextView;
        self.serverCaptionTextView.editable = NO;
        [self.view insertSubview:self.serverCaptionWrapperView aboveSubview:self.playerView];
        [self toggleEditingCaption:NO];
        
        if (completed) {
            [self.captionButton removeFromSuperview];
            self.videoCaption = [YAShareVideoCaption new];
            self.videoCaption.text = text;
            self.videoCaption.x = x;
            self.videoCaption.y = y;
            self.videoCaption.scale = scale;
            self.videoCaption.rotation = rotation;
        }
        
        [weakApplyCaptionView removeFromSuperview];
    };
    
    [self.view addSubview:applyCaptionView];
}

- (void)dismissExtension {
    [self dismissViewControllerAnimated:YES completion:nil];
    [self.extensionContext completeRequestReturningItems:nil completionHandler:nil];
}

#pragma mark - Requests

@end
