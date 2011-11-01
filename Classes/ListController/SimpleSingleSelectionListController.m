//
//  SimpleSingleSelectionListController.m
//  dreaMote
//
//  Created by Moritz Venn on 17.10.08.
//  Copyright 2008-2011 Moritz Venn. All rights reserved.
//

#import "SimpleSingleSelectionListController.h"

#import "Constants.h"
#import "RemoteConnectorObject.h"
#import "UITableViewCell+EasyInit.h"

@interface SimpleSingleSelectionListController()
/*!
 @brief done editing
 */
- (void)doneAction:(id)sender;
@property (nonatomic, strong) NSArray *items;
@end

@implementation SimpleSingleSelectionListController

@synthesize items = _items;
@synthesize selectedItem = _selectedItem;
@synthesize callback;

/* initialize */
- (id)init
{
	if((self = [super init]))
	{
		self.title = nil;
		callback = nil;

		if([self respondsToSelector:@selector(modalPresentationStyle)])
		{
			self.modalPresentationStyle = UIModalPresentationFormSheet;
			self.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
		}
	}
	return self;
}

- (void)dealloc
{
	((UITableView *)self.view).delegate = nil;
	((UITableView *)self.view).dataSource = nil;
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
	UITableView *tableView = [[UITableView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame] style:UITableViewStyleGrouped];	
	tableView.delegate = self;
	tableView.dataSource = self;
	tableView.rowHeight = kUIRowHeight;

	// setup our content view so that it auto-rotates along with the UViewController
	tableView.autoresizesSubviews = YES;
	tableView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);

	self.view = tableView;

	UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
																			target:self action:@selector(doneAction:)];
	self.navigationItem.rightBarButtonItem = button;
}

/* finish */
- (void)doneAction:(id)sender
{
	if(IS_IPAD())
		[self.navigationController dismissModalViewControllerAnimated:YES];
	else
		[self.navigationController popViewControllerAnimated:YES];
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
	UITableViewCell *cell = [UITableViewCell reusableTableViewCellInView:tableView withIdentifier:kVanilla_ID];;
	const NSInteger row = indexPath.row;

	cell.textLabel.text = [_items objectAtIndex:row];

	if((NSUInteger)row == _selectedItem)
		cell.accessoryType = UITableViewCellAccessoryCheckmark;
	else
		cell.accessoryType = UITableViewCellAccessoryNone;

	return cell;
}

/* row selected */
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	const NSUInteger previousSelection = _selectedItem;
	_selectedItem = indexPath.row;
	const BOOL willDispose = callback ? callback(_selectedItem, NO) : NO;

	[tableView deselectRowAtIndexPath:indexPath animated:YES];

	if(!willDispose)
	{
		UITableViewCell *cell = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:previousSelection inSection:0]];
		cell.accessoryType = UITableViewCellAccessoryNone;

		cell = [tableView cellForRowAtIndexPath:indexPath];
		cell.accessoryType = UITableViewCellAccessoryCheckmark;
	}
	else
		callback = nil;
}

#pragma mark - UIViewController delegate methods

/* about to disappear */
- (void)viewWillDisappear:(BOOL)animated
{
	if(callback)
		callback(_selectedItem, YES);
	callback = nil;
}

@end
