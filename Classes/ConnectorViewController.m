//
//  ConnectorViewController.m
//  Untitled
//
//  Created by Moritz Venn on 10.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "ConnectorViewController.h"

#import "Constants.h"
#import "RemoteConnector.h"

@implementation ConnectorViewController

@synthesize selectedItem = _selectedItem;

- (id)init
{
	if (self = [super init])
	{
		self.title = NSLocalizedString(@"Connector", @"Default title of ConnectorViewController");
		_selectedItem = kInvalidConnector;
	}
	return self;
}

+ (ConnectorViewController *)withConnector: (NSInteger) connectorKey
{
	ConnectorViewController *connectorViewController = [[ConnectorViewController alloc] init];
	connectorViewController.selectedItem = connectorKey;

	return connectorViewController;
}

- (void)dealloc
{
	[super dealloc];
}

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

- (void)doAutodetect: (id)sender
{
	_selectedItem = kInvalidConnector;
	[self.navigationController popViewControllerAnimated: YES];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	// Return YES for supported orientations
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - UITableView delegates

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	return nil;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return kMaxConnector;
}

// to determine which UITableViewCell to be used on a given row.
//
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *kVanilla_ID = @"Vanilla_ID";

	UITableViewCell *cell = nil;

	cell = [tableView dequeueReusableCellWithIdentifier: kVanilla_ID];
	if (cell == nil) 
		cell = [[[UITableViewCell alloc] initWithFrame: CGRectZero reuseIdentifier: kVanilla_ID] autorelease];

	// we are creating a new cell, setup its attributes
	switch(indexPath.row)
	{
		case kEnigma2Connector:
			cell.text = NSLocalizedString(@"Enigma 2", @"");
			break;
		case kEnigma1Connector:
			cell.text = NSLocalizedString(@"Enigma", @"");
			break;
		case kNeutrinoConnector:
			cell.text = NSLocalizedString(@"Neutrino", @"");
			break;
		default:
			cell.text = @"???";
			break;
	}

	if(indexPath.row == _selectedItem)
		cell.accessoryType = UITableViewCellAccessoryCheckmark;
	else
		cell.accessoryType = UITableViewCellAccessoryNone;

	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[tableView deselectRowAtIndexPath: indexPath animated: YES];

	UITableViewCell *cell = [tableView cellForRowAtIndexPath: [NSIndexPath indexPathForRow: _selectedItem inSection: 0]];
	cell.accessoryType = UITableViewCellAccessoryNone;

	cell = [tableView cellForRowAtIndexPath: indexPath];
	cell.accessoryType = UITableViewCellAccessoryCheckmark;

	_selectedItem = indexPath.row;
}

- (void)setTarget: (id)target action: (SEL)action
{
	_selectTarget = target;
	_selectCallback = action;
}

#pragma mark - UIViewController delegate methods

- (void)viewWillDisappear:(BOOL)animated
{
	if(_selectTarget != nil && _selectCallback != nil)
	{
		[_selectTarget performSelector:(SEL)_selectCallback withObject: [NSNumber numberWithInteger: _selectedItem]];
	}
}

@end
