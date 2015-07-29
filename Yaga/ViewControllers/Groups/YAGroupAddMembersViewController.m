//
//  AddMembersViewController.m
//  Pic6
//
//  Created by Raj Vir on 10/14/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import "YAGroupAddMembersViewController.h"
#import "NameGroupViewController.h"
#import "YAGroupOptionsViewController.h"
#import "APPhoneWithLabel.h"
#import "NSString+Hash.h"
#import "YAUtils.h"
#import "YAServer.h"
#import "YAAssetsCreator.h"
#import "YAInviteHelper.h"

@interface YAGroupAddMembersViewController ()
@property (strong, nonatomic) UIActivityIndicatorView *activityView;
@property (strong, nonatomic) VENTokenField *searchBar;
@property (strong, nonatomic) UILabel *placeHolder;
@property (strong, nonatomic) UITableView *membersTableview;
@property (strong, nonatomic) NSMutableArray *filteredContacts;
@property (strong, nonatomic) NSArray *deviceContacts;

@property (nonatomic, strong) YAInviteHelper *inviteHelper;
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
    
    [self.view setBackgroundColor:[UIColor whiteColor]];
    
    VENTokenField *searchBar = [[VENTokenField alloc] initWithFrame:CGRectMake(0, 0, VIEW_WIDTH, 44)];
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
    border.backgroundColor = SECONDARY_COLOR;
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
    
    [self setDoneButton];
    
    if(self.selectedContacts.count) {
        [self reloadSearchBox];
    }
    
    __weak typeof(self) weakSelf = self;
    [[YAUser currentUser] importContactsWithCompletion:^(NSError *error, NSArray *contacts, BOOL sentToServer) {
        if (error) {
            //show error
        }
        else {
            weakSelf.deviceContacts = contacts;
            
            //do not show all device contacts if search results filtered already by user
            if(!self.searchBar.inputText.length)
                weakSelf.filteredContacts = [weakSelf.deviceContacts mutableCopy];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf.membersTableview reloadData];
            });
        }
    } excludingPhoneNumbers:[self.existingGroup phonesSet]];
    
    [self.searchBar becomeFirstResponder];

}

- (void)setDoneButton {
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneTapped)];
    [doneButton setTitleTextAttributes:@{
                                         NSFontAttributeName: [UIFont fontWithName:BIG_FONT size:18],
                                         } forState:UIControlStateNormal];
    [doneButton setEnabled:NO];
    
    [doneButton setTintColor:[UIColor lightGrayColor]];
    self.navigationItem.rightBarButtonItem = doneButton;

}
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.navigationController.interactivePopGestureRecognizer.enabled = YES;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
//    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
    
    self.title = self.existingGroup ? self.existingGroup.name : @"Add Members";

    self.edgesForExtendedLayout = UIRectEdgeNone;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    if (![self.presentedViewController isKindOfClass:[MSAlertController class]]) {
        [self.searchBar resignFirstResponder];
    }
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

//val: do not delete this please
//    //update some data from phonebook
//    NSDictionary *phonebookItem = [YAUser currentUser].phonebook[contact[nPhone]];
//    if(phonebookItem) {
//        if(phonebookItem[nYagaUser]) {
//            NSMutableDictionary *updatedContact = [contact mutableCopy];
//            [updatedContact setObject:phonebookItem[nYagaUser] forKey:nYagaUser];
//            [self.filteredContacts replaceObjectAtIndex:indexPath.row withObject:updatedContact];
//        }
//    }
    
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
        [cell.textLabel       setTextColor:PRIMARY_COLOR];
        [cell.detailTextLabel setTextColor:PRIMARY_COLOR];
        
//        UIImage *img = [UIImage imageNamed:@"Ball"];
//        cell.imageView.image = img;
        
        UIView *accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Monkey_Pink"]];
        [accessoryView setFrame:CGRectMake(0, 0, 36, 36)];
        cell.accessoryView = accessoryView;
        
        NSPredicate *pred;
        NSString *phoneNumber = contact[nPhone];
        if(phoneNumber.length)
            pred = [NSPredicate predicateWithFormat:@"number = %@", contact[nPhone]];
        else
            pred = [NSPredicate predicateWithFormat:@"username = %@", contact[nUsername]];
        YAContact *ya_contact = [[YAContact objectsWithPredicate:pred] firstObject];
        if (!ya_contact) {
            ya_contact = [YAContact contactFromDictionary:contact];
        }
        
        if(![ya_contact.username isEqualToString:ya_contact.name])
            cell.detailTextLabel.text = [contact[kSearchedByUsername] boolValue] ? ya_contact.name : ya_contact.username;
        
    } else {
        [cell.textLabel       setTextColor:SECONDARY_COLOR];
        [cell.detailTextLabel setTextColor:SECONDARY_COLOR];
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
        [self.navigationItem.rightBarButtonItem setTintColor:SECONDARY_COLOR];
    } else {
        [self.navigationItem.rightBarButtonItem setEnabled:NO];
        [self.navigationItem.rightBarButtonItem setTintColor:[UIColor grayColor]];
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
                [self.filteredContacts addObject:@{nCompositeName:@"", nFirstname:@"", nLastname:@"", nPhone:phone, nYagaUser:[NSNumber numberWithBool:NO], nUsername:[YAUtils readableNumberFromString:text],  kSearchedByPhone:[NSNumber numberWithBool:YES]}];
            }
        }
        
        NSArray *keys = [[text lowercaseString] componentsSeparatedByString:@" "];
        
        NSMutableArray *subpredicates = [NSMutableArray array];
        for(NSString *key in keys) {
            if([key length] == 0) { continue; }
            NSPredicate *p = [NSPredicate predicateWithFormat:@"firstname BEGINSWITH[cd] %@ || lastname BEGINSWITH[cd] %@ || username BEGINSWITH[cd] %@", key, key, key];
            [subpredicates addObject:p];
        }
        
        NSPredicate *predicate = [NSCompoundPredicate andPredicateWithSubpredicates:subpredicates];
        NSArray *filtered = [self.deviceContacts filteredArrayUsingPredicate:predicate];
        
        //add by useraname
        if([text rangeOfString:@" "].location == NSNotFound && text.length > 0) {
            BOOL alreadyFound = NO;
            for (NSDictionary *contactData in filtered) {
                if([[contactData[nUsername] lowercaseString] isEqualToString:[text lowercaseString]]) {
                    alreadyFound = YES;
                    break;
                }
            }
            if(!alreadyFound)
                [self.filteredContacts addObject:@{nCompositeName:text, nFirstname:@"", nLastname:@"", nPhone:@"", nYagaUser:[NSNumber numberWithBool:YES], nUsername:text,  kSearchedByUsername:[NSNumber numberWithBool:YES]}];
        }
        
        [self.filteredContacts addObjectsFromArray:filtered];
        
        [self.membersTableview reloadData];
    }
    
    _existingGroupDirty = YES;
}

- (NSUInteger)numberOfTokensInTokenField:(VENTokenField *)tokenField {
    return [self.selectedContacts count];
}

- (void)showActivity:(BOOL)show {
    if(show) {
        self.activityView = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(VIEW_WIDTH - 35, 30, 30, 30)];
        self.activityView.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
        self.navigationItem.rightBarButtonItem.customView = self.activityView;
        self.navigationItem.rightBarButtonItem.enabled = NO;
        [self.activityView startAnimating];
        self.view.userInteractionEnabled = NO;
    }
    else {
        self.view.userInteractionEnabled = YES;
        [self setDoneButton];
    }
}

#pragma mark - Navigation
- (void)doneTapped {
    if(![self validateSelectedContacts])
        return;


    self.contactsThatNeedInvite = [self filterContactsToInvite];
    if (![self.contactsThatNeedInvite count]) {
        [self changeGroupOnServer];
    } else {
        self.inviteHelper = [[YAInviteHelper alloc] initWithContactsToInvite:self.contactsThatNeedInvite viewController:self cancelText:@"Skip" completion:^(BOOL sent) {
            self.inviteHelper = nil; // Do the weird __block and nil thing so inviteHelper doesn't get released until here. Could also make it a property.
            [self changeGroupOnServer];
        }];
        [self.inviteHelper show];
    }

    
    }

- (void)changeGroupOnServer {
    
    //If we come from GridViewController
    __block BOOL found = NO;
    [self.navigationController.viewControllers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if ([obj isKindOfClass:[YAGroupOptionsViewController class]]) {
            found = YES;
            *stop = YES;
        }
    }];
    
    self.inCreateGroupFlow = !found;

    __weak typeof(self) weakSelf = self;

    if(self.existingGroup && self.existingGroupDirty) {
        // Existing Group
        [self showActivity:YES];
        
        [self.existingGroup addMembers:self.selectedContacts withCompletion:^(NSError *error) {
            [weakSelf showActivity:NO];
            
            BOOL needRefresh = NO;
            for(NSDictionary *contactData in weakSelf.selectedContacts) {
                RLMResults *pendingMembers = [weakSelf.existingGroup.pending_members objectsWhere:[NSString stringWithFormat:@"username = '%@' || username = '%@'", [contactData[nUsername] lowercaseString], [contactData[nUsername] capitalizedString]]];
                if(pendingMembers.count) {
                    needRefresh = YES;
                    break;
                }
            }
            
            if(!error) {
                [[Mixpanel sharedInstance] track:@"Group changed" properties:@{@"friends added":[NSNumber numberWithInteger:weakSelf.selectedContacts.count]}];
                NSString *notificationMessage = [NSString stringWithFormat:@"%@ '%@' %@", NSLocalizedString(@"Group", @""), weakSelf.existingGroup.name, NSLocalizedString(@"Updated successfully", @"")];
                [YAUtils showNotification:notificationMessage type:YANotificationTypeSuccess];
            }
            
            if(needRefresh)
                [weakSelf.existingGroup refresh];
           
            [weakSelf dismissAddMembers];
        }];
    }
    else {
        // New group. Nested requests to create group and then add members
        [self showActivity:YES];
        
        [YAGroup groupWithName:self.groupName withCompletion:^(NSError *error, id result) {
            if(error) {
                [self showActivity:NO];
            } else {
                YAGroup *newGroup = result;
                [YAUser currentUser].currentGroup = newGroup;
                if (self.initialVideo ) {
                    [self postInitialVideo];
                }
                
                [newGroup addMembers:self.selectedContacts withCompletion:^(NSError *error) {
                    [weakSelf showActivity:NO];
                    if(!error) {
                        [[Mixpanel sharedInstance] track:@"Group created" properties:@{@"friends added":[NSNumber numberWithInteger:weakSelf.selectedContacts.count]}];
                    }
                    [weakSelf dismissAddMembers];
                }];
            }

        }];
        
    }

}

- (void)dismissAddMembers {
    // If we presented the create group flow on top of the trim screen, dimisss that & the camera as well.
    if (self.inCreateGroupFlow) {
        //       EditVideoVC              CameraVC                 GroupsNavController
        if (self.presentingViewController.presentingViewController.presentingViewController) {
            [self.presentingViewController.presentingViewController.presentingViewController dismissViewControllerAnimated:YES completion:nil];
            [[UIApplication sharedApplication]setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade]; // otherwise its hidden after dismissal
        } else {
            [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
        }
    } else {
        [self popToGridViewController];
    }
}

- (void)popToGridViewController {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)postInitialVideo {
    YAVideo *vid = self.initialVideo;
    [[YAAssetsCreator sharedCreator] createVideoFromRecodingURL:[NSURL URLWithString:vid.mp4Filename]
                                                withCaptionText:vid.caption x:vid.caption_x y:vid.caption_y scale:vid.caption_scale rotation:vid.caption_rotation
                                                    addToGroups:@[[YAUser currentUser].currentGroup]];
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
        MSAlertController *alertController = [MSAlertController
                                              alertControllerWithTitle:NSLocalizedString(@"Warning", nil)
                                              message:alertMessage
                                              preferredStyle:MSAlertControllerStyleAlert];
        MSAlertAction *okAction = [MSAlertAction
                                   actionWithTitle:NSLocalizedString(@"OK", nil)
                                   style:MSAlertActionStyleDefault
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
                               nYagaUser:[NSNumber numberWithBool:contact.registered]};
        [self.selectedContacts addObject:item];
        [memberPhones addObject:memberPhone];
    }
    
    self.filteredContacts = [[self.deviceContacts filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"NOT (%K IN %@)", nPhone, memberPhones]] mutableCopy];
    [self.membersTableview reloadData];
}

- (BOOL)blockCameraPresentationOnBackground {
    return YES;
}

@end
