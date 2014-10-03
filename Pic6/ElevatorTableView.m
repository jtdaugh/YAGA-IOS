//
//  ElevatorTableView.m
//  Pic6
//
//  Created by Raj Vir on 9/22/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import "ElevatorTableView.h"
#import "CNetworking.h"

@implementation ElevatorTableView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.dataSource = self;
        [self setContentInset:UIEdgeInsetsZero];
//        self.delegate = self;
        // Initialization code
    }
    return self;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    NSMutableArray *groupInfo = [[CNetworking currentUser] groupInfo];
    
    NSLog(@"number of rows: %lu", [groupInfo count] + 1);
    return [groupInfo count] + 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"ElevatorCell";
    //    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    UITableViewCell *cell = [[UITableViewCell alloc] init];
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(12, 12, self.frame.size.width, 70)];

    if(indexPath.row == ([tableView numberOfRowsInSection:0] - 1)) {
        [label setText:@"Create Group"];
    } else {
        GroupInfo *groupInfo = [[[CNetworking currentUser] groupInfo] objectAtIndex:indexPath.row];
        [label setText:groupInfo.name];
    }
    
    [label setFont:[UIFont fontWithName:BIG_FONT size:28]];
    
    //    [label setFont:[UIFont systemFontOfSize:28]];
    label.textColor = PRIMARY_COLOR;
    [cell addSubview:label];
    
    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    [cell setBackgroundColor:[UIColor clearColor]];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"test...");
}


@end
