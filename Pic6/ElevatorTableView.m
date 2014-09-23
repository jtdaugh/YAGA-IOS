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
    return [[[CNetworking currentUser] groupInfo] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"ElevatorCell";
    //    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    UITableViewCell *cell = [[UITableViewCell alloc] init];
    
    GroupInfo *groupInfo = [[[CNetworking currentUser] groupInfo] objectAtIndex:indexPath.row];
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(12, 12, self.frame.size.width, 70)];
    [label setText:groupInfo.name];
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
