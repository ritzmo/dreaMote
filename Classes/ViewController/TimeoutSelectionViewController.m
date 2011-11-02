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

@interface TimeoutSelectionViewController()
/*!
 @brief done editing
 */
- (void)doneAction:(id)sender;
@end

@implementation TimeoutSelectionViewController

@synthesize delegate, selectedItem;

/* initialize */
- (id)init
{
	if((self = [super init]))
	{
		self.title = NSLocalizedString(@"Connection Timeout", @"Default title of TimeoutSelectionViewController");

		if([self respondsToSelector:@selector(modalPresentationStyle)])
		{
			self.modalPresentationStyle = UIModalPresentationFormSheet;
			self.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
		}
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
	return 4;
}

/* to determine which UITableViewCell to be used on a given row. */
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell = [UITableViewCell reusableTableViewCellInView:tableView withIdentifier:kVanilla_ID];;
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
	TABLEVIEWCELL_TEXT(cell) = [NSString stringWithFormat:NSLocalizedString(@"%d sec", @"Seconds"), timeout];

	if(row == selectedItem)
		cell.accessoryType = UITableViewCellAccessoryCheckmark;
	else
		cell.accessoryType = UITableViewCellAccessoryNone;

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
