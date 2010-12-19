//
//  EventSearchListController.m
//  dreaMote
//
//  Created by Moritz Venn on 27.03.09.
//  Copyright 2009-2010 Moritz Venn. All rights reserved.
//

#import "EventSearchListController.h"

#import "Constants.h"
#import "EventViewController.h"
#import "EventTableViewCell.h"

#import "RemoteConnectorObject.h"

#import "Objects/EventProtocol.h"

#import "Insort/NSArray+CWSortedInsert.h"

#define kTransitionDuration	0.6

@implementation EventSearchListController

/* initialize */
- (id)init
{
	if((self = [super init]))
	{
		self.title = NSLocalizedString(@"Search Events", @"Default Title of EventSearchListController");
	}
	return self;
}

/* dealloc */
- (void)dealloc
{
	[_searchBar release];
	[_tableView release];

	[super dealloc];
}

/* memory warning */
- (void)didReceiveMemoryWarning
{
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

	_searchBar = [[UISearchBar alloc] initWithFrame: frame];
	_searchBar.delegate = self;
	_searchBar.showsCancelButton = YES;
	[contentView addSubview: _searchBar];

	frame = CGRectMake(0, kSearchBarHeight, size.width, size.height - 2 * kSearchBarHeight);
	_tableView = [[UITableView alloc] initWithFrame: frame style:UITableViewStylePlain];
	_tableView.delegate = self;
	_tableView.dataSource = self;
	_tableView.rowHeight = 48;
	_tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
	_tableView.sectionHeaderHeight = 0;
	[contentView addSubview: _tableView];

	[contentView release];
}

/* fetch event list */
- (void)fetchEvents
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[_eventXMLDoc release];
	// TODO: iso8859-1 is currently hardcoded, we might want to fix that
	NSData *data = [_searchBar.text dataUsingEncoding: NSISOLatin1StringEncoding allowLossyConversion: YES];
	NSString *title = [[[NSString alloc] initWithData: data encoding: NSISOLatin1StringEncoding] autorelease];
	_eventXMLDoc = [[[RemoteConnectorObject sharedRemoteConnector] searchEPG: self title: title] retain];
	[pool release];
}

/* add event to list */
- (void)addEvent: (NSObject<EventProtocol> *)event
{
	if(event != nil)
	{
		NSUInteger index = [_events indexForInsertingObject: event sortedUsingSelector: @selector(compare:)];
		[_events insertObject: event atIndex: index];
#ifdef ENABLE_LAGGY_ANIMATIONS
		[_tableView insertRowsAtIndexPaths: [NSArray arrayWithObject: [NSIndexPath indexPathForRow:index inSection:0]]
						withRowAnimation: UITableViewRowAnimationTop];
	}
	else
#else
	}
#endif
	[_tableView reloadData];
}


#pragma mark	-
#pragma mark		Table View
#pragma mark	-

/* cell for given row */
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	EventTableViewCell *cell = (EventTableViewCell*)[tableView dequeueReusableCellWithIdentifier:kEventCell_ID];
	if(cell == nil)
		cell = [[[EventTableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:kEventCell_ID] autorelease];
	
	cell.formatter = _dateFormatter;
	cell.showService = YES;
	cell.event = (NSObject<EventProtocol> *)[_events objectAtIndex: indexPath.row];
	
	return cell;
}

/* about to select row */
- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSObject<EventProtocol> *event = (NSObject<EventProtocol> *)[_events objectAtIndex: indexPath.row];
	NSObject<ServiceProtocol> *service = nil;

	// NOTE: if we encounter an exception we assume an invalid service
	@try {
		service = event.service;
	}
	@catch (NSException * e) {
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

#pragma mark UISearchBarDelegate delegate methods

/* called when keyboard search button pressed */
- (void)searchBarSearchButtonClicked:(UISearchBar *)callingSearchBar
{
	[_searchBar resignFirstResponder];

	[_events removeAllObjects];
	[_tableView reloadData];
	[_eventXMLDoc release];
	_eventXMLDoc = nil;	
	
	// Spawn a thread to fetch the event data so that the UI is not blocked while the
	// application parses the XML file.
	[NSThread detachNewThreadSelector:@selector(fetchEvents) toTarget:self withObject:nil];	
}

/* called when cancel button pressed */
- (void)searchBarCancelButtonClicked:(UISearchBar *)callingSearchBar
{
	[_searchBar resignFirstResponder];
}

/* rotation finished */
- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
	//[UIView beginAnimations:nil context:NULL];
	//[UIView setAnimationDuration: kTransitionDuration];

	// adjust size of _searchBar & _tableView
	const CGSize mainViewSize = self.view.bounds.size;
	_searchBar.frame = CGRectMake(0, 0, mainViewSize.width, kSearchBarHeight);
	_tableView.frame = CGRectMake(0, kSearchBarHeight, mainViewSize.width, mainViewSize.height - kSearchBarHeight);

	//[UIView commitAnimations];
}

/* about to display */
- (void)viewWillAppear:(BOOL)animated
{
	// this UIViewController is about to re-appear, make sure we remove the current selection in our table view
	NSIndexPath *tableSelection = [_tableView indexPathForSelectedRow];
	[_tableView deselectRowAtIndexPath:tableSelection animated:YES];
}

@end
