//
//  OverlayViewController.m
//  Pic6
//
//  Created by Raj Vir on 7/3/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import "OverlayViewController.h"
#import "NSString+File.h"
#import "CNetworking.h"
//#import "NSDate+TimeAgo.h"

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
    
    [self initLabels];
//    [self initLikeButton];
//    [self initSettingsButton];
//
//    [self initCaptionLabel];
    
    [UIView animateWithDuration:0.5 delay:0 usingSpringWithDamping:0.7 initialSpringVelocity:0.7 options:0 animations:^{
        for(UIView *label in self.labels){
            [label setAlpha:1.0];
        }
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
    tap.numberOfTapsRequired = 1;
    
    UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTapped:)];
    [doubleTap setNumberOfTapsRequired:2];
    [self.view addGestureRecognizer:doubleTap];
    
    [tap requireGestureRecognizerToFail:doubleTap];
    
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
    
    self.labels = [[NSMutableArray alloc] init];
    
}

- (void) initLabels {
    CGFloat height = 30;
    CGFloat gutter = 48;
    self.userLabel = [[UILabel alloc] initWithFrame:CGRectMake(gutter, 12, VIEW_WIDTH - gutter*2, height)];
    [self.userLabel setTextAlignment:NSTextAlignmentCenter];
    [self.userLabel setTextColor:[UIColor whiteColor]];
    [self.userLabel setFont:[UIFont fontWithName:BIG_FONT size:24]];
    [self.userLabel setText:self.tile.username];
    
    self.userLabel.layer.shadowColor = [[UIColor blackColor] CGColor];
    self.userLabel.layer.shadowRadius = 1.0f;
    self.userLabel.layer.shadowOpacity = 1.0;
    self.userLabel.layer.shadowOffset = CGSizeZero;
    
    [self.labels addObject:self.userLabel];
    
    CGFloat timeHeight = 24;
    self.timestampLabel = [[UILabel alloc] initWithFrame:CGRectMake(gutter, height + 12, VIEW_WIDTH - gutter*2, timeHeight)];
    [self.timestampLabel setTextAlignment:NSTextAlignmentCenter];
    [self.timestampLabel setTextColor:[UIColor whiteColor]];
    [self.timestampLabel setFont:[UIFont fontWithName:BIG_FONT size:14]];
    
    if(self.tile.snapshot.value[@"time"]){
        NSNumber *time = self.tile.snapshot.value[@"time"];
        NSDate *date = [[NSDate alloc] initWithTimeIntervalSinceReferenceDate:[time doubleValue]];
        NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
        [dateFormat setDateFormat:@"MM/dd hh:mma"];
        NSString *dateString = [dateFormat stringFromDate:date];
        //        NSLog(@"date: %@", dateString);
        [self.timestampLabel setText:dateString];
    } else {
        [self.timestampLabel setText:@"00:00"];
    }
    
    
    
    [self.timestampLabel setAlpha:0.0];
    
    self.timestampLabel.layer.shadowColor = [[UIColor blackColor] CGColor];
    self.timestampLabel.layer.shadowRadius = 1.0f;
    self.timestampLabel.layer.shadowOpacity = 1.0;
    self.timestampLabel.layer.shadowOffset = CGSizeZero;
    [self.labels addObject:self.timestampLabel];
    
    CGFloat captionHeight = 30;
    CGFloat captionGutter = 2;
    self.captionField = [[UITextField alloc] initWithFrame:CGRectMake(captionGutter, self.timestampLabel.frame.size.height + self.timestampLabel.frame.origin.y, VIEW_WIDTH - captionGutter*2, captionHeight)];
    [self.captionField setBackgroundColor:[UIColor clearColor]];
    [self.captionField setTextAlignment:NSTextAlignmentCenter];
    [self.captionField setTextColor:[UIColor whiteColor]];
    [self.captionField setFont:[UIFont fontWithName:BIG_FONT size:24]];
    
    self.captionField.delegate = self;
    [self.captionField setAutocorrectionType:UITextAutocorrectionTypeNo];
    
    [self.tile.snapshot.ref observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
        [self.captionField setText:snapshot.value[@"caption"]];
    }];
//    [[self.tile.snapshot.ref childByAppendingPath:@"caption"] setValue:self.captionField.text
//    if(self.tile.snapshot.value[@"caption"]){
//        [self.captionField setText:self.tile.snapshot.value[@"caption"]];
//    }
    
    //    [self.captionField addTarget:self action:@selector(textChanged) forControlEvents:UIControlEventEditingChanged];
    
    self.captionField.layer.shadowColor = [[UIColor blackColor] CGColor];
    self.captionField.layer.shadowRadius = 1.0f;
    self.captionField.layer.shadowOpacity = 1.0;
    self.captionField.layer.shadowOffset = CGSizeZero;
    [self.labels addObject:self.captionField];
    
    
    CGFloat likeSize = 42;
    self.likeButton = [[UIButton alloc] initWithFrame:CGRectMake((VIEW_WIDTH - likeSize)/2, VIEW_HEIGHT - likeSize - 12, likeSize, likeSize)];
    [self.likeButton setBackgroundImage:[UIImage imageNamed:@"Like"] forState:UIControlStateNormal];
    [self.likeButton addTarget:self action:@selector(likeButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    [self.labels addObject:self.likeButton];
    
    CGFloat tSize = 36;
    self.captionButton = [[UIButton alloc] initWithFrame:CGRectMake(VIEW_WIDTH - tSize - 12, 12, tSize, tSize)];
    [self.captionButton setBackgroundImage:[UIImage imageNamed:@"Text"] forState:UIControlStateNormal];
    [self.captionButton addTarget:self action:@selector(textButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    [self.labels addObject:self.captionButton];
    
    for(UIView *view in self.labels){
        [view setAlpha:0.0];
        [self.view addSubview:view];
    }
    
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSString *text = [textField.text stringByReplacingCharactersInRange:range withString:string];
    NSDictionary *attributes = @{NSFontAttributeName: textField.font};
    
    CGFloat width = [text sizeWithAttributes:attributes].width;
    //    CGFloat width =  [text sizeWithFont:textField.font].width;
    
    if(width <= self.captionField.frame.size.width){
        return YES;
    } else {
        return NO;
    }
    
}

- (void)textChanged {
    CGFloat width = [self.captionField.text sizeWithAttributes:@{NSFontAttributeName:self.captionField.font}].width;
    if(width > self.captionField.frame.size.width){
        
    }
}

- (void)textButtonPressed {
    NSLog(@"test");
    [self.captionField becomeFirstResponder];
}



- (void)likeButtonPressed {
    
    [UIView animateKeyframesWithDuration:0.5 delay:0 options:0 animations:^{
        [UIView addKeyframeWithRelativeStartTime:0.0 relativeDuration:0.4 animations:^{
            self.likeButton.transform = CGAffineTransformMakeScale(1.5, 1.5);
        }];
        
        [self.likeButton setBackgroundImage:[UIImage imageNamed:@"Liked"] forState:UIControlStateNormal];
        
        [UIView addKeyframeWithRelativeStartTime:0.6 relativeDuration:0.4 animations:^{
            self.likeButton.transform = CGAffineTransformIdentity;
        }];
        
    } completion:^(BOOL finished) {
        //
    }];
}

- (void) settingsButtonPressed {
    UIActionSheet *settings = [[UIActionSheet alloc] initWithTitle:@"" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Delete" otherButtonTitles:@"Save to Camera Roll", nil];
    
    [settings setActionSheetStyle:UIActionSheetStyleBlackOpaque];
    [settings showInView:self.view];
    
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    switch (buttonIndex) {
        case 0:
            // delete
            if([self.tile.username isEqualToString:(NSString *)[[CNetworking currentUser] userDataForKey:nUsername]]){
                // delete and collapse
                [self.tile.player setVolume:0.0];
                //    [self.bg removeFromSuperview];
                [self.previousViewController.overlay addSubview:self.tile];
                [self dismissViewControllerAnimated:NO completion:^{
                    [self.previousViewController collapse:self.tile speed:0.3];
                    [self.previousViewController deleteUid:self.tile.uid];
                }];
                
            } else {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Not your video"
                                                                message:@"You can only delete your own videos"
                                                               delegate:nil
                                                      cancelButtonTitle:@"OK"
                                                      otherButtonTitles:nil];
                [alert show];
            }
        case 1:
            UISaveVideoAtPathToSavedPhotosAlbum([self.tile.uid moviePath],nil,nil,nil);
            break;
        default:
            break;
    }
    NSLog(@"button index: %lu", buttonIndex);
}

- (void) initCaptionLabel {
    self.captionField = [[UITextField alloc] initWithFrame:CGRectMake(5, TILE_HEIGHT*3 + 8 + 48, VIEW_WIDTH - 16, 76)];
    
    //    [self.captionLabel setTextAlignment:NSTextAlignmentLeft];
    [self.captionField setText:@"Add caption"];
    [self.captionField setTextColor:[UIColor grayColor]];
    [self.captionField setFont:[UIFont systemFontOfSize:18]];
    [self.captionField setBackgroundColor:[UIColor clearColor]];
    [self.captionField setAlpha:0.0];
    [self.captionField setReturnKeyType:UIReturnKeyDone];
    [self.view addSubview:self.captionField];
    
    NSLog(@"%@", NSStringFromCGRect(self.captionField.bounds));
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
//    [textField resignFirstResponder];
    [self collapseCaption];
    return YES;
}

- (void) getCaptionText:(NSString *)uid {
}

- (void)tapped:(UITapGestureRecognizer *)gesture {
    if([self.captionField isFirstResponder]){
        [self collapseCaption];
    } else {
        [self collapse:0.3f];
    }
}

- (void)collapseCaption {
    if([[self.captionField text] length] > 0) {
        [[self.tile.snapshot.ref childByAppendingPath:@"caption"] setValue:self.captionField.text withCompletionBlock:^(NSError *error, Firebase *ref) {
            //
//            [ref observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
//                self.tile.snapshot = snapshot;
////                [CNetworking currentUser] gridDataForGroupId:<#(NSString *)#>
//            }];
        }];
//        [self.tile.snapshot.ref setValue:self.captionField.text forKeyPath:@"caption"];
//        [[CNetworking currentUser] firebase] childByAppendingPath:<#(NSString *)#>
    }
    [self.captionField resignFirstResponder];
}

- (void)doubleTapped:(UITapGestureRecognizer *)gesture {
    [self.captionField becomeFirstResponder];
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
