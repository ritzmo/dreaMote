//
//  BouquetListController.m
//  dreaMote
//
//  Created by Moritz Venn on 02.01.09.
//  Copyright 2008-2011 Moritz Venn. All rights reserved.
//

#import "BouquetListController.h"

#import "Constants.h"
#import "RemoteConnectorObject.h"
#import "Objects/ServiceProtocol.h"

#import "ServiceTableViewCell.h"

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

		if([self respondsToSelector:@selector(setContentSizeForViewInPopover:)])
		{
			self.contentSizeForViewInPopover = CGSizeMake(320.0f, 550.0f);
			self.modalPresentationStyle = UIModalPresentationFormSheet;
			self.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
		}
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

/* getter of willReapper */
- (BOOL)willReappear
{
	return !_refreshBouquets;
}

/* setter of willReapper */
- (void)setWillReappear:(BOOL)new
{
	if([_bouquets count]) _refreshBouquets = !new;
}

/* memory warning */
- (void)didReceiveMemoryWarning
{
	if(!IS_IPAD())
	{
		[_serviceListController release];
		_serviceListController = nil;
	}

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

	// Set title
	if(new)
	{
		self.title = NSLocalizedString(@"Radio Bouquets", @"Title of radio mode of BouquetListController");
		// since "radio" loses the (imo) most important information lets lose the less important one
		self.navigationController.tabBarItem.title = NSLocalizedString(@"Bouquets", @"Title of BouquetListController");
	}
	else
	{
		self.title = NSLocalizedString(@"Bouquets", @"Title of BouquetListController");
		self.navigationController.tabBarItem.title = self.title;
	}

	_isRadio = new;

	// on ipad also set service list to radio mode, unnecessary on iphone
	if(IS_IPAD())
		_serviceListController.isRadio = new;

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

	[super loadView];
	_tableView.delegate = self;
	_tableView.dataSource = self;
	_tableView.rowHeight = kServiceCellHeight;
	_tableView.sectionHeaderHeight = 0;
}

/* about to display */
- (void)viewWillAppear:(BOOL)animated
{
	// add button to navigation bar if radio mode supported
	if([[RemoteConnectorObject sharedRemoteConnector] hasFeature: kFeaturesRadioMode])
		self.navigationItem.leftBarButtonItem = _radioButton;
	else
		self.navigationItem.leftBarButtonItem = nil;

	// Refresh cache if we have a cleared one
	if(_refreshBouquets && !_reloading)
	{
		[_refreshHeaderView setTableLoadingWithinScrollView:_tableView];
		[self emptyData];

		// Spawn a thread to fetch the service data so that the UI is not blocked while the
		// application parses the XML file.
		[NSThread detachNewThreadSelector:@selector(fetchData) toTarget:self withObject:nil];
	}
	else
	{
		// this UIViewController is about to re-appear, make sure we remove the current selection in our table view
		NSIndexPath *tableSelection = [_tableView indexPathForSelectedRow];
		[_tableView deselectRowAtIndexPath:tableSelection animated:YES];
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
		[self emptyData];

		if(!IS_IPAD())
		{
			[_serviceListController release];
			_serviceListController = nil;
		}
	}
}

/* fetch contents */
- (void)fetchData
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[_bouquetXMLDoc release];
	_reloading = YES;
	_bouquetXMLDoc = [[[RemoteConnectorObject sharedRemoteConnector] fetchBouquets: self isRadio:_isRadio] retain];
	[pool release];
}

/* remove content data */
- (void)emptyData
{
	// Clean event list
	[_bouquets removeAllObjects];
	NSIndexSet *idxSet = [NSIndexSet indexSetWithIndex: 0];
	[_tableView reloadSections:idxSet withRowAnimation:UITableViewRowAnimationRight];
	[_bouquetXMLDoc release];
	_bouquetXMLDoc = nil;
}

#pragma mark -
#pragma mark DataSourceDelegate
#pragma mark -

- (void)dataSourceDelegate:(BaseXMLReader *)dataSource errorParsingDocument:(CXMLDocument *)document error:(NSError *)error
{
	// assume details will fail too if in split
	if(_isSplit)
	{
		[_refreshHeaderView egoRefreshScrollViewDataSourceDidFinishedLoading:_tableView];
		[_tableView reloadData];
		_reloading = NO;
	}
	else
	{
		[super dataSourceDelegate:dataSource errorParsingDocument:document error:error];
	}
}

#pragma mark -
#pragma mark ServiceSourceDelegate
#pragma mark -

/* add service to list */
- (void)addService: (NSObject<ServiceProtocol> *)bouquet
{
	[_bouquets addObject: bouquet];
#ifdef ENABLE_LAGGY_ANIMATIONS
	[_tableView insertRowsAtIndexPaths: [NSArray arrayWithObject: [NSIndexPath indexPathForRow:[_bouquets count]-1 inSection:0]]
					  withRowAnimation: UITableViewRowAnimationTop];
#endif
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

	// when in split view go back to service list, else push it on the stack
	if(!_isSplit)
		[self.navigationController pushViewController: _serviceListController animated:YES];
	else
		[_serviceListController.navigationController popToRootViewControllerAnimated: YES];
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
