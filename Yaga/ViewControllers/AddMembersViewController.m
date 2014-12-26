//
//  AddMembersViewController.m
//  Pic6
//
//  Created by Raj Vir on 10/14/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import "AddMembersViewController.h"
#import "NameGroupViewController.h"
#import "APPhoneWithLabel.h"
#import "NSString+Hash.h"
#import "YAAuthManager.h"
#import "YAGroupCreator.h"
#import "YAUtils.h"

@interface AddMembersViewController ()
@property (strong, nonatomic) VENTokenField *searchBar;
@property (strong, nonatomic) UILabel *placeHolder;
@property (strong, nonatomic) UITableView *membersTableview;
@property (strong, nonatomic) NSMutableArray *filteredContacts;
@property (strong, nonatomic) NSArray *deviceContacts;

//an array of arrays(firstname, lastname)
@property (strong, nonatomic) NSArray *deviceNames;
- (void)cancelScreen;
@end

@implementation AddMembersViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWasShown:)
                                                 name:UIKeyboardDidShowNotification
                                               object:nil];
    
    self.selectedContacts = [[NSMutableArray alloc] init];
    
    self.title = @"Add Members";
    
    [self.view setBackgroundColor:[UIColor blackColor]];
    
    VENTokenField *searchBar = [[VENTokenField alloc] initWithFrame:CGRectMake(0.0f, 0, VIEW_WIDTH, 42)];
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
    
    UIBarButtonItem *anotherButton = [[UIBarButtonItem alloc] initWithTitle:@"Next" style:UIBarButtonItemStylePlain target:self action:@selector(nextScreen)];
    [anotherButton setTitleTextAttributes:@{
                                            NSFontAttributeName: [UIFont fontWithName:BIG_FONT size:18],
                                            } forState:UIControlStateNormal];
    [anotherButton setEnabled:NO];
    [anotherButton setTintColor:[UIColor lightGrayColor]];
    self.navigationItem.rightBarButtonItem = anotherButton;
    
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Back", @"") style:UIBarButtonItemStylePlain target:self action:@selector(cancelScreen)];
    [cancelButton setTitleTextAttributes:@{
                                           NSFontAttributeName: [UIFont fontWithName:BIG_FONT size:18],
                                           } forState:UIControlStateNormal];
    [cancelButton setEnabled:YES];
    [cancelButton setTintColor:[UIColor lightGrayColor]];
    self.navigationItem.leftBarButtonItem = cancelButton;
    
    __weak typeof(self) weakSelf = self;
    [[YAUser currentUser] importContactsWithCompletion:^(NSError *error, NSOrderedSet *contacts) {
        if (error) {
            //show error
        }
        else {
            weakSelf.deviceContacts = [contacts mutableCopy];
            weakSelf.filteredContacts = [self.deviceContacts mutableCopy];
            dispatch_async(dispatch_get_global_queue(0, DISPATCH_QUEUE_PRIORITY_DEFAULT), ^{
                NSMutableArray *namesArray = [NSMutableArray new];
                for(NSDictionary *contactDic in self.deviceContacts){
                    NSArray *names = [[contactDic[nCompositeName] lowercaseString] componentsSeparatedByString:@" "];
                    [namesArray addObject:names];
                }
                self.deviceNames = namesArray;
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [weakSelf.membersTableview reloadData];
                });
            });
            
        }
    }];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.searchBar becomeFirstResponder];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:YES];
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
    
    
    NSDictionary *contactDic = self.filteredContacts[indexPath.row];
    
    cell.indentationLevel = 0;
    cell.indentationWidth = 0.0f;
    
    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    
    [cell.textLabel setText:contactDic[nCompositeName]];
    [cell.detailTextLabel setText:[YAUtils readableNumberFromString:contactDic[nPhone]]];
    
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
    
    [self.filteredContacts removeObject:self.filteredContacts[indexPath.row]];
    [self.membersTableview deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (NSString *)tokenField:(VENTokenField *)tokenField titleForTokenAtIndex:(NSUInteger)index {
    NSDictionary *contactDic = self.selectedContacts[index];
    return contactDic[nCompositeName];
}

- (void)tokenField:(VENTokenField *)tokenField didDeleteTokenAtIndex:(NSUInteger)index {
    [self.selectedContacts removeObjectAtIndex:index];
    
    [self reloadSearchBox];
    
    self.filteredContacts = [self.deviceContacts mutableCopy];
    [self.filteredContacts removeObjectsInArray:self.selectedContacts];
    
    [self.membersTableview reloadData];
}

- (void)tokenField:(VENTokenField *)tokenField didChangeText:(NSString *)text {
    self.filteredContacts = [self.deviceContacts mutableCopy];
    [self.filteredContacts removeObjectsInArray:self.selectedContacts];
    
    if([text isEqualToString:@""]) {
        [self.membersTableview reloadData];
    } else {
        [self.filteredContacts removeAllObjects];
        [self.membersTableview reloadData];
        
        NSArray *keys = [[text lowercaseString] componentsSeparatedByString:@" "];
        NSMutableSet *objectsToAdd = [NSMutableSet set];
        
        for(NSArray *names in self.deviceNames){
//            NSArray *names = [[contactDic[nCompositeName] lowercaseString] componentsSeparatedByString:@" "];
            
            BOOL notDetected = NO;
            
            for(NSString *key in keys){
                if(![key isEqualToString:@""]){
                    BOOL detected = NO;
                    
                    for(NSString *name in names){
                        NSRange r = [name rangeOfString:key];
                        if(r.location == 0){
                            detected = YES;
                        }
                    }
                    
                    if(!detected){
                        notDetected = YES;
                    }
                }
            }
            
            if(!notDetected){
                [objectsToAdd addObject:contactDic];
            }
        }
        
        [self.filteredContacts addObjectsFromArray:[objectsToAdd allObjects]];
        [self.membersTableview reloadData];
    }
}

- (NSUInteger)numberOfTokensInTokenField:(VENTokenField *)tokenField {
    return [self.selectedContacts count];
}

#pragma mark - Navigation
- (void)nextScreen {
    [[YAAuthManager sharedManager] addCascadingUsers:self.selectedContacts
                                             toGroup:[YAGroupCreator sharedCreator].groupId
                                      withCompletion:^(bool response, NSString *error) {
        [self performSegueWithIdentifier:@"NameGroup" sender:self];
    }];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if([segue.destinationViewController isKindOfClass:[NameGroupViewController class]]) {
        ((NameGroupViewController*)segue.destinationViewController).membersDic = self.selectedContacts;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Actions
- (void)cancelScreen
{
    [self.navigationController popViewControllerAnimated:YES];
}


@end
