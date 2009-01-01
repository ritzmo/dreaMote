//
//  BouquetListController.m
//  Untitled
//
//  Created by Moritz Venn on 02.01.09.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "BouquetListController.h"

#import "ServiceListController.h"

#import "RemoteConnectorObject.h"
#import "Objects/ServiceProtocol.h"

#import "ServiceTableViewCell.h"

@implementation BouquetListController

- (id)init
{
	self = [super init];
	if (self) {
		self.title = NSLocalizedString(@"Bouquets", @"Title of BouquetListController");
		_bouquets = [[NSMutableArray array] retain];
		_refreshBouquets = YES;
		serviceListController = nil;
	}
	return self;
}

- (void)dealloc
{
	[_bouquets release];
	[serviceListController release];
	[bouquetXMLDoc release];

	[super dealloc];
}

- (void)didReceiveMemoryWarning
{
	[serviceListController release];
	serviceListController = nil;

	[super didReceiveMemoryWarning];
}

- (void)loadView
{
	UITableView *tableView = [[UITableView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame] style:UITableViewStylePlain];
	tableView.delegate = self;
	tableView.dataSource = self;
	tableView.rowHeight = 38.0;
	tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
	tableView.sectionHeaderHeight = 0;

	// setup our content view so that it auto-rotates along with the UViewController
	tableView.autoresizesSubviews = YES;
	tableView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);

	self.view = tableView;
	[tableView release];
}

- (void)viewWillAppear:(BOOL)animated
{
	if(_refreshBouquets)
	{
		[_bouquets removeAllObjects];

		[(UITableView *)self.view reloadData];
		[bouquetXMLDoc release];
		bouquetXMLDoc = nil;

		// Spawn a thread to fetch the service data so that the UI is not blocked while the
		// application parses the XML file.
		[NSThread detachNewThreadSelector:@selector(fetchBouquets) toTarget:self withObject:nil];
	}

	_refreshBouquets = YES;

	[super viewWillAppear: animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	if(_refreshBouquets)
	{
		[_bouquets removeAllObjects];

		[serviceListController release];
		serviceListController = nil;
		[bouquetXMLDoc release];
		bouquetXMLDoc = nil;
	}
}

- (void)fetchBouquets
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[bouquetXMLDoc release];
	bouquetXMLDoc = [[[RemoteConnectorObject sharedRemoteConnector] fetchBouquets:self action:@selector(addService:)] retain];
	[pool release];
}

- (void)addService:(id)bouquet
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

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	ServiceTableViewCell *cell = (ServiceTableViewCell*)[tableView dequeueReusableCellWithIdentifier: kServiceCell_ID];
	if(cell == nil)
		cell = [[[ServiceTableViewCell alloc] initWithFrame: CGRectZero reuseIdentifier: kServiceCell_ID] autorelease];

	cell.service = [_bouquets objectAtIndex:indexPath.row];

	return cell;
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSObject<ServiceProtocol> *bouquet = [_bouquets objectAtIndex: indexPath.row];
	if(!bouquet.valid)
		return nil;

	if(serviceListController == nil)
		serviceListController = [[ServiceListController alloc] init];

	if(_selectTarget != nil && _selectCallback != nil)
		[serviceListController setTarget: _selectTarget action: _selectCallback];
	serviceListController.bouquet = bouquet;

	_refreshBouquets = NO;
	[self.navigationController pushViewController: serviceListController animated:YES];

	return nil;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView 
{
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
	return [_bouquets count];
}

- (void)setTarget: (id)target action: (SEL)action
{
	_selectTarget = target;
	_selectCallback = action;
}

- (BOOL)shouldAutorotateToInterfaceOrientation: (UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

@end
