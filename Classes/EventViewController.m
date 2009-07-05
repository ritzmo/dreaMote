//
//  EventViewController.m
//  dreaMote
//
//  Created by Moritz Venn on 09.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "EventViewController.h"

#import "TimerViewController.h"
#import "FuzzyDateFormatter.h"
#import "RemoteConnectorObject.h"

#import "EventTableViewCell.h"
#import "CellTextView.h"
#import "DisplayCell.h"
#import "Constants.h"

@implementation EventViewController

@synthesize service = _service;

- (id)init
{
	if (self = [super init])
	{
		self.title = NSLocalizedString(@"Event", @"");
		_dateFormatter = [[FuzzyDateFormatter alloc] init];
		_event = nil;
		_similarFetched = NO;
		_similarEvents = [[NSMutableArray array] retain];
		_isSearch = NO;
		_eventXMLDoc = nil;
	}
	
	return self;
}

+ (EventViewController *)withEventAndService: (NSObject<EventProtocol> *) newEvent: (NSObject<ServiceProtocol> *) newService
{
	EventViewController *eventViewController = [[EventViewController alloc] init];

	eventViewController.event = newEvent;
	eventViewController.service = newService;

	return eventViewController;
}

+ (EventViewController *)withEvent: (NSObject<EventProtocol> *) newEvent
{
	EventViewController *eventViewController = [[EventViewController alloc] init];

	eventViewController.event = newEvent;
	eventViewController.service = newEvent.service;

	return eventViewController;
}

- (void)dealloc
{
	[_event release];
	[_service release];
	[_similarEvents release];
	[_dateFormatter release];
	[_eventXMLDoc release];

	[super dealloc];
}

- (NSObject<EventProtocol> *)event
{
	return _event;
}

- (void)setEvent: (NSObject<EventProtocol> *)newEvent
{
	if(_event != newEvent)
	{
		[_event release];
		_event = [newEvent retain];
	}

	_similarFetched = NO;
	[_similarEvents removeAllObjects];

	if(newEvent != nil)
		self.title = newEvent.title;

	[(UITableView *)self.view reloadData];
	[(UITableView *)self.view scrollToRowAtIndexPath: [NSIndexPath indexPathForRow:0 inSection:0]
								atScrollPosition: UITableViewScrollPositionTop
								animated: NO];
	
	[_eventXMLDoc release];
	_eventXMLDoc = nil;
}

- (BOOL)search
{
	return _isSearch;
}

- (void)setSearch: (BOOL)newSearch
{
	BOOL oldSearch = _isSearch;
	_isSearch = newSearch;

	// reload data if value changed
	if(oldSearch != newSearch)
		[(UITableView *)self.view reloadData];
}

- (void)loadView
{
	// create and configure the table view
	UITableView *tableView = [[UITableView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame] style:UITableViewStyleGrouped];
	tableView.delegate = self;
	tableView.dataSource = self;

	// setup our content view so that it auto-rotates along with the UViewController
	tableView.autoresizesSubviews = YES;
	tableView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);

	self.view = tableView;
	[tableView release];
}

- (void)addTimer: (id)sender
{
	NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:3];
	[(UITableView *)self.view selectRowAtIndexPath: indexPath
								animated: YES
								scrollPosition: UITableViewScrollPositionNone];

	TimerViewController *targetViewController = [TimerViewController withEventAndService: _event: _service];
	[self.navigationController pushViewController: targetViewController animated: YES];
	[targetViewController release];

	[(UITableView *)self.view deselectRowAtIndexPath: indexPath animated: YES];
}

- (UITextView *)create_Summary
{
	UITextView *myTextView = [[UITextView alloc] initWithFrame:CGRectZero];
	myTextView.textColor = [UIColor blackColor];
	myTextView.font = [UIFont fontWithName:kFontName size:kTextViewFontSize];
	myTextView.editable = NO;
	myTextView.backgroundColor = [UIColor whiteColor];
	
	// We display short description (or title) and extended description (if available) in our textview
	NSMutableString *text = [[NSMutableString alloc] init];
	if([_event.sdescription length])
		[text appendString: _event.sdescription];
	else
		[text appendString: _event.title];

	if([_event.edescription length])
	{
		[text appendString: @"\n\n"];
		[text appendString: _event.edescription];
	}

	myTextView.text = text;

	[text release];

	return [myTextView autorelease];
}

- (NSString *)format_BeginEnd: (NSDate *)dateTime
{
	[_dateFormatter setDateStyle:NSDateFormatterMediumStyle];
	[_dateFormatter setTimeStyle:NSDateFormatterShortStyle];

	return [_dateFormatter stringFromDate: dateTime];
}

- (UIButton *)create_AddTimerButton
{
	UIButton *button = [UIButton buttonWithType:UIButtonTypeContactAdd];
	button.frame = CGRectMake(0.0, 0.0, 25.0, 25.0);
	[button addTarget:self action:@selector(addTimer:) forControlEvents:UIControlEventTouchUpInside];

	return button;
}

- (void)fetchEvents
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[_eventXMLDoc release];
	_eventXMLDoc = [[[RemoteConnectorObject sharedRemoteConnector] searchEPGSimilar: self event: _event] retain];
	[pool release];
}

- (void)addEvent: (NSObject<EventProtocol> *)event
{
	if(event != nil)
	{
		[_similarEvents addObject: event];
#ifdef ENABLE_LAGGY_ANIMATIONS
		[(UITableView*)self.view insertRowsAtIndexPaths: [NSArray arrayWithObject: [NSIndexPath indexPathForRow:[_events count]-1 inSection:0]]
		 withRowAnimation: UITableViewRowAnimationTop];
	}
	else
#else
	}
#endif
	[(UITableView *)self.view reloadData];
}

#pragma mark - UITableView delegates

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	// XXX: this is kinda hackish
	UITableViewCell *cell = [tableView cellForRowAtIndexPath: indexPath];
	@try {
		[((UIControl *)((DisplayCell *)cell).view) sendActionsForControlEvents: UIControlEventTouchUpInside];
	}
	@catch (NSException * e) {
		//
	}
	return nil;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	NSUInteger sections = 4;
	if([[RemoteConnectorObject sharedRemoteConnector] hasFeature: kFeaturesEPGSearchSimilar])
		++sections;
	if(_isSearch)
		++sections;

	return sections;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	if(section > 2 && !_isSearch)
		section++;
	if(section > 3 && ![[RemoteConnectorObject sharedRemoteConnector] hasFeature: kFeaturesEPGSearchSimilar])
		section++;

	switch (section) {
		case 0:
			return NSLocalizedString(@"Description", @"");
		case 1:
			return NSLocalizedString(@"Begin", @"");
		case 2:
			return NSLocalizedString(@"End", @"");
		case 3:
			return NSLocalizedString(@"Service", @"");
		case 4:
			return NSLocalizedString(@"Similar Events", @"");
		default:
			return nil;
	}
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	if(section > 2 && !_isSearch)
		section++;
	if(section == 4 && [[RemoteConnectorObject sharedRemoteConnector] hasFeature: kFeaturesEPGSearchSimilar])
	{
		NSUInteger count = [_similarEvents count];
		return count ? count : 1;
	}

	return 1;
}

// to determine specific row height for each cell, override this.  In this example, each row is determined
// buy the its subviews that are embedded.
//
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	CGFloat result;

	switch (indexPath.section)
	{
		case 0:
		{
			result = kTextViewHeight;
			break;
		}
		case 1:
		case 2:
		case 3:
		case 4:
		case 5:
		{
			result = kUIRowHeight;
			break;
		}
	}
	
	return result;
}

// to determine which UITableViewCell to be used on a given row.
//
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *kVanilla_ID = @"Vanilla_ID";

	NSInteger section = indexPath.section;
	UITableViewCell *sourceCell = nil;

	if(section > 2 && !_isSearch)
		section++;
	if(section > 3 && ![[RemoteConnectorObject sharedRemoteConnector] hasFeature: kFeaturesEPGSearchSimilar])
		section++;

	// we are creating a new cell, setup its attributes
	switch (section) {
		case 0:
			sourceCell = [tableView dequeueReusableCellWithIdentifier:kCellTextView_ID];
			if(sourceCell == nil)
				sourceCell = [[[CellTextView alloc] initWithFrame:CGRectZero reuseIdentifier:kCellTextView_ID] autorelease];
			
			((CellTextView *)sourceCell).view = [self create_Summary];
			break;
		case 1:
		case 2:
			sourceCell = [tableView dequeueReusableCellWithIdentifier: kVanilla_ID];
			if (sourceCell == nil) 
				sourceCell = [[[UITableViewCell alloc] initWithFrame: CGRectZero reuseIdentifier: kVanilla_ID] autorelease];
			
			TABLEVIEWCELL_ALIGN(sourceCell) = UITextAlignmentCenter;
			TABLEVIEWCELL_COLOR(sourceCell) = [UIColor blackColor];
			TABLEVIEWCELL_FONT(sourceCell) = [UIFont systemFontOfSize:kTextViewFontSize];
			sourceCell.selectionStyle = UITableViewCellSelectionStyleNone;
			sourceCell.indentationLevel = 1;

			if(section == 1)
				TABLEVIEWCELL_TEXT(sourceCell) = [self format_BeginEnd: _event.begin];
			 else
				TABLEVIEWCELL_TEXT(sourceCell) = [self format_BeginEnd: _event.end];
			break;
		case 3:
			sourceCell = [tableView dequeueReusableCellWithIdentifier: kVanilla_ID];
			if (sourceCell == nil) 
				sourceCell = [[[UITableViewCell alloc] initWithFrame: CGRectZero reuseIdentifier: kVanilla_ID] autorelease];

			TABLEVIEWCELL_ALIGN(sourceCell) = UITextAlignmentCenter;
			TABLEVIEWCELL_COLOR(sourceCell) = [UIColor blackColor];
			TABLEVIEWCELL_FONT(sourceCell) = [UIFont systemFontOfSize:kTextViewFontSize];
			sourceCell.selectionStyle = UITableViewCellSelectionStyleNone;
			sourceCell.indentationLevel = 1;
			TABLEVIEWCELL_TEXT(sourceCell) = _event.service.sname;
				
			break;
		case 4:
			if(![_similarEvents count])
			{
				sourceCell = [tableView dequeueReusableCellWithIdentifier: kVanilla_ID];
				if (sourceCell == nil) 
					sourceCell = [[[UITableViewCell alloc] initWithFrame: CGRectZero reuseIdentifier: kVanilla_ID] autorelease];

				TABLEVIEWCELL_ALIGN(sourceCell) = UITextAlignmentCenter;
				TABLEVIEWCELL_COLOR(sourceCell) = [UIColor blackColor];
				TABLEVIEWCELL_FONT(sourceCell) = [UIFont systemFontOfSize:kTextViewFontSize];
				sourceCell.selectionStyle = UITableViewCellSelectionStyleNone;
				sourceCell.indentationLevel = 1;
				TABLEVIEWCELL_TEXT(sourceCell) = NSLocalizedString(@"No similar Events", @"");
			}
			else
			{
				sourceCell = [tableView dequeueReusableCellWithIdentifier:kEventCell_ID];
				if(sourceCell == nil)
					sourceCell = [[[EventTableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:kEventCell_ID] autorelease];

				sourceCell.accessoryType = UITableViewCellAccessoryNone;
				((EventTableViewCell*)sourceCell).formatter = _dateFormatter;
				((EventTableViewCell*)sourceCell).showService = YES;
				((EventTableViewCell*)sourceCell).event = (NSObject<EventProtocol> *)[_similarEvents objectAtIndex: indexPath.row];
			}
			break;
		case 5:
			sourceCell = [tableView dequeueReusableCellWithIdentifier:kDisplayCell_ID];
			if(sourceCell == nil)
				sourceCell = [[[DisplayCell alloc] initWithFrame:CGRectZero reuseIdentifier:kDisplayCell_ID] autorelease];

			((DisplayCell *)sourceCell).nameLabel.text = NSLocalizedString(@"Add Timer", @"");
			((DisplayCell *)sourceCell).view = [self create_AddTimerButton];
		default:
			break;
	}
	
	return sourceCell;
}

#pragma mark - UIViewController delegate methods

- (void)viewWillAppear:(BOOL)animated
{
	if(_similarFetched == NO)
	{
		// Spawn a thread to fetch the event data so that the UI is not blocked while the
		// application parses the XML file.
		if([[RemoteConnectorObject sharedRemoteConnector] hasFeature: kFeaturesEPGSearchSimilar])
			[NSThread detachNewThreadSelector:@selector(fetchEvents) toTarget:self withObject:nil];

		_similarFetched = YES;
	}
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	// Return YES for supported orientations
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
