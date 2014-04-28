//
//  MainViewController.m
//  Pic6
//
//  Created by Raj Vir on 4/27/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import "MainViewController.h"
#import "UIImage+Resize.h"

@interface MainViewController ()
@property bool FrontCamera;
@end

@implementation MainViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    NSLog(@"yooo");
    
    UIView *plaque = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 640/4, 1136/8)];
    UIImageView *logo = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 640/4, 1136/8)];
    [logo setImage:[UIImage imageNamed:@"Logo"]];
    [plaque addSubview:logo];
    [self.view addSubview:plaque];
    
    [self initSwitchButton];
    [self initGrid];
    [self initFirebase];
    [self initCameraFrame];
    self.FrontCamera = 1;
    [self initCamera];
}

- (void)viewDidAppear:(BOOL)animated {
}

- (void)initSwitchButton {
    UIButton *switchButton = [[UIButton alloc] initWithFrame:CGRectMake(640/4 - 60, 1168/8 - 60, 50, 50)];
    [switchButton addTarget:self action:@selector(switchCamera:) forControlEvents:UIControlEventTouchUpInside];
    [switchButton setImage:[UIImage imageNamed:@"Switch"] forState:UIControlStateNormal];
    [self.view addSubview:switchButton];
}

- (void)initGrid {
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    [layout setSectionInset:UIEdgeInsetsZero];
    [layout setMinimumInteritemSpacing:0.0];
    [layout setMinimumLineSpacing:0.0];
    self.grid = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 1136/8, 640/2, 1136/8 * 3) collectionViewLayout:layout];
//    self.grid = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 1136/8, 640/2, 1136/8 * 3)];
    self.grid.delegate = self;
    self.grid.dataSource = self;
    
    [self.grid registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"Cell"];
    [self.view addSubview:self.grid];
    
    self.gridData = [NSMutableArray array];
}

-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}


-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [self.gridData count];
}

-(CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(640/4, 1136/8);
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
    
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 640/4, 1136/8)];
    [imageView setContentMode:UIViewContentModeScaleAspectFill];
    [imageView setClipsToBounds:YES];
    
    [cell addSubview:imageView];
    NSData *data = [[NSData alloc]initWithBase64EncodedString:self.gridData[indexPath.row][@"data"] options:NSDataBase64DecodingIgnoreUnknownCharacters];
    [imageView setImage:[UIImage imageWithData:data]];
    
    return cell;
}

- (void)initFirebase {
    self.firebase = [[Firebase alloc] initWithUrl:@"https://pic6.firebaseIO.com"];
    
    [[[self.firebase childByAppendingPath:@"global"] queryLimitedToNumberOfChildren:6] observeEventType:FEventTypeChildAdded withBlock:^(FDataSnapshot *snapshot) {
//        NSLog(@"%@", snapshot.value);
        [self.gridData insertObject:snapshot.value atIndex:0];
        while([self.gridData count] > 6){
            [self.gridData removeLastObject];
        }
        
        [self.grid reloadData];
    }];
}

- (void) initStream {
}

- (void)initCameraFrame {
    [self.cameraView removeFromSuperview];
    self.cameraView = [[UIImageView alloc] initWithFrame:CGRectMake(640/4, 0, 640/4, 1136/8)];
    [self.view addSubview:self.cameraView];
    
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    [self.cameraView setUserInteractionEnabled:YES];
    tapGestureRecognizer.delegate = self;
    [self.cameraView addGestureRecognizer:tapGestureRecognizer];
}

- (void)handleTap:(UITapGestureRecognizer *)recognizer {
    [self capImage];
}

- (void)initCamera {
    
    AVCaptureSession *session = [[AVCaptureSession alloc] init];
	session.sessionPreset = AVCaptureSessionPresetPhoto;
    
	AVCaptureVideoPreviewLayer *captureVideoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:session];
    [captureVideoPreviewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    
	captureVideoPreviewLayer.frame = self.cameraView.bounds;
	[self.cameraView.layer addSublayer:captureVideoPreviewLayer];
    
    UIView *view = [self cameraView];
    CALayer *viewLayer = [view layer];
    [viewLayer setMasksToBounds:YES];
    
    CGRect bounds = [view bounds];
    [captureVideoPreviewLayer setFrame:bounds];
    
    NSArray *devices = [AVCaptureDevice devices];
    AVCaptureDevice *frontCamera;
    AVCaptureDevice *backCamera;
    
    for (AVCaptureDevice *device in devices) {
        
        NSLog(@"Device name: %@", [device localizedName]);
        
        if ([device hasMediaType:AVMediaTypeVideo]) {
            
            if ([device position] == AVCaptureDevicePositionBack) {
                NSLog(@"Device position : back");
                backCamera = device;
            }
            else {
                NSLog(@"Device position : front");
                frontCamera = device;
            }
        }
    }
    if (!self.FrontCamera) {
        NSError *error = nil;
        AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:backCamera error:&error];
        if (!input) {
            NSLog(@"ERROR: trying to open camera: %@", error);
        }
        [session addInput:input];
    }
    
    if (self.FrontCamera) {
        NSError *error = nil;
        AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:frontCamera error:&error];
        if (!input) {
            NSLog(@"ERROR: trying to open camera: %@", error);
        }
        [session addInput:input];
    }
    
    self.stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
    NSDictionary *outputSettings = [[NSDictionary alloc] initWithObjectsAndKeys: AVVideoCodecJPEG, AVVideoCodecKey, nil];
    [self.stillImageOutput setOutputSettings:outputSettings];
    
    [session addOutput:self.stillImageOutput];
    
	[session startRunning];
}

- (void) capImage { //method to capture image from AVCaptureSession video feed
    AVCaptureConnection *videoConnection = nil;
    for (AVCaptureConnection *connection in self.stillImageOutput.connections) {
        
        for (AVCaptureInputPort *port in [connection inputPorts]) {
            
            if ([[port mediaType] isEqual:AVMediaTypeVideo] ) {
                videoConnection = connection;
                break;
            }
        }
        
        if (videoConnection) {
            break;
        }
    }
    
    NSLog(@"about to request a capture from: %@", self.stillImageOutput);
    [self.stillImageOutput captureStillImageAsynchronouslyFromConnection:videoConnection completionHandler: ^(CMSampleBufferRef imageSampleBuffer, NSError *error) {
        
        if (imageSampleBuffer != NULL) {
            NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageSampleBuffer];
            [self processImage:[UIImage imageWithData:imageData]];
        }
    }];
}

- (void)processImage:(UIImage *) image {
    
//    CGSize imageSize = image.size;
//    CGSize viewSize = CGSizeMake(450, 340); // size in which you want to draw
//    
//    float hfactor = imageSize.width / viewSize.width;
//    float vfactor = imageSize.height / viewSize.height;
//    
//    float factor = fmax(hfactor, vfactor);
//    
//    // Divide the size by the greater of the vertical or horizontal shrinkage factor
//    float newWidth = imageSize.width / factor;
//    float newHeight = imageSize.height / factor;
//    
//    CGRect newRect = CGRectMake(0, 0, newWidth, newHeight);
//    [image drawInRect:newRect];
    
    
    
//    CGSize newSize = CGSizeMake(640/4, 1136/8);
//    
//    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0);
//    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
//    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
//    UIGraphicsEndImageContext();
//    
//    NSData *imageData = UIImagePNGRepresentation(newImage); //UIImageJPEGRepresentation(newImage, 0.7);
//    [self uploadImage:imageData];

    UIImage *newImage = [image imageScaledToFitSize:CGSizeMake(640/4, 1136/8)];
    NSData *imageData = UIImagePNGRepresentation(newImage); //UIImageJPEGRepresentation(newImage, 0.7);
    [self uploadImage:imageData];
}

- (void)uploadImage:(NSData *) imageData {
    //NSString *stringData = [[NSString alloc] initWithData:imageData encoding:NSUTF8StringEncoding];
    //NSString *stringData = [NSString stringWithUTF8String:[imageData bytes]];
    NSString *stringData = [imageData base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
    NSLog(@"%i", [stringData length]);
    [self.firebase childByAppendingPath:@"global"];
    Firebase *newImage = [[self.firebase childByAppendingPath:@"global"] childByAutoId];
    [newImage setValue:@{@"type": @"image", @"data":stringData}];
    //    NSLog(@"%@", stringData);
}

- (IBAction)switchCamera:(id)sender { //switch cameras front and rear cameras
    if (self.FrontCamera == 1) {
        self.FrontCamera = 0;
    } else {
        self.FrontCamera = 1;
    }
    [self initCameraFrame];
    [self initCamera];
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
