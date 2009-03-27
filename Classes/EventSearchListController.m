//
//  EventSearchListController.m
//  dreaMote
//
//  Created by Moritz Venn on 27.03.09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "EventSearchListController.h"

#import "Constants.h"
#import "EventViewController.h"

#import "RemoteConnectorObject.h"

#import "Objects/EventProtocol.h"

@implementation EventSearchListController

- (id)init
{
	self = [super init];
	if (self) {
		self.title = NSLocalizedString(@"Search Events", @"Default Title of EventSearchListController");
	}
	return self;
}

- (void)dealloc
{
	[searchBar release];
	[tableView release];

	[super dealloc];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)loadView
{
	UIView *contentView = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]];
	self.view = contentView;
	[contentView release];

	CGSize size = self.view.bounds.size;
	CGRect frame = CGRectMake(0.0, 0.0, size.width, kSearchBarHeight);

	searchBar = [[UISearchBar alloc] initWithFrame: frame];
	searchBar.delegate = self;
	searchBar.showsCancelButton = YES;
	[contentView addSubview: searchBar];

	frame = CGRectMake(0.0, kSearchBarHeight, size.width, size.height - kSearchBarHeight);
	tableView = [[UITableView alloc] initWithFrame: frame style:UITableViewStylePlain];
	tableView.delegate = self;
	tableView.dataSource = self;
	tableView.rowHeight = 48.0;
	tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
	tableView.sectionHeaderHeight = 0;
	
	// setup our content view so that it auto-rotates along with the UViewController
	tableView.autoresizesSubviews = YES;
	tableView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
	[contentView addSubview: tableView];
}

- (void)fetchEvents
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[eventXMLDoc release];
	// XXX: do not forget to take some care of special chars (like hardcode iso8859-1 for now)
	NSString *title = searchBar.text;
	eventXMLDoc = [[[RemoteConnectorObject sharedRemoteConnector] searchEPG: self action:@selector(addEvent:) title: title] retain];
	[pool release];
}

- (void)addEvent:(id)event
{
	if(event != nil)
	{
		[(NSMutableArray *)_events addObject: event];
#ifdef ENABLE_LAGGY_ANIMATIONS
		[tableView insertRowsAtIndexPaths: [NSArray arrayWithObject: [NSIndexPath indexPathForRow:[_events count]-1 inSection:0]]
						withRowAnimation: UITableViewRowAnimationTop];
	}
	else
#else
	}
#endif
	[tableView reloadData];
}


#pragma mark	-
#pragma mark		Table View
#pragma mark	-

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSObject<EventProtocol> *event = (NSObject<EventProtocol> *)[_events objectAtIndex: indexPath.row];

	if(eventViewController == nil)
		eventViewController = [[EventViewController alloc] init];

	eventViewController.event = event;
	eventViewController.service = event.service;

	[self.navigationController pushViewController: eventViewController animated: YES];

	return nil;
}

#pragma mark UISearchBarDelegate delegate methods

// called when keyboard search button pressed
- (void)searchBarSearchButtonClicked:(UISearchBar *)callingSearchBar
{
	[searchBar resignFirstResponder];

	// Spawn a thread to fetch the event data so that the UI is not blocked while the
	// application parses the XML file.
	[NSThread detachNewThreadSelector:@selector(fetchEvents) toTarget:self withObject:nil];	
}

// called when cancel button pressed
- (void)searchBarCancelButtonClicked:(UISearchBar *)callingSearchBar
{
	[searchBar resignFirstResponder];
}

@end
