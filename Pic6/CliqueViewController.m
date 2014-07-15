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
#import "ECPhoneNumberFormatter.h"
#import "NBPhoneNumberUtil.h"
#import "CContact.h"
#import "NSString+Hash.h"

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

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.view setBackgroundColor:[UIColor whiteColor]];
    UINavigationBar *navBar = [[UINavigationBar alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
    
    UIBarButtonItem *rightButton = [[UIBarButtonItem alloc] initWithTitle:@"Done"
                                                                    style:UIBarButtonItemStyleDone target:nil action:@selector(donePressed)];
    
    UINavigationItem *item = [[UINavigationItem alloc] initWithTitle:@"Manage Clique"];
    item.rightBarButtonItem = rightButton;
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

    self.list = [[UITableView alloc] initWithFrame:CGRectMake(0, 44, 320, VIEW_HEIGHT-44)];
    [self.list setScrollsToTop:YES];
    [self.view addSubview:self.list];
    [self.list setBackgroundColor:[UIColor whiteColor]];
    [self.list setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    self.list.dataSource = self;
    self.list.delegate = self;
//    [self.list registerClass:[UITableViewCell class] forCellReuseIdentifier:@"Cell"];
    
    // Do any additional setup after loading the view.
    
    [self importAddressBook];
}

- (void)donePressed {
    NSLog(@"done motherfuckers");
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
    [cell.textLabel setText:contact.name];
    [cell.detailTextLabel setText:[contact readableNumber]];
    
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
            [accessory setBackgroundImage:[UIImage imageNamed:@"Invite"] forState:UIControlStateNormal];
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
                        [self.data[2] addObject:current];
                    }
                }
            }
//            for(APContact *contact in contacts){
//                for(APPhoneWithLabel *phone in contact.phonesWithLabels){
//                    
//                }
//                [self.data[2] addObject:contact];
//            }
            NSLog(@"contacts count: %lu", [contacts count]);
            NSIndexSet *set = [[NSIndexSet alloc] initWithIndex:2];
            [self.list reloadSections:set withRowAnimation:UITableViewRowAnimationAutomatic];
            // do something with contacts array
        }
        else
        {
            // show error
        }
    }];
    

//[[NSOperationQueue mainQueue] addOperationWithBlock:^{
//}];

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
    CContact *contact = self.data[indexPath.section][indexPath.row];
    [[[UIAlertView alloc] initWithTitle: [NSString stringWithFormat:@"Invite %@", contact.firstName]
                                message: [NSString stringWithFormat:@"Would you like to invite %@ to your Clique?", contact.name] //, [contact readableNumber]]
                               delegate: self
                      cancelButtonTitle:@"Invite"
                      otherButtonTitles:@"Not now", nil]
     show];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
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
