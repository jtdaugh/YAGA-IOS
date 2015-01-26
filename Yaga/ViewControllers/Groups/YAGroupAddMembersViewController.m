//
//  AddMembersViewController.m
//  Pic6
//
//  Created by Raj Vir on 10/14/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import "YAGroupAddMembersViewController.h"
#import "NameGroupViewController.h"
#import "APPhoneWithLabel.h"
#import "NSString+Hash.h"
#import "YAServer.h"
#import "YAUtils.h"

@interface YAGroupAddMembersViewController ()
@property (strong, nonatomic) VENTokenField *searchBar;
@property (strong, nonatomic) UILabel *placeHolder;
@property (strong, nonatomic) UITableView *membersTableview;
@property (strong, nonatomic) NSMutableArray *filteredContacts;
@property (strong, nonatomic) NSArray *deviceContacts;

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
    
    [self.view setBackgroundColor:[UIColor blackColor]];
    
    VENTokenField *searchBar = [[VENTokenField alloc] initWithFrame:CGRectMake(0, 0, VIEW_WIDTH, 44)];
    searchBar.translatesAutoresizingMaskIntoConstraints = NO;
    [searchBar setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
    [searchBar setBackgroundColor:[UIColor blackColor]];
    [searchBar setToLabelText:@""];
    [searchBar setPlaceholderText:NSLocalizedString(@"SEARCH_TIP", @"")];
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
    
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Back", @"") style: UIBarButtonItemStylePlain target:self action:@selector(backTapped)];
    [backButton setTitleTextAttributes:@{
                                           NSFontAttributeName: [UIFont fontWithName:BIG_FONT size:18],
                                           } forState:UIControlStateNormal];
    [backButton setEnabled:YES];
    [backButton setTintColor:PRIMARY_COLOR];//[UIColor lightGrayColor]];
    self.navigationItem.leftBarButtonItem = backButton;
    
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
    
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    self.navigationController.navigationBar.translucent = NO;
    
    self.title = self.existingGroup ? self.existingGroup.name : @"Add Members";
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self.searchBar resignFirstResponder];

    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    self.navigationController.navigationBar.translucent = YES;;


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
    
    //refactor in future
    //can be YAContact in case of search by username or NSDictionary, if it's phonebook search
    id contact = self.filteredContacts[indexPath.row];
    
    cell.indentationLevel = 0;
    cell.indentationWidth = 0.0f;
    
    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    
    if([contact[kSearchedByUsername] boolValue]) {
        cell.textLabel.text = [NSString stringWithFormat:@"Add @%@", contact[nUsername]];
        cell.detailTextLabel.text = @"";
    }
    else {
        cell.textLabel.text = contact[nCompositeName];
        cell.detailTextLabel.text = [YAUtils readableNumberFromString:contact[nPhone]];
    }
    
    [cell.textLabel setTextColor:[UIColor whiteColor]];
    [cell.detailTextLabel setTextColor:[UIColor whiteColor]];
    [cell setBackgroundColor:[UIColor clearColor]];
    
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
            NSString *contactsPredicate = [NSString stringWithFormat:@"username BEGINSWITH[c] '%@'", text];
            RLMResults *contactsByUsername = [YAContact objectsWhere:contactsPredicate];
            
            NSSet *selectedUsernames = [NSSet setWithArray:[self.selectedContacts valueForKey:@"username"]];
            for(YAContact *contact in contactsByUsername) {
                if(![selectedUsernames containsObject:contact.username]) {
                    NSMutableDictionary *contactDicMutable = [[contact dictionaryRepresentation] mutableCopy];
                    contactDicMutable[kSearchedByUsername] = [NSNumber numberWithBool:YES];
                    [self.filteredContacts addObject:contactDicMutable];
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
    
    if(self.existingGroup && self.existingGroupDirty) {
        
        NSArray *friendNumbers = [self.selectedContacts valueForKey:nPhone];
        [[YAUser currentUser] iMessageWithFriends:friendNumbers withCompletion:^(NSError *error) {
            if(error)
                [YAUtils showNotification:@"Error: Can't send iMessage" type:AZNotificationTypeError];
            
            [self.existingGroup addMembers:self.selectedContacts];
            
            [self.navigationController popToRootViewControllerAnimated:YES];
            
            NSString *notificationMessage = [NSString stringWithFormat:@"%@ '%@' %@", NSLocalizedString(@"Group", @""), self.existingGroup.name, NSLocalizedString(@"Updated successfully", @"")];
            
            [YAUtils showNotification:notificationMessage type:AZNotificationTypeSuccess];
        }];
    }
    //create default group
    else {
        [YAUser currentUser].currentGroup = [YAGroup groupWithName:@"Default"];
        
        [[YAUser currentUser].currentGroup addMembers:self.selectedContacts];
        
        [self performSegueWithIdentifier:@"NameGroup" sender:self];
    }
}

- (BOOL)validateSelectedContacts {
    NSString *errorsString = @"";
    for (id contact in self.selectedContacts) {
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
    if([segue.destinationViewController isKindOfClass:[NameGroupViewController class]]) {
        ((NameGroupViewController*)segue.destinationViewController).membersDic = self.selectedContacts;
        ((NameGroupViewController*)segue.destinationViewController).embeddedMode = self.embeddedMode;   
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Actions
- (void)backTapped {
    if(self.existingGroup) {
        [self.navigationController popToRootViewControllerAnimated:YES];
    }
    else {
        [self.navigationController popViewControllerAnimated:YES];
    }
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
        [memberPhones addObject:[contact readableNumber]];
    }
    
    self.filteredContacts = [[self.deviceContacts filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"NOT (%K IN %@)", nPhone, memberPhones]] mutableCopy];
    [self.membersTableview reloadData];
}
@end
