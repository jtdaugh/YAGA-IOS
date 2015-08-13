//
//  YAMeViewController.m
//
//
//  Created by valentinkovalski on 8/10/15.
//
//

#import "YAMyStreamViewController.h"
@interface YAMyStreamViewController ()

@end

@implementation YAMyStreamViewController

- (void)initStreamGroup {
    RLMResults *groups = [YAGroup objectsWhere:[NSString stringWithFormat:@"serverId = '%@'", kMyStreamGroupId]];
    if(groups.count == 1) {
        self.group = [groups objectAtIndex:0];        
    }
    else {
        [[RLMRealm defaultRealm] beginWriteTransaction];
        self.group = [YAGroup group];
        self.group.serverId = kMyStreamGroupId;
        self.group.name = NSLocalizedString(@"My Videos", @"");
        self.group.streamGroup = YES;
        [[RLMRealm defaultRealm] addObject:self.group];
        [[RLMRealm defaultRealm] commitWriteTransaction];
    }
}


@end
