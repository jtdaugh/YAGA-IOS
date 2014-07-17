//
//  SplashViewController.m
//  Pic6
//
//  Created by Raj Vir on 7/15/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import "SplashViewController.h"
#import "LoginViewController.h"
#import "AVPlayer+AVPlayer_Async.h"
#import "TileCell.h"

@implementation SplashViewController

- (void)viewDidAppear:(BOOL)animated {
    NSLog(@"yooo splashery");
    
    [self.view setBackgroundColor:[UIColor whiteColor]];
    
    UIView *plaque = [[UIView alloc] initWithFrame:CGRectMake(0, TILE_HEIGHT, TILE_WIDTH, TILE_HEIGHT)];
    [plaque setBackgroundColor:PRIMARY_COLOR];
    [self.view addSubview:plaque];
    
    UIButton *loginButton = [[UIButton alloc] initWithFrame:CGRectMake(0, TILE_HEIGHT*2, TILE_WIDTH, TILE_HEIGHT)];
    [loginButton addTarget:self action:@selector(loginPressed) forControlEvents:UIControlEventTouchUpInside];
    [loginButton setTitle:@"Log In" forState:UIControlStateNormal];
    [loginButton.titleLabel setFont:[UIFont fontWithName:BIG_FONT size:28]];
//    [loginButton setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [loginButton setBackgroundColor:SECONDARY_COLOR];
    [self.view addSubview:loginButton];
    
    UIButton *signupButton = [[UIButton alloc] initWithFrame:CGRectMake(TILE_WIDTH, TILE_HEIGHT*2, TILE_WIDTH, TILE_HEIGHT)];
    [signupButton addTarget:self action:@selector(signupPressed) forControlEvents:UIControlEventTouchUpInside];
    [signupButton setTitle:@"Sign Up" forState:UIControlStateNormal];
//    [signupButton.titleLabel setFont:[UIFont boldSystemFontOfSize:28]];
    [signupButton.titleLabel setFont:[UIFont fontWithName:BIG_FONT size:28]];
//    [signupButton setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [signupButton setBackgroundColor:TERTIARY_COLOR];
    [self.view addSubview:signupButton];
    
//    UICollectionViewFlowLayout *layout= [[UICollectionViewFlowLayout alloc] init];
//    [layout setSectionInset:UIEdgeInsetsMake(0, 0, 0, 0)];
//    [layout setMinimumInteritemSpacing:0.0];
//    [layout setMinimumLineSpacing:0.0];
//    self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 0, TILE_WIDTH*2, TILE_HEIGHT*2) collectionViewLayout:layout];
//    self.collectionView.delegate = self;
//    self.collectionView.dataSource = self;
//    [self.collectionView setBackgroundColor:PRIMARY_COLOR];
//    [self.collectionView registerClass:[TileCell class] forCellWithReuseIdentifier:@"SplashCell"];
    
    UIView *container = [[UIView alloc] initWithFrame:CGRectMake(0, 0, VIEW_WIDTH, VIEW_HEIGHT)];
    [self.view addSubview:container];
    
//    [container addSubview:self.collectionView];
    
    NSArray *positions = @[@0, @1, @3, @6, @7];
    for(int i = 0; i < [positions count]; i++){
        int position = [(NSNumber *)positions[i] intValue];
        TileCell *tile = [[TileCell alloc] initWithFrame:CGRectMake(position%2 * TILE_WIDTH, (position/2) * TILE_HEIGHT, TILE_WIDTH, TILE_HEIGHT)];

        NSString *filename = [NSString stringWithFormat:@"%i", i];
        NSString *path = [[NSBundle mainBundle] pathForResource:filename ofType:@"mov"];
        
        NSLog(@"path: %@", path);
        
        [container addSubview:tile];
        
        [tile playLocal:path];
    }
}

-(CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(TILE_WIDTH, TILE_HEIGHT);
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return 2;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    TileCell *tile = [collectionView dequeueReusableCellWithReuseIdentifier:@"SplashCell" forIndexPath:indexPath];
    
    int i = (int)indexPath.row;
    
    NSString *filename = [NSString stringWithFormat:@"%i", i];
    NSString *path = [[NSBundle mainBundle] pathForResource:filename ofType:@"mov"];
    
    [tile playLocal:path];
    
    return tile;
}

- (void)loginPressed {
//    LoginViewController *vc = [LoginViewController new];
//    [self presentViewController:vc animated:YES completion:^{
//        //
//    }];
    [self.collectionView reloadData];
    NSLog(@"login pressed");
}

- (void)signupPressed {
    NSLog(@"signup pressed");
}

@end
