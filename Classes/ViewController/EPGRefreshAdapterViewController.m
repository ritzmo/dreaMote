//
//  EPGRefreshAdapterViewController.m
//  dreaMote
//
//  Created by Moritz Venn on 21.05.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import "EPGRefreshAdapterViewController.h"

#import "Constants.h"
#import "RemoteConnectorObject.h"
#import "UITableViewCell+EasyInit.h"

@interface EPGRefreshAdapterViewController()
/*!
 @brief done editing
 */
- (void)doneAction:(id)sender;
@end

@implementation EPGRefreshAdapterViewController

@synthesize selectedItem = _selectedItem;

/* initialize */
- (id)init
{
	if((self = [super init]))
	{
		self.title = NSLocalizedString(@"EPGRefresh Adapter", @"Default title of EPGRefreshAdapterViewController");
		_delegate = nil;

		if([self respondsToSelector:@selector(modalPresentationStyle)])
		{
			self.modalPresentationStyle = UIModalPresentationFormSheet;
			self.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
		}
	}
	return self;
}

/* create EPGRefreshAdapterViewController with given adapter preselected */
+ (EPGRefreshAdapterViewController *)withAdapter:(NSString *)adapter
{
	EPGRefreshAdapterViewController *eavc = [[EPGRefreshAdapterViewController alloc] init];
	if([adapter isEqualToString:@"pip"])
		eavc.selectedItem = 1;
	else if([adapter isEqualToString:@"pip_hidden"])
		eavc.selectedItem = 2;
	else if([adapter isEqualToString:@"record"])
		eavc.selectedItem = 3;
	else// if([adapter isEqualToString:@"main"])
		eavc.selectedItem = 0;

	return [eavc autorelease];
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
	[tableView release];

	UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
																			target:self action:@selector(doneAction:)];
	self.navigationItem.rightBarButtonItem = button;
	[button release];
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

	switch(row)
	{
		case 0:
			TABLEVIEWCELL_TEXT(cell) = NSLocalizedStringFromTable(@"Main Picture", @"EPGRefresh", @"Adapter name");
			break;
		case 1:
			TABLEVIEWCELL_TEXT(cell) = NSLocalizedStringFromTable(@"Picture in Picture", @"EPGRefresh", @"Adapter name");
			break;
		case 2:
			TABLEVIEWCELL_TEXT(cell) = NSLocalizedStringFromTable(@"Picture in Picture (hidden)", @"EPGRefresh", @"Adapter name");
			break;
		case 3:
			TABLEVIEWCELL_TEXT(cell) = NSLocalizedStringFromTable(@"Fake Recording", @"EPGRefresh", @"Adapter name");
			break;
		default:
			break;
	}

	if((NSUInteger)row == _selectedItem)
		cell.accessoryType = UITableViewCellAccessoryCheckmark;
	else
		cell.accessoryType = UITableViewCellAccessoryNone;

	return cell;
}

/* row selected */
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[tableView deselectRowAtIndexPath: indexPath animated: YES];

	UITableViewCell *cell = [tableView cellForRowAtIndexPath: [NSIndexPath indexPathForRow: _selectedItem inSection: 0]];
	cell.accessoryType = UITableViewCellAccessoryNone;

	cell = [tableView cellForRowAtIndexPath: indexPath];
	cell.accessoryType = UITableViewCellAccessoryCheckmark;

	_selectedItem = indexPath.row;

	if(IS_IPAD())
	{
		[self dismissModalViewControllerAnimated:YES];
	}
}

/* set delegate */
- (void)setDelegate: (id<EPGRefreshAdapterDelegate>) delegate
{
	/*!
	 @note We do not retain the target, this theoretically could be a problem but
	 is not in this case.
	 */
	_delegate = delegate;
}

#pragma mark - UIViewController delegate methods

/* about to disappear */
- (void)viewWillDisappear:(BOOL)animated
{
	if(_delegate != nil)
	{
		NSString *adapter = nil;
		switch(_selectedItem)
		{
			default:
			case 0:
				adapter = @"main";
				break;
			case 1:
				adapter = @"pip";
				break;
			case 2:
				adapter = @"pip_hidden";
				break;
			case 3:
				adapter = @"record";
				break;
		}

		[_delegate performSelector:@selector(adapterSelected:) withObject:adapter];
	}
}

@end
