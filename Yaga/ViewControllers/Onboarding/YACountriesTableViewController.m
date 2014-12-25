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
@end

@implementation YACountriesTableViewController
- (void)viewDidLoad
{
    [super viewDidLoad];
    CountryListDataSource *dataSource = [CountryListDataSource new];
    self.dataRows = [dataSource countries];
    // Initialize the filteredCandyArray with a capacity equal to the candyArray's capacity
    self.filteredCountries = [NSMutableArray arrayWithArray:self.dataRows];
    [self.tableView reloadData];
}

#pragma mark - UITableView Datasource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        return [self.filteredCountries count];
    }
    else {
        return [self.dataRows count];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"Cell";
    
    CountryCell *cell = (CountryCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if(cell == nil) {
        cell = [[CountryCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellIdentifier];
    }
    id obj;
    if (tableView == self.searchDisplayController.searchResultsTableView) {
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
    
    return cell;
}

#pragma mark - UITableView Delegate methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *obj;
    if (tableView == self.searchDisplayController.searchResultsTableView) {
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

#pragma mark - UISearchDisplayController Delegate Methods
-(BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString {
    // Tells the table data source to reload when text changes
    [self filterContentForSearchText:searchString scope:
     [[self.searchDisplayController.searchBar scopeButtonTitles] objectAtIndex:[self.searchDisplayController.searchBar selectedScopeButtonIndex]]];
    // Return YES to cause the search result table view to be reloaded.
    return YES;
}

-(BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchScope:(NSInteger)searchOption {
    // Tells the table data source to reload when scope bar selection changes
    [self filterContentForSearchText:self.searchDisplayController.searchBar.text scope:
     [[self.searchDisplayController.searchBar scopeButtonTitles] objectAtIndex:searchOption]];
    // Return YES to cause the search result table view to be reloaded.
    return YES;
}
@end
