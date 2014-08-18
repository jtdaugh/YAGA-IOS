//
//  CameraViewController.m
//  Pic6
//
//  Created by Raj Vir on 8/18/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import "CameraViewController.h"
#import "ListViewController.h"
#import "GroupViewController.h"
#import "CreateGroupViewController.h"

@interface CameraViewController ()

@end

@implementation CameraViewController

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
    [self.view setBackgroundColor:[UIColor greenColor]];
    
    GridViewController *vc = [[ListViewController alloc] init];
    
//    [self displayContentController:vc];
    [self customPresentViewController:vc];
    NSLog(@"watup");
    
    UIButton *createGroup = [[UIButton alloc] initWithFrame:CGRectMake(20, 20, 50, 50)];
    [createGroup addTarget:self action:@selector(createGroup) forControlEvents:UIControlEventTouchUpInside];
    [createGroup.titleLabel setFont:[UIFont systemFontOfSize:30]];
    [createGroup setTitle:@"+" forState:UIControlStateNormal];
    [createGroup setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.view addSubview:createGroup];

    
    // Do any additional setup after loading the view.
}

- (void) displayContentController: (GridViewController*) content;
{
    [self addChildViewController:content];                 // 1
    content.view.frame = [self frameForContentController]; // 2
    [self.view addSubview:content.view];
    [content didMoveToParentViewController:self];          // 3

    content.cameraViewController = self;
    self.currentViewController = content;
    
}

- (void) hideContentController: (UIViewController*) content
{
    [content willMoveToParentViewController:nil];  // 1
    [content.view removeFromSuperview];            // 2
    [content removeFromParentViewController];      // 3

    self.currentViewController = nil;
}

- (void)createGroup {
    NSLog(@"create group pressed");
    CreateGroupViewController *vc = [[CreateGroupViewController alloc] init];
    
//    [self customPresentViewController:vc];
//    [self displayContentController:vc];
    [self presentViewController:vc animated:YES completion:^{
        //
    }];
}

- (CGRect) newViewStartFrame {
    return [self frameForContentController];
}

- (CGRect) oldViewEndFrame {
    return [self frameForContentController];
}

- (CGRect) frameForContentController {
    return CGRectMake(0, TILE_HEIGHT, TILE_WIDTH*2, VIEW_HEIGHT - TILE_HEIGHT);
}

- (void)customPresentViewController:(UIViewController *)viewControllerToPresent {
//    [self cycleFromViewController:self.currentViewController toViewController:viewControllerToPresent];
    [self hideContentController:self.currentViewController];
    [self displayContentController:viewControllerToPresent];
}

- (void) cycleFromViewController: (UIViewController*) oldC
                toViewController: (UIViewController*) newC
{
    [oldC willMoveToParentViewController:nil];                        // 1
    [self addChildViewController:newC];
    
    newC.view.frame = [self newViewStartFrame];                       // 2
    CGRect endFrame = [self oldViewEndFrame];
    
    [self transitionFromViewController: oldC toViewController: newC   // 3
                              duration: 0.25 options:0
                            animations:^{
                                newC.view.frame = oldC.view.frame;                       // 4
                                oldC.view.frame = endFrame;
                            }
                            completion:^(BOOL finished) {
                                [oldC removeFromParentViewController];                   // 5
                                [newC didMoveToParentViewController:self];
                                self.currentViewController = newC;

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
