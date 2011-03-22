//
//  MessageTypeViewController.m
//  dreaMote
//
//  Created by Moritz Venn on 17.10.08.
//  Copyright 2008-2011 Moritz Venn. All rights reserved.
//

#import "MessageTypeViewController.h"

#import "Constants.h"
#import "RemoteConnectorObject.h"
#import "UITableViewCell+EasyInit.h"

@interface MessageTypeViewController()
/*!
 @brief done editing
 */
- (void)doneAction:(id)sender;
@end

@implementation MessageTypeViewController

@synthesize selectedItem = _selectedItem;

/* initialize */
- (id)init
{
	if((self = [super init]))
	{
		self.title = NSLocalizedString(@"Message Type", @"Default title of MessageTypeViewController");
		_delegate = nil;

		if([self respondsToSelector:@selector(modalPresentationStyle)])
		{
			self.modalPresentationStyle = UIModalPresentationFormSheet;
			self.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
		}
	}
	return self;
}

/* create MessageTypeViewController with given type preselected */
+ (MessageTypeViewController *)withType: (NSUInteger) typeKey
{
	MessageTypeViewController *messageTypeViewController = [[MessageTypeViewController alloc] init];
	messageTypeViewController.selectedItem = typeKey;

	return [messageTypeViewController autorelease];
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
	return [[RemoteConnectorObject sharedRemoteConnector] getMaxMessageType];
}

/* to determine which UITableViewCell to be used on a given row. */
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell = [UITableViewCell reusableTableViewCellInView:tableView withIdentifier:kVanilla_ID];;
	const NSInteger row = indexPath.row;

	TABLEVIEWCELL_TEXT(cell) = [[RemoteConnectorObject sharedRemoteConnector] getMessageTitle: row];

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
- (void)setDelegate: (id<MessageTypeDelegate>) delegate
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
		[_delegate performSelector:@selector(typeSelected:) withObject: [NSNumber numberWithInteger: _selectedItem]];
	}
}

@end
