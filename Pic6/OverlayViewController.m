//
//  OverlayViewController.m
//  Pic6
//
//  Created by Raj Vir on 7/3/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import "OverlayViewController.h"
#import "NSString+File.h"

@interface OverlayViewController ()
@property (strong, nonatomic) NSArray *reactions;
@property int reactionIndex;
@end

@implementation OverlayViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated {

    //add background for tap gesture recognizer
    self.bg = [[UIView alloc] initWithFrame:CGRectMake(0, 0, VIEW_WIDTH, VIEW_HEIGHT)];
    [self.bg setBackgroundColor:[UIColor blackColor]];
    [self.view addSubview:self.bg];
    
    [self.view addSubview:self.tile];

    [self initUserLabel];
    [self initLikeButton];
    [self initSettingsButton];
    
//    [self initCaptionLabel];
    
    [UIView animateWithDuration:0.5 delay:0 usingSpringWithDamping:0.7 initialSpringVelocity:0.7 options:0 animations:^{
        [self.userLabel setAlpha:1.0];
        [self.likeButton setAlpha:1.0];
//        [self.captionField setAlpha:1.0];
    } completion:^(BOOL finished) {
        //
    }];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapped:)];
    [self.view addGestureRecognizer:tap];
    
    self.reactions = @[@"❤️", @"💙", @"💜", @"💚", @"💛"]; //😐", @"😄", @"😍", @"😜", @"😂", @"😎", @"😮"];
    // Do any additional setup after loading the view.
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didEnterBackground)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(willResignActive)
                                                 name:UIApplicationWillResignActiveNotification
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(willEnterForeground)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didBecomeActive)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];

}

- (void) initUserLabel {
    self.userLabel = [[UILabel alloc] initWithFrame:CGRectMake(8, TILE_HEIGHT*3 + 8, TILE_WIDTH, 48)];
    [self.userLabel setTextAlignment:NSTextAlignmentLeft];
    [self.userLabel setTextColor:[UIColor whiteColor]];
    [self.userLabel setFont:[UIFont systemFontOfSize:36]];
    [self.userLabel setText:self.tile.username];
    [self.userLabel setAlpha:0.0];
    [self.view addSubview:self.userLabel];
}

- (void) initLikeButton {
    float size = 60.0f;
    
    self.reactionIndex = 0;
    
    self.likeButton = [[UIButton alloc] initWithFrame:CGRectMake(VIEW_WIDTH-4-size, TILE_HEIGHT*3 + 4, size, size)];
    [self.likeButton setTitle:self.reactions[self.reactionIndex] forState:UIControlStateNormal];
    [self.likeButton.titleLabel setTextAlignment:NSTextAlignmentRight];
    [self.likeButton setContentVerticalAlignment:UIControlContentVerticalAlignmentTop];
    [self.likeButton.titleLabel setFont:[UIFont systemFontOfSize:44]];
    [self.likeButton addTarget:self action:@selector(likeButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    [self.likeButton setAlpha:0.0];
    [self.view addSubview:self.likeButton];
}

- (void)likeButtonPressed {
    self.reactionIndex++;
    if(self.reactionIndex >= [self.reactions count]){
        self.reactionIndex = 0;
    }
    
    [self.likeButton setTitle:self.reactions[self.reactionIndex] forState:UIControlStateNormal];
    
    [UIView animateKeyframesWithDuration:0.5 delay:0 options:0 animations:^{
        [UIView addKeyframeWithRelativeStartTime:0.0 relativeDuration:0.4 animations:^{
            self.likeButton.transform = CGAffineTransformMakeScale(1.5, 1.5);
        }];
        
        [UIView addKeyframeWithRelativeStartTime:0.6 relativeDuration:0.4 animations:^{
            self.likeButton.transform = CGAffineTransformIdentity;
        }];
        
    } completion:^(BOOL finished) {
        //
    }];
}

- (void) initSettingsButton {
    CGFloat size = 60.0f;
    self.settingsButton = [[UIButton alloc] initWithFrame:CGRectMake(VIEW_WIDTH - size, TILE_HEIGHT - 4 - size, size, size)];
    [self.settingsButton setTitle:@"🔧" forState:UIControlStateNormal];
    [self.settingsButton.titleLabel setFont:[UIFont systemFontOfSize:36]];
//    [self.settingsButton setContentHorizontalAlignment:UIControlContentHorizontalAlignmentRight];
    [self.settingsButton addTarget:self action:@selector(settingsButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.settingsButton];
    
}

- (void) settingsButtonPressed {
    UIActionSheet *settings = [[UIActionSheet alloc] initWithTitle:@"" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Delete" otherButtonTitles:[NSString stringWithFormat:@"Block %@", self.tile.username], [NSString stringWithFormat:@"Add %@ to Clique", self.tile.username], @"Save to Camera Roll", nil];
    
    [settings setActionSheetStyle:UIActionSheetStyleBlackOpaque];
    [settings showInView:self.view];    
    
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    switch (buttonIndex) {
        case 3:
            UISaveVideoAtPathToSavedPhotosAlbum([self.tile.uid moviePath],nil,nil,nil);
            break;
        default:
            break;
    }
    NSLog(@"button index: %lu", buttonIndex);
}

- (void) initCaptionLabel {
    self.captionField = [[UITextView alloc] initWithFrame:CGRectMake(5, TILE_HEIGHT*3 + 8 + 48, VIEW_WIDTH - 16, 76)];
    
//    [self.captionLabel setTextAlignment:NSTextAlignmentLeft];
    [self.captionField setText:@"Add caption"];
    [self.captionField setTextColor:[UIColor grayColor]];
    [self.captionField setFont:[UIFont systemFontOfSize:18]];
    [self.captionField setBackgroundColor:[UIColor clearColor]];
    [self.captionField setAlpha:0.0];
    [self.view addSubview:self.captionField];
    
    NSLog(@"%@", NSStringFromCGRect(self.captionField.bounds));
}

- (void) getCaptionText:(NSString *)uid {
}

- (void)tapped:(UITapGestureRecognizer *)gesture {
    [self collapse:0.3f];
}

- (void)collapse:(CGFloat)speed {
    [self.tile.player setVolume:0.0];
    //    [self.bg removeFromSuperview];
    [self.previousViewController.overlay addSubview:self.tile];
    [self dismissViewControllerAnimated:NO completion:^{
        [self.previousViewController collapse:self.tile speed:speed];
    }];
}

- (void)didEnterBackground {
//    [self.view setAlpha:0.0];
//    [self collapse:0.0f];
//    [self.view setAlpha:0.0f];
//    [self.previousViewController.view setAlpha:0.0f];
//    [self.previousViewController.gridTiles reloadItemsAtIndexPaths:@[[self.previousViewController.gridTiles indexPathForCell:self.tile]]];

//    [self.view setAlpha:0.0];
//    [self.tile setVideoFrame:CGRectMake(0, 0, TILE_WIDTH, TILE_HEIGHT)];
}

- (void)willEnterForeground {
//    [self tapped:[UITapGestureRecognizer new]];
}

- (void)willResignActive {
//    [self.view setAlpha:0.0];
    [self collapse:0.2f];
}

- (void)didBecomeActive {
//    [self.view setAlpha:1.0];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
