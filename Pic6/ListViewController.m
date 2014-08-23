//
//  ListViewController.m
//  Pic6
//
//  Created by Raj Vir on 8/14/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import "ListViewController.h"
#import "OnboardingNavigationController.h"
#import "GroupViewController.h"
#import "PlaqueView.h"
#import "CNetworking.h"
#import <Parse/Parse.h>
#import "NSString+File.h"
#import "CameraViewController.h"
#import "ListTileCell.h"
#import "UIImage+Resize.h"
#import "UIImage+Colors.h"

@interface ListViewController ()

@end

@implementation ListViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
//    [PFUser logOut];
//    
    if([PFUser currentUser]){
        NSLog(@"current user is set!");
        [self setupView];
    }
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
}

- (void)setupView {
    
    self.setup = [NSNumber numberWithBool:YES];
    self.picking = [NSNumber numberWithBool:NO];
    
    [self.view setBackgroundColor:PRIMARY_COLOR];
    
    PlaqueView *plaque = [[PlaqueView alloc] initWithFrame:CGRectMake(0, 0, TILE_WIDTH, TILE_HEIGHT)];
    //    [self.view addSubview:plaque];
        
    int tile_buffer = 0;
    
    UICollectionViewFlowLayout *layout= [[UICollectionViewFlowLayout alloc] init];
    [layout setSectionInset:UIEdgeInsetsMake(0, 0, TILE_HEIGHT*tile_buffer, 0)];
    [layout setMinimumInteritemSpacing:0.0];
    [layout setMinimumLineSpacing:0.0];
    self.groups = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 0, VIEW_WIDTH, VIEW_HEIGHT - TILE_HEIGHT) collectionViewLayout:layout];
    self.groups.dataSource = self;
    self.groups.delegate = self;
    
    [self.groups registerClass:[ListTileCell class] forCellWithReuseIdentifier:@"Cell"];
    [self.groups setBackgroundColor:PRIMARY_COLOR];
    
    [self.view addSubview:self.groups];
    
    [self setupFirebase];

}

- (void) setupFirebase {
    CNetworking *currentUser = [CNetworking currentUser];
    PFUser *pfUser = [PFUser currentUser];
    
    NSString *path = [NSString stringWithFormat:@"users/%@/groups", pfUser[@"phoneHash"]];
    
    NSLog(@"path: %@", path);
    
    // fetching all of a users groups
    [[currentUser.firebase childByAppendingPath:path] observeEventType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {

        __block NSNumber *received = [NSNumber numberWithInt:0];
        currentUser.groupInfo = [[NSMutableArray alloc] init];
        
        // iterate through returned groups
        for(FDataSnapshot *child in snapshot.children){
            
            NSLog(@"group id: %@", child.name);
            
            // fetch group meta data
            NSString *dataPath = [NSString stringWithFormat:@"groups/%@/data", child.name];
            [[currentUser.firebase childByAppendingPath:dataPath] observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *dataSnapshot) {
            
                // saving group data
                GroupInfo *info = [[GroupInfo alloc] init];
                info.name = dataSnapshot.value[@"name"];
                info.groupId = child.name;
                
                [currentUser.groupInfo insertObject:info atIndex:0];

                NSLog(@"fetching something!");
                // fetch most recent post from each group
                NSString *mediaPath = [NSString stringWithFormat:@"groups/%@/%@", child.name, STREAM];
                [[[currentUser.firebase childByAppendingPath:mediaPath] queryLimitedToNumberOfChildren:1] observeSingleEventOfType:FEventTypeChildAdded withBlock:^(FDataSnapshot *mediaSnapshot) {
                    
                    [[currentUser gridDataForGroupId:info.groupId] insertObject:mediaSnapshot atIndex:0];
                    
                    // add group to object
                    
//                    [self.groups reloadItemsAtIndexPaths:@[ [NSIndexPath indexPathForItem:0 inSection:0] ]];
                    
                    if([received intValue] == (snapshot.childrenCount - 1)){
                        // reload list view.
                        // done!
                        NSLog(@"done loading group metadata");
                        [self.groups reloadData];
                    } else {
                        NSLog(@"never reached count! %i", [received intValue]);
                    }
                    
                    received = [NSNumber numberWithInt:[received intValue] + 1];
                    
                    [self listenForUpdates:info.groupId];
                    
                }];

            }];
            
        }
    }];
    
}

- (void) listenForUpdates:(NSString *)groupId {
    CNetworking *currentUser = [CNetworking currentUser];
    
    NSString *mediaPath = [NSString stringWithFormat:@"groups/%@/%@", groupId, STREAM];
    [[[currentUser.firebase childByAppendingPath:mediaPath] queryLimitedToNumberOfChildren:1] observeEventType:FEventTypeChildAdded withBlock:^(FDataSnapshot *mediaSnapshot) {
        NSInteger index = -1;
        for(GroupInfo *group in currentUser.groupInfo){
            if([group.groupId isEqualToString:groupId]){
                index = [currentUser.groupInfo indexOfObject:group];
                break;
            }
        }
        
        if(index != -1){
            GroupInfo *tempGroup = [currentUser.groupInfo objectAtIndex:index];
            [currentUser.groupInfo removeObjectAtIndex:index];
            [currentUser.groupInfo insertObject:tempGroup atIndex:0];
            [self.groups moveItemAtIndexPath:[NSIndexPath indexPathForItem:index inSection:0] toIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
            
            [[currentUser gridDataForGroupId:groupId] insertObject:mediaSnapshot atIndex:0];
            [self.groups reloadItemsAtIndexPaths:@[ [NSIndexPath indexPathForItem:0 inSection:0] ]];
        }

    }];
    
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(TILE_WIDTH, TILE_HEIGHT);
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [[[CNetworking currentUser] groupInfo] count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    CNetworking *currentUser = [CNetworking currentUser];
    
    ListTileCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
    
    GroupInfo *groupInfo = [[currentUser groupInfo] objectAtIndex:indexPath.row];
    NSMutableArray *gridData = [currentUser gridDataForGroupId:groupInfo.groupId];
    
    FDataSnapshot *snapshot;
    
    if([gridData count] > 0){
        snapshot = [gridData objectAtIndex:0];
    } else {
        snapshot = nil;
    }
    
    if(![cell.uid isEqualToString:snapshot.name]){
        
        NSLog(@"id? %@", snapshot.name);
        [cell setUid:snapshot.name];
        [cell.groupTitle setText:groupInfo.name];
        NSArray *colors = (NSArray *) snapshot.value[@"colors"];
        
        [cell setColors:colors];
        
        if(cell.isLoaded){
            if([self.scrolling boolValue]){
                [cell showImage];
            } else {
                [cell play];
            }
        } else {
            NSLog(@"showing loader?");
            [cell showLoader];
            [self triggerRemoteLoad:cell.uid];
        }
        
        if([self.picking boolValue]){
            [cell showPicker];
        } else {
            [cell hidePicker];
        }

    }
    
    return cell;
}

- (void) triggerRemoteLoad:(NSString *)uid {
    
    NSLog(@"hello? %@", uid);
    
    [[[[CNetworking currentUser] firebase] childByAppendingPath:[NSString stringWithFormat:@"%@/%@", MEDIA, uid]] observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *dataSnapshot) {
        NSLog(@"anyone here? %@", dataSnapshot.name);
        if(dataSnapshot.value != [NSNull null]){
            
            NSLog(@"anyone here? %@", dataSnapshot.name);
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
    for(ListTileCell *tile in [self.groups visibleCells]){
        if([tile.uid isEqualToString:uid]){
            [self.groups reloadItemsAtIndexPaths:@[[self.groups indexPathForCell:tile]]];
        }
    }
}

- (void) collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"yoo didSelect");
    CNetworking *currentUser = [CNetworking currentUser];
    GroupInfo *info = (GroupInfo *) currentUser.groupInfo[indexPath.row];
    
    if([self.picking boolValue]){
        [self finishUploadToGroup:info.groupId];
    } else {
        GroupViewController *vc = [[GroupViewController alloc] init];
        
        vc.groupId = info.groupId;
        
        [self.cameraViewController customPresentViewController:vc];

    }
    
    
//    [self presentViewController:vc animated:YES completion:^{
//        //
//    }];
}

- (void)uploadData:(NSData *)data withType:(NSString *)type withOutputURL:(NSURL *)outputURL {
    
    self.picking = [NSNumber numberWithBool:YES];
    
    for(ListTileCell *cell in [self.groups visibleCells]){
        [cell showPicker];
    }
    
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
    
    [dataObject setValue:@{@"video":videoData, @"thumb":imageString} withCompletionBlock:^(NSError *error, Firebase *ref) {
    }];
    
    NSFileManager * fm = [[NSFileManager alloc] init];
    NSError *err = nil;
    [fm moveItemAtURL:outputURL toURL:[dataPath movieUrl] error:&err];
    [imageData writeToURL:[dataPath imageUrl] options:NSDataWritingAtomic error:&err];
    
    if(err){
        NSLog(@"error: %@", err);
    }
    
    PFUser *pfUser = [PFUser currentUser];

    self.pickingId = dataPath;
    self.pickingData = @{@"type": type, @"user":pfUser.username, @"colors":colors};

}

- (void)finishUploadToGroup:(NSString *)groupId {
    CNetworking *currentUser = [CNetworking currentUser];
    
//    NSString *groupId = [(GroupInfo *)currentUser.groupInfo[0] groupId];
    NSString *dataPath = self.pickingId;
    NSString *path = [NSString stringWithFormat:@"groups/%@/%@/%@", groupId, STREAM, dataPath];
    //    [[[[CNetworking currentUser] firebase] childByAppendingPath:path] setValue:@"yooollooo"];
    [[[[CNetworking currentUser] firebase] childByAppendingPath:path] setValue:self.pickingData];
    
    self.picking = [NSNumber numberWithBool:NO];
    
    for(ListTileCell *cell in [self.groups visibleCells]){
        [cell hidePicker];
    }
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
