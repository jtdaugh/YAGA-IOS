//
//  AddMembersViewController.m
//  Pic6
//
//  Created by Raj Vir on 10/14/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import "YAGroupAddMembersViewController.h"
#import "YACaptureSession.h"
#import "YAInviteViewController.h"
#import "GridViewController.h"
#import "NameGroupViewController.h"
#import "APPhoneWithLabel.h"
#import "NSString+Hash.h"
#import "YAUtils.h"

@interface YAGroupAddMembersViewController ()
@property (strong, nonatomic) VENTokenField *searchBar;
@property (strong, nonatomic) UILabel *placeHolder;
@property (strong, nonatomic) UITableView *membersTableview;
@property (strong, nonatomic) NSMutableArray *filteredContacts;
@property (strong, nonatomic) NSArray *deviceContacts;

@property (nonatomic) BOOL inOnboarding;
@property (nonatomic, strong) NSArray *contactsThatNeedInvite;

@property (nonatomic, readonly) BOOL existingGroupDirty;

@end

#define kSearchedByUsername @"SearchedByUsername"

@implementation YAGroupAddMembersViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWasShown:)
                                                 name:UIKeyboardDidShowNotification
                                               object:nil];
    
    if(!self.selectedContacts)
        _selectedContacts = [[NSMutableArray alloc] init];
    
    [self.view setBackgroundColor:PRIMARY_COLOR];
    
    VENTokenField *searchBar = [[VENTokenField alloc] initWithFrame:CGRectMake(0, 0, VIEW_WIDTH, 44)];
    searchBar.translatesAutoresizingMaskIntoConstraints = NO;
    [searchBar setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
    [searchBar setBackgroundColor:[UIColor whiteColor]];
    [searchBar setToLabelText:@""];
//    [[UILabel appearanceWhenContainedIn:[UISearchBar class], nil] setTextColor:[UIColor redColor]];
//    [[UITextField appearanceWhenContainedIn:[UISearchBar class], nil] setDefaultTextAttributes:@{NSForegroundColorAttributeName:[UIColor redColor]}];
    [searchBar setPlaceholderText:NSLocalizedString(@"SEARCH_TIP", @"")];
    [searchBar setColorScheme:PRIMARY_COLOR];
    [searchBar setInputTextFieldTextColor:PRIMARY_COLOR];
    searchBar.delegate = self;
    searchBar.dataSource = self;
    
    self.searchBar = searchBar;
    [self.view addSubview:self.searchBar];
    
    UIView *border = [[UIView alloc] init];
    border.translatesAutoresizingMaskIntoConstraints = NO;
    border.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:border];
    
    UITableView *membersList = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    membersList.translatesAutoresizingMaskIntoConstraints = NO;
    
    [membersList setBackgroundColor:[UIColor clearColor]];
    [membersList setDataSource:self];
    [membersList setDelegate:self];
    [membersList setContentInset:UIEdgeInsetsMake(0, 0, 216, 0)];
    
    membersList.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.membersTableview = membersList;
    
    [self.view addSubview:self.membersTableview];
    
    NSDictionary *views = NSDictionaryOfVariableBindings(searchBar, border, membersList);
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[searchBar]|" options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[border]|" options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[membersList]|" options:0 metrics:nil views:views]];
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[searchBar][border(1)]-0-[membersList]|" options:0 metrics:nil views:views]];
    
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneTapped)];
    [doneButton setTitleTextAttributes:@{
                                            NSFontAttributeName: [UIFont fontWithName:BIG_FONT size:18],
                                            } forState:UIControlStateNormal];
    [doneButton setEnabled:NO];
    
    [doneButton setTintColor:[UIColor lightGrayColor]];
    self.navigationItem.rightBarButtonItem = doneButton;
    
    if(self.selectedContacts.count) {
        [self reloadSearchBox];
    }
    
    __weak typeof(self) weakSelf = self;
    [[YAUser currentUser] importContactsWithCompletion:^(NSError *error, NSArray *contacts) {
        if (error) {
            //show error
        }
        else {
            weakSelf.deviceContacts = contacts;
            
            //do not show all device contacts if search results filtered already by user
            if(!self.searchBar.inputText.length)
                weakSelf.filteredContacts = [self.deviceContacts mutableCopy];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf.membersTableview reloadData];
            });
        }
    } excludingPhoneNumbers:[self.existingGroup phonesSet]];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.searchBar becomeFirstResponder];
    
    self.edgesForExtendedLayout = UIRectEdgeNone;
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    self.navigationController.navigationBar.translucent = NO;
    
    self.title = self.existingGroup ? self.existingGroup.name : @"Add Members";
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self.searchBar resignFirstResponder];
    
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    self.navigationController.navigationBar.translucent = YES;


    self.title = @"";
}

- (void)keyboardWasShown:(NSNotification *)notification {
    // Get the size of the keyboard.
    NSDictionary* keyboardInfo = [notification userInfo];
    NSValue* keyboardFrameBegin = [keyboardInfo valueForKey:UIKeyboardFrameBeginUserInfoKey];
    CGRect keyboardFrameBeginRect = [keyboardFrameBegin CGRectValue];
    CGSize keyboardSize = keyboardFrameBeginRect.size;
    [self.membersTableview setContentInset:UIEdgeInsetsMake(0, 0, keyboardSize.height, 0)];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.filteredContacts count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"Cell"];
    }
    
    CGRect frame = cell.contentView.frame;
    frame.origin.x = 0;
    [cell setFrame:frame];
    
    NSDictionary *contact = self.filteredContacts[indexPath.row];
    
    cell.indentationLevel = 0;
    cell.indentationWidth = 0.0f;
    
    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    
    //suggest existing or non existing usernames
    if([contact[kSearchedByUsername] boolValue]) {
        cell.textLabel.text = [NSString stringWithFormat:@"Add @%@", contact[nUsername]];
        cell.detailTextLabel.text = @"";
    }
    //existing phone book contacts
    else {
        cell.textLabel.text = contact[nCompositeName];
        cell.detailTextLabel.text = [YAUtils readableNumberFromString:contact[nPhone]];
    }
    
    BOOL yagaUser = NO;
    if(contact[nPhone]) {
        NSDictionary *phonebookItem = [YAUser currentUser].phonebook[contact[nPhone]];
        yagaUser = [phonebookItem[nYagaUser] boolValue];
    }
    
    if (yagaUser){
        [cell.textLabel       setTextColor:[UIColor blackColor]];
        [cell.detailTextLabel setTextColor:[UIColor blackColor]];
        
//        UIImage *img = [UIImage imageNamed:@"Ball"];
//        cell.imageView.image = img;
        
        UIView *accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Monkey"]];
        [accessoryView setFrame:CGRectMake(0, 0, 36, 36)];
        cell.accessoryView = accessoryView;
        
        
        NSPredicate *pred = [NSPredicate predicateWithFormat:@"number = %@", contact[nPhone]];
        YAContact *ya_contact = [[YAContact objectsWithPredicate:pred] firstObject];
        if (!ya_contact) {
            ya_contact = [YAContact contactFromDictionary:contact];
        }
        
        cell.detailTextLabel.text = ya_contact.username;
        
    } else {
        [cell.textLabel       setTextColor:[UIColor whiteColor]];
        [cell.detailTextLabel setTextColor:[UIColor whiteColor]];
//        cell.imageView.image = nil;
        cell.accessoryView = nil;
    }
    [cell setBackgroundColor:[UIColor clearColor]];
    
    return cell;
}

- (void)reloadSearchBox {
    [self.searchBar reloadData];
    
    if([self numberOfTokensInTokenField:self.searchBar] > 0){
        [self.navigationItem.rightBarButtonItem setEnabled:YES];
        [self.navigationItem.rightBarButtonItem setTintColor:[UIColor whiteColor]];
    } else {
        [self.navigationItem.rightBarButtonItem setEnabled:NO];
        [self.navigationItem.rightBarButtonItem setTintColor:[UIColor lightGrayColor]];
    }
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.selectedContacts addObject:self.filteredContacts[indexPath.row]];
    [self reloadSearchBox];
    
    [self.filteredContacts removeObjectAtIndex:indexPath.row];
    [self.membersTableview deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    
    //reload table view
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self tokenField:self.searchBar didChangeText:@""];
    });
    
    _existingGroupDirty = YES;
}

- (NSString *)tokenField:(VENTokenField *)tokenField titleForTokenAtIndex:(NSUInteger)index {
    id contact = self.selectedContacts[index];
    if([contact[kSearchedByUsername] boolValue])
        return contact[nUsername];
    else
        return contact[nCompositeName];
}

- (void)tokenField:(VENTokenField *)tokenField didDeleteTokenAtIndex:(NSUInteger)index {
    [self.selectedContacts removeObjectAtIndex:index];
    
    [self reloadSearchBox];
    
    self.filteredContacts = [self.deviceContacts mutableCopy];
    [self.filteredContacts removeObjectsInArray:self.selectedContacts];
    
    [self.membersTableview reloadData];
    
    _existingGroupDirty = YES;
}

- (void)tokenField:(VENTokenField *)tokenField didChangeText:(NSString *)text {
    self.filteredContacts = [self.deviceContacts mutableCopy];
    [self.filteredContacts removeObjectsInArray:self.selectedContacts];
    
    if([text isEqualToString:@""]) {
        [self.membersTableview reloadData];
    } else {
        [self.filteredContacts removeAllObjects];
        [self.membersTableview reloadData];
        
        //search by username
        if([text rangeOfString:@" "].location == NSNotFound) {
            if(text.length > 2) {
                
                NSString *contactsPredicate = [[NSString stringWithFormat:@"username BEGINSWITH[c] '%@'", text] stringByReplacingOccurrencesOfString:@"\\" withString:@""];
                RLMResults *contactsByUsername = [YAContact objectsWhere:contactsPredicate];
                
                NSSet *selectedUsernames = [NSSet setWithArray:[self.selectedContacts valueForKey:@"username"]];
                for(YAContact *contact in contactsByUsername) {
                    if(![selectedUsernames containsObject:contact.username]) {
                        NSMutableDictionary *contactDicMutable = [[contact dictionaryRepresentation] mutableCopy];
                        contactDicMutable[kSearchedByUsername] = [NSNumber numberWithBool:YES];
                        [self.filteredContacts addObject:contactDicMutable];
                    }
                    
                }
                
                NSArray *foundUsernames = [self.filteredContacts valueForKey:nUsername];
                if(![foundUsernames containsObject:text]) {
                    [self.filteredContacts addObject:@{nCompositeName:@"", nFirstname:@"", nLastname:@"", nPhone:@"", nRegistered:[NSNumber numberWithBool:NO], nUsername:text,  kSearchedByUsername:[NSNumber numberWithBool:YES]}];
                }
            }
        }
        
        NSArray *keys = [[text lowercaseString] componentsSeparatedByString:@" "];
        
        NSMutableArray *subpredicates = [NSMutableArray array];
        for(NSString *key in keys) {
            if([key length] == 0) { continue; }
            NSPredicate *p = [NSPredicate predicateWithFormat:@"firstname BEGINSWITH[cd] %@ || lastname BEGINSWITH[cd] %@", key, key];
            [subpredicates addObject:p];
        }
        
        NSPredicate *predicate = [NSCompoundPredicate andPredicateWithSubpredicates:subpredicates];
        NSArray *filtered = [self.deviceContacts filteredArrayUsingPredicate:predicate];
        
        [self.filteredContacts addObjectsFromArray:filtered];
        [self.membersTableview reloadData];
    }
    
    _existingGroupDirty = YES;
}

- (NSUInteger)numberOfTokensInTokenField:(VENTokenField *)tokenField {
    return [self.selectedContacts count];
}

#pragma mark - Navigation
- (void)doneTapped {
    if(![self validateSelectedContacts])
        return;

    //If we come from NoGroupsViewController
    __block BOOL found = NO;
    [self.navigationController.viewControllers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if ([obj isKindOfClass:[GridViewController class]]) {
            found = YES;
            *stop = YES;
        }
    }];
    self.inOnboarding = !found;
    
    if(self.existingGroup && self.existingGroupDirty) {
        // Existing Group
        [self.existingGroup addMembers:self.selectedContacts];
        [AnalyticsKit logEvent:@"Group changed" withProperties:@{@"friends added":[NSNumber numberWithInteger:self.selectedContacts.count]}];

        self.contactsThatNeedInvite = [self filterContactsToInvite];
        if (![self.contactsThatNeedInvite count]) {
            
            [self.navigationController popToRootViewControllerAnimated:YES];
            
            NSString *notificationMessage = [NSString stringWithFormat:@"%@ '%@' %@", NSLocalizedString(@"Group", @""), self.existingGroup.name, NSLocalizedString(@"Updated successfully", @"")];
            
            [YAUtils showNotification:notificationMessage type:YANotificationTypeSuccess];
        } else {
            // Push the invite screen
            [[YACaptureSession captureSession] closeCamera];
            YAInviteViewController *nextVC = [YAInviteViewController new];
            nextVC.inOnboardingFlow = NO;
            nextVC.contactsThatNeedInvite = self.contactsThatNeedInvite;
            [self.navigationController pushViewController:nextVC animated:YES];
        }
    }
    else {
        // New group
        
        [[YAUser currentUser].currentGroup addMembers:self.selectedContacts];
        [AnalyticsKit logEvent:@"Group created" withProperties:@{@"friends added":[NSNumber numberWithInteger:self.selectedContacts.count]}];
        
        
        self.contactsThatNeedInvite = [self filterContactsToInvite];
        if (![self.contactsThatNeedInvite count]) {
            if (self.inOnboarding) {
                [self performSegueWithIdentifier:@"CompleteOnboarding" sender:self];
            } else {
                [self.navigationController popToRootViewControllerAnimated:YES];
            }
        } else {
            if (self.inOnboarding) {
                [self performSegueWithIdentifier:@"ShowInviteScreen" sender:self];
            } else {
                // Push the invite screen
                YAInviteViewController *nextVC = [YAInviteViewController new];
                nextVC.inOnboardingFlow = NO;
                nextVC.contactsThatNeedInvite = self.contactsThatNeedInvite;
                [self.navigationController pushViewController:nextVC animated:YES];
            }
        }
    }
}

- (NSArray *)filterContactsToInvite {
    NSMutableArray *contactsNotOnYaga = [NSMutableArray new];
    for (NSDictionary *contact in self.selectedContacts) {
        BOOL yagaUser = [((NSNumber*)contact[nYagaUser]) boolValue];
        if (!yagaUser){
            [contactsNotOnYaga addObject:contact];
        }
    }
    return contactsNotOnYaga;
}

- (BOOL)validateSelectedContacts {
    NSString *errorsString = @"";
    for (NSDictionary *contact in self.selectedContacts) {
        if([contact[kSearchedByUsername] boolValue]) {
            continue;
        }
        
        NSString *phoneNumber = contact[nPhone];
        
        NSError *error;
        if(![YAUtils validatePhoneNumber:phoneNumber error:&error]) {
            errorsString = [errorsString stringByAppendingFormat:@"%@ : %@ \n", contact[nCompositeName], contact[nPhone]];
        }
    }
    
    if(errorsString.length) {
        NSString *alertMessage = [NSString stringWithFormat:@"%@:\n\n%@", NSLocalizedString(@"SOME PHONE NUMBERS ARE INCORRECT MESSAGE", @""), errorsString];
        UIAlertController *alertController = [UIAlertController
                                              alertControllerWithTitle:NSLocalizedString(@"Warning", nil)
                                              message:alertMessage
                                              preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *okAction = [UIAlertAction
                                   actionWithTitle:NSLocalizedString(@"OK", nil)
                                   style:UIAlertActionStyleDefault
                                   handler:nil];
        
        [alertController addAction:okAction];
        [self presentViewController:alertController animated:YES completion:nil];
    }
    
    return errorsString.length == 0;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.destinationViewController isKindOfClass:[YAInviteViewController class]]) {
        YAInviteViewController *destinationVC = (YAInviteViewController*)segue.destinationViewController;
        destinationVC.inOnboardingFlow = self.inOnboarding;
        destinationVC.contactsThatNeedInvite = self.contactsThatNeedInvite;
    }
    if([segue.destinationViewController isKindOfClass:[NameGroupViewController class]]) {
        NameGroupViewController *destinationVC = (NameGroupViewController*)segue.destinationViewController;
        destinationVC.membersDic = self.selectedContacts;
        destinationVC.embeddedMode = self.embeddedMode;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Actions
- (void)backTapped {
//    if(self.existingGroup) {
//        [self.navigationController popToRootViewControllerAnimated:YES];
//    }
//    else {
        [self.navigationController popViewControllerAnimated:YES];
//    }
}

#pragma mark -
- (void)setExistingGroup:(YAGroup *)existingGroup {
    _existingGroup = existingGroup;

    NSMutableArray *memberPhones = [NSMutableArray new];
    for(YAContact *contact in self.existingGroup.members) {
        
        NSDictionary *item = @{nCompositeName:[NSString stringWithFormat:@"%@ %@", contact.firstName, contact.lastName],
                               nPhone:[contact readableNumber],
                               nFirstname: [NSString stringWithFormat:@"%@", contact.firstName],
                               nLastname:  [NSString stringWithFormat:@"%@", contact.lastName],
                               nRegistered:[NSNumber numberWithBool:contact.registered]};
        [self.selectedContacts addObject:item];
        
        NSString *memberPhone = [contact readableNumber];
        if(memberPhone.length)
            [memberPhones addObject:memberPhone];
    }
    
    self.filteredContacts = [[self.deviceContacts filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"NOT (%K IN %@)", nPhone, memberPhones]] mutableCopy];
    [self.membersTableview reloadData];
}
@end
