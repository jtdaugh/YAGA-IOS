//
//  YAInitialShareViewController.m
//  Yaga
//
//  Created by Christopher Wendel on 7/16/15.
//  Copyright (c) 2015 Raj Vir. All rights reserved.
//

#import "YAInitialShareViewController.h"
#import "YAShareVideoViewController.h"

@interface YAInitialShareViewController ()

@end

@implementation YAInitialShareViewController

#pragma mark - View setup

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self performSegueWithIdentifier:@"initialToShare" sender:self];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Segues

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"initialToShare"]) {
        YAShareVideoViewController *shareVC = (YAShareVideoViewController *)[segue destinationViewController];
        NSExtensionItem *item = self.extensionContext.inputItems[0];
        NSItemProvider *itemProvider = item.attachments[0];
        shareVC.itemProvider = itemProvider;
    }
}

@end
