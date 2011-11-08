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

@interface ConnectorViewController()
/*!
 @brief start autodetection
 @param sender ui element
 */
- (void)doAutodetect: (id)sender;
@end

@implementation ConnectorViewController

@synthesize delegate, selectedItem;

/* initialize */
- (id)init
{
	if((self = [super init]))
	{
		self.title = NSLocalizedString(@"Connector", @"Default title of ConnectorViewController");
		selectedItem = kInvalidConnector;

		if([self respondsToSelector:@selector(modalPresentationStyle)])
		{
			self.modalPresentationStyle = UIModalPresentationFormSheet;
			self.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
		}
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
	((UITableView *)self.view).delegate = nil;
	((UITableView *)self.view).dataSource = nil;
}

/* layout */
- (void)loadView
{
	UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Autodetect", @"") style:UIBarButtonItemStyleBordered target:self action:@selector(doAutodetect:)];
	self.navigationItem.rightBarButtonItem = button;

	// create and configure the table view
	UITableView *tableView = [[UITableView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame] style:UITableViewStyleGrouped];	
	tableView.delegate = self;
	tableView.dataSource = self;
	tableView.rowHeight = kUIRowHeight;

	// setup our content view so that it auto-rotates along with the UViewController
	tableView.autoresizesSubviews = YES;
	tableView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);

	self.view = tableView;

	[self theme];
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
	UITableViewCell *cell = [UITableViewCell reusableTableViewCellInView:tableView withIdentifier:kVanilla_ID];

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

	if((NSInteger)indexPath.row == selectedItem)
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
