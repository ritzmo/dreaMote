//
//  ConnectorViewController.m
//  dreaMote
//
//  Created by Moritz Venn on 10.03.08.
//  Copyright 2008-2011 Moritz Venn. All rights reserved.
//

#import "ConnectorViewController.h"

#import "Constants.h"
#import "RemoteConnector.h"
#import "UITableViewCell+EasyInit.h"

#import <TableViewCell/BaseTableViewCell.h>

@interface ConnectorViewController()
/*!
 @brief start autodetection
 @param sender ui element
 */
- (void)doAutodetect: (id)sender;
@end

@implementation ConnectorViewController

@synthesize delegate, selectedItem;
@synthesize tableView = _tableView;

/* initialize */
- (id)init
{
	if((self = [super init]))
	{
		self.title = NSLocalizedString(@"Connector", @"Default title of ConnectorViewController");
		selectedItem = kInvalidConnector;

		self.modalPresentationStyle = UIModalPresentationFormSheet;
		self.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
	}
	return self;
}

/* create new ConnectorViewController instance with given connector preselected */
+ (ConnectorViewController *)withConnector: (NSInteger) connectorKey
{
	ConnectorViewController *connectorViewController = [[ConnectorViewController alloc] init];
	connectorViewController.selectedItem = connectorKey;

	return connectorViewController;
}

/* dealloc */
- (void)dealloc
{
	_tableView.delegate = nil;
	_tableView.dataSource = nil;
}

/* layout */
- (void)loadView
{
	UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Autodetect", @"Button in Connection Editor which detects the remote receiver type automatically.") style:UIBarButtonItemStyleBordered target:self action:@selector(doAutodetect:)];
	self.navigationItem.rightBarButtonItem = button;

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

	[self theme];
}

- (void)viewDidUnload
{
	_tableView = nil;
	[super viewDidUnload];
}

/* start autodetection */
- (void)doAutodetect: (id)sender
{
	selectedItem = kInvalidConnector;
	if(IS_IPAD())
		[self.navigationController dismissModalViewControllerAnimated:YES];
	else
		[self.navigationController popViewControllerAnimated: YES];
}

/* rotate with device */
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return YES;
}

#pragma mark - UITableView delegates

/* section titles */
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	return nil;
}

/* number of rows */
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return kMaxConnector;
}

/* to determine which UITableViewCell to be used on a given row. */
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell = [BaseTableViewCell reusableTableViewCellInView:tableView withIdentifier:kBaseCell_ID];

	// we are creating a new cell, setup its attributes
	switch(indexPath.row)
	{
		case kEnigma2Connector:
			cell.textLabel.text = NSLocalizedString(@"Enigma 2", @"");
			break;
		case kEnigma1Connector:
			cell.textLabel.text = NSLocalizedString(@"Enigma", @"");
			break;
		case kNeutrinoConnector:
			cell.textLabel.text = NSLocalizedString(@"Neutrino", @"");
			break;
		case kSVDRPConnector:
			cell.textLabel.text = NSLocalizedString(@"SVDRP", @"");
			break;
		default:
			cell.textLabel.text = @"???";
			break;
	}

	if((NSInteger)indexPath.row == selectedItem)
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

	cell = [tableView cellForRowAtIndexPath: indexPath];
	cell.accessoryType = UITableViewCellAccessoryCheckmark;

	selectedItem = indexPath.row;

	if(IS_IPAD())
		[self.navigationController dismissModalViewControllerAnimated:YES];
}

#pragma mark - UIViewController delegate methods

/* about to disappear */
- (void)viewWillDisappear:(BOOL)animated
{
	if(delegate != nil)
	{
		[delegate performSelector:@selector(connectorSelected:) withObject:[NSNumber numberWithInteger:selectedItem]];
	}
}

@end
