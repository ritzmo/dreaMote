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
#import "UITableViewCell+EasyInit.h"
#import "UIDevice+SystemVersion.h"

#import "ServiceListController.h"
#import "SimpleSingleSelectionListController.h"
#import "UIPromptView.h"

#import <TableViewCell/ServiceTableViewCell.h>

#import <Objects/ServiceProtocol.h>
#import <Objects/Generic/Result.h>
#import <Objects/Generic/Service.h>

#import <XMLReader/BaseXMLReader.h>

#import "MKStoreManager.h"

#import "GradientView.h"

enum bouquetListTags
{
	TAG_ADD = 99,
	TAG_RENAME = 100,
};

@interface BouquetListController()
/*!
 @brief done editing
 */
- (void)doneAction:(id)sender;

- (void)itemSelected:(NSNumber *)newSelection;

- (void)showBouquets:(id)sender;
- (void)showProvider:(id)sender;
- (void)showAllServices:(id)sender;
- (void)configureToolbar:(BOOL)animated;

/*!
 @brief Show context menu in editing mode.
 */
- (void)contextMenu:(NSIndexPath *)indexPath;

/*!
 @brief Show servicelist
 */
- (void)showServicelist:(NSObject<ServiceProtocol> *)bouquet;
@end

@implementation BouquetListController

@synthesize bouquetDelegate, serviceDelegate, isSplit;
@synthesize serviceListController = _serviceListController;

/* initialize */
- (id)init
{
	if((self = [super init]))
	{
		self.title = NSLocalizedString(@"Bouquets", @"Title of BouquetListController");
		_bouquets = [NSMutableArray array];
		_refreshBouquets = YES;
		_isRadio = NO;
		isSplit = NO;
		_serviceListController = nil;
		_listType = LIST_TYPE_BOUQUETS;

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
	[[NSNotificationCenter defaultCenter] removeObserver:self];
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
	_isRadio = new;
	_radioButton.enabled = NO;

	// eventually deselect row
	NSIndexPath *idx = [_tableView indexPathForSelectedRow];
	if(idx)
		[_tableView deselectRowAtIndexPath:idx animated:YES];

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

	// on ipad also set service list to radio mode, unnecessary on iphone
	if(IS_IPAD())
	{
		_serviceListController.isRadio = new;
		_serviceListController.bouquet = nil;
	}

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

	// only refresh if visible
	if([self.view superview])
		[self viewWillAppear:NO];
}

- (void)didReconnect:(NSNotification *)note
{
	_reloading = NO;
	_listType = LIST_TYPE_BOUQUETS;
	self.editButtonItem.enabled = YES;
	[self configureToolbar:NO];
	[self setEditing:NO animated:NO];

	// disable radio mode in case new connector does not support it
	if(_isRadio)
		[self switchRadio:nil];

	// eventually deselect row
	NSIndexPath *idx = [_tableView indexPathForSelectedRow];
	if(idx)
		[_tableView deselectRowAtIndexPath:idx animated:NO];
}

- (void)reloadBouquets:(NSNotification *)note
{
	[self emptyData];
	[RemoteConnectorObject queueInvocationWithTarget:self selector:@selector(fetchData)];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
	BOOL wasEditing = self.editing;
	[super setEditing:editing animated:animated];
	[_tableView setEditing:editing animated:animated];
	if(IS_IPAD())
		[_serviceListController setEditing:editing animated:animated];

	if(wasEditing != editing)
	{
		if(animated && _listType == LIST_TYPE_BOUQUETS)
		{
			if(editing)
				[_tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:_bouquets.count inSection:0]] withRowAnimation:UITableViewRowAnimationLeft];
			else
				[_tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:_bouquets.count inSection:0]] withRowAnimation:UITableViewRowAnimationRight];
		}
		else
			[_tableView reloadData];
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

	[super loadView];
	_tableView.delegate = self;
	_tableView.dataSource = self;
	_tableView.rowHeight = kServiceCellHeight;
	_tableView.sectionHeaderHeight = 0;
	_tableView.allowsSelectionDuringEditing = YES;
	if(self.editing)
		[_tableView setEditing:YES animated:NO];

	// listen to connection changes
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReconnect:) name:kReconnectNotification object:nil];
	// listen to bouquet changes
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadBouquets:) name:kBouquetsChangedNotification object:nil];

	[self theme];
}

- (void)viewDidUnload
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	_radioButton = nil;

	[super viewDidUnload];
}

/* about to display */
- (void)viewWillAppear:(BOOL)animated
{
	_tableView.allowsSelection = YES;

	// add button to navigation bar if radio mode supported
	if([[RemoteConnectorObject sharedRemoteConnector] hasFeature: kFeaturesRadioMode]
	   && !(   [bouquetDelegate isKindOfClass:[ServiceListController class]]
			|| [serviceDelegate isKindOfClass:[ServiceListController class]]))
	{
		self.navigationItem.leftBarButtonItem = _radioButton;
	}
	else
		self.navigationItem.leftBarButtonItem = nil;

	if(serviceDelegate || bouquetDelegate)
	{
		UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
																				target:self action:@selector(doneAction:)];
		self.navigationItem.rightBarButtonItem = button;
	}
	else if([MKStoreManager isFeaturePurchased:kServiceEditorPurchase] && [[RemoteConnectorObject sharedRemoteConnector] hasFeature:kFeaturesServiceEditor])
	{
		self.navigationItem.rightBarButtonItem = self.editButtonItem;
	}
	else
		self.navigationItem.rightBarButtonItem = nil;

	// Refresh cache if we have a cleared one
	if(_refreshBouquets && !_reloading)
	{
		_reloading = YES;
		[_refreshHeaderView setTableLoadingWithinScrollView:_tableView];
		[self emptyData];

		// Run this in our "temporary" queue
		[RemoteConnectorObject queueInvocationWithTarget:self selector:@selector(fetchData)];
	}
	else
	{
		// this UIViewController is about to re-appear, make sure we remove the current selection in our table view
		NSIndexPath *tableSelection = [_tableView indexPathForSelectedRow];
		[_tableView deselectRowAtIndexPath:tableSelection animated:YES];
	}
	[self configureToolbar:animated];

	[super viewWillAppear: animated];
}

/* cancel in delegate mode */
- (void)doneAction:(id)sender
{
	if(IS_IPAD())
		[self.navigationController dismissModalViewControllerAnimated:YES];
	else
	{
		[self.navigationController setToolbarHidden:YES animated:YES];
		[self.navigationController popViewControllerAnimated:YES];
	}
}

/* did appear */
- (void)viewDidAppear:(BOOL)animated
{
	_refreshBouquets = YES;
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
			_serviceListController = nil;
		}
	}
}

- (void)showServicelist:(NSObject<ServiceProtocol> *)bouquet
{
	// Check for cached ServiceListController instance
	if(_serviceListController == nil)
		_serviceListController = [[ServiceListController alloc] init];
	
	// Redirect callback if we have one
	if(serviceDelegate)
		_serviceListController.delegate = serviceDelegate;
	_serviceListController.bouquet = bouquet;
	
	// We do not want to refresh bouquet list when we return
	_refreshBouquets = NO;
	
	// when in split view go back to service list, else push it on the stack
	if(!isSplit)
	{
		// XXX: wtf?
		if([self.navigationController.viewControllers containsObject:_serviceListController])
		{
#if IS_DEBUG()
			NSMutableString* result = [[NSMutableString alloc] init];
			for(NSObject* obj in self.navigationController.viewControllers)
				[result appendString:[obj description]];
			[NSException raise:@"ServiceListTwiceInNavigationStack" format:@"_serviceListController was twice in navigation stack: %@", result];
#endif
			[self.navigationController popToRootViewControllerAnimated:NO]; // return to bouquet list, so we can push the service list without any problems
		}
		[_serviceListController setEditing:self.editing animated:YES];
		[self.navigationController pushViewController:_serviceListController animated:YES];
		[self.navigationController setToolbarHidden:YES animated:YES];
	}
	else
		[_serviceListController.navigationController popToRootViewControllerAnimated: YES];
}

- (void)showBouquets:(id)sender
{
	_listType = LIST_TYPE_BOUQUETS;
	_reloading = YES;
	[_refreshHeaderView setTableLoadingWithinScrollView:_tableView];
	[self emptyData];
	[RemoteConnectorObject queueInvocationWithTarget:self selector:@selector(fetchData)];
}

- (void)showProvider:(id)sender
{
	_listType = LIST_TYPE_PROVIDER;
	_reloading = YES;
	[_refreshHeaderView setTableLoadingWithinScrollView:_tableView];
	[self emptyData];
	[RemoteConnectorObject queueInvocationWithTarget:self selector:@selector(fetchData)];
}

- (void)showAllServices:(id)sender
{
	if(_serviceListController.reloading)
		return;

	NSIndexPath *indexPath = [_tableView indexPathForSelectedRow];
	if(indexPath)
		[_tableView deselectRowAtIndexPath:indexPath animated:YES];
	NSObject<ServiceProtocol> *bouquet = [[RemoteConnectorObject sharedRemoteConnector] allServicesBouquet:_isRadio];
	[self showServicelist:bouquet];
	// TODO: we might run into a race condition here, check this thoroughly
	_serviceListController.showNowNext = NO;
	_serviceListController.isAll = YES;
}

- (void)configureToolbar:(BOOL)animated
{
	// NOTE: rather hackish way to hide access to providers, but good enough :)
	if([[RemoteConnectorObject sharedRemoteConnector] hasFeature:kFeaturesProviderList] && ![bouquetDelegate isKindOfClass:[ServiceListController class]])
	{
		const UIBarButtonItem *bouquetItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Bouquets", @"Bouquets button in bouquet list")
																			  style:UIBarButtonItemStyleBordered
																			 target:self
																			 action:@selector(showBouquets:)];
		const UIBarButtonItem *providerItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Provider", @"Provider button in bouquet list")
																			   style:UIBarButtonItemStyleBordered
																			  target:self
																			  action:@selector(showProvider:)];
		const UIBarButtonItem *allItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"All", @"'All Services' button in bouquet list")
																			   style:UIBarButtonItemStyleBordered
																			  target:self
																			  action:@selector(showAllServices:)];
		const UIBarButtonItem *flexItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
																						target:nil
																						action:nil];
		NSArray *items = [[NSArray alloc] initWithObjects:bouquetItem, flexItem, providerItem, flexItem, allItem, nil];
		[self setToolbarItems:items animated:animated];
		[self.navigationController setToolbarHidden:NO animated:animated];
	}
	else
	{
		[self setToolbarItems:nil animated:animated];
		[self.navigationController setToolbarHidden:YES animated:animated];
	}
}

/* fetch contents */
- (void)fetchData
{
	_reloading = YES;
	NSObject<RemoteConnector> *sharedRemoteConnector = [RemoteConnectorObject sharedRemoteConnector];
	if(_listType == LIST_TYPE_PROVIDER && [sharedRemoteConnector respondsToSelector:@selector(fetchProviders:isRadio:)])
	{
		_xmlReader = [sharedRemoteConnector fetchProviders:self isRadio:_isRadio];
	}
	else
	{
#if IS_DEBUG()
		if(_listType == LIST_TYPE_PROVIDER)
		{
			NSLog(@"Provider list requested but sharedRemoteConnector (%@) does not respond to the respective selector...", [sharedRemoteConnector description]);
		}
#endif
		_xmlReader = [sharedRemoteConnector fetchBouquets:self isRadio:_isRadio];
	}
}

/* remove content data */
- (void)emptyData
{
	// Clean event list
	[_bouquets removeAllObjects];
#if INCLUDE_FEATURE(Extra_Animation)
	NSIndexSet *idxSet = [NSIndexSet indexSetWithIndex: 0];
	[_tableView reloadSections:idxSet withRowAnimation:UITableViewRowAnimationRight];
#else
	[_tableView reloadData];
#endif
	_xmlReader = nil;
}

#pragma mark -
#pragma mark DataSourceDelegate
#pragma mark -

- (void)dataSourceDelegate:(BaseXMLReader *)dataSource errorParsingDocument:(NSError *)error
{
	_radioButton.enabled = YES;
	// assume details will fail too if in split
	if(isSplit)
	{
		[_refreshHeaderView egoRefreshScrollViewDataSourceDidFinishedLoading:_tableView];
		[_tableView reloadData];
		_reloading = NO;
	}
	else
	{
		[super dataSourceDelegate:dataSource errorParsingDocument:error];
	}
}
- (void)dataSourceDelegateFinishedParsingDocument:(BaseXMLReader *)dataSource
{
	_radioButton.enabled = YES;
	if(isSplit)
	{
		// NOTE: reload service list, important for e.g. enigma1
		NSIndexPath *idxPath = [_tableView indexPathForSelectedRow];
		if(idxPath)
			[self tableView:_tableView didSelectRowAtIndexPath:idxPath];
	}
	[super dataSourceDelegateFinishedParsingDocument:dataSource];
}

#pragma mark -
#pragma mark ServiceSourceDelegate
#pragma mark -

/* add service to list */
- (void)addService: (NSObject<ServiceProtocol> *)bouquet
{
	[_bouquets addObject: bouquet];
#if INCLUDE_FEATURE(Extra_Animation)
	[_tableView insertRowsAtIndexPaths: [NSArray arrayWithObject: [NSIndexPath indexPathForRow:[_bouquets count]-1 inSection:0]]
					  withRowAnimation: UITableViewRowAnimationTop];
#endif
}

- (void)addServices:(NSArray *)items
{
#if INCLUDE_FEATURE(Extra_Animation)
	NSUInteger count = _bouquets.count;
	NSMutableArray *indexPaths = [NSMutableArray arrayWithCapacity:items.count];
#endif
	[_bouquets addObjectsFromArray:items];
#if INCLUDE_FEATURE(Extra_Animation)
	for(NSObject<ServiceProtocol> *service in items)
	{
		[indexPaths addObject:[NSIndexPath indexPathForRow:count inSection:0]];
		++count;
	}
	if(indexPaths)
		[_tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationLeft];
#endif
}

#pragma mark Context menu

- (void)contextMenu:(NSIndexPath *)indexPath
{
	if(IS_IPAD())
	{
		if(popoverController)
		{
			[popoverController dismissPopoverAnimated:YES];
			popoverController = nil;
		}
		SimpleSingleSelectionListController *vc = [SimpleSingleSelectionListController withItems:[NSArray arrayWithObjects:
																								  NSLocalizedStringFromTable(@"Open", @"ServiceEditor", @"Open selected service"),
																								  NSLocalizedStringFromTable(@"Rename", @"ServiceEditor", @"Rename currently selected service"),
																								  nil]
																					andSelection:NSNotFound
																						andTitle:nil];
		vc.callback = ^(NSUInteger selectedItem, BOOL isClosing, BOOL canceling){
			// NOTE: ignore cancel as the button is not visible in our case
			[popoverController dismissPopoverAnimated:YES];
			popoverController = nil;

			[self performSelectorOnMainThread:@selector(itemSelected:) withObject:[NSNumber numberWithUnsignedInteger:selectedItem] waitUntilDone:NO];

			return YES;
		};
		vc.contentSizeForViewInPopover = CGSizeMake(160.0f, 130.0f);
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
											   cancelButtonTitle:NSLocalizedString(@"Cancel", @"")
										  destructiveButtonTitle:nil//NSLocalizedStringFromTable(@"Delete", @"ServiceEditor", @"Delete selected service")
											   otherButtonTitles:
							 NSLocalizedStringFromTable(@"Open", @"ServiceEditor", @"Open selected service"),
							 NSLocalizedStringFromTable(@"Rename", @"ServiceEditor", @"Rename currently selected service"),
							 nil];
		if(self.tabBarController == nil) // XXX: bug in MGSplitViewController?
			[as showInView:self.view];
		else
			[as showFromTabBar:self.tabBarController.tabBar];
	}
}

- (void)itemSelected:(NSNumber *)newSelection
{
	[popoverController dismissPopoverAnimated:YES];
	popoverController = nil;

	switch([newSelection integerValue])
	{
		default:
		case NSNotFound: /* just deselect */
		{
			NSIndexPath *indexPath = [_tableView indexPathForSelectedRow];
			[_tableView deselectRowAtIndexPath:indexPath animated:YES];
			break;
		}
		case 0: /* open */
		{
			NSIndexPath *indexPath = [_tableView indexPathForSelectedRow];
			NSObject<ServiceProtocol> *bouquet = [_bouquets objectAtIndex:indexPath.row];
			[_tableView deselectRowAtIndexPath:indexPath animated:YES];
			[self showServicelist:bouquet];
			break;
		}
		case 1: /* rename */
		{
			UIPromptView *alertView = [[UIPromptView alloc] initWithTitle:NSLocalizedStringFromTable(@"Enter new name of bouquet", @"ServiceEditor", @"Title of prompt requesting new name for an existing bouquet")
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
}

#pragma mark -
#pragma mark UIActionSheetDelegate
#pragma mark -

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if (buttonIndex == actionSheet.cancelButtonIndex)
	{
		NSIndexPath *indexPath = [_tableView indexPathForSelectedRow];
		[_tableView deselectRowAtIndexPath:indexPath animated:YES];
	}
	else if(buttonIndex == actionSheet.destructiveButtonIndex)
	{
		// delete
		NSIndexPath *indexPath = [_tableView indexPathForSelectedRow];
		[self tableView:_tableView commitEditingStyle:UITableViewCellEditingStyleDelete forRowAtIndexPath:indexPath];
		[_tableView deselectRowAtIndexPath:indexPath animated:YES];
	}
	else
	{
		buttonIndex -= actionSheet.firstOtherButtonIndex;
		[self itemSelected:[NSNumber numberWithInteger:buttonIndex]];
	}
}

#pragma mark	-
#pragma mark		Table View
#pragma mark	-

/* create cell for given row */
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if(indexPath.row == (NSInteger)_bouquets.count)
	{
		UITableViewCell *cell = [BaseTableViewCell reusableTableViewCellInView:tableView withIdentifier:kBaseCell_ID];
		cell.textLabel.text = NSLocalizedStringFromTable(@"New Bouquet", @"ServiceEditor", @"Title of cell to add a bouquet");
		cell.textLabel.font = [UIFont boldSystemFontOfSize:kServiceTextSize];
		return [[DreamoteConfiguration singleton] styleTableViewCell:cell inTableView:tableView];
	}
	ServiceTableViewCell *cell = [ServiceTableViewCell reusableTableViewCellInView:tableView withIdentifier:kServiceCell_ID];
	cell.loadPicon = NO;
	cell.service = [_bouquets objectAtIndex:indexPath.row];
	if(_listType == LIST_TYPE_PROVIDER || [bouquetDelegate isKindOfClass:[ServiceListController class]])
		cell.editingAccessoryType = UITableViewCellAccessoryDisclosureIndicator;
	else
		cell.editingAccessoryType = UITableViewCellAccessoryNone;

	return [[DreamoteConfiguration singleton] styleTableViewCell:cell inTableView:tableView];
}

/* select row */
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	// do nothing if reloading
	if(_reloading)
	{
#if IS_DEBUG()
		NSLog(@"didSelectRowAtIndexPath was triggered for indexPath (section %d, row %d) while reloading", indexPath.section, indexPath.row);
#endif
		return [tableView deselectRowAtIndexPath:indexPath animated:YES];
	}
	if(indexPath.row >= (NSInteger)_bouquets.count)
	{
#if IS_DEBUG()
		NSLog(@"Selection (%d) outside of bounds (%d) in BouquetListController. This does not have to be bad!", indexPath.row, _bouquets.count);
#endif
		return [tableView deselectRowAtIndexPath:indexPath animated:YES];
	}

	// See if we have a valid bouquet
	NSObject<ServiceProtocol> *bouquet = [_bouquets objectAtIndex: indexPath.row];
	if(!bouquet.valid)
		return [tableView deselectRowAtIndexPath:indexPath animated:YES];

	if(bouquetDelegate)
	{
		tableView.allowsSelection = NO;
		[tableView deselectRowAtIndexPath:indexPath animated:YES];
		[bouquetDelegate performSelector:@selector(bouquetSelected:) withObject:bouquet];

		if(IS_IPAD())
			[self.navigationController dismissModalViewControllerAnimated:YES];
		else
		{
			[self.navigationController setToolbarHidden:YES animated:YES];
			if([bouquetDelegate isKindOfClass:[UIViewController class]])
				[self.navigationController popToViewController:(UIViewController *)bouquetDelegate animated:YES];
			else
				[self.navigationController popViewControllerAnimated:YES];
		}
	}
	else if(self.editing && _listType == LIST_TYPE_BOUQUETS)
	{
		[self contextMenu:indexPath];
	}
	else if(!_serviceListController.reloading)
	{
		[self showServicelist:bouquet];
	}
	else
		return [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

/* number of sections */
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView 
{
	return 1;
}

/* number of rows */
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
	NSInteger count = _bouquets.count;
	if(self.editing && _listType == LIST_TYPE_BOUQUETS)
		++count;
	return count;
}

/* editing style */
- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if(self.editing && _listType == LIST_TYPE_BOUQUETS)
	{
		if(indexPath.row == (NSInteger)_bouquets.count)
		{
			return UITableViewCellEditingStyleInsert;
		}
		else if(![bouquetDelegate isKindOfClass:[ServiceListController class]])
			return UITableViewCellEditingStyleDelete;
	}
	return UITableViewCellEditingStyleNone;
}

/* commit edit */
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
	if(editingStyle == UITableViewCellEditingStyleInsert)
	{
		UIPromptView *alertView = [[UIPromptView alloc] initWithTitle:NSLocalizedStringFromTable(@"Enter name of bouquet", @"ServiceEditor", @"Title of prompt requesting name for new bouquet")
															 message:nil
															delegate:self
												   cancelButtonTitle:NSLocalizedString(@"Cancel", @"")
													   okButtonTitle:@"OK"
		];
		alertView.tag = TAG_ADD;
		alertView.promptViewStyle = UIPromptViewStylePlainTextInput;
		[alertView show];
	}
	else
	{
		NSObject<ServiceProtocol> *bouquet = [_bouquets objectAtIndex:indexPath.row];
		Result *result = [[RemoteConnectorObject sharedRemoteConnector] serviceEditorRemoveBouquet:bouquet isRadio:_isRadio];
		if(result.result)
		{
			[_bouquets removeObjectAtIndex:indexPath.row];
			[tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationRight];
		}
		else
		{
			[tableView reloadData];
		}
	}
}

/* indentation */
- (BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath
{
	if(_listType == LIST_TYPE_PROVIDER || ([bouquetDelegate isKindOfClass:[ServiceListController class]] && indexPath.row != (NSInteger)_bouquets.count))
		return NO;
	return YES;
}

/* movable? */
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
	if(indexPath.row == (NSInteger)_bouquets.count || _listType == LIST_TYPE_PROVIDER || [bouquetDelegate isKindOfClass:[ServiceListController class]])
		return NO;
	return YES;
}

/* do move */
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath
{
	NSObject<ServiceProtocol> *bouquet = [_bouquets objectAtIndex:sourceIndexPath.row];
	Result *result = [[RemoteConnectorObject sharedRemoteConnector] serviceEditorMoveBouquet:bouquet toPosition:destinationIndexPath.row isRadio:_isRadio];
	if(result.result)
	{
		[_bouquets removeObjectAtIndex:sourceIndexPath.row];
		[_bouquets insertObject:bouquet atIndex:destinationIndexPath.row];
	}
	else
	{
		// NOTE: just reloading the rows is not enough and results in a craash later on, so force-reload the whole table
		[tableView reloadData];
	}
}

/* row bounds */
- (NSIndexPath *)tableView:(UITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath
{
	if(proposedDestinationIndexPath.row >= (NSInteger)_bouquets.count)
	{
		proposedDestinationIndexPath = [NSIndexPath indexPathForRow:_bouquets.count-1 inSection:0];
	}
	return proposedDestinationIndexPath;
}

#pragma mark -
#pragma mark UIAlertViewDelegate methods
#pragma mark -

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
	NSIndexPath *indexPath = nil;
#define promptView (UIPromptView *)alertView
	if(alertView.tag == TAG_ADD)
	{
		if(buttonIndex == alertView.cancelButtonIndex)
			return;
		NSString *bouquetName = [promptView promptFieldAtIndex:0].text;
		Result *result = [[RemoteConnectorObject sharedRemoteConnector] serviceEditorAddBouquet:bouquetName isRadio:_isRadio];
		if(result.result)
		{
			NSDictionary *userInfo = nil;
#if 0
			// if we can make use of this information in the future: this is the code to enable :D
			userInfo = [NSDictionary dictionaryWithObjectsAndKeys:bouquetName, @"bouquetName", nil];
#endif
			[[NSNotificationCenter defaultCenter] postNotificationName:kBouquetsChangedNotification object:nil userInfo:userInfo];
		}
		else
		{
			const UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", @"")
																  message:[NSString stringWithFormat:NSLocalizedStringFromTable(@"Unable to create bouquet: %@", @"ServiceEditor", @"Creating a bouquet has failed"), result.resulttext]
																 delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
			[alert show];
		}
	}
	else //if(alertView.tag == TAG_RENAME)
	{
		indexPath = [_tableView indexPathForSelectedRow];
		if(buttonIndex == alertView.cancelButtonIndex)
		{
			[_tableView deselectRowAtIndexPath:indexPath animated:YES];
			return;
		}
		NSObject<ServiceProtocol> *bouquet = [_bouquets objectAtIndex:indexPath.row];
		NSString *bouquetName = [promptView promptFieldAtIndex:0].text;
		Result *result = [[RemoteConnectorObject sharedRemoteConnector] serviceEditorRenameBouquet:bouquet name:bouquetName isRadio:_isRadio];
		if(result.result)
		{
			@try
			{
				bouquet.sname = bouquetName;
				ServiceTableViewCell *cell = (ServiceTableViewCell *)[_tableView cellForRowAtIndexPath:indexPath];
				// reset cell once
				cell.service = nil;
				cell.service = bouquet;
			}
			@catch (NSException *exception)
			{
#if IS_DEBUG()
				NSLog(@"Unable to rename service internally (%@)... reloading", [exception description]);
#endif
				[self emptyData];
				[RemoteConnectorObject queueInvocationWithTarget:self selector:@selector(fetchData)];
			}
		}
		else
		{
			const UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", @"")
																  message:[NSString stringWithFormat:NSLocalizedStringFromTable(@"Unable to rename bouquet: %@", @"ServiceEditor", @"Renaming a bouquet has failed"), result.resulttext]
																 delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
			[alert show];
		}
	}
	[_tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark -

/* support rotation */
- (BOOL)shouldAutorotateToInterfaceOrientation: (UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

@end
