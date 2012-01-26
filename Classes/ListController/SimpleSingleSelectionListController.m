//
//  SimpleSingleSelectionListController.m
//  dreaMote
//
//  Created by Moritz Venn on 17.10.08.
//  Copyright 2008-2012 Moritz Venn. All rights reserved.
//

#import "SimpleSingleSelectionListController.h"

#import "Constants.h"
#import "RemoteConnectorObject.h"
#import "UITableViewCell+EasyInit.h"

#import <TableViewCell/BaseTableViewCell.h>

@interface SimpleSingleSelectionListController()
/*!
 @brief done editing
 */
- (void)doneAction:(id)sender;
@property (nonatomic, strong) NSArray *items;
@end

@implementation SimpleSingleSelectionListController

@synthesize items = _items;
@synthesize selectedItem, callback;
@synthesize tableView = _tableView;

/* initialize */
- (id)init
{
	if((self = [super init]))
	{
		self.title = nil;
		callback = nil;

		self.modalPresentationStyle = UIModalPresentationFormSheet;
		self.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
	}
	return self;
}

- (void)dealloc
{
	_tableView.delegate = nil;
	_tableView.dataSource = nil;
}

/* create SimpleSingleSelectionListController with given type preselected */
+ (SimpleSingleSelectionListController *)withItems:(NSArray *)items andSelection:(NSUInteger)selectedItem andTitle:(NSString *)title
{
	SimpleSingleSelectionListController *vc = [[SimpleSingleSelectionListController alloc] init];
	vc.selectedItem = selectedItem;
	vc.items = items;
	vc.title = title;

	return vc;
}

/* layout */
- (void)loadView
{
	// create and configure the table view
	_tableView = [[UITableView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame] style:UITableViewStyleGrouped];	
	_tableView.delegate = self;
	_tableView.dataSource = self;
	_tableView.rowHeight = kUIRowHeight;
	_tableView.autoresizesSubviews = YES;
	_tableView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
	if(IS_IPAD())
		_tableView.backgroundView = [[UIView alloc] init];

	self.view = _tableView;

	UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
																			target:self action:@selector(doneAction:)];
	self.navigationItem.rightBarButtonItem = button;

	[self theme];
}

/* finish */
- (void)doneAction:(id)sender
{
	simplesingleselection_callback_t call = callback;
	callback = nil;
	if(call)
		call(NSNotFound, NO, YES);
}

/* rotate with device */
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return YES;
}

#pragma mark - UITableView delegates

/* title for section */
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	return nil;
}

/* rows in section */
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return _items.count;
}

/* to determine which UITableViewCell to be used on a given row. */
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell = [BaseTableViewCell reusableTableViewCellInView:tableView withIdentifier:kBaseCell_ID];
	const NSInteger row = indexPath.row;

	cell.textLabel.text = [_items objectAtIndex:row];

	if((NSUInteger)row == selectedItem)
		cell.accessoryType = UITableViewCellAccessoryCheckmark;
	else
		cell.accessoryType = UITableViewCellAccessoryNone;

	[[DreamoteConfiguration singleton] styleTableViewCell:cell inTableView:tableView];
	return cell;
}

/* row selected */
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	const NSUInteger previousSelection = selectedItem;
	selectedItem = indexPath.row;
	simplesingleselection_callback_t call = callback;
	callback = nil;
	const BOOL willDispose = call ? call(selectedItem, NO, NO) : NO;

	[tableView deselectRowAtIndexPath:indexPath animated:YES];

	if(!willDispose)
	{
		UITableViewCell *cell = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:previousSelection inSection:0]];
		cell.accessoryType = UITableViewCellAccessoryNone;

		cell = [tableView cellForRowAtIndexPath:indexPath];
		cell.accessoryType = UITableViewCellAccessoryCheckmark;
		callback = call;
	}
}

#pragma mark - UIViewController delegate methods

/* about to disappear */
- (void)viewWillDisappear:(BOOL)animated
{
	simplesingleselection_callback_t call = callback;
	callback = nil;
	if(call)
		call(selectedItem, YES, NO);
}

@end
