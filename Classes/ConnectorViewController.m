//
//  ConnectorViewController.m
//  dreaMote
//
//  Created by Moritz Venn on 10.03.08.
//  Copyright 2008-2010 Moritz Venn. All rights reserved.
//

#import "ConnectorViewController.h"

#import "Constants.h"
#import "RemoteConnector.h"

@interface ConnectorViewController()
/*!
 @brief start autodetection
 @param sender ui element
 */
- (void)doAutodetect: (id)sender;
@end

@implementation ConnectorViewController

@synthesize selectedItem = _selectedItem;

/* initialize */
- (id)init
{
	if((self = [super init]))
	{
		self.title = NSLocalizedString(@"Connector", @"Default title of ConnectorViewController");
		_selectedItem = kInvalidConnector;
		_delegate = nil;
	}
	return self;
}

/* create new ConnectorViewController instance with given connector preselected */
+ (ConnectorViewController *)withConnector: (NSInteger) connectorKey
{
	ConnectorViewController *connectorViewController = [[ConnectorViewController alloc] init];
	connectorViewController.selectedItem = connectorKey;

	return [connectorViewController autorelease];
}

/* dealloc */
- (void)dealloc
{
	[super dealloc];
}

/* layout */
- (void)loadView
{
	UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Autodetect", @"") style:UIBarButtonItemStyleBordered target:self action:@selector(doAutodetect:)];
	self.navigationItem.rightBarButtonItem = button;
	[button release];

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
}

/* start autodetection */
- (void)doAutodetect: (id)sender
{
	_selectedItem = kInvalidConnector;
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
	UITableViewCell *cell = nil;

	cell = [tableView dequeueReusableCellWithIdentifier: kVanilla_ID];
	if (cell == nil) 
		cell = [[[UITableViewCell alloc] initWithFrame: CGRectZero reuseIdentifier: kVanilla_ID] autorelease];

	// we are creating a new cell, setup its attributes
	switch(indexPath.row)
	{
		case kEnigma2Connector:
			TABLEVIEWCELL_TEXT(cell) = NSLocalizedString(@"Enigma 2", @"");
			break;
		case kEnigma1Connector:
			TABLEVIEWCELL_TEXT(cell) = NSLocalizedString(@"Enigma", @"");
			break;
		case kNeutrinoConnector:
			TABLEVIEWCELL_TEXT(cell) = NSLocalizedString(@"Neutrino", @"");
			break;
		case kSVDRPConnector:
			TABLEVIEWCELL_TEXT(cell) = NSLocalizedString(@"SVDRP", @"");
			break;
		default:
			TABLEVIEWCELL_TEXT(cell) = @"???";
			break;
	}

	if((NSInteger)indexPath.row == _selectedItem)
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
}

/* set delegate */
- (void)setDelegate: (id<ConnectorDelegate>) delegate
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
		[_delegate performSelector:@selector(connectorSelected:) withObject: [NSNumber numberWithInteger: _selectedItem]];
	}
}

@end
