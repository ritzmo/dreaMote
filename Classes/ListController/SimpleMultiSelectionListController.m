//
//  SimpleMultiSelectionListController.m
//  dreaMote
//
//  Created by Moritz Venn on 20.11.11.
//  Copyright (c) 2011 Moritz Venn. All rights reserved.
//

#import "SimpleMultiSelectionListController.h"

#import "Constants.h"
#import "RemoteConnectorObject.h"
#import "UITableViewCell+EasyInit.h"

#import <TableViewCell/BaseTableViewCell.h>

@interface SimpleMultiSelectionListController()
/*!
 @brief done editing
 */
- (void)doneAction:(id)sender;
/*!
 @brief cancel editing
 */
- (void)cancelAction:(id)sender;
@property (nonatomic, strong) NSArray *items;
@end

@implementation SimpleMultiSelectionListController

@synthesize items, selectedItems, callback;
@synthesize tableView = _tableView;

/* initialize */
- (id)init
{
	if((self = [super init]))
	{
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

/* create SimpleMultiSelectionListController with given items preselected */
+ (SimpleMultiSelectionListController *)withItems:(NSArray *)items andSelection:(NSSet *)selectedItems andTitle:(NSString *)title
{
	SimpleMultiSelectionListController *vc = [[SimpleMultiSelectionListController alloc] init];
	if(selectedItems)
		vc.selectedItems = [selectedItems mutableCopy];
	else
		vc.selectedItems = [NSMutableSet set];
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

	UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
																			target:self action:@selector(doneAction:)];
	self.navigationItem.rightBarButtonItem = button;

	button = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
														   target:self action:@selector(cancelAction:)];
	self.navigationItem.leftBarButtonItem = button;

	[self theme];
}

/* finish */
- (void)doneAction:(id)sender
{
	simplemultiselection_callback_t call = callback;
	callback = nil;
	if(call)
		call(selectedItems, NO);
}

/* cancel */
- (void)cancelAction:(id)sender
{
	simplemultiselection_callback_t call = callback;
	callback = nil;
	if(call)
		call(nil, YES);
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
	return items.count;
}

/* to determine which UITableViewCell to be used on a given row. */
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell = [BaseTableViewCell reusableTableViewCellInView:tableView withIdentifier:kBaseCell_ID];

	NSString *item = [items objectAtIndex:indexPath.row];
	cell.textLabel.text = item;

	if([selectedItems containsObject:item])
		cell.accessoryType = UITableViewCellAccessoryCheckmark;
	else
		cell.accessoryType = UITableViewCellAccessoryNone;

	return [[DreamoteConfiguration singleton] styleTableViewCell:cell inTableView:tableView];
}

/* row selected */
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
	NSString *text = cell.textLabel.text;
	if([selectedItems containsObject:text])
	{
		[selectedItems removeObject:text];
		cell.accessoryType = UITableViewCellAccessoryNone;
	}
	else
	{
		[selectedItems addObject:text];
		cell.accessoryType = UITableViewCellAccessoryCheckmark;
	}
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - UIViewController delegate methods

/* about to disappear */
- (void)viewWillDisappear:(BOOL)animated
{
	if(callback)
		callback(selectedItems, NO);
	callback = nil;
}

@end
