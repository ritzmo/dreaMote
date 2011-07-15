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
#import "UITableViewCell+EasyInit.h"

#import "ServiceEventTableViewCell.h"
#import "ServiceTableViewCell.h"

@interface ServiceListController()
- (void)fetchNowData;
- (void)fetchNextData;
/*!
 @brief done editing
 */
- (void)doneAction:(id)sender;

/*!
 @brief Should zap?
 */
- (void)zapAction:(UILongPressGestureRecognizer *)gesture;

/*!
 @brief Popover Controller.
 */
@property (nonatomic, retain) UIPopoverController *popoverController;
@property (nonatomic, retain) UIPopoverController *popoverZapController;

/*!
 @brief Event View.
 */
@property (nonatomic, retain) EventViewController *eventViewController;
@end

@implementation ServiceListController

@synthesize mgSplitViewController = _mgSplitViewController;
@synthesize popoverController, popoverZapController;

/* initialize */
- (id)init
{
	if((self = [super init]))
	{
		self.title = NSLocalizedString(@"Services", @"Title of ServiceListController");
		_mainList = [[NSMutableArray array] retain];
		_subList = [[NSMutableArray array] retain];
		_refreshServices = YES;
		_eventListController = nil;
		_isRadio = NO;
		_delegate = nil;
		_supportsNowNext = NO;
		_dateFormatter = [[NSDateFormatter alloc] init];
		[_dateFormatter setDateStyle:NSDateFormatterNoStyle];
		[_dateFormatter setTimeStyle:NSDateFormatterShortStyle];
#if IS_FULL()
		_multiEPG = [[MultiEPGListController alloc] init];
		_multiEPG.multiEpgDelegate = self;
#endif

		if([self respondsToSelector:@selector(modalPresentationStyle)])
		{
			self.modalPresentationStyle = UIModalPresentationFormSheet;
			self.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
		}
	}
	return self;
}

/* dealloc */
- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[_mainList release];
	[_subList release];
	[_eventListController release];
	[_eventViewController release];
	[_mainXMLDoc release];
	[_subXMLDoc release];
	[_radioButton release];
	[_dateFormatter release];
	[popoverController release];
	[popoverZapController release];
	[_mgSplitViewController release];
	[_zapListController release];
#if IS_FULL()
	[_multiEPG release];
#endif

	[super dealloc];
}

/* memory warning */
- (void)didReceiveMemoryWarning
{
	[_eventListController release];
	_eventListController = nil;
	[_eventViewController release];
	_eventViewController = nil;

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
	SafeCopyAssign(_bouquet, new);

	// Set Title
	if(new)
		self.title = new.sname;

	// Free Caches and reload data
	_supportsNowNext = [RemoteConnectorObject showNowNext];
	[_refreshHeaderView setTableLoadingWithinScrollView:_tableView];
	[self emptyData];
	_refreshServices = NO;

	// Eventually remove popover
	if(self.popoverController != nil) {
        [self.popoverController dismissPopoverAnimated:YES];
    }
	if(self.popoverZapController)
	{
		[self.popoverZapController dismissPopoverAnimated:YES];
		self.popoverZapController = nil;
	}

#if IS_FULL()
	// make multi epg aware of current bouquet
	_multiEPG.bouquet = new;
#endif

	// Spawn a thread to fetch the event data so that the UI is not blocked while the
	// application parses the XML file.
	[NSThread detachNewThreadSelector:@selector(fetchData) toTarget:self withObject:nil];
}

/* getter of reloading property */
- (BOOL)reloading
{
	return _reloading;
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
	_radioButton.enabled = NO;

	// Set title
	if(new)
	{
		self.title = NSLocalizedString(@"Radio Services", @"Title of Radio mode of ServiceListController");
		// since "radio" loses the (imo) most important information lets lose the less important one
		self.navigationController.tabBarItem.title = NSLocalizedString(@"Services", @"Title of ServiceListController");
	}
	else
	{
		self.title = NSLocalizedString(@"Services", @"Title of ServiceListController");
		self.navigationController.tabBarItem.title = self.title;
	}

	// pop to root view, needed on ipad when switching to radio in bouquet list
	[self.navigationController popToRootViewControllerAnimated: YES];

	// TODO: do we need to hand this down to multi epg? (single bouquet on iphone possibly)

	// Refresh services
	if(_bouquet != nil)
	{
		self.bouquet = nil;
	}
	else
	{
		_refreshServices = YES;
		// only refresh if visible
		if([self.view superview])
			[self viewWillAppear:NO];
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

#if IS_FULL()
/* show multi epg */
- (void)openMultiEPG:(id)sender
{
	if([_multiEPG.view superview])
	{
		self.navigationItem.rightBarButtonItem.title = NSLocalizedString(@"Multi EPG", @"Multi EPG Button title");
		_multiEPG.willReappear = NO;
		[_multiEPG viewWillDisappear:YES];
		[self.navigationController setToolbarHidden:YES animated:YES];
		self.view = _tableView;
		self.mgSplitViewController.showsMasterInLandscape = YES;
	}
	else
	{
		self.navigationItem.rightBarButtonItem.title = NSLocalizedString(@"Service List", @"Service List (former Multi EPG) Button title");
		[_multiEPG viewWillAppear:YES];
		self.view = _multiEPG.view;
		[self setToolbarItems:_multiEPG.toolbarItems];
		[self.navigationController setToolbarHidden:NO animated:YES];
		self.mgSplitViewController.showsMasterInLandscape = NO;
		[_multiEPG viewDidAppear:YES];
	}
}
#endif

- (void)didReconnect:(NSNotification *)note
{
	// disable radio mode in case new connector does not support it
	if(_isRadio)
		[self switchRadio:nil];

	// reset bouquet or do nothing if switchRadio did this already
	self.bouquet = nil;
}

/* layout */
- (void)loadView
{
	_radioButton = [[UIBarButtonItem alloc] initWithTitle:nil style:UIBarButtonItemStylePlain target:self action:@selector(switchRadio:)];
	if(_isRadio)
		_radioButton.title = NSLocalizedString(@"TV", @"TV switch button");
	else
		_radioButton.title = NSLocalizedString(@"Radio", @"Radio switch button");

#if IS_FULL()
	// hide multi epg button if there is a delegate
	if(_delegate == nil)
	{
		UIBarButtonItem *multiEPG = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Multi EPG", @"Multi EPG Button title") style:UIBarButtonItemStylePlain target:self action:@selector(openMultiEPG:)];
		self.navigationItem.rightBarButtonItem = multiEPG;
		[multiEPG release];
	}
	// show "done" button if in delegate and single bouquet mode
	else
	{
		const BOOL isSingleBouquet =
			[[RemoteConnectorObject sharedRemoteConnector] hasFeature: kFeaturesSingleBouquet]
			&& (
				[RemoteConnectorObject isSingleBouquet] ||
				![[RemoteConnectorObject sharedRemoteConnector] hasFeature: kFeaturesBouquets]);
		if(isSingleBouquet)
		{
			UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
																					target:self action:@selector(doneAction:)];
			self.navigationItem.rightBarButtonItem = button;
			[button release];
		}
	}
#endif

	[super loadView];
	_tableView.delegate = self;
	_tableView.dataSource = self;
	_tableView.sectionHeaderHeight = 0;

	// XXX: for simplicity only support this on iOS 3.2+
	if([UIDevice newerThanIos:3.2f])
	{
		UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(zapAction:)];
		longPressGesture.minimumPressDuration = 1;
		[_tableView addGestureRecognizer:longPressGesture];
		[longPressGesture release];
	}

	// listen to connection changes
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReconnect:) name:kReconnectNotification object:nil];
}

- (void)viewDidUnload
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[_radioButton release];
	_radioButton = nil;

	[super viewDidUnload];
}

/* cancel in delegate mode */
- (void)doneAction:(id)sender
{
	if(_delegate == nil) return;

	if(IS_IPAD())
		[self.navigationController dismissModalViewControllerAnimated:YES];
	else
		[self.navigationController popToViewController:_delegate animated:YES];
}

/* about to appear */
- (void)viewWillAppear:(BOOL)animated
{
	if(IS_IPHONE())
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
			self.navigationItem.leftBarButtonItem = _radioButton;
		}
		else
			self.navigationItem.leftBarButtonItem = nil;
	}
	else
	{
		if(self.popoverZapController != nil)
		{
			[self.popoverZapController dismissPopoverAnimated:YES];
			self.popoverZapController = nil;
		}
	}

	/*!
	 @brief See if we should refresh services
	 @note If bouquet is nil we are in single bouquet mode and therefore we refresh here
	 and not in setBouquet:
	 */
	if(_refreshServices && _bouquet == nil && !_reloading)
	{
		_supportsNowNext = [RemoteConnectorObject showNowNext];
		[_refreshHeaderView setTableLoadingWithinScrollView:_tableView];
#if IS_FULL()
		_multiEPG.bouquet = nil;
#endif

		[self emptyData];

		// Spawn a thread to fetch the service data so that the UI is not blocked while the
		// application parses the XML file.
		[NSThread detachNewThreadSelector:@selector(fetchData) toTarget:self withObject:nil];
	}
	else
	{
#if IS_FULL()
		/*!
		 @brief force reload of events and restart of timer
		 @note in single bouquet mode setting bouquet to nil will also trigger
		 curBegin being reset and therefore the timer being restarted, so we "hide"
		 this here for convenience reasons.
		 */
		if([_multiEPG.view superview])
			[_multiEPG viewWillAppear:animated];
#endif

		// this UIViewController is about to re-appear, make sure we remove the current selection in our table view
		NSIndexPath *tableSelection = [_tableView indexPathForSelectedRow];
		[_tableView deselectRowAtIndexPath:tableSelection animated:YES];
	}

#if IS_FULL()
	if([_multiEPG.view superview])
	{
		[self.navigationController setToolbarHidden:NO animated:YES];
		[_multiEPG viewDidAppear:YES];
	}
#endif

	_refreshServices = YES;
	[super viewWillAppear: animated];
}

/* will disappear */
- (void)viewWillDisappear:(BOOL)animated
{
#if IS_FULL()
	if([_multiEPG.view superview])
	{
		[self.navigationController setToolbarHidden:YES animated:YES];
		[_multiEPG viewWillDisappear:animated];
	}
#endif
	if(_refreshServices && _bouquet == nil)
	{
		[self emptyData];
	}
	[super viewWillDisappear:animated];
}

/* did rotate */
- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
#if IS_FULL()
	if([_multiEPG.view superview])
		[_multiEPG didRotateFromInterfaceOrientation:fromInterfaceOrientation];
#endif

	[super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
}

/* fetch main list */
- (void)fetchData
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[_mainXMLDoc release];
	_reloading = YES;
	if(_supportsNowNext)
	{
		pendingRequests = 2;
		[NSThread detachNewThreadSelector:@selector(fetchNextData) toTarget:self withObject:nil];
		[NSThread detachNewThreadSelector:@selector(fetchNowData) toTarget:self withObject:nil];
	}
	else
	{
		pendingRequests = 1;
		_mainXMLDoc = [[[RemoteConnectorObject sharedRemoteConnector] fetchServices: self bouquet: _bouquet isRadio:_isRadio] retain];
	}
	[pool release];
}

/* fetch now list */
- (void)fetchNowData
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	SafeRetainAssign(_mainXMLDoc, [[RemoteConnectorObject sharedRemoteConnector] getNow:self bouquet:_bouquet isRadio:_isRadio]);
	[pool release];
}

/* fetch next list */
- (void)fetchNextData
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	SafeRetainAssign(_subXMLDoc, [[RemoteConnectorObject sharedRemoteConnector] getNext:self bouquet:_bouquet isRadio:_isRadio]);
	[pool release];
}

/* remove content data */
- (void)emptyData
{
	// Clean event list
	[_mainList removeAllObjects];
	[_subList removeAllObjects];
#if INCLUDE_FEATURE(Extra_Animation)
	NSIndexSet *idxSet = [NSIndexSet indexSetWithIndex: 0];
	[_tableView reloadSections:idxSet withRowAnimation:UITableViewRowAnimationRight];
#else
	[_tableView reloadData];
#endif
#if IS_FULL()
	[_multiEPG emptyData];
#endif
	SafeRetainAssign(_mainXMLDoc, nil);
	SafeRetainAssign(_subXMLDoc, nil);
}

/* getter of eventViewController property */
- (EventViewController *)eventViewController
{
	if(_eventViewController == nil)
	{
		@synchronized(self)
		{
			if(_eventViewController == nil)
				_eventViewController = [[EventViewController alloc] init];
		}
	}
	return _eventViewController;
}

/* setter of eventViewController property */
- (void)setEventViewController:(EventViewController *)new
{
	if(_eventViewController == new) return;
	SafeRetainAssign(_eventViewController, new);
}

#pragma mark -
#pragma mark MultiEPGDelegate
#pragma mark -
#if IS_FULL()

- (void)multiEPG:(MultiEPGListController *)multiEPG didSelectEvent:(NSObject<EventProtocol> *)event onService:(NSObject<ServiceProtocol> *)service
{
	if(!service.valid) return;

	UIViewController *targetViewController = nil;
	if(event)
	{
		self.eventViewController.event = event;
		_eventViewController.service = service;

		targetViewController = _eventViewController;
	}
	else
	{
		if(_eventListController == nil)
			_eventListController = [[EventListController alloc] init];
		_eventListController.service = service;

		targetViewController = _eventListController;
	}

	_refreshServices = NO;
	multiEPG.willReappear = YES;
	[self.navigationController pushViewController:targetViewController animated:YES];
}

#endif
#pragma mark -
#pragma mark DataSourceDelegate
#pragma mark -

- (void)dataSourceDelegate:(BaseXMLReader *)dataSource errorParsingDocument:(CXMLDocument *)document error:(NSError *)error
{
	// NOTE: this might hide an error, but we prefer missing one over getting the same one twice
	if(--pendingRequests == 0)
	{
		_radioButton.enabled = YES;
		_reloading = NO;
		[_refreshHeaderView egoRefreshScrollViewDataSourceDidFinishedLoading:_tableView];
		[_tableView reloadData];

		// Alert user
		const UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Failed to retrieve data", @"")
															  message:[error localizedDescription]
															 delegate:nil
													cancelButtonTitle:@"OK"
													otherButtonTitles:nil];
		[alert show];
		[alert release];
#if IS_FULL()
		[_multiEPG dataSourceDelegate:dataSource finishedParsingDocument:document];
#endif
	}
}

- (void)dataSourceDelegate:(BaseXMLReader *)dataSource finishedParsingDocument:(CXMLDocument *)document
{
	if(--pendingRequests == 0)
	{
		_radioButton.enabled = YES;
		_reloading = NO;
		[_refreshHeaderView egoRefreshScrollViewDataSourceDidFinishedLoading:_tableView];
#if INCLUDE_FEATURE(Extra_Animation)
		[_tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
#else
		[_tableView reloadData];
#endif
#if IS_FULL()
		[_multiEPG dataSourceDelegate:dataSource finishedParsingDocument:document];
#endif
	}
}

#pragma mark -
#pragma mark NowSourceDelegate
#pragma mark -

/* add event to list */
- (void)addNowEvent:(NSObject <EventProtocol>*)event
{
	[_mainList addObject: event];
#if INCLUDE_FEATURE(Extra_Animation)
	const NSInteger idx = _mainList.count-1;
	[_tableView insertRowsAtIndexPaths: [NSArray arrayWithObject: [NSIndexPath indexPathForRow:idx inSection:0]]
					  withRowAnimation: UITableViewRowAnimationLeft];
#endif
#if IS_FULL()
	[_multiEPG addService:event.service];
#endif
}

#pragma mark -
#pragma mark NextSourceDelegate
#pragma mark -

/* add event to list */
- (void)addNextEvent:(NSObject <EventProtocol>*)event
{
	[_subList addObject: event];
}

#pragma mark -
#pragma mark ServiceSourceDelegate
#pragma mark -

/* add service to list */
- (void)addService: (NSObject<ServiceProtocol> *)service
{
	[_mainList addObject: service];
#if INCLUDE_FEATURE(Extra_Animation)
	const NSInteger idx = _mainList.count-1;
	[_tableView insertRowsAtIndexPaths: [NSArray arrayWithObject: [NSIndexPath indexPathForRow:idx inSection:0]]
					  withRowAnimation: UITableViewRowAnimationLeft];
#endif
#if IS_FULL()
	[_multiEPG addService:service];
#endif
}

#pragma mark -
#pragma mark SwipeTableViewDelegate
#pragma mark -

- (void)tableView:(SwipeTableView *)tableView didSwipeRowAtIndexPath:(NSIndexPath *)indexPath
{
	if(!_supportsNowNext) return;
#if IS_DEBUG()
	NSParameterAssert([_mainList count] > indexPath.row);
#else
	if(indexPath.row > [_mainList count])
		return;
#endif
	NSObject<ServiceProtocol> *service = ((NSObject<EventProtocol > *)[_mainList objectAtIndex: indexPath.row]).service;;

	// Check for invalid service
	if(!service || !service.valid)
		return;

	// Callback mode
	if(_delegate != nil)
	{
		[_delegate performSelector:@selector(serviceSelected:) withObject: service];
		if(IS_IPAD())
			[self.navigationController dismissModalViewControllerAnimated:YES];
		else
			[self.navigationController popToViewController: _delegate animated: YES];
	}
	// Handle swipe
	else if(tableView.lastSwipe & oneFinger)
	{
		NSObject<EventProtocol> *evt = nil;
		if(tableView.lastSwipe & swipeTypeLeft)
			evt = (NSObject<EventProtocol > *)[_mainList objectAtIndex: indexPath.row];
		else if([_subList count] > indexPath.row) // check if we have "next" event, if not the validity check will fail (so ignore the else case)
			evt = (NSObject<EventProtocol > *)[_subList objectAtIndex: indexPath.row];

		// FIXME: for convenience reasons a valid service marks an event valid, also if it may
		// be invalid, so we have to check begin here too
		if(!evt.valid || !evt.begin) return;
		EventViewController *evc = self.eventViewController;
		evc.event = evt;
		evc.service = service;

		_refreshServices = NO;
		[self.navigationController pushViewController:evc animated:YES];
	}
}

#pragma mark	-
#pragma mark		Table View
#pragma mark	-

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if(_supportsNowNext)
		return kServiceEventCellHeight;
	return kServiceCellHeight;
}

/* cell for row */
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell = nil;
	if(_supportsNowNext)
	{
		cell = [ServiceEventTableViewCell reusableTableViewCellInView:tableView withIdentifier:kServiceEventCell_ID];

		NSObject<EventProtocol> *event = [_mainList objectAtIndex:indexPath.row];
		((ServiceEventTableViewCell *)cell).formatter = _dateFormatter;
		((ServiceEventTableViewCell *)cell).now = event;
		@try {
			event = [_subList objectAtIndex:indexPath.row];
			[(ServiceEventTableViewCell *)cell setNext:event];
		}
		@catch (NSException * e) {
			[(ServiceEventTableViewCell *)cell setNext:nil];
		}
	}
	else
	{
		cell = [ServiceTableViewCell reusableTableViewCellInView:tableView withIdentifier:kServiceCell_ID];

		((ServiceTableViewCell *)cell).service = [_mainList objectAtIndex:indexPath.row];
	}

	return cell;
}

/* select row */
- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	// do nothing if reloading
	if(_reloading)
	{
#if IS_DEBUG()
		[NSException raise:@"ServiceListUserInteractionWhileReloading" format:@"willSelectRowAtIndexPath was triggered for indexPath (section %d, row %d) while reloading", indexPath.section, indexPath.row];
#endif
		return nil;
	}

	NSObject<ServiceProtocol> *service = nil;
	if(_supportsNowNext)
		service = ((NSObject<EventProtocol > *)[_mainList objectAtIndex: indexPath.row]).service;
	else
		service = [_mainList objectAtIndex: indexPath.row];

	// Check for invalid service
	if(!service || !service.valid)
		return nil;

	// Callback mode
	if(_delegate != nil)
	{
		[_delegate performSelector:@selector(serviceSelected:) withObject: service];
		if(IS_IPAD())
			[self.navigationController dismissModalViewControllerAnimated:YES];
		else
			[self.navigationController popToViewController: _delegate animated: YES];
	}
	// Load events
	else
	{
		if(_eventListController == nil)
			_eventListController = [[EventListController alloc] init];

		_eventListController.service = service;

		_refreshServices = NO;
		// XXX: wtf?
		if([self.navigationController.viewControllers containsObject:_eventListController])
		{
#if IS_DEBUG()
			NSMutableString* result = [[NSMutableString alloc] init];
			for(NSObject* obj in self.navigationController.viewControllers)
				[result appendString:[obj description]];
			[NSException raise:@"EventListTwiceInNavigationStack" format:@"_eventListController was twice in navigation stack: %@", result];
			[result release]; // never reached, but to keep me from going crazy :)
#endif
			[self.navigationController popToViewController:self animated:NO]; // return to us, so we can push the service list without any problems
		}
		[self.navigationController pushViewController:_eventListController animated:YES];
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
	return [_mainList count];
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

- (void)splitViewController:(MGSplitViewController*)svc willHideViewController:(UIViewController *)aViewController withBarButtonItem:(UIBarButtonItem*)barButtonItem forPopoverController: (UIPopoverController*)pc
{
	barButtonItem.title = aViewController.title;
	self.navigationItem.leftBarButtonItem = barButtonItem;
	self.popoverController = pc;
}


// Called when the view is shown again in the split view, invalidating the button and popover controller.
- (void)splitViewController:(MGSplitViewController*)svc willShowViewController:(UIViewController *)aViewController invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem
{
	self.navigationItem.leftBarButtonItem = nil;
	self.popoverController = nil;
}

#pragma mark Zapping

/* zap */
- (void)zapAction:(UILongPressGestureRecognizer *)gesture
{
	// only do something on gesture start
	if(gesture.state != UIGestureRecognizerStateBegan)
		return;

	// get service
	const CGPoint p = [gesture locationInView:_tableView];
	NSIndexPath *indexPath = [_tableView indexPathForRowAtPoint:p];
	if(_supportsNowNext)
		_service = ((NSObject<EventProtocol > *)[_mainList objectAtIndex:indexPath.row]).service;
	else
		_service = [_mainList objectAtIndex:indexPath.row];

	// Check for invalid service
	if(!_service || !_service.valid)
		return;

	// if streaming supported, show popover on ipad and action sheet on iphone
	if([ServiceZapListController canStream])
	{
		if(IS_IPAD())
		{
			// hide popover if already visible
			if([popoverController isPopoverVisible])
			{
				[popoverController dismissPopoverAnimated:YES];
			}
			if([self.popoverZapController isPopoverVisible])
			{
				[popoverZapController dismissPopoverAnimated:YES];
				self.popoverController = nil;
				return;
			}

			ServiceZapListController *zlc = [[ServiceZapListController alloc] init];
			zlc.zapDelegate = self;
			[popoverZapController release];
			popoverZapController = [[UIPopoverController alloc] initWithContentViewController:zlc];
			[zlc release];

			CGRect cellRect = [_tableView rectForRowAtIndexPath:indexPath];
			cellRect.origin.x = p.x - 25.0f;
			cellRect.size.width = cellRect.size.width - cellRect.origin.x;
			[popoverZapController presentPopoverFromRect:cellRect
												  inView:_tableView
								permittedArrowDirections:UIPopoverArrowDirectionLeft | UIPopoverArrowDirectionRight
												animated:YES];
		}
		else
		{
			SafeRetainAssign(_zapListController, [ServiceZapListController showAlert:self fromTabBar:self.tabBarController.tabBar]);
		}
	}
	// else just zap on remote host
	else
	{
		[[RemoteConnectorObject sharedRemoteConnector] zapTo:_service];
	}
}

#pragma mark -
#pragma mark ServiceZapListDelegate methods
#pragma mark -

- (void)serviceZapListController:(ServiceZapListController *)zapListController selectedAction:(zapAction)selectedAction
{
	NSURL *streamingURL = nil;
	NSObject<RemoteConnector> *sharedRemoteConnector = [RemoteConnectorObject sharedRemoteConnector];
	SafeRetainAssign(_zapListController, nil);

	if(selectedAction == zapActionRemote)
	{
		[sharedRemoteConnector zapTo:_service];
		return;
	}

	streamingURL = [sharedRemoteConnector getStreamURLForService:_service];
	if(!streamingURL)
	{
		// Alert user
		const UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", @"")
															  message:NSLocalizedString(@"Unable to generate stream URL.", @"Failed to retrieve or generate URL of remote stream")
															 delegate:nil
													cancelButtonTitle:@"OK"
													otherButtonTitles:nil];
		[alert show];
		[alert release];
	}
	else
		[ServiceZapListController openStream:streamingURL withAction:selectedAction];
}

@end
