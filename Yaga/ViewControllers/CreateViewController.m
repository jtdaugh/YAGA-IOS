//
//  CreateGroupViewController.m
//  Pic6
//
//  Created by Raj Vir on 8/14/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import "CreateViewController.h"
#import "APAddressBook.h"
#import "APContact.h"
#import "APPhoneWithLabel.h"
#import "NBPhoneNumberUtil.h"
#import "YAContact.h"
#import "NSString+Hash.h"
#import "YAUser.h"
#import "CliqueTextField.h"

@interface CreateViewController ()

@end

@implementation CreateViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
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
    NSLog(@"yoo");
    
    [self.view setBackgroundColor:[UIColor lightGrayColor]];
    
    UINavigationBar *navBar = [[UINavigationBar alloc] initWithFrame:CGRectMake(0, 0, VIEW_WIDTH, 44 + 10)];
    
    UIBarButtonItem *rightButton = [[UIBarButtonItem alloc] initWithTitle:@"Done"
                                                                    style:UIBarButtonItemStyleDone target:nil action:@selector(donePressed)];
    
    UIBarButtonItem *leftButton = [[UIBarButtonItem alloc] initWithTitle:@"Cancel"
                                                                    style:UIBarButtonItemStylePlain
                                                                  target:nil action:@selector(cancelPressed)];
    
    UINavigationItem *item = [[UINavigationItem alloc] initWithTitle:@"Create Group"];
    item.rightBarButtonItem = rightButton;
    item.leftBarButtonItem = leftButton;
    item.hidesBackButton = YES;
    [navBar pushNavigationItem:item animated:NO];
    [navBar setTranslucent:NO];
    [navBar setTitleTextAttributes:@{
                                     NSForegroundColorAttributeName: [UIColor whiteColor]
                                     }];
    
    [self.view addSubview:navBar];
    [navBar setTintColor:[UIColor whiteColor]];
    [navBar setBarTintColor:TERTIARY_COLOR];
    NSLog(@"clique view controller did loaed");
    
    self.groupName = [[CliqueTextField alloc] initWithPosition:1];
    [self.groupName setFrame:CGRectMake(0, 44 + 10 + 10, self.groupName.frame.size.width, self.groupName.frame.size.height)];
    [self.groupName setPlaceholder:@"Name"];
    [self.groupName setAutocorrectionType:UITextAutocorrectionTypeNo];
    [self.groupName setAutocapitalizationType:UITextAutocapitalizationTypeNone];
    [self.groupName setReturnKeyType:UIReturnKeyDone];
    self.groupName.delegate = self;
    [self.view addSubview:self.groupName];

    // Do any additional setup after loading the view.
    
    
    self.data = [@[
                   [@[] mutableCopy],
                   [@[] mutableCopy],
                   [@[] mutableCopy]
                   ] mutableCopy];
    
    CGFloat top = 44 + 10 + 10 + self.groupName.frame.size.height + 10;
    self.list = [[UITableView alloc] initWithFrame:CGRectMake(0, top, VIEW_WIDTH, VIEW_HEIGHT-top)];
    [self.list setScrollsToTop:YES];
    [self.view addSubview:self.list];
    [self.list setBackgroundColor:[UIColor whiteColor]];
    [self.list setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    self.list.dataSource = self;
    self.list.delegate = self;
    
    [self.groupName becomeFirstResponder];
    [self.list setAlpha:0.0];

}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [self.data count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.data[section] count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return @"Members";
            break;
        case 1:
            return @"Contacts on Clique";
            break;
        case 2:
            return @"All Contacts";
            break;
        default:
            return @"Too Many Sections";
            break;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"Cell"];
    }
    
    YAContact *contact = self.data[indexPath.section][indexPath.row];
    
    if(indexPath.section == 2){
        [cell.textLabel setText:contact.name];
        [cell.detailTextLabel setText:[contact readableNumber]];
    } else {
        [cell.textLabel setText:contact.name];
        [cell.detailTextLabel setText:@""];
    }
    
    cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    
    UIButton *accessory = [[UIButton alloc] initWithFrame:CGRectMake(240, 5, 34, 34)];
    [accessory setUserInteractionEnabled:NO];
    //    [accessory addTarget:self action:@selector(accessoryButtonTapped:withEvent:)forControlEvents:UIControlEventTouchUpInside];
    switch (indexPath.section) {
        case 0:
            // @"My Clique";
            [accessory setBackgroundImage:[UIImage imageNamed:@"Remove"] forState:UIControlStateNormal];
            break;
        case 1:
            // Contacts on Clique
            [accessory setBackgroundImage:[UIImage imageNamed:@"Add"] forState:UIControlStateNormal];
            break;
        case 2:
            // All Contacts
            [accessory setBackgroundImage:[UIImage imageNamed:@"Add"] forState:UIControlStateNormal];
            break;
        default:
            accessory = nil;
            break;
    }
    
    [cell setAccessoryView:accessory];
    
    return cell;
    
    
}

- (void) accessoryButtonTapped: (UIControl *) button withEvent: (UIEvent *) event
{
    NSIndexPath * indexPath = [self.list indexPathForRowAtPoint: [[[event touchesForView: button] anyObject] locationInView: self.list]];
    if ( indexPath == nil )
        return;
    
    [self.list.delegate tableView: self.list accessoryButtonTappedForRowWithIndexPath: indexPath];
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"tapped");
    //    YAContact *contact = self.data[indexPath.section][indexPath.row];
    //    [[[UIAlertView alloc] initWithTitle: [NSString stringWithFormat:@"Invite %@", contact.firstName]
    //                                message: [NSString stringWithFormat:@"Would you like to invite %@ to your Clique?", contact.name] //, [contact readableNumber]]
    //                               delegate: nil
    //                      cancelButtonTitle:@"Invite"
    //                      otherButtonTitles:@"Not now", nil]
    //     show];
    [self.list selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.list deselectRowAtIndexPath:indexPath animated:YES];
    if(indexPath.section == 2 || indexPath.section == 1){
        [self addToClique:indexPath];
    } else {
        [self removeFromClique:indexPath];
    }
}

- (void)addToClique:(NSIndexPath *)indexPath {
    YAContact *o = self.data[indexPath.section][indexPath.row];
    [self.data[indexPath.section] removeObject:o];
    [self.data[0] addObject:o];
    NSUInteger newRow = [(NSArray *)(self.data[0]) count] - 1;
    
    [self.list moveRowAtIndexPath:indexPath toIndexPath:[NSIndexPath indexPathForRow:newRow inSection:0]];
    //    [self.list reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:newRow inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
    [self.list reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
    
}

- (void)removeFromClique:(NSIndexPath *)indexPath {
    YAContact *o = self.data[indexPath.section][indexPath.row];
    int newSection;
    if(o.registered){
        newSection = 1;
    } else {
        newSection = 2;
    }
    
    NSUInteger newRow = [self.data[newSection] indexOfObject:o
                                      inSortedRange:(NSRange){0, [self.data[newSection] count]}
                                            options:NSBinarySearchingInsertionIndex
                                    usingComparator:(NSComparator) ^(YAContact *first, YAContact *second){
                                        return (NSComparisonResult)[first.name compare:second.name];
                                    }];
    
    [self.data[indexPath.section] removeObject:o];
    [self.data[newSection] insertObject:o atIndex:newRow];
    
    [self.list moveRowAtIndexPath:indexPath toIndexPath:[NSIndexPath indexPathForRow:newRow inSection:newSection]];
    [self.list reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:newRow inSection:newSection]] withRowAnimation:UITableViewRowAnimationFade];
//    [self.list reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self.list setAlpha:1.0];
    [textField resignFirstResponder];
    return YES;
}

- (void)donePressed {
    NSLog(@"done motherfuckers");
    if(([self.data[0] count] > 0) && ([self.groupName.text length] > 0)){
        
        [self dismissViewControllerAnimated:YES completion:^{
            
            NSMutableArray *members = [[NSMutableArray alloc] init];
            for(YAContact *user in self.data[0]){
                [members addObject:user.number];
            }
            
            // TODO: create group function call (CNetworking, initial members, etc)
            
            
        }];
    }
    
}

- (void)cancelPressed {
    NSLog(@"cancelled motherfuckers");
    [self dismissViewControllerAnimated:YES completion:^{
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
