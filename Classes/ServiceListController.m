//
//  ServiceListController.m
//  dreaMote
//
//  Created by Moritz Venn on 08.03.08.
//  Copyright 2008-2011 Moritz Venn. All rights reserved.
//

#import "ServiceListController.h"

#import "EventListController.h"

#import "Constants.h"
#import "RemoteConnectorObject.h"
#import "Objects/ServiceProtocol.h"

#import "ServiceTableViewCell.h"

@interface ServiceListController()
/*!
 @brief Popover Controller.
 */
@property (nonatomic, retain) UIPopoverController *popoverController;
@end

@implementation ServiceListController

@synthesize popoverController;

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
	[_radioButton release];

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
	[_tableView reloadData];
	[_serviceXMLDoc release];
	_serviceXMLDoc = nil;
	_refreshServices = NO;

	// Eventually remove popover
	if(self.popoverController != nil) {
        [self.popoverController dismissPopoverAnimated:YES];
    }

	// Spawn a thread to fetch the event data so that the UI is not blocked while the
	// application parses the XML file.
	[NSThread detachNewThreadSelector:@selector(fetchData) toTarget:self withObject:nil];
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
	_isRadio = new;

	// Set title
	if(new)
		self.title = NSLocalizedString(@"Radio Services", @"Title of Radio mode of ServiceListController");
	else
		self.title = NSLocalizedString(@"Services", @"Title of ServiceListController");

	// Refresh services
	if(_bouquet != nil)
	{
		self.bouquet = nil;
	}
	else
	{
		_refreshServices = YES;
		[self viewWillAppear: NO];
	}
}

/* switch radio mode */
- (void)switchRadio:(id)sender
{
	self.isRadio = !_isRadio;
	if(_isRadio)
		_radioButton.title = NSLocalizedString(@"TV", @"TV switch button");
	else
		_radioButton.title = NSLocalizedString(@"Radio", @"Radio switch button");
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
	_tableView.rowHeight = kUISmallRowHeight;
	_tableView.sectionHeaderHeight = 0;
}

/* about to appear */
- (void)viewWillAppear:(BOOL)animated
{
	if(!IS_IPAD())
	{
		const BOOL isSingleBouquet =
			[[RemoteConnectorObject sharedRemoteConnector] hasFeature: kFeaturesSingleBouquet]
			&& (
				[RemoteConnectorObject isSingleBouquet] ||
				![[RemoteConnectorObject sharedRemoteConnector] hasFeature: kFeaturesBouquets]);

		// show radio button if in single bouquet mode and supported
		if(isSingleBouquet &&
			[[RemoteConnectorObject sharedRemoteConnector] hasFeature: kFeaturesRadioMode])
		{
			self.navigationItem.rightBarButtonItem = _radioButton;
		}
		else
			self.navigationItem.rightBarButtonItem = nil;
	}

	/*!
	 @brief See if we should refresh services
	 @note If bouquet is nil we are in single bouquet mode and therefore we refresh here
	 and not in setBouquet:
	 */
	if(_refreshServices && _bouquet == nil)
	{
		[_services removeAllObjects];

		[_tableView reloadData];
		[_serviceXMLDoc release];
		_serviceXMLDoc = nil;

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
- (void)fetchData
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[_serviceXMLDoc release];
	_reloading = YES;
	_serviceXMLDoc = [[[RemoteConnectorObject sharedRemoteConnector] fetchServices: self bouquet: _bouquet isRadio:_isRadio] retain];
	[pool release];
}

/* remove content data */
- (void)emptyData
{
	// Clean event list
	[_services removeAllObjects];
	NSIndexSet *idxSet = [NSIndexSet indexSetWithIndex: 0];
	[_tableView reloadSections:idxSet withRowAnimation:UITableViewRowAnimationRight];
	[_serviceXMLDoc release];
	_serviceXMLDoc = nil;
}

/* add service to list */
- (void)addService: (NSObject<ServiceProtocol> *)service
{
	if(service != nil)
	{
		[_services addObject: service];
#ifdef ENABLE_LAGGY_ANIMATIONS
		[_tableView insertRowsAtIndexPaths: [NSArray arrayWithObject: [NSIndexPath indexPathForRow:[_services count]-1 inSection:0]]
						withRowAnimation: UITableViewRowAnimationTop];
	}
	else
#else
	}
#endif
	{
		[_refreshHeaderView egoRefreshScrollViewDataSourceDidFinishedLoading:_tableView];
		[_tableView reloadData];
		_reloading = NO;
	}
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

#pragma mark -
#pragma mark Split view support
#pragma mark -

- (void)splitViewController: (UISplitViewController*)svc willHideViewController:(UIViewController *)aViewController withBarButtonItem:(UIBarButtonItem*)barButtonItem forPopoverController: (UIPopoverController*)pc
{
	barButtonItem.title = aViewController.title;
	self.navigationItem.leftBarButtonItem = barButtonItem;
	self.popoverController = pc;
}


// Called when the view is shown again in the split view, invalidating the button and popover controller.
- (void)splitViewController: (UISplitViewController*)svc willShowViewController:(UIViewController *)aViewController invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem
{
	self.navigationItem.leftBarButtonItem = nil;
	self.popoverController = nil;
}

@end
