//
//  ListViewController.m
//  Pic6
//
//  Created by Raj Vir on 8/14/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import "ListViewController.h"
#import "OnboardingNavigationController.h"
#import "CreateGroupViewController.h"
#import "GridViewController.h"
#import "PlaqueView.h"
#import "TileCell.h"
#import "CNetworking.h"
#import <Parse/Parse.h>
#import "NSString+File.h"

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

    [self.view setBackgroundColor:PRIMARY_COLOR];
    
    PlaqueView *plaque = [[PlaqueView alloc] initWithFrame:CGRectMake(0, 0, TILE_WIDTH, TILE_HEIGHT)];
    //    [self.view addSubview:plaque];
    
    UIButton *createGroup = [[UIButton alloc] initWithFrame:CGRectMake(20, 20, 50, 50)];
    [createGroup addTarget:self action:@selector(createGroup) forControlEvents:UIControlEventTouchUpInside];
    [createGroup.titleLabel setFont:[UIFont systemFontOfSize:30]];
    [createGroup setTitle:@"+" forState:UIControlStateNormal];
    [createGroup setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.view addSubview:createGroup];
    
    int tile_buffer = 0;
    
    UICollectionViewFlowLayout *layout= [[UICollectionViewFlowLayout alloc] init];
    [layout setSectionInset:UIEdgeInsetsMake(0, 0, TILE_HEIGHT*tile_buffer, 0)];
    [layout setMinimumInteritemSpacing:0.0];
    [layout setMinimumLineSpacing:0.0];
    self.groups = [[UICollectionView alloc] initWithFrame:CGRectMake(0, TILE_HEIGHT, VIEW_WIDTH, VIEW_HEIGHT - TILE_HEIGHT) collectionViewLayout:layout];
    self.groups.dataSource = self;
    self.groups.delegate = self;
    
    [self.groups registerClass:[TileCell class] forCellWithReuseIdentifier:@"Cell"];
    [self.groups setBackgroundColor:PRIMARY_COLOR];
    
    [self.view addSubview:self.groups];
    
    [self setupFirebase];

}

- (void)createGroup {
    NSLog(@"create group pressed");
    CreateGroupViewController *vc = [[CreateGroupViewController alloc] init];
    [self presentViewController:vc animated:YES completion:^{
        //
    }];
}

- (void) setupFirebase {
    CNetworking *currentUser = [CNetworking currentUser];
    PFUser *pfUser = [PFUser currentUser];
    
    NSString *path = [NSString stringWithFormat:@"users/%@/groups", pfUser[@"phoneHash"]];
    
    NSLog(@"path: %@", path);
    
    NSLog(@"setting up firebase");
    
    [[currentUser.firebase childByAppendingPath:path] observeEventType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {

        currentUser.groupInfo = [[NSMutableArray alloc] init];
        for(FDataSnapshot *child in snapshot.children){
            
            NSLog(@"group id: %@", child.name);
            
            NSString *dataPath = [NSString stringWithFormat:@"groups/%@/data", child.name];
            [[currentUser.firebase childByAppendingPath:dataPath] observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *dataSnapshot) {
                
                GroupInfo *info = [[GroupInfo alloc] init];
                info.name = dataSnapshot.value[@"name"];
                info.latestSnapshot = nil;
                info.groupId = child.name;
                
                [currentUser.groupInfo addObject:info];
                
                if([currentUser.groupInfo count] == snapshot.childrenCount){
                    // reload list view.
                    // done!
                    NSLog(@"done loading group metadata");
                    [self.groups reloadData];
                }
            }];
            
            NSString *mediaPath = [NSString stringWithFormat:@"groups/%@/%@", child.name, STREAM];
            [[[currentUser.firebase childByAppendingPath:mediaPath] queryLimitedToNumberOfChildren:1] observeSingleEventOfType:FEventTypeChildAdded withBlock:^(FDataSnapshot *mediaSnapshot) {
                int i = 0;
                for(GroupInfo *info in currentUser.groupInfo){
                    if([info.groupId isEqualToString:child.name]){
                        [info setLatestSnapshot:mediaSnapshot];
                        [self.groups reloadData];
//                        [self.groups reloadItemsAtIndexPaths:@[ [NSIndexPath indexPathForItem:i inSection:0] ]];
                    }
                    i++;
                }
            }];
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
    
    TileCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
    
    GroupInfo *groupInfo = [[currentUser groupInfo] objectAtIndex:indexPath.row];
    
    if(![cell.uid isEqualToString:groupInfo.latestSnapshot.name]){
        
        NSLog(@"id? %@", groupInfo.latestSnapshot.name);
        [cell setUid:groupInfo.latestSnapshot.name];

        NSArray *colors = (NSArray *) groupInfo.latestSnapshot.value[@"colors"];
        
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
    for(TileCell *tile in [self.groups visibleCells]){
        if([tile.uid isEqualToString:uid]){
            [self.groups reloadItemsAtIndexPaths:@[[self.groups indexPathForCell:tile]]];
        }
    }
}

- (void) collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"yoo");
    CNetworking *currentUser = [CNetworking currentUser];
    
    GridViewController *vc = [[GridViewController alloc] init];
    
    GroupInfo *info = (GroupInfo *) currentUser.groupInfo[indexPath.row];
    
    vc.groupId = info.groupId;
    
    [self presentViewController:vc animated:YES completion:^{
        //
    }];
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
