//
//  MultiEPGIntervalViewController.m
//  dreaMote
//
//  Created by Moritz Venn on 16.03.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import "MultiEPGIntervalViewController.h"

#import "Constants.h"
#import "RemoteConnectorObject.h"
#import "UITableViewCell+EasyInit.h"

@interface MultiEPGIntervalViewController()
/*!
 @brief done editing
 */
- (void)doneAction:(id)sender;
@end

@implementation MultiEPGIntervalViewController

@synthesize delegate, selectedItem;

/* initialize */
- (id)init
{
	if((self = [super init]))
	{
		self.title = NSLocalizedString(@"Multi-EPG Interval", @"Default title of MultiEPGIntervalViewController");

		if([self respondsToSelector:@selector(modalPresentationStyle)])
		{
			self.modalPresentationStyle = UIModalPresentationFormSheet;
			self.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
		}
	}
	return self;
}

/* create MultiEPGIntervalViewController with given type preselected */
+ (MultiEPGIntervalViewController *)withInterval: (NSUInteger)interval
{
	MultiEPGIntervalViewController *multiEPGIntervalViewController = [[MultiEPGIntervalViewController alloc] init];
	NSUInteger selectedItem = 0;
	switch(interval)
	{
		default:
		case 120:
			++selectedItem;
		case 90:
			++selectedItem;
		case 60:
			++selectedItem;
		case 30: break;
	}
	multiEPGIntervalViewController.selectedItem = selectedItem;

	return multiEPGIntervalViewController;
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
	const NSInteger row = indexPath.row;

	TABLEVIEWCELL_TEXT(cell) = [NSString stringWithFormat:NSLocalizedString(@"%d min", @"Minutes"), (row + 1) * 30];

	if((NSUInteger)row == selectedItem)
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
	NSUserDefaults *stdDefaults = [NSUserDefaults standardUserDefaults];
	[stdDefaults setObject:[NSNumber numberWithInteger:(selectedItem + 1) * 30 * 60] forKey:kMultiEPGInterval];
	[stdDefaults synchronize];

	[delegate performSelectorOnMainThread:@selector(didSetInterval) withObject:nil waitUntilDone:NO];
}

@end
