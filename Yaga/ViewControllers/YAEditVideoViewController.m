//
//  YAEditVideoViewController.m
//  Yaga
//
//  Created by valentinkovalski on 7/21/15.
//  Copyright © 2015 Raj Vir. All rights reserved.
//

#import "YAEditVideoViewController.h"
#import "YAVideoPage.h"
#import "YAUser.h"
#import "SAVideoRangeSlider.h"
#import "YAServerTransactionQueue.h"
#import "YAAssetsCreator.h"
#import "YACameraManager.h"
#import "YACrosspostCell.h"
#import "UIImage+Color.h"

#define kGroupRowHeight 60
#define kBottomFrameHeight 60
#define kNewGroupCellId @"postToNewGroupCell"
#define kCrosspostCellId @"crossPostCell"

@interface YAEditVideoViewController () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) SAVideoRangeSlider *trimmingView;
@property (nonatomic, strong) YAVideoPlayerView *videoPlayerView;
@property (nonatomic, strong) UIImageView *previewImageView;
@property (nonatomic, strong) UIView *bottomView;
@property (nonatomic, strong) AVAssetExportSession *exportSession;
@property (nonatomic, strong) UIButton *xButton;
@property (nonatomic, strong) UIButton *captionButton;
@property (nonatomic, strong) UIButton *sendButton;
@property (nonatomic, strong) UIButton *chooseGroupsButton;
@property (nonatomic, strong) UILabel *chosenGroupsLabel;
@property (nonatomic, strong) UITableView *groupsTableView;
@property (nonatomic, strong) UITapGestureRecognizer *groupsListTapOutRecognizer;
@property (nonatomic) BOOL groupsExpanded;

@property (nonatomic, strong) RLMResults *groups;

@property CGFloat startTime;
@property CGFloat endTime;

@property BOOL dragging;
@end

typedef void(^trimmingCompletionBlock)(NSError *error);

@implementation YAEditVideoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
   
    self.view.backgroundColor = [UIColor blackColor];
    self.groupsListTapOutRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(collapseGroupList)];
    self.groupsExpanded = NO;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.groups = [[YAGroup allObjects] sortedResultsUsingDescriptors:@[[RLMSortDescriptor sortDescriptorWithProperty:@"publicGroup" ascending:NO], [RLMSortDescriptor sortDescriptorWithProperty:@"updatedAt" ascending:NO]]];
    
    self.startTime = 0.0f;
    self.endTime = CGFLOAT_MAX;
    
    self.previewImageView = [[UIImageView alloc] initWithFrame:self.view.bounds];
    self.previewImageView.contentMode = UIViewContentModeScaleAspectFit;
    self.previewImageView.image = self.previewImage;
    [self.view addSubview:self.previewImageView];
    
    self.videoPlayerView = [[YAVideoPlayerView alloc] initWithFrame:self.view.bounds];
    [self.videoPlayerView setSmoothLoopingComposition:NO];
    [self.videoPlayerView setDontHandleLooping:YES];
    self.videoPlayerView.URL = self.videoUrl;
    self.videoPlayerView.playWhenReady = YES;
    self.videoPlayerView.delegate = self;
    
    [self.view addSubview:self.videoPlayerView];
    
    [self addBottomView];
    [self setupTableView];
    [self addTrimmingView];
    [self addTopButtons];
    [[YACameraManager sharedManager] pauseCameraAndStop:NO];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[YACameraManager sharedManager] resumeCameraAndNeedsRestart:NO];
}

- (void)setupTableView {
    self.groupsTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, VIEW_HEIGHT, VIEW_WIDTH, VIEW_HEIGHT*0.5)];
    self.groupsTableView.dataSource = self;
    self.groupsTableView.delegate = self;
    self.groupsTableView.hidden = YES;
    self.groupsTableView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.42];
    [self.groupsTableView registerClass:[YACrosspostCell class] forCellReuseIdentifier:kCrosspostCellId];
    [self.groupsTableView registerClass:[UITableViewCell class] forCellReuseIdentifier:kNewGroupCellId];
    self.groupsTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.groupsTableView.allowsSelection = YES;
    self.groupsTableView.allowsMultipleSelection = YES;
    [self.view addSubview:self.groupsTableView];

    
//    dispatch_async(dispatch_get_main_queue(), ^{
        if ([YAUser currentUser].currentGroup) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[self.groups indexOfObject:[YAUser currentUser].currentGroup] inSection:0];
            [self.groupsTableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
        }
        [self layoutGroupButtons];
//    });
}

- (void)addTrimmingView {
    const CGFloat sliderHeight = 35;
    self.trimmingView = [[SAVideoRangeSlider alloc] initWithFrame:CGRectMake(5, self.bottomView.frame.origin.y - sliderHeight - 10 , self.view.bounds.size.width - 10, sliderHeight)
                                                         videoUrl:self.videoUrl];
    self.trimmingView.delegate = self;
    [self.view addSubview:self.trimmingView];
}

- (void)addBottomView {
    self.bottomView = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height - kBottomFrameHeight, self.view.bounds.size.width, kBottomFrameHeight)];
    self.bottomView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.bottomView];
    
    UIView *transparentView = [[UIView alloc] initWithFrame:self.bottomView.bounds];
    transparentView.backgroundColor = [UIColor blackColor];
    transparentView.alpha = 0.42;
    [self.bottomView addSubview:transparentView];
    
    self.sendButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.sendButton.frame = CGRectMake(self.view.bounds.size.width - self.bottomView.bounds.size.height, 0, self.bottomView.bounds.size.height, self.bottomView.bounds.size.height);
    [self.sendButton setImage:[[UIImage imageNamed:@"PaperPlane"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    [self.sendButton addTarget:self action:@selector(sendButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    self.sendButton.imageEdgeInsets = UIEdgeInsetsMake(15, 15, 15, 15);
    self.sendButton.tintColor = [UIColor whiteColor];
    [self.sendButton.imageView setContentMode:UIViewContentModeScaleAspectFit];
    [self.bottomView addSubview:self.sendButton];
    
    self.chosenGroupsLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 5, self.view.bounds.size.width - 80, self.bottomView.bounds.size.height/2)];
    self.chosenGroupsLabel.textColor = [UIColor whiteColor];
    self.chosenGroupsLabel.font = [UIFont fontWithName:BOLD_FONT size:16];
    [self.bottomView addSubview:self.chosenGroupsLabel];
        
    self.chooseGroupsButton = [[UIButton alloc] initWithFrame:CGRectMake(10, self.bottomView.bounds.size.height/2 - 5, self.view.bounds.size.width - 80, self.bottomView.bounds.size.height/2)];
    self.chooseGroupsButton.titleLabel.textColor = [UIColor whiteColor];
    self.chooseGroupsButton.titleLabel.font = [UIFont fontWithName:BIG_FONT size:12];
    [self.chooseGroupsButton setTitle:@"Tap to add more groups" forState:UIControlStateNormal];
    [self.chooseGroupsButton addTarget:self action:@selector(chooseGroupsPressed) forControlEvents:UIControlEventTouchUpInside];
    self.chooseGroupsButton.titleLabel.textAlignment = NSTextAlignmentLeft;
    [self.bottomView addSubview:self.chooseGroupsButton];
}

#pragma mark - TableView delegate & data source

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return kGroupRowHeight;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.groups count]; //  + 1; // +1 cuz create new group
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
//    if (indexPath.row == [self.groups count]) {
//        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kNewGroupCellId forIndexPath:indexPath];
//        cell.backgroundColor = [UIColor clearColor];
//        cell.textLabel.font = [UIFont fontWithName:BIG_FONT size:28];
//        cell.textLabel.textColor = [UIColor whiteColor];
//        
//        cell.textLabel.shadowColor = [UIColor blackColor];
//        cell.textLabel.shadowOffset = CGSizeMake(0.5, 0.5);
//        UIImageView *disclosure = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 40, 40)];
//        disclosure.image = [UIImage imageNamed:@"Disclosure"];
//        cell.accessoryView = disclosure;
//        cell.textLabel.text = @" Create new group";
//        cell.selectedBackgroundView = [[UIImageView alloc] initWithImage:[UIImage imageWithColor:PRIMARY_COLOR]];
//        return cell;
//    } else {
        YACrosspostCell *cell = [tableView dequeueReusableCellWithIdentifier:kCrosspostCellId forIndexPath:indexPath];
        YAGroup *group = [self.groups objectAtIndex:indexPath.row];
        [cell setGroupTitle:group.name];
        return cell;
//    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
//    if (indexPath.row == [self.groups count]) {
//        [[NSNotificationCenter defaultCenter] postNotificationName:BEGIN_CREATE_GROUP_FROM_VIDEO_NOTIFICATION object:self.video];
//        [tableView deselectRowAtIndexPath:indexPath animated:NO];
//    } else {
    [self layoutGroupButtons];
//    }
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self layoutGroupButtons];
}



#pragma mark - layout

- (void)layoutGroupButtons {
    NSArray *selectedPaths = [self.groupsTableView indexPathsForSelectedRows];
    NSUInteger count = [selectedPaths count];
    if (count) {
        self.chosenGroupsLabel.hidden = NO;
        self.sendButton.enabled = YES;

        if (!self.groupsExpanded) {
            self.chosenGroupsLabel.frame = CGRectMake(10, 5, self.view.bounds.size.width - 80, self.bottomView.bounds.size.height/2);
            self.chosenGroupsLabel.font = [UIFont fontWithName:BOLD_FONT size:16];
        } else {
            self.chosenGroupsLabel.frame = CGRectMake(10, self.bottomView.bounds.size.height/4, self.view.bounds.size.width - 80, self.bottomView.bounds.size.height/2);
            self.chosenGroupsLabel.font = [UIFont fontWithName:BOLD_FONT size:18];
        }
        
        self.chooseGroupsButton.frame = CGRectMake(10, self.bottomView.bounds.size.height/2 - 5, self.view.bounds.size.width - 80, self.bottomView.bounds.size.height/2);
        self.chooseGroupsButton.titleLabel.font = [UIFont fontWithName:BIG_FONT size:12];
        [self.chooseGroupsButton setTitle:(!self.groupsExpanded ? @"Tap to add more groups" : @"") forState:UIControlStateNormal];
        [self.chooseGroupsButton sizeToFit];

        YAGroup *group = [self.groups objectAtIndex:((NSIndexPath *)selectedPaths[0]).row];
        if (count == 1) {
            self.chosenGroupsLabel.text = group.name;
        } else {
            self.chosenGroupsLabel.text = [NSString stringWithFormat:@"%@ and %lu other%@", group.name, count - 1, count > 2 ? @"s" : @""];
        }
        
    } else {
        self.chosenGroupsLabel.hidden = YES;
        self.sendButton.enabled = NO;

        self.chooseGroupsButton.frame = CGRectMake(10, self.bottomView.bounds.size.height / 4, self.view.bounds.size.width - 80, self.bottomView.bounds.size.height/2);
        self.chooseGroupsButton.titleLabel.textColor = [UIColor colorWithWhite:0.8 alpha:1];
        self.chooseGroupsButton.titleLabel.font = [UIFont fontWithName:BOLD_FONT size:18];
        [self.chooseGroupsButton setTitle:(!self.groupsExpanded ? @"Tap to choose groups" : @"Choose groups") forState:UIControlStateNormal];
        [self.chooseGroupsButton sizeToFit];
    }
    
}

- (void)addTopButtons {
    CGFloat buttonSize = 50;
    self.xButton = [[UIButton alloc] initWithFrame:CGRectMake(VIEW_WIDTH - buttonSize - 10, 10, buttonSize, buttonSize)];
    [self.xButton setImage:[UIImage imageNamed:@"Cancel"] forState:UIControlStateNormal];
    [self.xButton addTarget:self action:@selector(dismissAnimated) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.xButton];
    
    self.captionButton = [[UIButton alloc] initWithFrame:CGRectMake(10, 10, buttonSize, buttonSize)];
    [self.captionButton setImage:[UIImage imageNamed:@"Text"] forState:UIControlStateNormal];
    [self.captionButton addTarget:self action:@selector(captionButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.captionButton];
}

- (void)captionButtonPressed {
    #warning implement this
}

- (void)collapseGroupList {
    [self.videoPlayerView removeGestureRecognizer:self.groupsListTapOutRecognizer];
    self.groupsExpanded = NO;

    CGRect tableViewFrame = self.groupsTableView.frame;
    tableViewFrame.origin.y = VIEW_HEIGHT;
    self.trimmingView.hidden = NO;
    [UIView animateWithDuration:0.3 delay:0.0 usingSpringWithDamping:0.8 initialSpringVelocity:1 options:UIViewAnimationOptionAllowAnimatedContent animations:^{
        self.groupsTableView.frame = tableViewFrame;
        self.trimmingView.alpha = 1;
        [self layoutGroupButtons];
    } completion:^(BOOL finished) {
        self.groupsTableView.hidden = YES;
    }];
    
}

- (void)chooseGroupsPressed {
    [self.videoPlayerView addGestureRecognizer:self.groupsListTapOutRecognizer];
    self.groupsExpanded = YES;
    
    self.groupsTableView.hidden = NO;
    [self layoutGroupButtons];
    CGFloat tableHeight = MIN(self.groupsTableView.frame.size.height, [self.groups count] * kGroupRowHeight);
    CGRect tableViewFrame = self.groupsTableView.frame;
    tableViewFrame.origin.y = VIEW_HEIGHT - kBottomFrameHeight - tableHeight;
    [UIView animateWithDuration:0.3 delay:0.0 usingSpringWithDamping:0.8 initialSpringVelocity:1 options:UIViewAnimationOptionAllowAnimatedContent animations:^{
        self.groupsTableView.frame = tableViewFrame;
        self.trimmingView.alpha = 0;
    } completion:^(BOOL finished) {
        self.trimmingView.hidden = YES;
    }];
}

- (void)sendButtonTapped:(id)sender {
    
    NSMutableArray *groupsToSendTo = [NSMutableArray array];
    for (NSIndexPath *path in [self.groupsTableView indexPathsForSelectedRows]) {
        YAGroup *group = [self.groups objectAtIndex:path.row];
        [groupsToSendTo addObject:group];
    }
    
    __weak typeof(self) weakSelf = self;
    [self trimVideoWithStartTime:self.startTime andStopTime:self.endTime completion:^(NSError *error) {
        if(!error) {
            NSError *replaceError;
            NSURL *resultingUrl;
            [[NSFileManager defaultManager] replaceItemAtURL:weakSelf.videoUrl withItemAtURL:[weakSelf trimmedFileUrl] backupItemName:nil options:NSFileManagerItemReplacementUsingNewMetadataOnly resultingItemURL:&resultingUrl error:&replaceError];
            if(replaceError) {
                [YAUtils showNotification:@"Can not save video" type:YANotificationTypeError];
                return;
            }
            [weakSelf deleteTrimmedFile];
            [[YAAssetsCreator sharedCreator] createVideoFromRecodingURL:weakSelf.videoUrl addToGroups:groupsToSendTo];
            
            #warning gotta be a better way to dismiss these
            [weakSelf dismissAnimated];
            [(YASwipeToDismissViewController *)weakSelf.presentingViewController dismissAnimated];
        }
        else {
            [YAUtils showNotification:@"Error: can't trim video" type:YANotificationTypeError];
        }
    }];
}

#pragma mark - YASwipeToDismissViewController

- (void)suspendAllGestures:(id)sender {
    // prevent non-visible pages from sending stray calls
//    if ([sender isEqual:self.videoPage]) {
//        self.panGesture.enabled = NO;
//    }
}

- (void)restoreAllGestures:(id)sender  {
//    // prevent non-visible pages from sending stray calls
//    if ([sender isEqual:self.videoPage]) {
//        self.panGesture.enabled = YES;
//    }
}

- (void)dismissAnimated{
    [super dismissAnimated];
    
    [self deleteTrimmedFile];
}

#pragma mark - SAVideoRangeSliderDelegate
- (void)rangeSliderDidMoveLeftSlider:(SAVideoRangeSlider *)rangeSlider {
    
    NSLog(@"left position: %f", rangeSlider.leftPosition);

    self.dragging = YES;
    
    if(self.videoPlayerView.player.rate == 1.0){
        [self.videoPlayerView.player pause];
    }
    
    [self.videoPlayerView.player seekToTime:CMTimeMakeWithSeconds(rangeSlider.leftPosition, self.videoPlayerView.player.currentItem.asset.duration.timescale) toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero completionHandler:^(BOOL finished) {
    }];
    
//    [self.trimmingView setPlayerProgress:0.0f];
}

- (void)rangeSliderDidMoveRightSlider:(SAVideoRangeSlider *)rangeSlider {
    
    self.dragging = YES;
    
    if(self.videoPlayerView.player.rate == 1.0){
        [self.videoPlayerView.player pause];
    }
    
    [self.videoPlayerView.player seekToTime:CMTimeMakeWithSeconds(rangeSlider.rightPosition, self.videoPlayerView.player.currentItem.asset.duration.timescale) toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero completionHandler:^(BOOL finished) {
    }];
    
//    [self.trimmingView setPlayerProgress:0.0f];
}

- (void)rangeSliderDidEndMoving:(SAVideoRangeSlider *)rangeSlider {
    self.startTime = rangeSlider.leftPosition;
    self.endTime = rangeSlider.rightPosition;
    
    [self.videoPlayerView.player seekToTime:CMTimeMakeWithSeconds(self.startTime, self.videoPlayerView.player.currentItem.asset.duration.timescale) toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero completionHandler:^(BOOL finished) {
        
        NSLog(@"hello?");
        
        self.dragging = NO;
        self.videoPlayerView.playWhenReady = YES;
    }];
}

#pragma mark - Trimming
-(void)deleteTrimmedFile {
    NSURL *url = [self trimmedFileUrl];
    
    NSFileManager *fm = [NSFileManager defaultManager];
    BOOL exist = [fm fileExistsAtPath:url.path];
    
    NSError *error;
    if (exist) {
        [fm removeItemAtURL:url error:&error];
        if (error)
            DLog(@"file remove error, %@", error.localizedDescription );
    }
}

- (NSURL*)trimmedFileUrl {
    NSString *urlString = [[self.videoUrl absoluteString] lastPathComponent];
    NSString *pathExtenstion = [urlString pathExtension];
    NSString *trimmedFilename = [[[urlString stringByDeletingPathExtension] stringByAppendingString:@"_trimmed"] stringByAppendingPathExtension:pathExtenstion];
    
    NSURL *result = [YAUtils urlFromFileName:trimmedFilename];
    
    return result;
}

- (void)trimVideoWithStartTime:(CGFloat)startTime andStopTime:(CGFloat)stopTime completion:(trimmingCompletionBlock)completion {
    self.videoPlayerView.URL = nil;
    
    AVAsset *anAsset = [[AVURLAsset alloc] initWithURL:self.videoUrl options:nil];
    NSArray *compatiblePresets = [AVAssetExportSession exportPresetsCompatibleWithAsset:anAsset];
    if ([compatiblePresets containsObject:AVAssetExportPresetMediumQuality]) {
        
        self.exportSession = [[AVAssetExportSession alloc]
                              initWithAsset:anAsset presetName:AVAssetExportPresetPassthrough];
        
        NSURL *outputUrl = [self trimmedFileUrl];
        [self deleteTrimmedFile];
        
        self.exportSession.outputURL = outputUrl;
        self.exportSession.outputFileType = AVFileTypeMPEG4;
        
        CMTime start = CMTimeMakeWithSeconds(startTime, anAsset.duration.timescale);
        CMTime duration = CMTimeMakeWithSeconds(stopTime-startTime, anAsset.duration.timescale);
        CMTimeRange range = CMTimeRangeMake(start, duration);
        self.exportSession.timeRange = range;
        
        __weak typeof(self) weakSelf = self;
        [self.exportSession exportAsynchronouslyWithCompletionHandler:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                switch ([weakSelf.exportSession status]) {
                    case AVAssetExportSessionStatusFailed:
                        DLog(@"Edit video - export failed: %@", [[weakSelf.exportSession error] localizedDescription]);
                        if(completion)
                            completion([weakSelf.exportSession error]);
                        break;
                    case AVAssetExportSessionStatusCancelled:
                        DLog(@"Edit video - export canceled");
                        if(completion)
                            completion([weakSelf.exportSession error]);
                        break;
                    default:
                        if(completion)
                            completion(nil);
                        break;
                }
                
            });
        }];
        
    }
}

#pragma mark - YAVideoPlayerDelegate
- (void)playbackProgressChanged:(CGFloat)progress duration:(CGFloat)duration {
    if(!self.dragging){
        
        CGFloat end = (self.endTime == CGFLOAT_MAX) ? duration : self.endTime;

        // if is end time, loop back to the start time
        if(progress){
//            NSLog(@"progress: %f", progress);
//            NSLog(@"duration: %f", duration);
//            NSLog(@"progress/duration: %f", progress/duration);
            
        }
        
        if(progress >= end){
            
            [self.videoPlayerView.player seekToTime:CMTimeMakeWithSeconds(self.startTime, self.videoPlayerView.player.currentItem.asset.duration.timescale) toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero completionHandler:^(BOOL finished) {
            }];
        } else {
            if((progress - self.startTime) >= 0){
                CGFloat normalizedProgress = (progress - self.startTime)/(end - self.startTime);
                [self.trimmingView setPlayerProgress:normalizedProgress];
            } else {
                [self.trimmingView setPlayerProgress:0.0];
            }
            
        }

    }
}

- (BOOL)blockCameraPresentationOnBackground {
    return YES;
}

@end
