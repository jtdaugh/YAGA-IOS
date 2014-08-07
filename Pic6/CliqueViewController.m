//
//  CliqueViewController.m
//  Pic6
//
//  Created by Raj Vir on 7/13/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import "CliqueViewController.h"
#import "APAddressBook.h"
#import "APContact.h"
#import "APPhoneWithLabel.h"
#import "NBPhoneNumberUtil.h"
#import "CContact.h"
#import "NSString+Hash.h"
#import "CNetworking.h"
#import <Parse/Parse.h>

@interface CliqueViewController ()

@end

@implementation CliqueViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.view setBackgroundColor:[UIColor whiteColor]];
    UINavigationBar *navBar = [[UINavigationBar alloc] initWithFrame:CGRectMake(0, 0, VIEW_WIDTH, 44 + 10)];
    
    UIBarButtonItem *rightButton = [[UIBarButtonItem alloc] initWithTitle:@"Done"
                                                                    style:UIBarButtonItemStyleDone target:nil action:@selector(donePressed)];
    
    UIButton *leftButtonTemp = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 34, 34)];
    [leftButtonTemp addTarget:self action:@selector(logoutPressed) forControlEvents:UIControlEventTouchUpInside];
    [leftButtonTemp setImage:[UIImage imageNamed:@"Logout"] forState:UIControlStateNormal];
    [leftButtonTemp setContentMode:UIViewContentModeScaleAspectFit];
    
    UIBarButtonItem *leftButton = [[UIBarButtonItem alloc] initWithCustomView:leftButtonTemp];
    
    
    UINavigationItem *item = [[UINavigationItem alloc] initWithTitle:@"Manage Clique"];
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
    [navBar setBarTintColor:PRIMARY_COLOR];
    NSLog(@"clique view controller did loaed");
    
    self.data = [@[
                   [@[] mutableCopy],
                   [@[] mutableCopy],
                   [@[] mutableCopy]
                   ] mutableCopy];

    self.list = [[UITableView alloc] initWithFrame:CGRectMake(0, 44 + 10, VIEW_WIDTH, VIEW_HEIGHT-44 - 10)];
    [self.list setScrollsToTop:YES];
    [self.view addSubview:self.list];
    [self.list setBackgroundColor:[UIColor whiteColor]];
    [self.list setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    self.list.dataSource = self;
    self.list.delegate = self;
//    [self.list registerClass:[UITableViewCell class] forCellReuseIdentifier:@"Cell"];
    
    // Do any additional setup after loading the view.
    
    [self importAddressBook];
    
//    self.messageView = [MFMessageComposeViewController new];
}

- (void)donePressed {
    NSLog(@"done motherfuckers");
    [self dismissViewControllerAnimated:YES completion:^{
        //
    }];
}

- (void)logoutPressed {
    [PFUser logOut];
    
    // request all friends here. see what happens.
    
    
//    [[CNetworking currentUser] saveUserData:[NSNumber numberWithBool:NO] forKey:@"onboarded"];
    [self dismissViewControllerAnimated:YES completion:^{
        //
    }];
    
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
            return [NSString stringWithFormat:@"My Clique (%lu/12)", [self.data[section] count]];
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
    
    CContact *contact = self.data[indexPath.section][indexPath.row];

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

- (void)importAddressBook {
    
    APAddressBook *addressBook = [[APAddressBook alloc] init];
    addressBook.fieldsMask = APContactFieldCompositeName | APContactFieldPhones | APContactFieldFirstName;
    addressBook.filterBlock = ^BOOL(APContact *contact){
        return
            // has a #
            (contact.phones.count > 0) &&
        
            // has a name
            contact.compositeName &&
        
            // name does not contain "GroupMe"
            ([contact.compositeName rangeOfString:@"GroupMe:"].location == NSNotFound);
    };
    addressBook.sortDescriptors = @[
                                    [NSSortDescriptor sortDescriptorWithKey:@"compositeName" ascending:YES]
                                    ];
    
    [addressBook loadContacts:^(NSArray *contacts, NSError *error){
        // hide activity
        if (!error){
            for(int i = 0; i<[contacts count]; i++){
                APContact *contact = contacts[i];
                for(int j = 0; j<[contact.phones count]; j++){
                    NBPhoneNumberUtil *phoneUtil = [NBPhoneNumberUtil sharedInstance];
                    NSError *aError = nil;
                    NBPhoneNumber *myNumber = [phoneUtil parse:contact.phones[j]
                                                 defaultRegion:@"US" error:&aError];
                    NSString *num = [phoneUtil format:myNumber numberFormat:NBEPhoneNumberFormatE164 error:&aError];


                    int dupe = 0;

                    //crawl backwards
                    int k = (int)[self.data[2] count] - 1;
                    while(k > 0){
                        CContact *previous = self.data[2][k];
                        if([previous.name isEqualToString:contact.compositeName]){
                            if([previous.number isEqualToString:num]){
                                dupe = 1;
                            }
                        } else {
                            break;
                        }
                        k = k-1;
                    }
                                        
                    if(dupe == 0){
                        CContact *current = [CContact new];
                        current.name = contact.compositeName;
                        current.number = num;
                        current.firstName = contact.firstName;
                        
                        if([(NSMutableDictionary *)[PFUser currentUser][@"clique"] objectForKey:[current.number sha1]]){
                            NSLog(@"in clique!");
                            [self.data[0] addObject:current];
                        } else {
                            NSLog(@"not in clique!");
                            [self.data[2] addObject:current];
                        }
                    }
                }
            }
//            for(APContact *contact in contacts){
//                for(APPhoneWithLabel *phone in contact.phonesWithLabels){
//                    
//                }
//                [self.data[2] addObject:contact];
//            }
            
//            [self.list reloadData];
            NSLog(@"contacts count: %lu", [contacts count]);
            [self.list reloadData];
            
//            NSMutableIndexSet *set = [[NSMutableIndexSet alloc] init];
//            [set addIndex:0];
//            [set addIndex:1];
//            [set addIndex:2];
//            [self.list reloadSections:set withRowAnimation:UITableViewRowAnimationAutomatic];
            
            // do something with contacts array
            [self afterContactsLoaded];
        }
        else
        {
            // show error
        }
    }];

//[[NSOperationQueue mainQueue] addOperationWithBlock:^{
//}];

}

- (void)afterContactsLoaded {
    NSDate *start = [NSDate date];
    
    // a considerable amount of difficult processing here
    // a considerable amount of difficult processing here
    // a considerable amount of difficult processing here
    
    NSMutableArray *hashedNumbers = [@[] mutableCopy];
    NSMutableDictionary *indexes = [@{} mutableCopy];
    
    int i = 0;
    for(CContact *contact in self.data[2]){
        [hashedNumbers addObject:[contact.number sha1]];
        [indexes setObject:[NSNumber numberWithInt:i] forKey:[contact.number sha1]];
        i++;
    }
    
    NSLog(@"hashedNumbers count: %lu", [hashedNumbers count]);
    
    PFQuery *query = [PFUser query];
    [query whereKey:@"phoneHash" containedIn:hashedNumbers];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        
        for(PFUser *user in objects){
            NSString *phoneHash = user[@"phoneHash"];
            NSString *myPhoneHash = [PFUser currentUser][@"phoneHash"];
            
            if(![phoneHash isEqualToString:myPhoneHash]){
                NSUInteger index = [(NSNumber *)indexes[phoneHash] unsignedIntegerValue];
                
                CContact *o = self.data[2][index];
                [self.data[2] removeObject:o];
                [self.data[1] addObject:o];
                NSUInteger newRow = [(NSArray *)(self.data[1]) count] - 1;
                
                NSIndexPath *oldIndexPath = [NSIndexPath indexPathForRow:index inSection:2];
                NSIndexPath *newIndexPath = [NSIndexPath indexPathForRow:newRow inSection:1];
                
                [self.list moveRowAtIndexPath:oldIndexPath toIndexPath:newIndexPath];
                //    [self.list reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:newRow inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
            }
        }
        [self.list reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationFade];
        

        
        NSLog(@"%lu", [objects count]);

        NSLog(@"done!");
        NSDate *methodFinish = [NSDate date];
        NSTimeInterval executionTime = [methodFinish timeIntervalSinceDate:start];

        NSLog(@"Execution Time: %f", executionTime);
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
//    CContact *contact = self.data[indexPath.section][indexPath.row];
//    [[[UIAlertView alloc] initWithTitle: [NSString stringWithFormat:@"Invite %@", contact.firstName]
//                                message: [NSString stringWithFormat:@"Would you like to invite %@ to your Clique?", contact.name] //, [contact readableNumber]]
//                               delegate: nil
//                      cancelButtonTitle:@"Invite"
//                      otherButtonTitles:@"Not now", nil]
//     show];
    [self.list selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.section == 2){
        CContact *contact = self.data[indexPath.section][indexPath.row];
        [[[UIAlertView alloc] initWithTitle: [NSString stringWithFormat:@"Invite %@", contact.firstName]
                                    message: [NSString stringWithFormat:@"Would you like to invite %@ to your Clique?", contact.name] //, [contact readableNumber]]
                                   delegate: self
                          cancelButtonTitle:@"Not Now"
                          otherButtonTitles:@"Invite", nil]
         show];
        self.messageView = [[MFMessageComposeViewController alloc] init];
        [self addToClique:indexPath];
    } else {
        [self.list deselectRowAtIndexPath:indexPath animated:YES];
        if(indexPath.section == 1){
            [self addToClique:indexPath];
        } else if(indexPath.section == 0){
            [self removeFromClique:indexPath];
        }
    }
}

- (void)addToClique:(NSIndexPath *)indexPath {
    CContact *o = self.data[indexPath.section][indexPath.row];
    [self.data[indexPath.section] removeObject:o];
    [self.data[0] addObject:o];
    NSUInteger newRow = [(NSArray *)(self.data[0]) count] - 1;
    
    [self.list moveRowAtIndexPath:indexPath toIndexPath:[NSIndexPath indexPathForRow:newRow inSection:0]];
//    [self.list reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:newRow inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
    [self.list reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
    
    NSMutableDictionary *clique = (NSMutableDictionary *)[PFUser currentUser][@"clique"];
    if(!clique){
        clique = [@{} mutableCopy];
    }
    
    [clique setObject:@1 forKey:[[o number] sha1]];
    
    [PFUser currentUser][@"clique"] = clique;
    [[PFUser currentUser] saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        NSLog(@"%@", error);
        NSLog(@"succeded? %@", succeeded ? @"true" : @"false");
    }];
}

- (void)removeFromClique:(NSIndexPath *)indexPath {
    CContact *o = self.data[indexPath.section][indexPath.row];
    
    NSUInteger newRow = [self.data[1] indexOfObject:o
                                 inSortedRange:(NSRange){0, [self.data[1] count]}
                                       options:NSBinarySearchingInsertionIndex
                                      usingComparator:(NSComparator) ^(CContact *first, CContact *second){
                                          return (NSComparisonResult)[first.name compare:second.name];
                                      }];
    
    [self.data[indexPath.section] removeObject:o];
    [self.data[1] insertObject:o atIndex:newRow];
    
    [self.list moveRowAtIndexPath:indexPath toIndexPath:[NSIndexPath indexPathForRow:newRow inSection:1]];
    [self.list reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:newRow inSection:1]] withRowAnimation:UITableViewRowAnimationFade];
    [self.list reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
    
    NSMutableDictionary *clique = (NSMutableDictionary *)[PFUser currentUser][@"clique"];
    if(!clique){
        clique = [@{} mutableCopy];
    }
    
    [clique removeObjectForKey:[[o number] sha1]];
    
    [PFUser currentUser][@"clique"] = clique;
    [[PFUser currentUser] saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        NSLog(@"%@", error);
        NSLog(@"succeded? %@", succeeded ? @"true" : @"false");
    }];

}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    NSIndexPath *indexPath = [self.list indexPathForSelectedRow];
    [self.list deselectRowAtIndexPath:indexPath animated:YES];

    if(buttonIndex == 0){
        NSLog(@"cancel");
    } else {
        NSLog(@"invite");
        CContact *contact = self.data[indexPath.section][indexPath.row];
        self.messageView.messageComposeDelegate = self;
        [self.messageView setRecipients:@[contact.number]];
        [self.messageView setBody:@"I just added you to my Clique. Add me back! http://clique.com/download"];
        [self presentViewController:self.messageView animated:YES completion:^{
            
        }];
    }
}

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result {
    NSLog(@"result %u", result);
    [controller dismissViewControllerAnimated:YES completion:^{
        //
    }];
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
