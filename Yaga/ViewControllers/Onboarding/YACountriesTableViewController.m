//
//  YACountriesTableViewController.m
//  Yaga
//
//  Created by Iegor on 12/18/14.
//  Copyright (c) 2014 Raj Vir. All rights reserved.
//

#import "YACountriesTableViewController.h"
#import "CountryListDataSource.h"
#import "CountryCell.h"
#import "YAUser.h"

@interface YACountriesTableViewController ()
@property (strong, nonatomic) NSArray *dataRows;
@property (strong, nonatomic) NSMutableArray *filteredCountries;
@property (nonatomic) BOOL isBeingSearched;
@end

@implementation YACountriesTableViewController
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    CountryListDataSource *dataSource = [CountryListDataSource new];
    self.dataRows = [dataSource countries];
    // Initialize the filteredCandyArray with a capacity equal to the candyArray's capacity
    self.filteredCountries = [NSMutableArray arrayWithArray:self.dataRows];
    [self.tableView reloadData];
    
    self.title = NSLocalizedString(@"Choose your Country", @"");
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [self.view setBackgroundColor:PRIMARY_COLOR];
    
    self.searchBar.tintColor = PRIMARY_COLOR;
    self.searchBar.barTintColor = [UIColor whiteColor];
    
    [self.tableView setBackgroundColor:[UIColor clearColor]];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.searchBar becomeFirstResponder];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.searchBar resignFirstResponder];
}


#pragma mark - UITableView Datasource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.isBeingSearched) {
        return [self.filteredCountries count];
    }
    else {
        return [self.dataRows count];
    }
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    cell.backgroundColor = [UIColor clearColor];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"Cell";
    
    CountryCell *cell = (CountryCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if(cell == nil) {
        cell = [[CountryCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellIdentifier];
    }
    id obj;
    if (self.isBeingSearched) {
        obj = [_filteredCountries objectAtIndex:indexPath.row];
    } else {
        obj = [_dataRows objectAtIndex:indexPath.row];
    }
    
    if (![obj isKindOfClass:[NSNull class]]) {
        cell.textLabel.text = [obj valueForKey:kCountryName];
        
        cell.detailTextLabel.text = [obj valueForKey:kCountryCallingCode];
    } else {
        cell.textLabel.text = @"Unknown error";
    }
    [cell.contentView setBackgroundColor:[UIColor clearColor]];
//    [cell setBackgroundColor:PRIMARY_COLOR];
    [cell.textLabel setTextColor:[UIColor whiteColor]];
    [cell.detailTextLabel setTextColor:[UIColor whiteColor]];
    
    return cell;
}

#pragma mark - UITableView Delegate methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *obj;
    if (self.isBeingSearched) {
        obj = [_filteredCountries objectAtIndex:indexPath.row];
    } else {
        obj = [_dataRows objectAtIndex:indexPath.row];
    }
    [[YAUser currentUser] setDialCode:obj[DIAL_CODE]];
    [[YAUser currentUser] setCountryCode:obj[COUNTRY_CODE]];
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark Content Filtering
-(void)filterContentForSearchText:(NSString*)searchText scope:(NSString*)scope {
    // Update the filtered array based on the search text and scope.
    // Remove all objects from the filtered search array
    [self.filteredCountries removeAllObjects];
    // Filter the array using NSPredicate
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.name BEGINSWITH[c] %@",searchText];
    _filteredCountries = [NSMutableArray arrayWithArray:[self.dataRows filteredArrayUsingPredicate:predicate]];
}

#pragma mark -
#pragma mark Actions
- (IBAction)dismiss:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UISearchBarDelegate
- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    if (searchText.length == 0)
    {
        self.isBeingSearched = NO;
        
    } else {
        self.isBeingSearched = YES;
        [self filterContentForSearchText:searchText scope:nil];
        
    }
    
    [[self tableView] reloadData];
}

#pragma mark - Keyboard
- (void)keyboardWillShow:(NSNotification *)notification {
    CGSize keyboardSize = [[[notification userInfo] objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    
    UIEdgeInsets contentInsets;
    if (UIInterfaceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation])) {
        contentInsets = UIEdgeInsetsMake(0.0, 0.0, (keyboardSize.height), 0.0);
    } else {
        contentInsets = UIEdgeInsetsMake(0.0, 0.0, (keyboardSize.width), 0.0);
    }
    
    self.tableView.contentInset = contentInsets;
    self.tableView.scrollIndicatorInsets = contentInsets;
    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
}

- (void)keyboardWillHide:(NSNotification *)notification {
    self.tableView.contentInset = UIEdgeInsetsZero;
    self.tableView.scrollIndicatorInsets = UIEdgeInsetsZero;
}
@end
