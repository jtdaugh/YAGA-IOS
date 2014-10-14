//
//  AddMembersViewController.m
//  Pic6
//
//  Created by Raj Vir on 10/14/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import "AddMembersViewController.h"
#import "APAddressBook.h"
#import "APContact.h"
#import "APPhoneWithLabel.h"
#import "NBPhoneNumberUtil.h"
#import "CContact.h"
#import "NSString+Hash.h"
#import "CNetworking.h"
#import "NameGroupViewController.h"

@interface AddMembersViewController ()

@end

@implementation AddMembersViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWasShown:)
                                                 name:UIKeyboardDidShowNotification
                                               object:nil];
    
    // if no contacts permissions, ask for contact permissions
    
    self.selectedContacts = [[NSMutableArray alloc] init];
    
    self.title = @"Add Members";
//    [self.navigationController setNavigationBarHidden:NO];
    
    [self.view setBackgroundColor:[UIColor blackColor]];
    
    VENTokenField *searchBar = [[VENTokenField alloc] initWithFrame:CGRectMake(0.0f, 0, VIEW_WIDTH, 42)];
    searchBar.translatesAutoresizingMaskIntoConstraints = NO;
    [searchBar setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
    [searchBar setBackgroundColor:[UIColor blackColor]];
    [searchBar setToLabelText:@""];
    [searchBar setPlaceholderText:SEARCH_INSTRUCTION];
    [searchBar setColorScheme:PRIMARY_COLOR];
    [searchBar setInputTextFieldTextColor:[UIColor whiteColor]];
    searchBar.delegate = self;
    searchBar.dataSource = self;
    
    self.searchBar = searchBar;
    [self.view addSubview:self.searchBar];
    
    UIView *border = [[UIView alloc] init];
    border.translatesAutoresizingMaskIntoConstraints = NO;
    border.backgroundColor = [UIColor darkGrayColor];
    [self.view addSubview:border];
    
    UITableView *membersList = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    membersList.translatesAutoresizingMaskIntoConstraints = NO;
    
//    NSDictionary *views = NSDictionaryOfVariableBindings(searchBar, self.membersList);
//    NSDictionary *metrics = @{@"padding":@15.0};
    
    [membersList setBackgroundColor:[UIColor clearColor]];
    [membersList setDataSource:self];
    [membersList setDelegate:self];
    [membersList setContentInset:UIEdgeInsetsMake(0, 0, 216, 0)];
//    self.membersList.autoresizingMask = UIViewAutoresizingFlexibleHeight;
//    [self.membersList setContentInset:UIEdgeInsetsMake(0, 10.0f, 0, 0)];
//    [self.membersList setSeparatorColor:PRIMARY_COLOR];
//    [self.membersList setSeparatorInset:UIEdgeInsetsZero];

    membersList.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.membersList = membersList;
    [self.view addSubview:self.membersList];
    
    NSDictionary *views = NSDictionaryOfVariableBindings(searchBar, border, membersList);
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[searchBar]|" options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[border]|" options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[membersList]|" options:0 metrics:nil views:views]];

    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[searchBar][border(1)]-0-[membersList]|" options:0 metrics:nil views:views]];
    
    UIBarButtonItem *anotherButton = [[UIBarButtonItem alloc] initWithTitle:@"Next" style:UIBarButtonItemStylePlain target:self action:@selector(nextScreen)];
    [anotherButton setTitleTextAttributes:@{
                                            NSFontAttributeName: [UIFont fontWithName:BIG_FONT size:18],
                                            } forState:UIControlStateNormal];
    [anotherButton setEnabled:NO];
    [anotherButton setTintColor:[UIColor lightGrayColor]];
    self.navigationItem.rightBarButtonItem = anotherButton;
    
    [searchBar becomeFirstResponder];

    [self importAddressBook];
    
}

- (void)keyboardWasShown:(NSNotification *)notification {
    // Get the size of the keyboard.
    NSDictionary* keyboardInfo = [notification userInfo];
    NSValue* keyboardFrameBegin = [keyboardInfo valueForKey:UIKeyboardFrameBeginUserInfoKey];
    CGRect keyboardFrameBeginRect = [keyboardFrameBegin CGRectValue];
    CGSize keyboardSize = keyboardFrameBeginRect.size;
    [self.membersList setContentInset:UIEdgeInsetsMake(0, 0, keyboardSize.height, 0)];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
//    CNetworking *currentUser = [CNetworking currentUser];
//
//    NSLog(@"count? : %lu", (unsigned long)[currentUser.contacts count]);
    
    return [self.filteredContacts count];
}

//- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
//    return @"My Contacts";
//}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"Cell"];
    }
    
    CGRect frame = cell.contentView.frame;
    frame.origin.x = 0;
    [cell setFrame:frame];

    
    CNetworking *currentUser = [CNetworking currentUser];
    
    CContact *contact = self.filteredContacts[indexPath.row];
    
    cell.indentationLevel = 0;
    cell.indentationWidth = 0.0f;

    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    
    [cell.textLabel setText:contact.name];
    [cell.detailTextLabel setText:[contact readableNumber]];
    
    [cell.textLabel setTextColor:[UIColor whiteColor]];
    [cell.detailTextLabel setTextColor:[UIColor whiteColor]];
    [cell setBackgroundColor:[UIColor clearColor]];
    
//    cell.selectionStyle = UITableViewCellSelectionStyleDefault;

    
    return cell;
}

- (void)reloadSearchBox {
    [self.searchBar reloadData];
    if([self numberOfTokensInTokenField:self.searchBar] > 0){
        [self.navigationItem.rightBarButtonItem setEnabled:YES];
        [self.navigationItem.rightBarButtonItem setTintColor:PRIMARY_COLOR];
    } else {
        [self.navigationItem.rightBarButtonItem setEnabled:NO];
        [self.navigationItem.rightBarButtonItem setTintColor:[UIColor lightGrayColor]];
    }
//    CGRect frame = self.searchBar.frame;
//    [self.membersList setFrame:CGRectMake(0, frame.size.height, VIEW_WIDTH, self.view.frame.size.height - frame.size.height)];
    
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"did select");
    [self.selectedContacts addObject:self.filteredContacts[indexPath.row]];
    [self reloadSearchBox];
    CNetworking *currentUser = [CNetworking currentUser];
    self.filteredContacts = [currentUser.contacts mutableCopy];
    [self.membersList reloadData];
}

- (NSString *)tokenField:(VENTokenField *)tokenField titleForTokenAtIndex:(NSUInteger)index {
    CContact *contact = self.selectedContacts[index];
    return contact.name;
}

- (void)tokenField:(VENTokenField *)tokenField didDeleteTokenAtIndex:(NSUInteger)index {
    [self.selectedContacts removeObjectAtIndex:index];
    [self reloadSearchBox];
}

-(void)tokenField:(VENTokenField *)tokenField didChangeText:(NSString *)text {
    CNetworking *currentUser = [CNetworking currentUser];
    if([text isEqualToString:@""]){
        self.filteredContacts = [currentUser.contacts mutableCopy];
        [self.membersList reloadData];
    } else {
        [self.filteredContacts removeAllObjects];
        // Filter the array using NSPredicate
        
        
        NSArray *keys = [[text lowercaseString] componentsSeparatedByString:@" "];
        for(CContact *contact in currentUser.contacts){
            NSArray *names = [[contact.name lowercaseString] componentsSeparatedByString:@" "];
            
            BOOL notDetected = false;
            
            for(NSString *key in keys){
                if(![key isEqualToString:@""]){
                    bool detected = false;
                    
                    for(NSString *name in names){
                        NSRange r = [name rangeOfString:key];
                        if(r.location == 0){
                            detected = true;
                        }
                    }
                    
                    if(!detected){
                        notDetected = true;
                    }
                }
            }
            
            if(!notDetected){
                
                [self.filteredContacts addObject:contact];
            }
            
        }
        [self.membersList reloadData];
        
    }

}

- (NSUInteger)numberOfTokensInTokenField:(VENTokenField *)tokenField {
    return [self.selectedContacts count];
}

- (void)textViewDidChange:(UITextView *)textView {
    NSString *text = textView.text;
    CNetworking *currentUser = [CNetworking currentUser];
    if([text isEqualToString:@""]){
        self.filteredContacts = [currentUser.contacts mutableCopy];
    } else {
        [self.filteredContacts removeAllObjects];
        // Filter the array using NSPredicate
        
        
        for(CContact *contact in currentUser.contacts){
            NSRange r = [[contact.name lowercaseString] rangeOfString:[text lowercaseString]];
            if(r.location != NSNotFound && r.location == 0){
                [self.filteredContacts addObject:contact];
            }
            
        }
        [self.membersList reloadData];
        //    NSLog(@"changed");
        
    }
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    
//    NSLog(@"replacement text: %@", text);
//    
//    if([textView.text isEqualToString:SEARCH_INSTRUCTION]){
//        textView.text = @"";
//        [textView setTextColor:[UIColor whiteColor]];
//    } else if([text isEqualToString:@""] && textView.text.length == 1){
//        textView.text = SEARCH_INSTRUCTION;
//        self.searchBar.selectedRange = NSMakeRange(0, 0);
//        [textView setTextColor:[UIColor darkGrayColor]];
//    }
    return YES;
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
        
        CNetworking *currentUser = [CNetworking currentUser];

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
                    int k = (int)[currentUser.contacts count] - 1;
                    while(k > 0){
                        CContact *previous = currentUser.contacts[k];
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
                        current.registered = [NSNumber numberWithBool:NO];
                        
                        [currentUser.contacts addObject:current];
                    }
                }
            }
            
            NSLog(@"contacts count: %lu", [currentUser.contacts count]);
            
            [self afterContactsLoaded];
        }
        else
        {
            // show error
        }
    }];
    
}

- (void)afterContactsLoaded {
    CNetworking *currentUser = [CNetworking currentUser];
    
    self.filteredContacts = [currentUser.contacts mutableCopy];
    [self.membersList reloadData];

    
    NSDate *start = [NSDate date];
    
    // a considerable amount of difficult processing here
    // a considerable amount of difficult processing here
    // a considerable amount of difficult processing here
    
    NSMutableArray *hashedNumbers = [@[] mutableCopy];
    NSMutableDictionary *indexes = [@{} mutableCopy];
    
    int i = 0;
    for(CContact *contact in currentUser.contacts){
        [hashedNumbers addObject:[contact.number crypt]];
        [indexes setObject:[NSNumber numberWithInt:i] forKey:[contact.number crypt]];
        i++;
    }
    
    NSLog(@"hashedNumbers count: %lu", [hashedNumbers count]);
    
}

- (void)nextScreen {
    NameGroupViewController *vc = [[NameGroupViewController alloc] init];
    vc.members = self.selectedContacts;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
