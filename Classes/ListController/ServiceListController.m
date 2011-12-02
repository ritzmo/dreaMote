//
//  ServiceListController.m
//  dreaMote
//
//  Created by Moritz Venn on 08.03.08.
//  Copyright 2008-2011 Moritz Venn. All rights reserved.
//

#import "ServiceListController.h"

#import "EventListController.h"
#import "SimpleSingleSelectionListController.h"
#import "UIPromptView.h"

#import "Constants.h"
#import "RemoteConnectorObject.h"
#import "UIDevice+SystemVersion.h"
#import "UITableViewCell+EasyInit.h"

#import "ServiceEventTableViewCell.h"
#import "ServiceTableViewCell.h"

#import <Objects/Generic/Result.h>
#import <Objects/ServiceProtocol.h>

#import <XMLReader/BaseXMLReader.h>
#import <XMLReader/SaxXMLReader.h>

#import "MBProgressHUD.h"
#import "MKStoreManager.h"

enum serviceListTags
{
	TAG_MARKER = 99,
	TAG_RENAME = 100,
};

@interface ServiceListController()
- (void)itemSelected:(NSNumber *)newSelection;

/*!
 @brief Show context menu in editing mode.
 */
- (void)contextMenu:(NSIndexPath *)indexPath forService:(NSObject<ServiceProtocol> *)service;

/*!
 @brief done editing
 */
- (void)doneAction:(id)sender;

/*!
 @brief delete
 Used if the bouquet is actually an alternative service which is supposed to be removed.
 */
- (void)deleteAction:(id)sender;

/*!
 @brief Long press gesture was issued.
 */
- (void)longPress:(UILongPressGestureRecognizer *)gesture inView:(UITableView *)tableView;

- (void)longPressInMainTable:(UILongPressGestureRecognizer *)gesture;
- (void)longPressInSearchTable:(UILongPressGestureRecognizer *)gesture;

/*!
 @brief Should zap?
 */
- (void)zapAction:(UILongPressGestureRecognizer *)gesture inView:(UITableView *)tableView;

/*!
 @brief Handle right button.
 */
- (void)configureRightBarButtonItem:(BOOL)animated forOrientation:(UIInterfaceOrientation)interfaceOrientation;

/*!
 @brief Popover Controller.
 */
@property (nonatomic, strong) UIPopoverController *popoverController;
@property (nonatomic, strong) UIPopoverController *popoverZapController;

/*!
 @brief Event View.
 */
@property (nonatomic, strong) EventViewController *eventViewController;
@end

@implementation ServiceListController

@synthesize delegate, isAll, mgSplitViewController;
@synthesize popoverController, popoverZapController;
@synthesize searchBar;

/* initialize */
- (id)init
{
	if((self = [super init]))
	{
		self.title = NSLocalizedString(@"Services", @"Title of ServiceListController");
		_mainList = [[NSMutableArray alloc] init];
		_subList = [[NSMutableArray alloc] init];
		_filteredServices = [[NSMutableArray alloc] init];
		_selectedServices = [[NSMutableArray alloc] init];
		_refreshServices = YES;
		_eventListController = nil;
		_dateFormatter = [[NSDateFormatter alloc] init];
		[_dateFormatter setDateStyle:NSDateFormatterNoStyle];
		[_dateFormatter setTimeStyle:NSDateFormatterShortStyle];
		_piconLoader = [[NSOperationQueue alloc] init];
#if IS_FULL()
		_multiEPG = [[MultiEPGListController alloc] init];
		_multiEPG.multiEpgDelegate = self;
#endif

		self.modalPresentationStyle = UIModalPresentationFormSheet;
		self.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
	}
	return self;
}

/* dealloc */
- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];

	[_piconLoader cancelAllOperations];

	_tableView.tableHeaderView = nil; // references searchBar
	_searchDisplay.delegate = nil;
	_searchDisplay.searchResultsDataSource = nil;
	_searchDisplay.searchResultsDelegate = nil;
}

/* memory warning */
- (void)didReceiveMemoryWarning
{
	_eventListController = nil;
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
	_bouquet = [new copy];

	// Set Title
	if(new)
		self.title = new.sname;

	// Free Caches and reload data
	_supportsNowNext = [RemoteConnectorObject showNowNext];
	isAll = NO;
	_reloading = YES;
	[_searchDisplay setActive:NO animated:YES];
	[_refreshHeaderView setTableLoadingWithinScrollView:_tableView];
	[self emptyData];
	_refreshServices = NO;
	if(searchBar)
	{
		CGFloat topOffset = -_tableView.contentInset.top;
#if 0 // TODO: at least on the simulator this has the contrary effect... recheck this!
		if(IS_IPHONE() && [UIDevice olderThanIos:5.0f])
			topOffset += searchBar.frame.size.height;
#endif
		[_tableView setContentOffset:CGPointMake(0, topOffset) animated:YES];
	}

	// Eventually remove popover
	if(self.popoverController != nil) {
        [self.popoverController dismissPopoverAnimated:YES];
    }
	if(self.popoverZapController)
	{
		[self.popoverZapController dismissPopoverAnimated:YES];
		self.popoverZapController = nil;
	}

	if([_bouquet.sref hasPrefix:@"1:134:"])
		_tableView.allowsSelection = _tableView.allowsSelectionDuringEditing = NO;
	else
		_tableView.allowsSelection = _tableView.allowsSelectionDuringEditing = YES;

#if IS_FULL()
	// make multi epg aware of current bouquet
	_multiEPG.bouquet = new;
#endif

	// Run this in our "temporary" queue
	[RemoteConnectorObject queueInvocationWithTarget:self selector:@selector(fetchData)];
}

- (BOOL)showNowNext
{
	return _supportsNowNext && !self.editing;
}

- (void)setShowNowNext:(BOOL)showNowNext
{
	_supportsNowNext = showNowNext;
}

/* getter of reloading property */
- (BOOL)reloading
{
	return _reloading;
}

#if IS_FULL()
/* custom setter for split view to forward isSlave to multi epg */
- (void)setMgSplitViewController:(MGSplitViewController *)new
{
	mgSplitViewController = new;
	_multiEPG.isSlave = new != nil;
}
#endif

/*! getter of isSlave property */
- (BOOL)isSlave
{
	return mgSplitViewController != nil;
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
		_multiEpgButton.title = NSLocalizedString(@"Multi EPG", @"Multi EPG Button title");
		_multiEPG.willReappear = NO;
		[_multiEPG viewWillDisappear:YES];
		[self configureRightBarButtonItem:NO forOrientation:self.interfaceOrientation];
		if(IS_IPAD())
			[self.navigationController setToolbarHidden:YES animated:YES];
		NSIndexPath *idxPath = [_tableView indexPathForSelectedRow];
		if(idxPath)
			[_tableView deselectRowAtIndexPath:idxPath animated:NO];
		self.view = _tableView;
		self.mgSplitViewController.showsMasterInLandscape = YES;
	}
	else
	{
		_multiEpgButton.title = NSLocalizedString(@"Service List", @"Service List (former Multi EPG) Button title");
		[_multiEPG viewWillAppear:YES];
		self.view = _multiEPG.view;
		[self setToolbarItems:_multiEPG.toolbarItems];
		if(IS_IPHONE())
			self.navigationItem.rightBarButtonItem = _multiEpgButton;
		[self.navigationController setToolbarHidden:NO animated:YES];
		self.mgSplitViewController.showsMasterInLandscape = NO;
		[_multiEPG viewDidAppear:YES];
	}
}
#endif

- (void)didReconnect:(NSNotification *)note
{
	_reloading = NO;
	// disable radio mode in case new connector does not support it
	if(_isRadio)
		[self switchRadio:nil];

	// reset bouquet or do nothing if switchRadio did this already
	self.bouquet = nil;
}

#pragma mark -
#pragma mark UIViewController lifecycle
#pragma mark -

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
	const BOOL wasEditing = self.editing;
	[super setEditing:editing animated:animated];
	[_tableView setEditing:editing animated:animated];
	if(_searchDisplay.active)
		[_searchDisplay.searchResultsTableView setEditing:editing animated:animated];
	if(_supportsNowNext && wasEditing != editing && !_reloading)
	{
		id anyObject = [_mainList lastObject];
		const BOOL isNowNext = [anyObject conformsToProtocol:@protocol(EventProtocol)];
		if(editing || !isNowNext)
		{
			_reloading = YES;
			[_searchDisplay setActive:NO animated:YES];
			[_refreshHeaderView setTableLoadingWithinScrollView:_tableView];
#if IS_FULL()
			_multiEPG.pendingRequests++;
#endif
			[self emptyData];
			[RemoteConnectorObject queueInvocationWithTarget:self selector:@selector(fetchData)];
		}
	}
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
	if(delegate == nil)
	{
		_multiEpgButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Multi EPG", @"Multi EPG Button title") style:UIBarButtonItemStyleBordered target:self action:@selector(openMultiEPG:)];
		self.navigationItem.rightBarButtonItem = _multiEpgButton;
	}
	else
#else
	if(delegate)
#endif
	// show "done" button if in delegate and single bouquet mode
	{
		const BOOL isSingleBouquet =
			[[RemoteConnectorObject sharedRemoteConnector] hasFeature: kFeaturesSingleBouquet]
			&& (
				[RemoteConnectorObject isSingleBouquet] ||
				![[RemoteConnectorObject sharedRemoteConnector] hasFeature: kFeaturesBouquets]);
		if(isSingleBouquet)
		{
			UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
																					target:self action:@selector(doneAction:)];
			self.navigationItem.rightBarButtonItem = button;
		}
	}

	[super loadView];
	_tableView.delegate = self;
	_tableView.dataSource = self;
	_tableView.sectionHeaderHeight = 0;
	if([_bouquet.sref hasPrefix:@"1:134:"])
	{
		_tableView.allowsSelection = _tableView.allowsSelectionDuringEditing = NO;
	}
	else
		_tableView.allowsSelectionDuringEditing = YES;
	if(self.editing)
		[_tableView setEditing:YES animated:NO];

	UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressInMainTable:)];
	longPressGesture.minimumPressDuration = 1;
	longPressGesture.enabled = YES;
	[_tableView addGestureRecognizer:longPressGesture];

#if IS_LITE()
	if(delegate == nil && [MKStoreManager isFeaturePurchased:kServiceEditorPurchase])
#endif
	{
		searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 320.0f, 44.0f)];
		searchBar.autocorrectionType = UITextAutocorrectionTypeNo;
		searchBar.autocapitalizationType = UITextAutocapitalizationTypeNone;
		searchBar.keyboardType = UIKeyboardTypeDefault;
		_tableView.tableHeaderView = searchBar;

		if(_reloading)
		{
			[_refreshHeaderView setTableLoadingWithinScrollView:_tableView];
			CGFloat topOffset = -_tableView.contentInset.top;
			[_tableView setContentOffset:CGPointMake(0, topOffset) animated:YES];
		}
		else
			[_tableView setContentOffset:CGPointMake(0, searchBar.frame.size.height)];

		_searchDisplay = [[UISearchDisplayController alloc] initWithSearchBar:searchBar contentsController:self];
		_searchDisplay.delegate = self;
		_searchDisplay.searchResultsDataSource = self;
		_searchDisplay.searchResultsDelegate = self;
	}
#if IS_LITE()
	else if(_reloading)
		[_refreshHeaderView setTableLoadingWithinScrollView:_tableView];
#endif

	// listen to connection changes
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReconnect:) name:kReconnectNotification object:nil];

	[self theme];
}

- (void)theme
{
	[super theme];
	mgSplitViewController.view.backgroundColor = _tableView.backgroundColor;
}

- (void)viewDidUnload
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	_radioButton = nil;
	_multiEpgButton = nil;

	_tableView.tableHeaderView = nil; // references searchBar
	searchBar = nil;
	_searchDisplay.delegate = nil;
	_searchDisplay.searchResultsDataSource = nil;
	_searchDisplay.searchResultsDelegate = nil;
	_searchDisplay = nil;

	[super viewDidUnload];
}

/* about to appear */
- (void)viewWillAppear:(BOOL)animated
{
	_tableView.allowsSelection = YES;

	if(IS_IPHONE())
	{
		const BOOL isSingleBouquet =
			[[RemoteConnectorObject sharedRemoteConnector] hasFeature: kFeaturesSingleBouquet]
			&& (
				[RemoteConnectorObject isSingleBouquet] ||
				![[RemoteConnectorObject sharedRemoteConnector] hasFeature: kFeaturesBouquets]);

		// show radio button if in single bouquet mode and supported
		if(isSingleBouquet
		   && [[RemoteConnectorObject sharedRemoteConnector] hasFeature: kFeaturesRadioMode]
		   && ![delegate isKindOfClass:[ServiceListController class]])
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
		_reloading = YES;
		_supportsNowNext = [RemoteConnectorObject showNowNext];
		[_refreshHeaderView setTableLoadingWithinScrollView:_tableView];
#if IS_FULL()
		_multiEPG.bouquet = nil;
#endif
		// TODO: why do we NOT need this? all other views require this ^^
		//if(searchBar)
		//	[_tableView setContentOffset:CGPointMake(0, -_tableView.contentInset.top) animated:YES];

		[self emptyData];

		// Run this in our "temporary" queue
		[RemoteConnectorObject queueInvocationWithTarget:self selector:@selector(fetchData)];
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
	else
#endif
		[self configureRightBarButtonItem:animated forOrientation:self.interfaceOrientation];

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

/* will rotate */
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
#if IS_FULL()
	if([_multiEPG.view superview])
		[_multiEPG willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
	else
#endif
		[self configureRightBarButtonItem:YES forOrientation:toInterfaceOrientation];
	[super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
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

/* rotate with device */
- (BOOL)shouldAutorotateToInterfaceOrientation: (UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

#pragma mark -

/* cancel in delegate mode */
- (void)doneAction:(id)sender
{
	if(IS_IPAD())
		[self.navigationController dismissModalViewControllerAnimated:YES];
	else if(delegate && [delegate isKindOfClass:[UIViewController class]])
		[self.navigationController popToViewController:(UIViewController *)delegate animated:YES];
	else
		[self.navigationController popViewControllerAnimated:YES];
}

/* delete alternatives */
- (void)deleteAction:(id)sender
{
	if(delegate && [delegate respondsToSelector:@selector(removeAlternatives:)])
		[delegate removeAlternatives:_bouquet];
	[self doneAction:nil];
}

- (void)configureRightBarButtonItem:(BOOL)animated forOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	UIBarButtonItem *firstButton = nil;
	UIBarButtonItem *secondButton = nil;

	if(delegate == nil && [MKStoreManager isFeaturePurchased:kServiceEditorPurchase])
	{
		const BOOL isIphone = IS_IPHONE();
		// show on iPhone or on iPad in portrait
		// NOTE: we do this for easy access, but the edit button here is flawed on in multi bouquet mode (which is forced on the iPad)
		BOOL showButton = isIphone || UIInterfaceOrientationIsPortrait(interfaceOrientation);

		// and don't show it at all if unsupported by backend
		if(![[RemoteConnectorObject sharedRemoteConnector] hasFeature:kFeaturesServiceEditor])
			showButton = NO;

		if(showButton)
		{
			if(_multiEpgButton)
			{
				firstButton = self.editButtonItem;
				if(isIphone)
				{
					self.navigationItem.rightBarButtonItem = nil; // this might be set to the _multiEpgButton, so unset first
					const UIBarButtonItem *flexItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
																									target:nil
																									action:nil];
					[self setToolbarItems:[NSArray arrayWithObjects:flexItem, _multiEpgButton, nil] animated:YES];
					[self.navigationController setToolbarHidden:NO animated:animated];
				}
				else
					secondButton = _multiEpgButton;
			}
			else
				firstButton = self.editButtonItem;
		}
		else
		{
			firstButton = _multiEpgButton;
			[self setToolbarItems:nil animated:animated];
			[self.navigationController setToolbarHidden:YES animated:animated];
		}
	}
	else
	{
		const BOOL isAlternative = [_bouquet.sref hasPrefix:@"1:134:"];
		if(isAlternative && [delegate respondsToSelector:@selector(removeAlternatives:)])
		{
			UIBarButtonItem *deleteButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedStringFromTable(@"Delete all", @"ServiceEditor", @"Button removing service alternatives")
																			 style:UIBarButtonItemStyleBordered
																			target:self
																			action:@selector(deleteAction:)];
			// on the iPhone we have the navigation item to return to the previous view, so no need for the done button in this clobbered view
			if(IS_IPHONE())
			{
				firstButton = deleteButton;
			}
			else
			{
				firstButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
																			target:self
																			action:@selector(doneAction:)];
				secondButton = deleteButton;
			}
		}
		else
		{
			[self setToolbarItems:nil animated:animated];
			[self.navigationController setToolbarHidden:YES animated:animated];
			firstButton = self.navigationItem.rightBarButtonItem;
		}
	}

	if(secondButton)
	{
		NSArray *items = nil;
		// iOS 5.0+
		if([self.navigationItem respondsToSelector:@selector(rightBarButtonItems)])
		{
			items = [[NSArray alloc] initWithObjects:firstButton, secondButton, nil];
			[self.navigationItem setRightBarButtonItems:items animated:animated];
		}
		else
		{
			const UIBarButtonItem *flexItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
																							target:nil
																							action:nil];
			UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, 190, self.navigationController.navigationBar.frame.size.height)];
			items = [[NSArray alloc] initWithObjects:flexItem, secondButton, firstButton, nil];
			[toolbar setItems:items animated:NO];
			UIBarButtonItem *buttonItem = [[UIBarButtonItem alloc] initWithCustomView:toolbar];

			[self.navigationItem setRightBarButtonItem:buttonItem animated:animated];
		}
	}
	else
	{
		// iOS 5.0+
		if([self.navigationItem respondsToSelector:@selector(rightBarButtonItems)])
			[self.navigationItem setRightBarButtonItems:((firstButton) ? [NSArray arrayWithObject:firstButton] : nil) animated:animated];
		else
			[self.navigationItem setRightBarButtonItem:firstButton animated:animated];
	}
}

/* fetch main list */
- (void)fetchData
{
	_xmlReader = nil;
	_xmlReaderSub = nil;
	_reloading = YES;
	if(self.showNowNext)
	{
		_tableView.rowHeight = kServiceEventCellHeight;
		if([[RemoteConnectorObject sharedRemoteConnector] hasFeature:kFeaturesOptimizedNowNext])
		{
			pendingRequests = 1;
			_xmlReader = [[RemoteConnectorObject sharedRemoteConnector] getNowNext:self bouquet:_bouquet isRadio:_isRadio];
		}
		else
		{
			pendingRequests = 2;
			[RemoteConnectorObject queueBlock:^{
				_xmlReader = [[RemoteConnectorObject sharedRemoteConnector] getNow:self bouquet:_bouquet isRadio:_isRadio];
			}];
			[RemoteConnectorObject queueBlock:^{
				_xmlReaderSub = [[RemoteConnectorObject sharedRemoteConnector] getNext:self bouquet:_bouquet isRadio:_isRadio];
			}];
		}
	}
	else
	{
		pendingRequests = 1;
		_tableView.rowHeight = kServiceCellHeight;
		_xmlReader = [[RemoteConnectorObject sharedRemoteConnector] fetchServices: self bouquet: _bouquet isRadio:_isRadio];
	}
}

/* remove content data */
- (void)emptyData
{
	// Cancel picon loading operations
	[_piconLoader cancelAllOperations];
	// Clean event list
	[_mainList removeAllObjects];
	[_subList removeAllObjects];
	[_selectedServices removeAllObjects];
#if INCLUDE_FEATURE(Extra_Animation)
	NSIndexSet *idxSet = [NSIndexSet indexSetWithIndex: 0];
	[_tableView reloadSections:idxSet withRowAnimation:UITableViewRowAnimationRight];
#else
	[_tableView reloadData];
#endif
#if IS_FULL()
	[_multiEPG emptyData];
#endif
	_xmlReader = nil;
	_xmlReaderSub = nil;
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
	_eventViewController = new;
}

- (NSObject<ServiceProtocol> *)nextService
{
	NSIndexPath *indexPath = [_tableView indexPathForSelectedRow];
	if(indexPath.row < (NSInteger)[_mainList count] - 1)
		indexPath = [NSIndexPath indexPathForRow:indexPath.row + 1 inSection:indexPath.section];
	else
		indexPath = nil;

	if(indexPath)
	{
		[_tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionMiddle];

		id objectAtIndexPath = [_mainList objectAtIndex:indexPath.row];
		if([objectAtIndexPath conformsToProtocol:@protocol(EventProtocol)])
			return ((NSObject<EventProtocol > *)objectAtIndexPath).service;
		else
			return objectAtIndexPath;
	}
	return nil;
}

- (NSObject<ServiceProtocol> *)previousService
{
	NSIndexPath *indexPath = [_tableView indexPathForSelectedRow];
	if(indexPath.row > 0)
		indexPath = [NSIndexPath indexPathForRow:indexPath.row - 1 inSection:indexPath.section];
	else
		indexPath = nil;

	if(indexPath)
	{
		[_tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionMiddle];

		id objectAtIndexPath = [_mainList objectAtIndex:indexPath.row];
		if([objectAtIndexPath conformsToProtocol:@protocol(EventProtocol)])
			return ((NSObject<EventProtocol > *)objectAtIndexPath).service;
		else
			return objectAtIndexPath;
	}
	return nil;
}

#pragma mark Gestures

- (void)longPress:(UILongPressGestureRecognizer *)gesture inView:(UITableView *)tableView
{
	if(!self.editing)
	{
		[self zapAction:gesture inView:tableView];
		return;
	}

	// only do something on gesture start
	if(gesture.state != UIGestureRecognizerStateBegan)
		return;

	// get service
	const CGPoint p = [gesture locationInView:tableView];
	NSIndexPath *indexPath = [tableView indexPathForRowAtPoint:p];
	NSObject<ServiceProtocol> *service;
	NSArray *array = (tableView == _tableView) ? _mainList : _filteredServices;
	id objectAtIndexPath = [array objectAtIndex:indexPath.row];
	if([objectAtIndexPath conformsToProtocol:@protocol(EventProtocol)])
		service = ((NSObject<EventProtocol > *)objectAtIndexPath).service;
	else
		service = objectAtIndexPath;

	// Check for invalid service
	if(!service || !service.valid)
		return;

	if([_selectedServices containsObject:service])
		[_selectedServices removeObject:service];
	else
		[_selectedServices addObject:service];
	[tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
}

- (void)longPressInMainTable:(UILongPressGestureRecognizer *)gesture
{
	[self longPress:gesture inView:_tableView];
}

- (void)longPressInSearchTable:(UILongPressGestureRecognizer *)gesture
{
	[self longPress:gesture inView:_searchDisplay.searchResultsTableView];
}

#pragma mark Context Menu

- (void)contextMenu:(NSIndexPath *)indexPath forService:(NSObject<ServiceProtocol> *)service
{
	/*
	 The fully propagates list (and the one we work with internally) is:
	 - Add Alternative
	 - Show Alternatives
	 - Add to Bouquet
	 - Add Marker
	 - Rename
	 ---------------------
	 Multi-Select is recuded to this choices:
	 - Add to bouquet
	 - Reset selection
	 */
	NSMutableArray *items = nil;
	NSUInteger selectedServicesCount = _selectedServices.count;
	if([_bouquet.sref hasPrefix:@"1:7:0:"] || selectedServicesCount > 1 || (selectedServicesCount == 1 && ![_selectedServices containsObject:service]))
	{
		items = [NSMutableArray arrayWithObject:NSLocalizedStringFromTable(@"Add to Bouquet", @"ServiceEditor", @"Add this service to another bouquet")];
		if(_selectedServices.count)
		{
			[items addObject:NSLocalizedStringFromTable(@"Remove selection", @"ServiceEditor", @"Undo selection made by the user.")];
		}
	}
	else
	{
		items = [NSMutableArray arrayWithObjects:
				 NSLocalizedStringFromTable(@"Add Marker", @"ServiceEditor", @"Add new marker before this position"),
				 NSLocalizedStringFromTable(@"Rename", @"ServiceEditor", @"Rename currently selected service"),
				 nil];
		if(service.valid)
		{
			[items insertObject:NSLocalizedStringFromTable(@"Add Alternative", @"ServiceEditor", @"Add new alternative service to currently selected service")
						atIndex:0];
			[items insertObject:NSLocalizedStringFromTable(@"Add to Bouquet", @"ServiceEditor", @"Add this service to another bouquet")
						atIndex:1];
			if([service.sref hasPrefix:@"1:134:"])
				[items insertObject:NSLocalizedStringFromTable(@"Show Alternatives", @"ServiceEditor", @"Show alternatives for selected service")
							atIndex:1];
		}
	}

	if(IS_IPAD())
	{
		if(popoverController)
		{
			[popoverController dismissPopoverAnimated:YES];
			popoverController = nil;
		}
		SimpleSingleSelectionListController *vc = [SimpleSingleSelectionListController withItems:items
																					andSelection:NSNotFound
																						andTitle:nil];
		vc.callback = ^(NSUInteger selectedItem, BOOL isClosing, BOOL canceling){
			// NOTE: ignore cancel as the button is not visible in our case
			[popoverController dismissPopoverAnimated:YES];
			popoverController = nil;

			[self performSelectorOnMainThread:@selector(itemSelected:) withObject:[NSNumber numberWithUnsignedInteger:selectedItem] waitUntilDone:NO];

			return YES;
		};
		CGFloat viewHeight = (kUIRowHeight) * items.count + 20;
		vc.contentSizeForViewInPopover = CGSizeMake(250.0f, viewHeight);
		popoverController = [[UIPopoverController alloc] initWithContentViewController:vc];
		CGRect cellRect = [_tableView rectForRowAtIndexPath:indexPath];
		[popoverController presentPopoverFromRect:cellRect
										   inView:_tableView
						 permittedArrowDirections:UIPopoverArrowDirectionLeft|UIPopoverArrowDirectionRight
										 animated:YES];
	}
	else
	{
		UIActionSheet *as = [[UIActionSheet alloc] initWithTitle:nil
														delegate:self
											   cancelButtonTitle:nil
										  destructiveButtonTitle:nil//NSLocalizedStringFromTable(@"Delete", @"ServiceEditor", @"Delete selected service")
											   otherButtonTitles:nil];
		for(NSString *text in items)
		{
			[as addButtonWithTitle:text];
		}
		as.cancelButtonIndex = [as addButtonWithTitle:NSLocalizedString(@"Cancel", @"")];

		if(self.tabBarController == nil) // XXX: bug in MGSplitViewController?
			[as showInView:self.view];
		else
			[as showFromTabBar:self.tabBarController.tabBar];
	}
}

- (void)itemSelected:(NSNumber *)newSelection
{
	UITableView *tableView = nil;
	NSArray *array = nil;
	if(_searchDisplay.active){
		tableView =_searchDisplay.searchResultsTableView;
		array = _filteredServices;
	}
	else
	{
		tableView = _tableView;
		array = _mainList;
	}
	NSIndexPath *indexPath = [tableView indexPathForSelectedRow];
	NSObject<ServiceProtocol> *service = nil;
	id objectAtIndexPath = [array objectAtIndex:indexPath.row];
	if([objectAtIndexPath conformsToProtocol:@protocol(EventProtocol)])
		service = ((NSObject<EventProtocol > *)objectAtIndexPath).service;
	else
		service = objectAtIndexPath;

	NSInteger selection = [newSelection integerValue];
	if(selection != NSNotFound) // NOTE: this checks selection twice, but spares us from having to implement the default behavior twice
	{
		NSUInteger selectedServicesCount = _selectedServices.count;
		if(selectedServicesCount > 1 || (selectedServicesCount == 1 && ![_selectedServices containsObject:service]))
		{
			if(selection == 0)
				selection = 2;
			else
			{
				[_selectedServices removeAllObjects];
				[tableView reloadData];
				return;
			}
		}
		else if([_bouquet.sref hasPrefix:@"1:7:0:"])
		{
			selection = 2;
		}
		else
		{
			if(service.valid)
			{
				if(selection > 0 && ![service.sref hasPrefix:@"1:134:"])
					++selection;
			}
			else
				selection += 3;
		}
	}

	UIViewController *targetViewController = nil;
	switch(selection)
	{
		default:
		case NSNotFound: /* just deselect */
		{
			[tableView deselectRowAtIndexPath:indexPath animated:YES];
			break;
		}
		case 0: /* add alternative */
		{
			BouquetListController *bl = [[BouquetListController alloc] init];
			bl.isRadio = _isRadio;
			[bl setServiceDelegate:self];

			if(IS_IPAD())
			{
				targetViewController = [[UINavigationController alloc] initWithRootViewController:bl];
				targetViewController.modalPresentationStyle = bl.modalPresentationStyle;
				targetViewController.modalPresentationStyle = bl.modalPresentationStyle;
			}
			else
				targetViewController = bl;
			break;
		}
		case 1: /* show alternatives */
		{
			ServiceListController *sl = [[ServiceListController alloc] init];
			sl.isRadio = _isRadio;
			sl.delegate = self;
			[sl setEditing:YES animated:NO];
			sl.bouquet = service;

			if(IS_IPAD())
			{
				targetViewController = [[UINavigationController alloc] initWithRootViewController:sl];
				targetViewController.modalPresentationStyle = sl.modalPresentationStyle;
				targetViewController.modalPresentationStyle = sl.modalPresentationStyle;
			}
			else
				targetViewController = sl;
			[tableView deselectRowAtIndexPath:indexPath animated:YES]; // for simplicity, do not keep entry selected
			break;
		}
		case 2: /* add to bouquet */
		{
			BouquetListController *bl = [[BouquetListController alloc] init];
			bl.isRadio = _isRadio;
			bl.bouquetDelegate = self;
			[bl setEditing:YES animated:NO];

			if(IS_IPAD())
			{
				targetViewController = [[UINavigationController alloc] initWithRootViewController:bl];
				targetViewController.modalPresentationStyle = bl.modalPresentationStyle;
				targetViewController.modalPresentationStyle = bl.modalPresentationStyle;
			}
			else
				targetViewController = bl;
			break;
		}
		case 3: /* add marker */
		{
			UIPromptView *alertView = [[UIPromptView alloc] initWithTitle:NSLocalizedStringFromTable(@"Enter title for marker", @"ServiceEditor", @"Title of prompt requesting name for a marker the user requested")
																  message:nil
																 delegate:self
														cancelButtonTitle:NSLocalizedString(@"Cancel", @"")
															okButtonTitle:@"OK"
									   ];
			alertView.tag = TAG_MARKER;
			alertView.promptViewStyle = UIPromptViewStylePlainTextInput;
			[alertView show];
			break;
		}
		case 4: /* rename */
		{
			UIPromptView *alertView = [[UIPromptView alloc] initWithTitle:NSLocalizedStringFromTable(@"Enter new name", @"ServiceEditor",  @"Title of prompt requesting new name for an existing service")
																  message:nil
																 delegate:self
														cancelButtonTitle:NSLocalizedString(@"Cancel", @"")
															okButtonTitle:@"OK"
									   ];
			alertView.tag = TAG_RENAME;
			alertView.promptViewStyle = UIPromptViewStylePlainTextInput;
			[alertView show];

			break;
		}
	}

	if(targetViewController)
	{
		if(IS_IPAD())
			[self presentModalViewController:targetViewController animated:YES];
		else
		{
			_refreshServices = NO;
			[self.navigationController setToolbarHidden:YES animated:YES];
			[self.navigationController pushViewController:targetViewController animated:YES];
		}
	}
}

#pragma mark -
#pragma mark ServiceListDelegate
#pragma mark -

- (void)serviceSelected:(NSObject<ServiceProtocol> *)newService
{
	UITableView *tableView = nil;
	NSArray *array = nil;
	if(_searchDisplay.active){
		tableView =_searchDisplay.searchResultsTableView;
		array = _filteredServices;
	}
	else
	{
		tableView = _tableView;
		array = _mainList;
	}
	NSIndexPath *indexPath = [tableView indexPathForSelectedRow];
	NSObject<ServiceProtocol> *service = nil;
	id objectAtIndexPath = [array objectAtIndex:indexPath.row];
	if([objectAtIndexPath conformsToProtocol:@protocol(EventProtocol)])
		service = ((NSObject<EventProtocol > *)objectAtIndexPath).service;
	else
		service = objectAtIndexPath;

	Result *result = [[RemoteConnectorObject sharedRemoteConnector] serviceEditorAddService:newService toBouquet:service inBouquet:_bouquet isRadio:_isRadio];
	if(!result.result)
	{
		const UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", @"")
															  message:[NSString stringWithFormat:NSLocalizedStringFromTable(@"Unable to add service %@ to alternative %@: %@", @"ServiceEditor", @"Adding an alternative to a service failed"), newService.sname, service.sname, result.resulttext]
															 delegate:nil
													cancelButtonTitle:@"OK"
													otherButtonTitles:nil];
		[alert show];
	}
	else
	{
		showCompletedHudWithText(NSLocalizedStringFromTable(@"Alternative added", @"ServiceEditor", @"Text of HUD when a service was added as alternative to the currently selected one"));
		if(![service.sref hasPrefix:@"1:134:"])
		{
			// NOTE: reload service list to get the sref of the alternative service
			[self emptyData];
#if IS_FULL()
			_multiEPG.pendingRequests++;
#endif
			[RemoteConnectorObject queueInvocationWithTarget:self selector:@selector(fetchData)];
			return;
		}
	}
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)removeAlternatives:(NSObject<ServiceProtocol> *)service
{
	Result *result = [[RemoteConnectorObject sharedRemoteConnector] serviceEditorRemoveAlternatives:service inBouquet:_bouquet isRadio:_isRadio];
	if(!result.result)
	{
		const UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", @"")
															  message:[NSString stringWithFormat:NSLocalizedStringFromTable(@"Unable to remove alternatives: %@", @"ServiceEditor", @"Removing alternatives failed"), result.resulttext]
															 delegate:nil
													cancelButtonTitle:@"OK"
													otherButtonTitles:nil];
		[alert show];
	}
	else
	{
		showCompletedHudWithText(NSLocalizedStringFromTable(@"Alternatives deleted", @"ServiceEditor", @"Text of HUD when all alternatives were removed for a services"));
		// NOTE: we don't know which service reference the original service is going to have, so just reload everything
		[self emptyData];
#if IS_FULL()
		_multiEPG.pendingRequests++;
#endif
		[RemoteConnectorObject queueInvocationWithTarget:self selector:@selector(fetchData)];
	}
}

#pragma mark -
#pragma mark BouquetListDelegate
#pragma mark -

- (void)bouquetSelected:(NSObject<ServiceProtocol> *)newBouquet
{
	UITableView *tableView = nil;
	NSArray *array = nil;
	if(_searchDisplay.active){
		tableView =_searchDisplay.searchResultsTableView;
		array = _filteredServices;
	}
	else
	{
		tableView = _tableView;
		array = _mainList;
	}
	NSIndexPath *indexPath = [tableView indexPathForSelectedRow];
	NSObject<ServiceProtocol> *service = nil;
	id objectAtIndexPath = [array objectAtIndex:indexPath.row];
	if([objectAtIndexPath conformsToProtocol:@protocol(EventProtocol)])
		service = ((NSObject<EventProtocol > *)objectAtIndexPath).service;
	else
		service = objectAtIndexPath;

	NSMutableString *errorMessages = [[NSMutableString alloc] init];
	const NSUInteger selectedServicesCount = _selectedServices.count;
	const BOOL addedService = ![_selectedServices containsObject:service];
	Result *result = nil;
	if(addedService)
		[_selectedServices addObject:service];
	@autoreleasepool
	{
		for(NSObject<ServiceProtocol> *servicee in _selectedServices)
		{
			result = [[RemoteConnectorObject sharedRemoteConnector] serviceEditorAddService:servicee toBouquet:newBouquet inBouquet:_bouquet isRadio:_isRadio];
			if(!result.result)
			{
				if(errorMessages.length)
					[errorMessages appendString:@"\n"];
				[errorMessages appendString:result.resulttext];
			}
		}
	}
	if(addedService)
		[_selectedServices removeObject:service];

	if(errorMessages.length)
	{
		const UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", @"")
															  message:[NSString stringWithFormat:NSLocalizedStringFromTable(@"Unable to add service(s) to bouquet %@: %@", @"ServiceEditor", @"Adding a service to a bouquet failed"), newBouquet.sname, errorMessages]
															 delegate:nil
													cancelButtonTitle:@"OK"
													otherButtonTitles:nil];
		[alert show];
	}
	else if(selectedServicesCount)
	{
		showCompletedHudWithText(NSLocalizedStringFromTable(@"Service(s) added", @"ServiceEditor", @"Text of HUD when one or multiple services were added to a bouquet"));
		[_selectedServices removeAllObjects];
		[tableView reloadData];
	}
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark -
#pragma mark UIActionSheetDelegate
#pragma mark -

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
	UITableView *tableView = (_searchDisplay.active) ? _searchDisplay.searchResultsTableView : _tableView;
	if (buttonIndex == actionSheet.cancelButtonIndex)
	{
		NSIndexPath *indexPath = [tableView indexPathForSelectedRow];
		[tableView deselectRowAtIndexPath:indexPath animated:YES];
	}
	else if(buttonIndex == actionSheet.destructiveButtonIndex)
	{
		// delete
		NSIndexPath *indexPath = [tableView indexPathForSelectedRow];
		[self tableView:tableView commitEditingStyle:UITableViewCellEditingStyleDelete forRowAtIndexPath:indexPath];
		[tableView deselectRowAtIndexPath:indexPath animated:YES];
	}
	else
	{
		//--buttonIndex; // needed if destructive button is present
		[self itemSelected:[NSNumber numberWithInteger:buttonIndex]];
	}
}

#pragma mark -
#pragma mark UIAlertViewDelegate methods
#pragma mark -

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
	UITableView *tableView = nil;
	NSArray *array = nil;
	if(_searchDisplay.active){
		tableView =_searchDisplay.searchResultsTableView;
		array = _filteredServices;
	}
	else
	{
		tableView = _tableView;
		array = _mainList;
	}
	NSIndexPath *indexPath = [tableView indexPathForSelectedRow];
	NSObject<ServiceProtocol> *service = nil;
	id objectAtIndexPath = [array objectAtIndex:indexPath.row];
	const BOOL isNowNext = [objectAtIndexPath conformsToProtocol:@protocol(EventProtocol)];
	if(isNowNext)
		service = ((NSObject<EventProtocol > *)objectAtIndexPath).service;
	else
		service = objectAtIndexPath;

#define promptView (UIPromptView *)alertView
	if(buttonIndex == alertView.cancelButtonIndex)
	{
		// do nothing
	}
	else if(alertView.tag == TAG_MARKER)
	{
		NSString *markerName = [promptView promptFieldAtIndex:0].text;
		Result *result = [[RemoteConnectorObject sharedRemoteConnector] serviceEditorAddMarker:markerName beforeService:service inBouquet:_bouquet isRadio:_isRadio];
		if(result.result)
		{
			// TODO: optimize
			[self emptyData];
#if IS_FULL()
			_multiEPG.pendingRequests++;
#endif
			[RemoteConnectorObject queueInvocationWithTarget:self selector:@selector(fetchData)];
		}
		else
		{
			const UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", @"")
																  message:[NSString stringWithFormat:NSLocalizedStringFromTable(@"Unable to add marker: %@", @"ServiceEditor", @"Creating a marker has failed"), result.resulttext]
																 delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
			[alert show];
		}
	}
	else //if(alertView.tag == TAG_RENAME)
	{
		NSString *serviceName = [promptView promptFieldAtIndex:0].text;
		NSObject<ServiceProtocol> *before = nil;
		if(indexPath.row + 1 < (NSInteger)array.count)
		{
			objectAtIndexPath = [array objectAtIndex:indexPath.row + 1];
			if(isNowNext)
				before = ((NSObject<EventProtocol > *)objectAtIndexPath).service;
			else
				before = objectAtIndexPath;
		}
		Result *result = [[RemoteConnectorObject sharedRemoteConnector] serviceEditorRenameService:service name:serviceName inBouquet:_bouquet beforeService:before isRadio:_isRadio];
		if(result.result)
		{
			// TODO: optimize
			[self emptyData];
#if IS_FULL()
			_multiEPG.pendingRequests++;
#endif
			[RemoteConnectorObject queueInvocationWithTarget:self selector:@selector(fetchData)];
		}
		else
		{
			const UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", @"")
																  message:[NSString stringWithFormat:NSLocalizedStringFromTable(@"Unable to rename service: %@", @"ServiceEditor", @"Renaming a service has failed"), result.resulttext]
																 delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
			[alert show];
		}
	}
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
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
		@synchronized(self)
		{
			if(_eventListController == nil)
				_eventListController = [[EventListController alloc] init];
		}
		_eventListController.service = service;
		_eventListController.serviceListController = self;
		_eventListController.isSlave = self.isSlave;

		NSInteger idx = NSNotFound;
		if([[_mainList lastObject] conformsToProtocol:@protocol(EventProtocol)])
		{
			NSInteger i = 0;
			for(NSObject<EventProtocol> *event in _mainList)
			{
				if(event.service == service)
				{
					idx = i;
					break;
				}
			}
		}
		else
		{
			idx = [_mainList indexOfObject:service];
		}
		if(idx != NSNotFound)
		{
			NSIndexPath *indexPath = [NSIndexPath indexPathForRow:idx inSection:0];
			[_tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionMiddle];
		}

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

- (void)dataSourceDelegate:(BaseXMLReader *)dataSource errorParsingDocument:(NSError *)error
{
	// NOTE: this might hide an error, but we prefer missing one over getting the same one twice
	if(--pendingRequests == 0)
	{
		_radioButton.enabled = YES;
		_reloading = NO;
		[_refreshHeaderView egoRefreshScrollViewDataSourceDidFinishedLoading:_tableView];
		[_tableView reloadData];

		// Alert user
		const UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Failed to retrieve data", @"Title of Alert when retrieving remote data failed.")
															  message:[error localizedDescription]
															 delegate:nil
													cancelButtonTitle:@"OK"
													otherButtonTitles:nil];
		[alert show];
#if IS_FULL()
		[_multiEPG dataSourceDelegateFinishedParsingDocument:dataSource];
#endif
		if(searchBar)
			[_tableView setContentOffset:CGPointMake(0, searchBar.frame.size.height) animated:YES];
	}

	if(dataSource == _xmlReader)
	{
		if([dataSource isKindOfClass:[SaxXmlReader class]])
			_xmlReader = nil;
	}
	else if(dataSource == _xmlReaderSub)
	{
		if([dataSource isKindOfClass:[SaxXmlReader class]])
			_xmlReaderSub = nil;
	}
}

- (void)dataSourceDelegateFinishedParsingDocument:(BaseXMLReader *)dataSource
{
	if(--pendingRequests == 0)
	{
		_radioButton.enabled = YES;
		_reloading = NO;
		[_refreshHeaderView egoRefreshScrollViewDataSourceDidFinishedLoading:_tableView];
		if(_searchDisplay.active)
		{
			[self searchDisplayController:_searchDisplay shouldReloadTableForSearchString:searchBar.text];
			[_searchDisplay.searchResultsTableView reloadData];
			[_tableView reloadData];
		}
		else
		{
#if INCLUDE_FEATURE(Extra_Animation)
			if(!isAll)
				[_tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
			else
#endif
				[_tableView reloadData];
		}
#if IS_FULL()
		[_multiEPG dataSourceDelegateFinishedParsingDocument:dataSource];
#endif
		if(searchBar)
			[_tableView setContentOffset:CGPointMake(0, searchBar.frame.size.height) animated:YES];
	}

	if(dataSource == _xmlReader)
	{
		if([dataSource isKindOfClass:[SaxXmlReader class]])
			_xmlReader = nil;
	}
	else if(dataSource == _xmlReaderSub)
	{
		if([dataSource isKindOfClass:[SaxXmlReader class]])
			_xmlReaderSub = nil;
	}
}

#pragma mark -
#pragma mark NowSourceDelegate
#pragma mark -

/* add event to list */
- (void)addNowEvent:(NSObject <EventProtocol>*)event
{
	[_mainList addObject: event];
	[_piconLoader addOperationWithBlock:^{ [event.service picon]; }];
#if INCLUDE_FEATURE(Extra_Animation)
	const NSInteger idx = _mainList.count-1;
	[_tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:idx inSection:0]]
					  withRowAnimation:UITableViewRowAnimationLeft];
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
	[_piconLoader addOperationWithBlock:^{ [service picon]; }];
#if INCLUDE_FEATURE(Extra_Animation)
	if(!isAll)
	{
		const NSInteger idx = _mainList.count-1;
		[_tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:idx inSection:0]]
						  withRowAnimation:UITableViewRowAnimationLeft];
	}
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
	if(!self.showNowNext) return;
#if IS_DEBUG()
	NSParameterAssert([_mainList count] > (NSUInteger)indexPath.row);
#else
	if(indexPath.row > [_mainList count])
		return;
#endif
	NSObject<ServiceProtocol> *service = ((NSObject<EventProtocol > *)[_mainList objectAtIndex: indexPath.row]).service;

	// Check for invalid service
	if(!service || !service.valid)
		return;

	// Callback mode
	if(delegate != nil)
	{
		[delegate performSelector:@selector(serviceSelected:) withObject: service];
		if(IS_IPAD())
			[self.navigationController dismissModalViewControllerAnimated:YES];
		else if([delegate isKindOfClass:[UIViewController class]])
			[self.navigationController popToViewController:(UIViewController *)delegate animated:YES];
		else
			[self.navigationController popViewControllerAnimated:YES];
	}
	// Handle swipe
	else if(tableView.lastSwipe & oneFinger)
	{
		NSObject<EventProtocol> *evt = nil;
		if(tableView.lastSwipe & swipeTypeRight)
			evt = (NSObject<EventProtocol > *)[_mainList objectAtIndex: indexPath.row];
		else if([_subList count] > (NSUInteger)indexPath.row) // check if we have "next" event, if not the validity check will fail (so ignore the else case)
			evt = (NSObject<EventProtocol > *)[_subList objectAtIndex: indexPath.row];

		// FIXME: for convenience reasons a valid service marks an event valid, also if it may
		// be invalid, so we have to check begin here too
		if(!evt.valid || !evt.begin) return;
		EventViewController *evc = self.eventViewController;
		evc.event = evt;
		evc.service = service;

		_refreshServices = NO;
		if(IS_IPHONE())
			[self.navigationController setToolbarHidden:YES animated:YES];
		[self.navigationController pushViewController:evc animated:YES];
	}
}

#pragma mark	-
#pragma mark		Table View
#pragma mark	-

/* cell for row */
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSArray *array = (tableView == _tableView) ? _mainList : _filteredServices;
	UITableViewCell *cell = nil;
	id firstObject = [array objectAtIndex:indexPath.row];
	if([firstObject conformsToProtocol:@protocol(EventProtocol)])
	{
		cell = [ServiceEventTableViewCell reusableTableViewCellInView:tableView withIdentifier:kServiceEventCell_ID];
		((ServiceEventTableViewCell *)cell).formatter = _dateFormatter;
		((ServiceEventTableViewCell *)cell).now = firstObject;
		@try
		{
			((ServiceEventTableViewCell *)cell).next = [_subList objectAtIndex:indexPath.row];
		}
		@catch (NSException *e)
		{
			((ServiceEventTableViewCell *)cell).next = nil;
		}
	}
	else
	{
		cell = [ServiceTableViewCell reusableTableViewCellInView:tableView withIdentifier:kServiceCell_ID];

		((ServiceTableViewCell *)cell).service = firstObject;

		const BOOL shouldSelect = [_selectedServices containsObject:firstObject];
		return [[DreamoteConfiguration singleton] styleTableViewCell:cell inTableView:tableView asSlave:self.isSlave multiSelected:shouldSelect];
	}

	return [[DreamoteConfiguration singleton] styleTableViewCell:cell inTableView:tableView asSlave:self.isSlave];
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
	NSArray *array = (tableView == _tableView) ? _mainList : _filteredServices;
	id objectAtIndexPath = [array objectAtIndex: indexPath.row];
	if([objectAtIndexPath conformsToProtocol:@protocol(EventProtocol)])
		service = ((NSObject<EventProtocol > *)objectAtIndexPath).service;
	else
		service = objectAtIndexPath;

	// Check for invalid service
	if(!service || (!self.editing && !service.valid))
		return nil;

	// Callback mode
	if(delegate != nil)
	{
		tableView.allowsSelection = NO;
		[tableView deselectRowAtIndexPath:indexPath animated:YES];

		[delegate performSelector:@selector(serviceSelected:) withObject: service];
		if(IS_IPAD())
			[self.navigationController dismissModalViewControllerAnimated:YES];
		else if([delegate isKindOfClass:[UIViewController class]])
			[self.navigationController popToViewController:(UIViewController *)delegate animated:YES];
		else
			[self.navigationController popViewControllerAnimated:YES];
	}
	// Service Editor
	else if(self.editing)
	{
		[self contextMenu:indexPath forService:service];
	}
	// Load events
	else
	{
		@synchronized(self)
		{
			if(_eventListController == nil)
				_eventListController = [[EventListController alloc] init];
		}

		_eventListController.service = service;
		_eventListController.serviceListController = self;
		_eventListController.isSlave = self.isSlave;

		_refreshServices = NO;
		// XXX: wtf?
		if([self.navigationController.viewControllers containsObject:_eventListController])
		{
#if IS_DEBUG()
			NSMutableString* result = [[NSMutableString alloc] init];
			for(NSObject* obj in self.navigationController.viewControllers)
				[result appendString:[obj description]];
			[NSException raise:@"EventListTwiceInNavigationStack" format:@"_eventListController was twice in navigation stack: %@", result];
#endif
			[self.navigationController popToViewController:self animated:NO]; // return to us, so we can push the service list without any problems
		}
		if(IS_IPHONE())
			[self.navigationController setToolbarHidden:YES animated:YES];
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
	return tableView == _tableView ? _mainList.count : _filteredServices.count;
}

/* editing style */
- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if(self.editing && !(isAll || [_bouquet.sref hasPrefix:@"1:7:0:"]))
		return UITableViewCellEditingStyleDelete;
	return UITableViewCellEditingStyleNone;
}

/* commit edit */
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSObject<ServiceProtocol> *service = nil;
	const BOOL isSearch = tableView == _searchDisplay.searchResultsTableView;
	NSMutableArray *array = (isSearch) ? _filteredServices : _mainList;
	id objectAtIndexPath = [array objectAtIndex:indexPath.row];
	const BOOL isNowNext = [objectAtIndexPath conformsToProtocol:@protocol(EventProtocol)];
	if(isNowNext)
		service = ((NSObject<EventProtocol > *)objectAtIndexPath).service;
	else
		service = objectAtIndexPath;

	Result *result = [[RemoteConnectorObject sharedRemoteConnector] serviceEditorRemoveService:service fromBouquet:_bouquet isRadio:_isRadio];
	if(result.result)
	{
		[array removeObjectAtIndex:indexPath.row];
		if(isSearch)
		{
			// this was a search: remove from the main array
			objectAtIndexPath = [_mainList lastObject];
			const BOOL realNowNext = [objectAtIndexPath conformsToProtocol:@protocol(EventProtocol)];
			if(realNowNext)
			{
				NSUInteger idx = 0;
				for(NSObject<EventProtocol> *event in _mainList)
				{
					if(event.service == service)
						break;
					++idx;
				}
				[_mainList removeObjectAtIndex:idx];
				[_subList removeObjectAtIndex:idx];
			}
			else
				[_mainList removeObject:service];
		}
		else if(isNowNext)
			[_subList removeObjectAtIndex:indexPath.row];
		[tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationRight];
	}
	else
	{
		[tableView reloadData];
	}
}

/* indentation */
- (BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath
{
	if(isAll || [_bouquet.sref hasPrefix:@"1:7:0:"])
		return NO;
	return YES;
}

/* movable? */
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
	if(isAll || [_bouquet.sref hasPrefix:@"1:7:0:"] || tableView == _searchDisplay.searchResultsTableView)
		return NO;
	return !_reloading;
}

/* do move */
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath
{
	NSObject<ServiceProtocol> *service = nil;
	id objectAtIndexPath = [_mainList objectAtIndex:sourceIndexPath.row];
	const BOOL isNowNext = [objectAtIndexPath conformsToProtocol:@protocol(EventProtocol)];
	if(isNowNext)
		service = ((NSObject<EventProtocol > *)objectAtIndexPath).service;
	else
		service = objectAtIndexPath;

	Result *result = [[RemoteConnectorObject sharedRemoteConnector] serviceEditorMoveService:service toPosition:destinationIndexPath.row inBouquet:_bouquet isRadio:_isRadio];
	if(result.result)
	{
		if(isNowNext)
		{
			NSObject *elem = (NSObject<EventProtocol > *)[_subList objectAtIndex:sourceIndexPath.row];
			[_subList removeObjectAtIndex:sourceIndexPath.row];
			[_subList insertObject:elem atIndex:destinationIndexPath.row];
		}
		[_mainList removeObjectAtIndex:sourceIndexPath.row];
		[_mainList insertObject:objectAtIndexPath atIndex:destinationIndexPath.row];
	}
	else
	{
		// NOTE: just reloading the rows is not enough and results in a craash later on, so force-reload the whole table
		[tableView reloadData];
	}
}

#pragma mark -
#pragma mark UIScrollViewDelegate Methods
#pragma mark -

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
	if(scrollView != _searchDisplay.searchResultsTableView)
		[_refreshHeaderView egoRefreshScrollViewDidScroll:scrollView];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
	if(scrollView != _searchDisplay.searchResultsTableView)
		[_refreshHeaderView egoRefreshScrollViewDidEndDragging:scrollView];
}

#pragma mark -
#pragma mark UISearchDisplayController Delegate Methods
#pragma mark -

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
	[_piconLoader cancelAllOperations];
	[_filteredServices removeAllObjects];
	const BOOL caseInsensitive = [searchString isEqualToString:[searchString lowercaseString]];
	NSStringCompareOptions options = caseInsensitive ? (NSCaseInsensitiveSearch|NSDiacriticInsensitiveSearch) : 0;

	id anyObject = [_mainList lastObject];
	const BOOL isNowNext = [anyObject conformsToProtocol:@protocol(EventProtocol)];
	if(isNowNext)
	{
		for(NSObject<EventProtocol> *event in _mainList)
		{
			NSRange range = [event.service.sname rangeOfString:searchString options:options];
			if(range.location != NSNotFound)
				[_filteredServices addObject:event.service];
		}
	}
	else
	{
		for(NSObject<ServiceProtocol> *service in _mainList)
		{
			NSRange range = [service.sname rangeOfString:searchString options:options];
			if(range.location != NSNotFound)
				[_filteredServices addObject:service];
		}
	}

    return YES;
}

- (void)searchDisplayController:(UISearchDisplayController *)controller willUnloadSearchResultsTableView:(UITableView *)tableView
{
	// reload table view to refresh selection status
	[_tableView reloadData];
}

- (void)searchDisplayController:(UISearchDisplayController *)controller willShowSearchResultsTableView:(UITableView *)searchTableView
{
	UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressInSearchTable:)];
	longPressGesture.minimumPressDuration = 1;
	longPressGesture.enabled = YES;
	[searchTableView addGestureRecognizer:longPressGesture];
	searchTableView.editing = self.editing;
	searchTableView.allowsSelectionDuringEditing = YES;
	searchTableView.rowHeight = kServiceCellHeight;
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
- (void)zapAction:(UILongPressGestureRecognizer *)gesture inView:(UITableView *)tableView
{
	// only do something on gesture start
	if(gesture.state != UIGestureRecognizerStateBegan)
		return;

	// get service
	const CGPoint p = [gesture locationInView:tableView];
	NSIndexPath *indexPath = [tableView indexPathForRowAtPoint:p];
	id objectAtIndexPath = [_mainList objectAtIndex:indexPath.row];
	if([objectAtIndexPath conformsToProtocol:@protocol(EventProtocol)])
		_service = ((NSObject<EventProtocol > *)objectAtIndexPath).service;
	else
		_service = objectAtIndexPath;

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
			popoverZapController = [[UIPopoverController alloc] initWithContentViewController:zlc];

			CGRect cellRect = [tableView rectForRowAtIndexPath:indexPath];
			cellRect.origin.x = p.x - 25.0f;
			cellRect.size.width = cellRect.size.width - cellRect.origin.x;
			[popoverZapController presentPopoverFromRect:cellRect
												  inView:tableView
								permittedArrowDirections:UIPopoverArrowDirectionLeft | UIPopoverArrowDirectionRight
												animated:YES];
		}
		else
		{
			_zapListController = [ServiceZapListController showAlert:self fromTabBar:self.tabBarController.tabBar];
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
	_zapListController = nil;

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
	}
	else
		[ServiceZapListController openStream:streamingURL withAction:selectedAction];
}

@end
