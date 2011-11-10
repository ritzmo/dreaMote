//
//  TimeoutSelectionViewController.m
//  dreaMote
//
//  Created by Moritz Venn on 14.04.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import "TimeoutSelectionViewController.h"

#import "Constants.h"
#import "RemoteConnectorObject.h"
#import "UITableViewCell+EasyInit.h"

#import <TableViewCell/BaseTableViewCell.h>

@interface TimeoutSelectionViewController()
/*!
 @brief done editing
 */
- (void)doneAction:(id)sender;
@end

@implementation TimeoutSelectionViewController

@synthesize delegate, selectedItem;
@synthesize tableView = _tableView;

/* initialize */
- (id)init
{
	if((self = [super init]))
	{
		self.title = NSLocalizedString(@"Connection Timeout", @"Default title of TimeoutSelectionViewController");

		self.modalPresentationStyle = UIModalPresentationFormSheet;
		self.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
	}
	return self;
}

/* create TimeoutSelectionViewController with given type preselected */
+ (TimeoutSelectionViewController *)withTimeout:(NSInteger)timeout
{
	TimeoutSelectionViewController *timeoutSelectionViewController = [[TimeoutSelectionViewController alloc] init];
	NSUInteger selectedItem = 0;
	switch(timeout)
	{
		case 45:
			++selectedItem;
		case 30:
			++selectedItem;
		default:
		case 15:
			++selectedItem;
		case 7: break;
	}
	timeoutSelectionViewController.selectedItem = selectedItem;

	return timeoutSelectionViewController;
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

- (void)viewDidUnload
{
	_tableView = nil;
	[super viewDidUnload];
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
	return 4;
}

/* to determine which UITableViewCell to be used on a given row. */
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell = [BaseTableViewCell reusableTableViewCellInView:tableView withIdentifier:kBaseCell_ID];
	const NSUInteger row = indexPath.row;
	NSInteger timeout = 7;

	if(row > 0)
	{
		timeout *= 2;
		timeout += 1;
		if(row == 2)
			timeout *= 2;
		else if(row == 3)
			timeout *= 3;
	}
	cell.textLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%d sec", @"Seconds"), timeout];

	if(row == selectedItem)
		cell.accessoryType = UITableViewCellAccessoryCheckmark;
	else
		cell.accessoryType = UITableViewCellAccessoryNone;

	[[DreamoteConfiguration singleton] styleTableViewCell:cell inTableView:tableView];
	return cell;
}

/* row selected */
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[tableView deselectRowAtIndexPath:indexPath animated:YES];

	UITableViewCell *cell = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:selectedItem inSection:0]];
	cell.accessoryType = UITableViewCellAccessoryNone;

	cell = [tableView cellForRowAtIndexPath:indexPath];
	cell.accessoryType = UITableViewCellAccessoryCheckmark;

	selectedItem = indexPath.row;

	if(IS_IPAD())
	{
		[self dismissModalViewControllerAnimated:YES];
	}
}

#pragma mark - UIViewController delegate methods

/* about to disappear */
- (void)viewWillDisappear:(BOOL)animated
{
	NSInteger timeout = 7;
	
	if(selectedItem > 0)
	{
		timeout *= 2;
		timeout += 1;
		if(selectedItem == 2)
			timeout *= 2;
		else if(selectedItem == 3)
			timeout *= 3;
	}

	NSUserDefaults *stdDefaults = [NSUserDefaults standardUserDefaults];
	[stdDefaults setObject:[NSNumber numberWithInteger:timeout] forKey:kTimeoutKey];
	[stdDefaults synchronize];

	[delegate performSelectorOnMainThread:@selector(didSetTimeout) withObject:nil waitUntilDone:NO];
}

@end
