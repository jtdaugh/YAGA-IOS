//
//  YAInitialShareViewController.m
//  Yaga
//
//  Created by Christopher Wendel on 7/16/15.
//  Copyright (c) 2015 Raj Vir. All rights reserved.
//

#import "YAInitialShareViewController.h"
#import "YAShareVideoViewController.h"
#import "YAShareServer.h"
#import "YAShareGroup.h"

@interface YAInitialShareViewController ()

@end

@implementation YAInitialShareViewController

#pragma mark - View setup

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [YAShareServer sharedServer];
    
    [[[NSUserDefaults alloc] initWithSuiteName:@"group.com.yaga.yagaapp"] synchronize];
    
    [[YAShareServer sharedServer] getGroupsWithCompletion:^(id response, NSError *error){
        if (error) {

        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self performSegueWithIdentifier:@"initialToShare" sender:response];
            });
        }
    } publicGroups:NO];
}

#pragma mark - Segues

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"initialToShare"]) {
        YAShareVideoViewController *shareVC = (YAShareVideoViewController *)[segue destinationViewController];
        NSExtensionItem *item = self.extensionContext.inputItems[0];
        NSItemProvider *itemProvider = item.attachments[0];
        shareVC.itemProvider = itemProvider;
        shareVC.groups = [self shareGroupsFromResponse:sender];
    }
}

- (NSArray *)shareGroupsFromResponse:(id)response {
    NSArray *responseArray = (NSArray *)response;
    NSMutableArray *shareGroupsMutable = [NSMutableArray array];
    for (NSDictionary *group in responseArray) {
        YAShareGroup *shareGroup = [YAShareGroup new];
        shareGroup.name = group[@"name"];
        shareGroup.serverId = group[@"id"];
        [shareGroupsMutable addObject:shareGroup];
    }
    return [NSArray arrayWithArray:shareGroupsMutable];
}

@end
