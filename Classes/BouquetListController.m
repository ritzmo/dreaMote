//
//  BouquetListController.m
//  dreaMote
//
//  Created by Moritz Venn on 02.01.09.
//  Copyright 2008-2011 Moritz Venn. All rights reserved.
//

#import "BouquetListController.h"

#import "RemoteConnectorObject.h"
#import "Objects/ServiceProtocol.h"

#import "ServiceTableViewCell.h"

@interface BouquetListController()
/*!
 @brief entry point of thread which fetches bouquets
 */
- (void)fetchBouquets;
@end

@implementation BouquetListController

@synthesize serviceListController = _serviceListController;
@synthesize isSplit = _isSplit;

/* initialize */
- (id)init
{
	if((self = [super init]))
	{
		self.title = NSLocalizedString(@"Bouquets", @"Title of BouquetListController");
		_bouquets = [[NSMutableArray array] retain];
		_refreshBouquets = YES;
		_isRadio = NO;
		_isSplit = NO;
		_serviceListController = nil;
		_delegate = nil;
		self.contentSizeForViewInPopover = CGSizeMake(320.0f, 600.0f);
	}
	return self;
}

/* dealloc */
- (void)dealloc
{
	[_bouquets release];
	[_serviceListController release];
	[_bouquetXMLDoc release];
	[_radioButton release];

	[super dealloc];
}

/* memory warning */
- (void)didReceiveMemoryWarning
{
	[_serviceListController release];
	_serviceListController = nil;

	[super didReceiveMemoryWarning];
}

/* getter for isRadio property */
- (BOOL)isRadio
{
	return _isRadio;
}

/* setter for isRadio property */
- (void)setIsRadio:(BOOL)new
{
	if(_isRadio == new) return;

	if(new)
		self.title = NSLocalizedString(@"Radio Bouquets", @"Title of radio mode of BouquetListController");
	else
		self.title = NSLocalizedString(@"Bouquets", @"Title of BouquetListController");
	_isRadio = new;

	// make sure we are going to refresh
	_refreshBouquets = YES;
}

/* switch radio mode */
- (void)switchRadio:(id)sender
{
	self.isRadio = !_isRadio;
	if(_isRadio)
		_radioButton.title = NSLocalizedString(@"TV", @"TV switch button");
	else
		_radioButton.title = NSLocalizedString(@"Radio", @"Radio switch button");
	[self viewWillAppear: NO];
}

/* layout */
- (void)loadView
{
	_radioButton = [[UIBarButtonItem alloc] initWithTitle:nil style:UIBarButtonItemStylePlain target:self action:@selector(switchRadio:)];
	if(_isRadio)
		_radioButton.title = NSLocalizedString(@"TV", @"TV switch button");
	else
		_radioButton.title = NSLocalizedString(@"Radio", @"Radio switch button");

	UITableView *tableView = [[UITableView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame] style:UITableViewStylePlain];
	tableView.delegate = self;
	tableView.dataSource = self;
	tableView.rowHeight = 38;
	tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
	tableView.sectionHeaderHeight = 0;

	// setup our content view so that it auto-rotates along with the UViewController
	tableView.autoresizesSubviews = YES;
	tableView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);

	self.view = tableView;
	[tableView release];
}

/* about to display */
- (void)viewWillAppear:(BOOL)animated
{
	// add button to navigation bar if radio mode supported
	if([[RemoteConnectorObject sharedRemoteConnector] hasFeature: kFeaturesRadioMode])
		self.navigationItem.rightBarButtonItem = _radioButton;
	else
		self.navigationItem.rightBarButtonItem = nil;

	// Refresh cache if we have a cleared one
	if(_refreshBouquets)
	{
		[_bouquets removeAllObjects];

		[(UITableView *)self.view reloadData];
		[_bouquetXMLDoc release];
		_bouquetXMLDoc = nil;

		// Spawn a thread to fetch the service data so that the UI is not blocked while the
		// application parses the XML file.
		[NSThread detachNewThreadSelector:@selector(fetchBouquets) toTarget:self withObject:nil];
	}
	else
	{
		// this UIViewController is about to re-appear, make sure we remove the current selection in our table view
		NSIndexPath *tableSelection = [(UITableView *)self.view indexPathForSelectedRow];
		[(UITableView *)self.view deselectRowAtIndexPath:tableSelection animated:YES];
	}

	_refreshBouquets = YES;

	[super viewWillAppear: animated];
}

/* did hide */
- (void)viewDidDisappear:(BOOL)animated
{
	// Clean caches if supposed to
	if(_refreshBouquets)
	{
		[_bouquets removeAllObjects];

		[_serviceListController release];
		_serviceListController = nil;
		[_bouquetXMLDoc release];
		_bouquetXMLDoc = nil;
	}
}

/* fetch contents */
- (void)fetchBouquets
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[_bouquetXMLDoc release];
	_bouquetXMLDoc = [[[RemoteConnectorObject sharedRemoteConnector] fetchBouquets: self isRadio:_isRadio] retain];
	[pool release];
}

/* add service to list */
- (void)addService: (NSObject<ServiceProtocol> *)bouquet
{
	if(bouquet != nil)
	{
		[_bouquets addObject: bouquet];
#ifdef ENABLE_LAGGY_ANIMATIONS
		[(UITableView*)self.view insertRowsAtIndexPaths: [NSArray arrayWithObject: [NSIndexPath indexPathForRow:[_bouquets count]-1 inSection:0]]
						withRowAnimation: UITableViewRowAnimationTop];
	}
	else
#else
	}
#endif
		[(UITableView *)self.view reloadData];
}

#pragma mark	-
#pragma mark		Table View
#pragma mark	-

/* create cell for given row */
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	ServiceTableViewCell *cell = (ServiceTableViewCell*)[tableView dequeueReusableCellWithIdentifier: kServiceCell_ID];
	if(cell == nil)
		cell = [[[ServiceTableViewCell alloc] initWithFrame: CGRectZero reuseIdentifier: kServiceCell_ID] autorelease];

	cell.service = [_bouquets objectAtIndex:indexPath.row];

	return cell;
}

/* select row */
- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	// See if we have a valid bouquet
	NSObject<ServiceProtocol> *bouquet = [_bouquets objectAtIndex: indexPath.row];
	if(!bouquet.valid)
		return nil;

	// Check for cached ServiceListController instance
	if(_serviceListController == nil)
		_serviceListController = [[ServiceListController alloc] init];

	// Redirect callback if we have one
	if(_delegate != nil)
		[_serviceListController setDelegate: _delegate];
	_serviceListController.bouquet = bouquet;

	// We do not want to refresh bouquet list when we return
	_refreshBouquets = NO;

	if(!_isSplit)
		[self.navigationController pushViewController: _serviceListController animated:YES];
	return indexPath;
}

/* number of sections */
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView 
{
	return 1;
}

/* number of rows */
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
	return [_bouquets count];
}

/* set delegate */
- (void)setDelegate: (id<ServiceListDelegate, NSCoding>) delegate
{
	/*!
	 @note We do not retain the target, this theoretically could be a problem but
	 is not in this case.
	 */
	_delegate = delegate;
}

/* support rotation */
- (BOOL)shouldAutorotateToInterfaceOrientation: (UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

@end
