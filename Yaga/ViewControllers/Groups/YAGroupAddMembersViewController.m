//
//  AddMembersViewController.m
//  Pic6
//
//  Created by Raj Vir on 10/14/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import "YAGroupAddMembersViewController.h"
#import "YAInviteViewController.h"
#import "YAGridViewController.h"
#import "NameGroupViewController.h"
#import "APPhoneWithLabel.h"
#import "NSString+Hash.h"
#import "YAUtils.h"

@interface YAGroupAddMembersViewController ()
@property (strong, nonatomic) UIView *topBar;
@property (strong, nonatomic) UIButton *doneButton;
@property (strong, nonatomic) VENTokenField *searchBar;
@property (strong, nonatomic) UILabel *placeHolder;
@property (strong, nonatomic) UITableView *membersTableview;
@property (strong, nonatomic) NSMutableArray *filteredContacts;
@property (strong, nonatomic) NSArray *deviceContacts;

@property (nonatomic, strong) NSArray *contactsThatNeedInvite;

@property (nonatomic, readonly) BOOL existingGroupDirty;

@end

#define kSearchedByUsername @"SearchedByUsername"
#define kSearchedByPhone    @"SearchedByPhone"

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
    
    [self addNavBarView];
    CGFloat origin = 64;
    
    VENTokenField *searchBar = [[VENTokenField alloc] initWithFrame:CGRectMake(0, origin, VIEW_WIDTH, 44)];
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
    origin = searchBar.frame.origin.y + searchBar.frame.size.height;
    UITableView *membersList = [[UITableView alloc] initWithFrame:CGRectMake(0, origin, VIEW_WIDTH, VIEW_HEIGHT - origin) style:UITableViewStylePlain];
    membersList.translatesAutoresizingMaskIntoConstraints = NO;

    [membersList setBackgroundColor:[UIColor clearColor]];
    [membersList setDataSource:self];
    [membersList setDelegate:self];
    [membersList setContentInset:UIEdgeInsetsMake(0, 0, 216, 0)];
    
    membersList.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.membersTableview = membersList;
    
    [self.view addSubview:self.membersTableview];
    UIView *navBar = self.topBar;
    NSDictionary *views = NSDictionaryOfVariableBindings(navBar, searchBar, border, membersList);
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[navBar]|" options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[searchBar]|" options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[border]|" options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[membersList]|" options:0 metrics:nil views:views]];
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[navBar][searchBar][border(1)]-0-[membersList]|" options:0 metrics:nil views:views]];

    
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
    self.navigationController.interactivePopGestureRecognizer.enabled = YES;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
//    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];

    [self.searchBar becomeFirstResponder];
    
    self.edgesForExtendedLayout = UIRectEdgeNone;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self.searchBar resignFirstResponder];

    self.title = @"";
}

- (void)addNavBarView {
    
    self.topBar = [[UIView alloc] initWithFrame:CGRectMake(0, 0, VIEW_WIDTH, 64)];
    self.topBar.backgroundColor = PRIMARY_COLOR;
    UILabel *groupNameLabel = [[UILabel alloc] initWithFrame:CGRectMake((VIEW_WIDTH - 200)/2, 28, 200, 30)];
    groupNameLabel.textColor = [UIColor whiteColor];
    groupNameLabel.textAlignment = NSTextAlignmentCenter;
    [groupNameLabel setFont:[UIFont fontWithName:BIG_FONT size:20]];
    groupNameLabel.text = self.existingGroup ? self.existingGroup.name : @"Add Members";
    [self.topBar addSubview:groupNameLabel];
    
    UIButton *backButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 25, 34, 34)];
    backButton.imageEdgeInsets = UIEdgeInsetsMake(5, 5, 5, 5);
    [backButton setImage:[[UIImage imageNamed:@"Back"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    backButton.tintColor = [UIColor whiteColor];
    [backButton.imageView setContentMode:UIViewContentModeScaleAspectFit];
    [backButton addTarget:self action:@selector(backButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.topBar addSubview:backButton];
    
    CGFloat doneWidth = 70;
    self.doneButton = [[UIButton alloc] initWithFrame:CGRectMake(VIEW_WIDTH - doneWidth - 10, 31, doneWidth, 28)];
    [self.doneButton setTitle:@"Done" forState:UIControlStateNormal];
    [self.doneButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.doneButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateDisabled];
    [self.doneButton.titleLabel setFont:[UIFont fontWithName:BIG_FONT size:18]];
    self.doneButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
    [self.doneButton addTarget:self action:@selector(doneTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.doneButton setEnabled:NO];
    [self.topBar addSubview:self.doneButton];
    
    [self.view addSubview:self.topBar];
    
}

- (void)backButtonPressed:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
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
    
    NSMutableDictionary *contact = self.filteredContacts[indexPath.row];

    //update some data from phonebook
    NSDictionary *phonebookItem = [YAUser currentUser].phonebook[contact[nPhone]];
    if(phonebookItem) {
        if(phonebookItem[nYagaUser]) {
            NSMutableDictionary *updatedContact = [contact mutableCopy];
            [updatedContact setObject:phonebookItem[nYagaUser] forKey:nYagaUser];
            [self.filteredContacts replaceObjectAtIndex:indexPath.row withObject:updatedContact];
        }
    }
    
    cell.indentationLevel = 0;
    cell.indentationWidth = 0.0f;
    
    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    
    //suggest existing or non existing usernames
    if([contact[kSearchedByUsername] boolValue]) {
        cell.textLabel.text = [NSString stringWithFormat:@"Add @%@", contact[nUsername]];
        cell.detailTextLabel.text = @"";
    }
    else if([contact[kSearchedByPhone] boolValue]) {
        cell.textLabel.text = [NSString stringWithFormat:@"Add %@", contact[nUsername]];
        cell.detailTextLabel.text = @"";
    }
    //existing phone book contacts
    else {
        cell.textLabel.text = contact[nCompositeName];
        cell.detailTextLabel.text = [YAUtils readableNumberFromString:contact[nPhone]];
    }
    
    if ([contact[nYagaUser] boolValue]){
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
        [self.doneButton setEnabled:YES];
    } else {
        [self.doneButton setEnabled:NO];
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
    else if([contact[kSearchedByPhone] boolValue])
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
        
        //add by phone
        if([YAUtils validatePhoneNumber:text]) {
            NSString *phone = [YAUtils phoneNumberFromText:text numberFormat:NBEPhoneNumberFormatE164];
            if(phone) {
                [self.filteredContacts addObject:@{nCompositeName:@"", nFirstname:@"", nLastname:@"", nPhone:phone, nRegistered:[NSNumber numberWithBool:NO], nUsername:[YAUtils phoneNumberFromText:text numberFormat:NBEPhoneNumberFormatNATIONAL],  kSearchedByPhone:[NSNumber numberWithBool:YES]}];
            }
        }
        //add by username
        else if([text rangeOfString:@" "].location == NSNotFound) {
            if(text.length > 2) {
                
                NSString *contactsPredicate = [[NSString stringWithFormat:@"username BEGINSWITH[c] '%@'", text] stringByReplacingOccurrencesOfString:@"\\" withString:@""];
                RLMResults *contactsByUsername = [YAContact objectsWhere:contactsPredicate];
                
                NSSet *selectedUsernames = [NSSet setWithArray:[self.selectedContacts valueForKey:@"username"]];
                for(YAContact *contact in contactsByUsername) {
                    if(![selectedUsernames containsObject:contact.username]) {
                        NSMutableDictionary *contactDicMutable = [[contact dictionaryRepresentation] mutableCopy];
                        contactDicMutable[kSearchedByUsername] = [NSNumber numberWithBool:YES];
                        contactDicMutable[nYagaUser] = [NSNumber numberWithBool:YES];
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

    //If we come from GridViewController
    __block BOOL found = NO;
    [self.navigationController.viewControllers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if ([obj isKindOfClass:[YAGridViewController class]]) {
            found = YES;
            *stop = YES;
        }
    }];
    self.inCreateGroupFlow = !found;
    
    __weak typeof(self) weakSelf = self;
    
    if(self.existingGroup && self.existingGroupDirty) {
        // Existing Group
        [self.existingGroup addMembers:self.selectedContacts withCompletion:^(NSError *error) {
            if(!error) {
                [[Mixpanel sharedInstance] track:@"Group changed" properties:@{@"friends added":[NSNumber numberWithInteger:weakSelf.selectedContacts.count]}];
                
                weakSelf.contactsThatNeedInvite = [weakSelf filterContactsToInvite];
                if (![weakSelf.contactsThatNeedInvite count]) {
                    NSString *notificationMessage = [NSString stringWithFormat:@"%@ '%@' %@", NSLocalizedString(@"Group", @""), weakSelf.existingGroup.name, NSLocalizedString(@"Updated successfully", @"")];
                    [YAUtils showNotification:notificationMessage type:YANotificationTypeSuccess];
                    [weakSelf popToGridViewController];
                } else {
                    // Push the invite screen
                    YAInviteViewController *nextVC = [YAInviteViewController new];
                    nextVC.inCreateGroupFlow = NO;
                    nextVC.contactsThatNeedInvite = weakSelf.contactsThatNeedInvite;
                    [weakSelf.navigationController pushViewController:nextVC animated:YES];
                }
            }

        }];
    }
    else {
        // New group
        [[YAUser currentUser].currentGroup addMembers:self.selectedContacts withCompletion:^(NSError *error) {
            if(!error) {
                [[Mixpanel sharedInstance] track:@"Group created" properties:@{@"friends added":[NSNumber numberWithInteger:weakSelf.selectedContacts.count]}];
                
                weakSelf.contactsThatNeedInvite = [weakSelf filterContactsToInvite];
                if (![weakSelf.contactsThatNeedInvite count]) {
                    [weakSelf popToGridViewController];
                } else {
                    YAInviteViewController *nextVC = [YAInviteViewController new];
                    nextVC.inCreateGroupFlow = YES;
                    nextVC.contactsThatNeedInvite = weakSelf.contactsThatNeedInvite;
                    [weakSelf.navigationController pushViewController:nextVC animated:YES];
                }
            }
        }];
    }
}

- (void)popToGridViewController {
    if (self.inCreateGroupFlow) {
        NSMutableArray *navStack = [[self.navigationController viewControllers] mutableCopy];
        YAGridViewController *gridVC = [[YAGridViewController alloc] init];
        [navStack insertObject:gridVC atIndex:1]; // right after groups VC
        [self.navigationController setViewControllers:navStack];
    }
    UIViewController *dest = nil;
    for (UIViewController *vc in [self.navigationController viewControllers]) {
        if ([vc isKindOfClass:[YAGridViewController class]]) {
            dest = vc;
            break;
        }
    }
    if (dest) {
        [self.navigationController popToViewController:dest animated:YES];
    } else {
        [self.navigationController popToRootViewControllerAnimated:YES];
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
        
        if(![YAUtils validatePhoneNumber:phoneNumber]) {
            if(((NSString*)contact[nCompositeName]).length)
                errorsString = [errorsString stringByAppendingFormat:@"%@ : %@ \n", contact[nCompositeName], contact[nPhone]];
            else
                errorsString = [errorsString stringByAppendingFormat:@"%@ \n", contact[nPhone]];
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

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Actions
- (void)backTapped {
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark -
- (void)setExistingGroup:(YAGroup *)existingGroup {
    _existingGroup = existingGroup;

    NSMutableArray *memberPhones = [NSMutableArray new];
    for(YAContact *contact in self.existingGroup.members) {
        
        NSString *memberPhone = [contact readableNumber];
        if(!memberPhone.length)
            continue;
        
        NSDictionary *item = @{nCompositeName:[NSString stringWithFormat:@"%@ %@", contact.firstName, contact.lastName],
                               nPhone:memberPhone,
                               nFirstname: [NSString stringWithFormat:@"%@", contact.firstName],
                               nLastname:  [NSString stringWithFormat:@"%@", contact.lastName],
                               nRegistered:[NSNumber numberWithBool:contact.registered]};
        [self.selectedContacts addObject:item];
        [memberPhones addObject:memberPhone];
    }
    
    self.filteredContacts = [[self.deviceContacts filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"NOT (%K IN %@)", nPhone, memberPhones]] mutableCopy];
    [self.membersTableview reloadData];
}
@end
