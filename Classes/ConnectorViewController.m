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
@synthesize selectTarget = _selectTarget;
@synthesize selectCallback = _selectCallback;

- (id)init
{
	if (self = [super init])
	{
		self.title = NSLocalizedString(@"Connector", @"Default title of ConnectorViewController");
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
	// create and configure the table view
	UITableView *tableView = [[UITableView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame] style:UITableViewStyleGrouped];	
	tableView.delegate = self;
	tableView.dataSource = self;

	// setup our content view so that it auto-rotates along with the UViewController
	tableView.autoresizesSubviews = YES;
	tableView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);

	self.view = tableView;
	[tableView release];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	// Return YES for supported orientations
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - UITableView delegates

// if you want the entire table to just be re-orderable then just return UITableViewCellEditingStyleNone
//
- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return UITableViewCellEditingStyleNone;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	return nil;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return kMaxConnector;
}

// to determine specific row height for each cell, override this.  In this example, each row is determined
// buy the its subviews that are embedded.
//
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return kUIRowHeight;
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
		default:
			break;
	}

	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	// XXX: don't animate this as long as its buggy :-)
	[tableView deselectRowAtIndexPath: indexPath animated: NO];

	_selectedItem = indexPath.row;
	[tableView reloadData];
}

- (UITableViewCellAccessoryType)tableView:(UITableView *)tv accessoryTypeForRowWithIndexPath:(NSIndexPath *)indexPath {
    return (indexPath.row == _selectedItem) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
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
