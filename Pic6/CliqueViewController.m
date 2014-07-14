//
//  CliqueViewController.m
//  Pic6
//
//  Created by Raj Vir on 7/13/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import "CliqueViewController.h"
@import AddressBook;

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
    
    self.list = [[UITableView alloc] initWithFrame:CGRectMake(0, 44, 320, VIEW_HEIGHT-44)];
    [self.view addSubview:self.list];
    [self.list setBackgroundColor:[UIColor whiteColor]];
    [self.list setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    self.list.dataSource = self;
    self.list.delegate = self;
    [self.list registerClass:[UITableViewCell class] forCellReuseIdentifier:@"Cell"];

    self.data = [@[
                  [@[@"Kobe Bryant", @"Steve Jobs", @"Leo", @"Tim Tebow"] mutableCopy],
                  [@[@"Michael Jordan (Added You)", @"Kanye West (Added You)", @"Dr. Dre", @"50 Cent", @"Phil Jackson"] mutableCopy],
                  [@[] mutableCopy]
                  ] mutableCopy];
    
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
            return @"My Clique (4/12)";
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
    [cell.textLabel setText:self.data[indexPath.section][indexPath.row]];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    [cell setAccessoryView:[[UIImageView alloc] init]];
    
    UIImageView *accessory = [[UIImageView alloc] initWithFrame:CGRectMake(240, 5, 34, 34)];
    
    switch (indexPath.section) {
        case 0:
            // @"My Clique";
            [accessory setImage:[UIImage imageNamed:@"Remove"]];
            break;
        case 1:
            // Contacts on Clique
            [accessory setImage:[UIImage imageNamed:@"Add"]];
            break;
        case 2:
            // All Contacts
            [accessory setImage:[UIImage imageNamed:@"Invite"]];
            break;
        default:
            accessory = nil;
            break;
    }
    
    [cell setAccessoryView:accessory];
    
    return cell;
    
    
}

- (void)importAddressBook {
    ABAddressBookRequestAccessWithCompletion(ABAddressBookCreateWithOptions(NULL, nil), ^(bool granted, CFErrorRef error) {
        if (!granted){
            //4
            NSLog(@"Just denied");
            return;
        }
        
        CFErrorRef *aError = NULL;
        ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, aError);
        ABRecordRef source = ABAddressBookCopyDefaultSource(addressBook);
        CFArrayRef people = ABAddressBookCopyArrayOfAllPeopleInSourceWithSortOrdering(addressBook, source, kABPersonSortByFirstName);
        
        //(addressBook);
//        CFMutableArrayRef peopleMutable = CFArrayCreateMutableCopy(kCFAllocatorDefault, CFArrayGetCount(people), people);
//        
//        CFArraySortValues(
//                          peopleMutable,
//                          CFRangeMake(0, CFArrayGetCount(peopleMutable)),
//                          (CFComparatorFunction) ABPersonComparePeopleByName,
//                          (void*) ABPersonGetSortOrdering()
//                          );
        
        CFIndex numberOfPeople = ABAddressBookGetPersonCount(addressBook);
        int i;
        for(i = 0; i < numberOfPeople; i++) {
            
            ABRecordRef person = CFArrayGetValueAtIndex(people, i );
            
            if(person){
                
                ABRecordCopyValue(person, kABPersonPhoneProperty);
                NSString *name = (__bridge NSString *)(ABRecordCopyCompositeName(person));
                if(name){
                    NSLog(@"name: %@", name);
                    [self.data[2] addObject:name];
                }
            }
        }
        
        
        
        // update table view
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            NSIndexSet *set = [[NSIndexSet alloc] initWithIndex:2];
            [self.list reloadSections:set withRowAnimation:UITableViewRowAnimationAutomatic];
        }];
        
    });

    
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
