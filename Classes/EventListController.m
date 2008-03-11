//
//  EventListController.m
//  Untitled
//
//  Created by Moritz Venn on 09.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "EventListController.h"

#import "EventTableViewCell.h"
#import "EventViewController.h"
#import "AppDelegateMethods.h"
#import "Event.h"

@implementation EventListController

@synthesize events = _events;

- (id)init
{
    self = [super init];
    if (self) {
        self.title = NSLocalizedString(@"Events", @"");
		self.events = [NSMutableArray array];
    }
    return self;
}

+ (EventListController*)withEventList: (NSArray*) eventList
{
	EventListController *eventListController = [[EventListController alloc] init];
	eventListController.events = [NSMutableArray arrayWithArray: eventList];

	// XXX: we might want to replace title with our service (if one is provided or we add sref/sname to event)

	return eventListController;
}

- (void)dealloc
{
	[_events release];
	
	[super dealloc];
}

- (void)loadView
{
    UITableView *tableView = [[UITableView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame] style:UITableViewStylePlain];
    tableView.delegate = self;
	tableView.dataSource = self;
	tableView.rowHeight = 48.0;
	tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
	tableView.sectionHeaderHeight = 0;
	
	self.view = tableView;
	[tableView release];
}

- (void)reloadData
{
	[(UITableView *)self.view reloadData];
}

#pragma mark	-
#pragma mark		Table View
#pragma mark	-

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath withAvailableCell:(UITableViewCell *)availableCell {
	EventTableViewCell *cell = nil;
	if (availableCell != nil) {
		cell = (EventTableViewCell *)availableCell;
	} else {
		CGSize size = CGSizeMake(300, 36);
		CGRect cellFrame = CGRectMake(0,0,size.width,size.height);
		cell = [[[EventTableViewCell alloc] initWithFrame:cellFrame] autorelease];
	}

	Event *eventForRow = [self.events objectAtIndex:indexPath.row];
	cell.event = eventForRow;
	
	return cell;
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	id applicationDelegate = [[UIApplication sharedApplication] delegate];

	Event *event = [(EventTableViewCell *)[(UITableView*)self.view cellForRowAtIndexPath: indexPath] event];
	EventViewController *eventViewController = [EventViewController withEvent: event];
	[[applicationDelegate navigationController] pushViewController: eventViewController animated: YES];

	//[eventViewController release];

	return nil;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView 
{
	// TODO: handle seperators?
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
	return [self.events count];
}

@end