//
//  ServiceListController.m
//  dreaMote
//
//  Created by Moritz Venn on 08.03.08.
//  Copyright 2008-2010 Moritz Venn. All rights reserved.
//

#import "ServiceListController.h"

#import "EventListController.h"

#import "Constants.h"
#import "RemoteConnectorObject.h"
#import "Objects/ServiceProtocol.h"

#import "ServiceTableViewCell.h"

@interface ServiceListController()
/*!
 @brief fetch service list
 */
- (void)fetchServices;
@end

@implementation ServiceListController

/* initialize */
- (id)init
{
	if((self = [super init]))
	{
		self.title = NSLocalizedString(@"Services", @"Title of ServiceListController");
		_services = [[NSMutableArray array] retain];
		_refreshServices = YES;
		_eventListController = nil;
		_isRadio = NO;
		_delegate = nil;
	}
	return self;
}

/* dealloc */
- (void)dealloc
{
	[_services release];
	[_eventListController release];
	[_serviceXMLDoc release];

	[super dealloc];
}

/* memory warning */
- (void)didReceiveMemoryWarning
{
	[_eventListController release];
	_eventListController = nil;

	[super didReceiveMemoryWarning];
}

/* getter for bouquet property */
- (NSObject<ServiceProtocol> *)bouquet
{
	return _bouquet;
}

/* setter for bouquet property */
- (void)setBouquet: (NSObject<ServiceProtocol> *)new
{
	// Same bouquet assigned, abort
	if(_bouquet == new) return;

	// Free old bouquet, retain new one
	[_bouquet release];
	_bouquet = [new retain];

	// Set Title
	self.title = new.sname;

	// Free Caches and reload data
	[_services removeAllObjects];
	[(UITableView *)self.view reloadData];
	[_serviceXMLDoc release];
	_serviceXMLDoc = nil;
	_refreshServices = NO;

	// Spawn a thread to fetch the event data so that the UI is not blocked while the
	// application parses the XML file.
	[NSThread detachNewThreadSelector:@selector(fetchServices) toTarget:self withObject:nil];
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
		self.title = NSLocalizedString(@"Radio Services", @"Title of Radio mode of ServiceListController");
	else
		self.title = NSLocalizedString(@"Services", @"Title of ServiceListController");
	_isRadio = new;

	// make sure we are going to refresh
	_refreshServices = YES;
}

/* layout */
- (void)loadView
{
	UITableView *tableView = [[UITableView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame] style:UITableViewStylePlain];
	tableView.delegate = self;
	tableView.dataSource = self;
	tableView.rowHeight = kUISmallRowHeight;
	tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
	tableView.sectionHeaderHeight = 0;

	// setup our content view so that it auto-rotates along with the UViewController
	tableView.autoresizesSubviews = YES;
	tableView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);

	self.view = tableView;
	[tableView release];
}

/* about to appear */
- (void)viewWillAppear:(BOOL)animated
{
	/*!
	 @brief See if we should refresh services
	 @note If bouquet is nil we are in single bouquet mode and therefore we refresh here
	 and not in setBouquet:
	 */
	if(_refreshServices && _bouquet == nil)
	{
		[_services removeAllObjects];

		[(UITableView *)self.view reloadData];
		[_serviceXMLDoc release];
		_serviceXMLDoc = nil;

		// Spawn a thread to fetch the service data so that the UI is not blocked while the
		// application parses the XML file.
		[NSThread detachNewThreadSelector:@selector(fetchServices) toTarget:self withObject:nil];
	}
	else
	{
		// this UIViewController is about to re-appear, make sure we remove the current selection in our table view
		NSIndexPath *tableSelection = [(UITableView *)self.view indexPathForSelectedRow];
		[(UITableView *)self.view deselectRowAtIndexPath:tableSelection animated:YES];
	}

	_refreshServices = YES;

	[super viewWillAppear: animated];
}

/* did disappear */
- (void)viewDidDisappear:(BOOL)animated
{
	if(_refreshServices && _bouquet == nil)
	{
		[_services removeAllObjects];

		[_eventListController release];
		_eventListController = nil;
		[_serviceXMLDoc release];
		_serviceXMLDoc = nil;
	}
}

/* fetch service list */
- (void)fetchServices
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[_serviceXMLDoc release];
	_serviceXMLDoc = [[[RemoteConnectorObject sharedRemoteConnector] fetchServices: self bouquet: _bouquet isRadio:_isRadio] retain];
	[pool release];
}

/* add service to list */
- (void)addService: (NSObject<ServiceProtocol> *)service
{
	if(service != nil)
	{
		[_services addObject: service];
#ifdef ENABLE_LAGGY_ANIMATIONS
		[(UITableView*)self.view insertRowsAtIndexPaths: [NSArray arrayWithObject: [NSIndexPath indexPathForRow:[_services count]-1 inSection:0]]
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

/* cell for row */
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	ServiceTableViewCell *cell = (ServiceTableViewCell*)[tableView dequeueReusableCellWithIdentifier: kServiceCell_ID];
	if(cell == nil)
		cell = [[[ServiceTableViewCell alloc] initWithFrame: CGRectZero reuseIdentifier: kServiceCell_ID] autorelease];

	cell.service = [_services objectAtIndex:indexPath.row];

	return cell;
}

/* select row */
- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSObject<ServiceProtocol> *service = [_services objectAtIndex: indexPath.row];

	// Check for invalid service
	if(!service.valid)
		return nil;
	// Callback mode
	else if(_delegate != nil)
	{
		[_delegate performSelector:@selector(serviceSelected:) withObject: service];
		[self.navigationController popToViewController: _delegate animated: YES];
	}
	// Load events
	else
	{
		if(_eventListController == nil)
			_eventListController = [[EventListController alloc] init];

		_eventListController.service = service;

		_refreshServices = NO;
		[self.navigationController pushViewController: _eventListController animated:YES];
	}
	return indexPath;
}

/* number of sections */
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView 
{
	// TODO: handle seperators?
	return 1;
}

/* number of rows */
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
	return [_services count];
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

/* rotate with device */
- (BOOL)shouldAutorotateToInterfaceOrientation: (UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

@end
