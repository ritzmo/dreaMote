//
//  MultiEPGListController.m
//  dreaMote
//
//  Created by Moritz Venn on 27.01.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import "MultiEPGListController.h"

#import "Constants.h"
#import "RemoteConnectorObject.h"

#import "MultiEPGTableViewCell.h"

@implementation MultiEPGListController

- (id)init
{
	if((self = [super init]))
	{
		self.title = NSLocalizedString(@"Multi EPG", @"Default title of MultiEPGListController");
		_epgCache = [EPGCache sharedInstance];
		_events = [[NSMutableDictionary alloc] init];
		_services = [[NSMutableArray alloc] init];
	}
	return self;
}

- (void)dealloc
{
	[_events release];
	[_services release];
	[_serviceXMLDocument release];

	[super dealloc];
}

/* layout */
- (void)loadView
{
	[super loadView];
	_tableView.delegate = self;
	_tableView.dataSource = self;
	_tableView.rowHeight = kMultiEPGCellHeight;
	_tableView.sectionHeaderHeight = 0;
}

- (void)fetchData
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[_serviceXMLDocument release];
	_reloading = YES;
	_serviceXMLDocument = [[RemoteConnectorObject sharedRemoteConnector] fetchServices:self bouquet:nil isRadio:NO];
	[pool release];
}

- (void)viewWillAppear:(BOOL)animated
{
	[self fetchData];
	//[_epgCache refreshBouquet:nil delegate:self isRadio:NO];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
	return YES;
}

#pragma mark -
#pragma mark DataSourceDelegate
#pragma mark -

- (void)dataSourceDelegate:(BaseXMLReader *)dataSource errorParsingDocument:(CXMLDocument *)document error:(NSError *)error
{
	// alert user
	const UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Failed to retrieve data", @"")
														  message:[error localizedDescription]
														 delegate:nil
												cancelButtonTitle:@"OK"
												otherButtonTitles:nil];
	[alert show];
	[alert release];

	[_tableView reloadData];
	_reloading = NO;
	[_refreshHeaderView egoRefreshScrollViewDataSourceDidFinishedLoading:_tableView];
}

- (void)dataSourceDelegate:(BaseXMLReader *)dataSource finishedParsingDocument:(CXMLDocument *)document
{
	if(![_events count])
	{
		NSDate *now = [NSDate dateWithTimeIntervalSinceNow:0];
		NSDate *two = [NSDate dateWithTimeIntervalSinceNow:60*60*2];
		[_epgCache readEPGForTimeIntervalFrom:now until:two to:self];
	}
	[_tableView reloadData];
	_reloading = NO;
	[_refreshHeaderView egoRefreshScrollViewDataSourceDidFinishedLoading:_tableView];
}

#pragma mark -
#pragma mark ServiceSourceDelegate
#pragma mark -

- (void)addService:(NSObject <ServiceProtocol>*)service
{
	const NSUInteger idx = _services.count;
	[_services addObject:service];
	[_tableView insertRowsAtIndexPaths: [NSArray arrayWithObject: [NSIndexPath indexPathForRow:idx inSection:0]]
					  withRowAnimation: UITableViewRowAnimationLeft];
}

#pragma mark -
#pragma mark EventSourceDelegate
#pragma mark -

- (void)addEvent:(NSObject <EventProtocol>*)event
{
	NSMutableArray *arr = [_events valueForKey:event.service.sref];
	if(arr)
	{
		[arr addObject:event];
	}
	else
	{
		arr = [[NSMutableArray alloc] initWithObjects:event, nil];
		[_events setValue:arr forKey:event.service.sref];
		[arr release];
	}
}

#pragma mark -
#pragma mark EPGCacheDelegate
#pragma mark -

- (void)finishedRefreshingCache
{
	// FIXME: implement
	NSDate *now = [NSDate dateWithTimeIntervalSinceNow:0];
	NSDate *two = [NSDate dateWithTimeIntervalSinceNow:60*60*2];
	[_epgCache readEPGForTimeIntervalFrom:now until:two to:self];
}

#pragma mark -
#pragma mark UITableViewCell
#pragma mark -

/* cell for row */
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	MultiEPGTableViewCell *cell = (MultiEPGTableViewCell*)[tableView dequeueReusableCellWithIdentifier:kMultiEPGCell_ID];
	if(cell == nil)
		cell = [[[MultiEPGTableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:kMultiEPGCell_ID] autorelease];

	NSObject<ServiceProtocol> *service = [_services objectAtIndex:indexPath.row];
	cell.service = service;
	cell.begin = [NSDate dateWithTimeIntervalSinceNow:0];
	cell.events = [_events valueForKey:service.sref];

	return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return [_services count];
}

@end
