//
//  MainViewController.m
//  Pic6
//
//  Created by Raj Vir on 4/27/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import "GroupViewController.h"
#import "UIImage+Resize.h"
#import "UIImage+Colors.h"
#import "NSString+File.h"
#import "TileCell.h"
#import "AVPlayer+AVPlayer_Async.h"
#import "OverlayViewController.h"
#import "CliqueViewController.h"
#import "OnboardingNavigationController.h"
#import <Crashlytics/Crashlytics.h>
#import <Parse/Parse.h>

@interface GroupViewController ()
@end

@implementation GroupViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:YES animated:YES];
}

- (void)viewDidAppear:(BOOL)animated {
    
    if([PFUser currentUser]){
        NSLog(@"current user is set in View Did Appear!");
        if(![self.appeared boolValue]){
            self.appeared = [NSNumber numberWithBool:YES];
            if(![self.setup boolValue]){
                [self setupView];
            }
        }
    } else {
        NSLog(@"poop. not logged in.");
        OnboardingNavigationController *vc = [[OnboardingNavigationController alloc] init];
        [self presentViewController:vc animated:NO completion:^{
            //
        }];
    }

////    [currentUser saveUserData:[NSNumber numberWithBool:NO] forKey:@"onboarded"];
//    CNetworking *currentUser = [CNetworking currentUser];
//
//    if([(NSNumber *)[currentUser userDataForKey:@"onboarded"] boolValue]){
//        if(![self.appeared boolValue]){
//            self.appeared = [NSNumber numberWithBool:YES];
//            if(![self.setup boolValue]){
//                [self setupView];
//            }
//        }
//    } else {
//        OnboardingNavigationController *vc = [[OnboardingNavigationController alloc] init];
//        [self presentViewController:vc animated:NO completion:^{
//            //
//        }];
//    }

}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if([PFUser currentUser]){
        NSLog(@"group id: %@", self.groupId);
        NSLog(@"current user is set!");
        [self setupView];
    }
//    [currentUser saveUserData:[NSNumber numberWithBool:NO] forKey:@"onboarded"];
//    
//    if([(NSNumber *)[currentUser userDataForKey:@"onboarded"] boolValue]){
//        [currentUser saveUserData:[NSNumber numberWithBool:YES] forKey:@"onboarded"];
//        [self setupView];
//    }
}

- (void)setupView {
    
    NSLog(@"setting up muthafuckas");
    
    self.setup = [NSNumber numberWithBool:YES];
        
    [Crashlytics setUserIdentifier:(NSString *) [[CNetworking currentUser] userDataForKey:@"username"]];
    
    [self initOverlay];
    [self initGridView];
    [self initGridTiles];
    [self initLoader];
    [self initFirebase];
    // look at afterCameraInit to see what happens after the camera gets initialized. eg initFirebase.

}

- (void)initGridView {
    self.gridView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, TILE_WIDTH * 2, TILE_HEIGHT * 4)];
    [self.gridView setBackgroundColor:PRIMARY_COLOR];
    
    [self.view addSubview:self.gridView];
}

- (void) initGridTiles {
    int tile_buffer = 0;
    
    UICollectionViewFlowLayout *layout= [[UICollectionViewFlowLayout alloc] init];
    [layout setSectionInset:UIEdgeInsetsMake(0, 0, TILE_HEIGHT*tile_buffer, 0)];
    [layout setMinimumInteritemSpacing:0.0];
    [layout setMinimumLineSpacing:0.0];
    self.gridTiles = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 0, TILE_WIDTH*2, TILE_HEIGHT*3 + tile_buffer*TILE_HEIGHT) collectionViewLayout:layout];
    self.gridTiles.delegate = self;
    self.gridTiles.dataSource = self;
    [self.gridTiles registerClass:[TileCell class] forCellWithReuseIdentifier:@"Cell"];
    [self.gridTiles setBackgroundColor:PRIMARY_COLOR];
    //    [self.gridTiles setBounces:NO];
    [self.gridView addSubview:self.gridTiles];
    
    self.pull = [[UIRefreshControl alloc] init];
    [self.pull setTintColor:[UIColor whiteColor]];
    [self.pull addTarget:self action:@selector(refreshTable) forControlEvents:UIControlEventValueChanged];
    [self.gridTiles addSubview:self.pull];
    
    CGFloat size = 48;
    self.loader = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake((self.gridTiles.frame.size.width - size)/2, (self.gridTiles.frame.size.height - size)/2, size, size)];
    [self.loader setTintColor:[UIColor whiteColor]];
    [self.loader setHidesWhenStopped:YES];
    [self.loader setActivityIndicatorViewStyle:UIActivityIndicatorViewStyleWhiteLarge];
    [self.gridTiles addSubview:self.loader];
    [self.loader startAnimating];
    
}

- (void) initLoader {
    NSLog(@"initing loader");
    UIView *loader = [[UIView alloc] initWithFrame:self.gridTiles.frame];
    [self.gridView insertSubview:loader belowSubview:self.gridTiles];
}

- (void) initOverlay {
    self.overlay = [[UIView alloc] initWithFrame:CGRectMake(0, 0, TILE_WIDTH * 2, TILE_HEIGHT*4)];
    [self.overlay setBackgroundColor:[UIColor blackColor]];
    [self.overlay setAlpha:0.0];

    [self.view addSubview:self.overlay];
}

- (void)initFirebase {

//    NSString *hash = [PFUser currentUser][@"phoneHash"];
//    NSString *escapedHash = [hash stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]];

    CNetworking *currentUser = [CNetworking currentUser];
    
    [[[[currentUser firebase] childByAppendingPath:[NSString stringWithFormat:@"groups/%@/%@", self.groupId, STREAM]] queryLimitedToNumberOfChildren:NUM_TILES] observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
        NSLog(@"children count: %lu", snapshot.childrenCount);
        for (FDataSnapshot* child in snapshot.children) {
            
            NSMutableArray *gridData = [currentUser gridDataForGroupId:self.groupId];
            [gridData insertObject:child atIndex:0];
        }
        [self.loader stopAnimating];
        [self.gridTiles reloadData];
        [self listenForChanges];
    }];
}

- (void)listenForChanges {
    
    [[[[[CNetworking currentUser] firebase] childByAppendingPath:[NSString stringWithFormat:@"groups/%@/%@", self.groupId, STREAM]] queryLimitedToNumberOfChildren:1] observeEventType:FEventTypeChildAdded withBlock:^(FDataSnapshot *snapshot) {
//        [self newTile:snapshot];
    }];
}

- (void) newTile:(FDataSnapshot *)snapshot {
    NSLog(@"newtile called?");
    CNetworking *currentUser = [CNetworking currentUser];
    NSMutableArray *gridData = [currentUser gridDataForGroupId:self.groupId];
    if(!([gridData count] > 0 && [[(FDataSnapshot *) gridData[0] name] isEqualToString:snapshot.name])){
        [gridData insertObject:snapshot atIndex:0];
        [self.gridTiles insertItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:0 inSection:0]]];
        NSLog(@"wtf conditional!!");
    }
}

- (void) triggerRemoteLoad:(NSString *)uid {
    
    [[[[CNetworking currentUser] firebase] childByAppendingPath:[NSString stringWithFormat:@"%@/%@", MEDIA, uid]] observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *dataSnapshot) {
        if(dataSnapshot.value != [NSNull null]){
            NSError *error = nil;
            
            NSData *videoData = [[NSData alloc] initWithBase64EncodedString:dataSnapshot.value[@"video"] options:NSDataBase64DecodingIgnoreUnknownCharacters];
            
            NSData *imageData = [[NSData alloc] initWithBase64EncodedString:dataSnapshot.value[@"thumb"] options:NSDataBase64DecodingIgnoreUnknownCharacters];

            if(videoData != nil && imageData != nil){
                NSURL *movieURL = [uid movieUrl];
                [videoData writeToURL:movieURL options:NSDataWritingAtomic error:&error];

                NSURL *imageURL = [uid imageUrl];
                [imageData writeToURL:imageURL options:NSDataWritingAtomic error:&error];
            }
            
            [self finishedLoading:uid];
            
        }
    }];
}

- (void) finishedLoading:(NSString *)uid {
    for(TileCell *tile in [self.gridTiles visibleCells]){
        if([tile.uid isEqualToString:uid]){
            [self.gridTiles reloadItemsAtIndexPaths:@[[self.gridTiles indexPathForCell:tile]]];
        }
    }
}

- (void) refreshTable {
    [self.pull endRefreshing];
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    NSUInteger count = [[[CNetworking currentUser] gridDataForGroupId:self.groupId] count];
    NSLog(@"count: %lu", count);
    return count;
}

-(CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(TILE_WIDTH, TILE_HEIGHT);
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    TileCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
    FDataSnapshot *snapshot = [[[CNetworking currentUser] gridDataForGroupId:self.groupId] objectAtIndex:indexPath.row];
    
    if(![cell.uid isEqualToString:snapshot.name]){

        [cell setUid:snapshot.name];
        [cell setUsername:snapshot.value[@"user"]];
        
        NSArray *colors = (NSArray *) snapshot.value[@"colors"];
        
        [cell setColors:colors];
        
        if(cell.isLoaded){
            if([self.scrolling boolValue]){
//                [cell play];
                [cell showImage];
            } else {
                [cell play];
            }
        } else {
            [cell showLoader];
            [self triggerRemoteLoad:cell.uid];
        }
    }
        
    return cell;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    self.scrolling = [NSNumber numberWithBool:YES];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    self.scrolling = [NSNumber numberWithBool:NO];
    [self scrollingEnded];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if(!decelerate){
        self.scrolling = [NSNumber numberWithBool:NO];
        [self performSelector:@selector(scrollingEnded) withObject:self afterDelay:0.1];
    }
}

- (void)scrollingEnded {
    if(![self.scrolling boolValue]){
        for(TileCell *cell in [self.gridTiles visibleCells]){
            if([cell.state isEqualToNumber:[NSNumber numberWithInt: LOADED]]){
                [cell play];
            } else {
                
            }
        }
    }
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    
    TileCell *selected = (TileCell *)[collectionView cellForItemAtIndexPath:indexPath];
    
    if([selected.state isEqualToNumber:[NSNumber numberWithInt:PLAYING]]) {
        if(selected.player.rate == 1.0){
            selected.frame = CGRectMake(selected.frame.origin.x, selected.frame.origin.y - collectionView.contentOffset.y + TILE_HEIGHT, TILE_WIDTH, TILE_HEIGHT);
            [self.overlay addSubview:selected];
            
            [UIView animateWithDuration:0.5 delay:0.0 usingSpringWithDamping:0.7 initialSpringVelocity:0.7 options:0 animations:^{
                [self.view bringSubviewToFront:self.overlay];
                [self.overlay setAlpha:1.0];
                [selected.player setVolume:1.0];
                [selected setVideoFrame:CGRectMake(0, TILE_HEIGHT, TILE_WIDTH*2, TILE_HEIGHT*2)];
            } completion:^(BOOL finished) {
                //
                OverlayViewController *overlay = [[OverlayViewController alloc] init];
                [overlay setTile:selected];
                [overlay setPreviousViewController:self];
                self.modalPresentationStyle = UIModalPresentationCurrentContext;
                [self presentViewController:overlay animated:NO completion:^{
                    
                }];
            }];
        } else {
            [collectionView reloadItemsAtIndexPaths:@[indexPath]];
        }
    } else {
        NSLog(@"state: %@", selected.state);
//        [collectionView reloadItemsAtIndexPaths:@[[collectionView indexPathForCell:selected]]];
    }
    
}

- (void) collapse:(TileCell *)tile speed:(CGFloat)speed {
    tile.frame = CGRectMake(0, self.gridTiles.contentOffset.y, TILE_WIDTH*2, TILE_HEIGHT*2);
    [self.gridTiles addSubview:tile];
    [self.overlay setAlpha:0.0];
//    [self.gridTiles addSubview:self.overlay];
    [UIView animateWithDuration:speed delay:0.0 usingSpringWithDamping:0.9 initialSpringVelocity:0.7 options:0 animations:^{
        NSIndexPath *ip = [self.gridTiles indexPathForCell:tile];
        [tile setVideoFrame:[self.gridTiles layoutAttributesForItemAtIndexPath:ip].frame];
        //
    } completion:^(BOOL finished) {
        //
    }];
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
    
}

- (void)manageClique:(id)sender { //switch cameras front and rear cameras
    CliqueViewController *vc = [[CliqueViewController alloc] init];
    [self presentViewController:vc animated:YES completion:^{
        //
    }];
}

- (void)uploadData:(NSData *)data withType:(NSString *)type withOutputURL:(NSURL *)outputURL {
    // measure size of data
    NSLog(@"%@ size: %lu", type, (unsigned long)[data length]);
    
    // set up data object
    NSString *videoData = [data base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
    Firebase *dataObject = [[[[CNetworking currentUser] firebase] childByAppendingPath:[NSString stringWithFormat:@"%@", MEDIA]] childByAutoId];
    NSString *dataPath = dataObject.name;
    
    AVURLAsset* asset = [AVURLAsset URLAssetWithURL:outputURL options:nil];
    AVAssetImageGenerator* imageGenerator = [AVAssetImageGenerator assetImageGeneratorWithAsset:asset];
    [imageGenerator setAppliesPreferredTrackTransform:YES];
//    UIImage* image = [UIImage imageWithCGImage:[imageGenerator copyCGImageAtTime:CMTimeMake(0, 1) actualTime:nil error:nil]];
    CGImageRef imageRef = [imageGenerator copyCGImageAtTime:CMTimeMake(0,1) actualTime:nil error:nil];
    
    UIImage *image = [[UIImage imageWithCGImage:imageRef] imageScaledToFitSize:CGSizeMake(TILE_WIDTH*2, TILE_HEIGHT*2)];
    NSData *imageData = UIImageJPEGRepresentation(image, 0.7);
    NSString *imageString = [imageData base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
    
    NSArray *colors = [image getColors];
    
//    for(NSString *color in colors){
//        NSLog(@"color: %@", color);
//    }
    
    [dataObject setValue:@{@"video":videoData, @"thumb":imageString} withCompletionBlock:^(NSError *error, Firebase *ref) {
    }];
    
    NSMutableDictionary *clique = (NSMutableDictionary *)[PFUser currentUser][@"clique"];
    [clique setObject:@1 forKeyedSubscript:[PFUser currentUser][@"phoneHash"]];
    
//    for(NSString *hash in clique){
//        NSLog(@"hash: %@", hash);
//        NSString *escapedHash = [hash stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]];
//        NSString *path = [NSString stringWithFormat:@"%@/%@/%@", STREAM, escapedHash, dataPath];
//        [[[[CNetworking currentUser] firebase] childByAppendingPath:path] setValue:@{@"type": type, @"user":(NSString *)[[CNetworking currentUser] userDataForKey:@"username"], @"colors":colors}];
//    }
    
    PFUser *pfUser = [PFUser currentUser];
    NSLog(@"group id: %@", self.groupId);
    NSString *path = [NSString stringWithFormat:@"groups/%@/%@/%@", self.groupId, STREAM, dataPath];
//    [[[[CNetworking currentUser] firebase] childByAppendingPath:path] setValue:@"yooollooo"];
    [[[[CNetworking currentUser] firebase] childByAppendingPath:path] setValue:@{@"type": type, @"user":pfUser.username, @"colors":colors}];
    
    NSFileManager * fm = [[NSFileManager alloc] init];
    NSError *err = nil;
    [fm moveItemAtURL:outputURL toURL:[dataPath movieUrl] error:&err];
    [imageData writeToURL:[dataPath imageUrl] options:NSDataWritingAtomic error:&err];

    if(err){
        NSLog(@"error: %@", err);
    }
    
}

- (void)willResignActive {
//    [self removeAudioInput];
// remove microphone

}

- (void)didBecomeActive {
//    [self addAudioInput];
// add microphone
}

- (void)didEnterBackground {
//    NSLog(@"did enter background");
//    [self.view setAlpha:0.0];
    for(TileCell *tile in [self.gridTiles visibleCells]){
        if([tile.state isEqualToNumber:[NSNumber numberWithInt: PLAYING]]){
            tile.state = [NSNumber numberWithInt:LOADED];
            tile.player = nil;
            [tile.player removeObservers];
        }
    }
}

- (void)willEnterForeground {
//    NSLog(@"will enter foreground");
//    [self.view setAlpha:1.0];
    [self.gridTiles reloadData];

//    for(TileCell *tile in [self.gridTiles visibleCells]){
//        if([tile.state isEqualToNumber:[NSNumber numberWithInt: PLAYING]] || [tile.state  isEqualToNumber:[NSNumber numberWithInt:  LOADED]]){
//            [tile play];
//        }
//    }
}

- (void)dismiss {
    [self dismissViewControllerAnimated:YES completion:^{
        //
    }];
}

-(BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    NSLog(@"memory warning?");
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