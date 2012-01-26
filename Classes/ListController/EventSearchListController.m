//
//  EventSearchListController.m
//  dreaMote
//
//  Created by Moritz Venn on 27.03.09.
//  Copyright 2009-2012 Moritz Venn. All rights reserved.
//

#import "EventSearchListController.h"

#import "Constants.h"
#import "EventViewController.h"
#import "EventTableViewCell.h"

#if IS_FULL()
	#import "EPGCache.h"
#endif
#import "RemoteConnectorObject.h"

#import "Objects/EventProtocol.h"

#import "Insort/NSArray+CWSortedInsert.h"
#import "UITableViewCell+EasyInit.h"

#import "SSKManager.h"

#define kTransitionDuration	0.6

@interface EventSearchListController()
/*!
 @brief Show search history.
 
 @param sender Sender of this action.
 */
- (IBAction)showHistory:(id)sender;
@end

@implementation EventSearchListController

/* initialize */
- (id)init
{
	if((self = [super init]))
	{
		self.title = NSLocalizedString(@"Search Events", @"Default Title of EventSearchListController");
		self.hidesBottomBarWhenPushed = NO;
	}
	return self;
}

/* getter of searchHistory */
- (SearchHistoryListController *)searchHistory
{
	if(!_searchHistory)
	{
		_searchHistory = [[SearchHistoryListController alloc] init];
		_searchHistory.historyDelegate = self;
	}
	return _searchHistory;
}

/* memory warning */
- (void)didReceiveMemoryWarning
{
	// if on iphone and history is not visible, release it
	if(!IS_IPAD() && _searchHistory
		&& ![self.navigationController.visibleViewController isEqual:_searchHistory])
	{
		[_searchHistory saveHistory];
		_searchHistory = nil;
	}
    [super didReceiveMemoryWarning];
}

/* layout */
- (void)loadView
{
	UIView *contentView = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]];
	self.view = contentView;

	// setup our content view so that it auto-rotates along with the UViewController
	contentView.autoresizesSubviews = YES;
	contentView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);

	const CGSize size = self.view.bounds.size;
	CGRect frame = CGRectMake(0, 0, size.width, kSearchBarHeight);

	searchBar = [[UISearchBar alloc] initWithFrame: frame];
	searchBar.delegate = self;
	searchBar.showsCancelButton = YES;
	searchBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	[contentView addSubview: searchBar];

	frame = CGRectMake(0, kSearchBarHeight, size.width, size.height - kSearchBarHeight);
	_tableView = [[SwipeTableView alloc] initWithFrame: frame style:UITableViewStylePlain];
	_tableView.delegate = self;
	_tableView.dataSource = self;
	_tableView.rowHeight = 48;
	_tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
	_tableView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
	[contentView addSubview: _tableView];


	UIBarButtonItem *barButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemBookmarks target:self action:@selector(showHistory:)];
	self.navigationItem.rightBarButtonItem = barButtonItem;

#if INCLUDE_FEATURE(Ads)
	if(IS_IPHONE() && ![SSKManager isFeaturePurchased:kAdFreePurchase])
	{
		[self createAdBannerView];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(adsWereRemoved:) name:kAdRemovalPurchased object:nil];
	}
#endif
	[self theme];
}

- (void)viewDidUnload
{
	searchBar = nil;
	_tableView = nil;

	[super viewDidUnload];
}

- (IBAction)showHistory:(id)sender
{
	if(IS_IPAD())
	{
		// hide popover if already visible
		if([self.popoverController isPopoverVisible])
		{
			[self.popoverController dismissPopoverAnimated:YES];
			self.popoverController = nil;
			return;
		}

		self.popoverController = [[UIPopoverController alloc] initWithContentViewController:self.searchHistory];
		/*!
		 @note In case I want to bind this to the search bar at some point in the future,
		 but currently I prefer it bound to an extra button.
		 */
#if 0
		if([sender isEqual:searchBar])
		{
			[self.popoverController presentPopoverFromRect:searchBar.frame
										inView:searchBar
										permittedArrowDirections:UIPopoverArrowDirectionUp
										animated:YES];
		}
		else
#endif
		{
			[self.popoverController presentPopoverFromBarButtonItem:sender
										permittedArrowDirections:UIPopoverArrowDirectionUp
										animated:YES];
		}
	}
	else
	{
		[self.navigationController pushViewController:self.searchHistory animated:YES];
	}
}

/* fetch event list */
- (void)fetchData
{
	// TODO: iso8859-1 is currently hardcoded, we might want to fix that
	NSData *data = [searchBar.text dataUsingEncoding: NSISOLatin1StringEncoding allowLossyConversion: YES];
	NSString *title = [[NSString alloc] initWithData: data encoding: NSISOLatin1StringEncoding];
	[self.searchHistory prepend:title];

	// perform native search
	if([[RemoteConnectorObject sharedRemoteConnector] hasFeature:kFeaturesEPGSearch])
		_xmlReader = [[RemoteConnectorObject sharedRemoteConnector] searchEPG:self title:title];
#if IS_FULL()
	// serch in epg cache
	else
	{
		_xmlReader = nil;
		[[EPGCache sharedInstance] searchEPGForTitle:title delegate:self];
	}
#endif
}

#pragma mark -
#pragma mark SearchHistoryListViewDelegate methods
#pragma mark -

/* set text in search bar */
- (void)startSearch:(NSString *)text
{
	// set search text
	NSString *textCopy = [text copy];
	searchBar.text = textCopy;

	// initiate search
	[self searchBarSearchButtonClicked:nil];

	// hide history
	if(IS_IPAD())
	{
		[self.popoverController dismissPopoverAnimated: YES];
		self.popoverController = nil;
	}
	else
	{
		[self.navigationController popToViewController:self animated:YES];
	}
}

#pragma mark -
#pragma mark DataSourceDelegate
#pragma mark -

// NOTE: can't use super because it has modifications for the search bar
- (void)dataSourceDelegate:(SaxXmlReader *)dataSource errorParsingDocument:(NSError *)error
{
	_reloading = NO;
	[_refreshHeaderView egoRefreshScrollViewDataSourceDidFinishedLoading:_tableView];
	[_tableView reloadData];

	if(!error)
		return;

	// Alert user
	const UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Failed to retrieve data", @"Title of Alert when retrieving remote data failed.")
														  message:[error localizedDescription]
														 delegate:nil
												cancelButtonTitle:@"OK"
												otherButtonTitles:nil];
	[alert show];
}

- (void)dataSourceDelegateFinishedParsingDocument:(SaxXmlReader *)dataSource
{
	if(_useSections)
		[self sortEventsInSections]; // calls reloadData by itself
	else
		[_tableView reloadData];
}

#pragma mark -
#pragma mark EventSourceDelegate methods
#pragma mark -

/* add event to list */
- (void)addEvent: (NSObject<EventProtocol> *)event
{
	const NSUInteger index = [_events indexForInsertingObject: event sortedUsingSelector: @selector(compare:)];
	[_events insertObject: event atIndex: index];
#if INCLUDE_FEATURE(Extra_Animation)
	if(!_useSections)
		[_tableView reloadData];
#endif
}

- (void)addEvents:(NSArray *)items
{
	for(NSObject<EventProtocol> *event in items)
	{
		const NSUInteger index = [_events indexForInsertingObject:event sortedUsingSelector:@selector(compare:)];
		[_events insertObject:event atIndex:index];
	}
#if INCLUDE_FEATURE(Extra_Animation)
	if(!_useSections)
		[_tableView reloadData];
#endif
}

#pragma mark	-
#pragma mark		Table View
#pragma mark	-

/* cell for given row */
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	EventTableViewCell *cell = [EventTableViewCell reusableTableViewCellInView:tableView withIdentifier:kEventCell_ID];

	cell.formatter = self.dateFormatter;
	cell.showService = YES;
	if(_useSections)
	{
		const NSInteger offset = [[_sectionOffsets objectAtIndex:indexPath.section] integerValue];
		cell.event = (NSObject<EventProtocol> *)[_events objectAtIndex:offset + indexPath.row];
	}
	else
		cell.event = (NSObject<EventProtocol> *)[_events objectAtIndex: indexPath.row];

	[[DreamoteConfiguration singleton] styleTableViewCell:cell inTableView:tableView asSlave:self.isSlave];
	return cell;
}

/* about to select row */
- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	// do nothing if reloading
	if(_reloading)
	{
#if IS_DEBUG()
		[NSException raise:@"EventSearchListUserInteractionWhileReloading" format:@"willSelectRowAtIndexPath was triggered for indexPath (section %d, row %d) while reloading", indexPath.section, indexPath.row];
#endif
		return nil;
	}

	NSObject<EventProtocol> *event = ((EventTableViewCell *)[tableView cellForRowAtIndexPath:indexPath]).event;
	NSObject<ServiceProtocol> *service = nil;

	// NOTE: if we encounter an exception we assume an invalid service
	@try {
		service = event.service;
	}
	@catch (NSException * e) {
#if IS_DEBUG()
		NSLog(@"exception while trying to retrieve service from event %@ at index %d/%d", [event description], indexPath.section, indexPath.row);
		[e raise];
#endif
		return nil;
	}

	if(_eventViewController == nil)
		_eventViewController = [[EventViewController alloc] init];

	_eventViewController.event = event;
	_eventViewController.service = service;
	_eventViewController.search = YES;

	[self.navigationController pushViewController: _eventViewController animated: YES];

	return indexPath;
}

#pragma mark -
#pragma mark UIPopoverControllerDelegate methods
#pragma mark -

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)pc
{
	// cleanup memory
	if([pc isEqual:self.popoverController])
		self.popoverController = nil;
}

#pragma mark UISearchBarDelegate delegate methods

/* called when keyboard search button pressed */
- (void)searchBarSearchButtonClicked:(UISearchBar *)pSearchBar
{
	[pSearchBar resignFirstResponder];

	_useSections = [[NSUserDefaults standardUserDefaults] boolForKey:kSeparateEpgByDay];
	[_sectionOffsets removeAllObjects];
	_lastDay = NSNotFound;

	[_events removeAllObjects];
	[_tableView reloadData];
	_xmlReader = nil;
	
	// Run this in our "temporary" queue
	[RemoteConnectorObject queueInvocationWithTarget:self selector:@selector(fetchData)];
}

/* called when cancel button pressed */
- (void)searchBarCancelButtonClicked:(UISearchBar *)pSearchBar
{
	[pSearchBar resignFirstResponder];
}

/* rotation finished */
- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
	//[UIView beginAnimations:nil context:NULL];
	//[UIView setAnimationDuration: kTransitionDuration];

	// adjust size of searchBar & _tableView
	const CGSize mainViewSize = self.view.bounds.size;
	searchBar.frame = CGRectMake(0, 0, mainViewSize.width, kSearchBarHeight);
	_tableView.frame = CGRectMake(0, kSearchBarHeight, mainViewSize.width, mainViewSize.height - kSearchBarHeight);

	//[UIView commitAnimations];
	[super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
}

/* about to display */
- (void)viewWillAppear:(BOOL)animated
{
	// this UIViewController is about to re-appear, make sure we remove the current selection in our table view
	NSIndexPath *tableSelection = [_tableView indexPathForSelectedRow];
	[_tableView deselectRowAtIndexPath:tableSelection animated:YES];
}

/* about to disappear */
- (void)viewWillDisappear:(BOOL)animated
{
	// eventually remove popover
	if(self.popoverController)
	{
		[self.popoverController dismissPopoverAnimated:YES];
		self.popoverController = nil;
	}

	[_searchHistory saveHistory];
	if(!IS_IPAD())
	{
		_searchHistory = nil;
	}
	[super viewWillDisappear:animated];
}

@end
