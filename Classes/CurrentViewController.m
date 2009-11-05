//
//  CurrentViewController.m
//  dreaMote
//
//  Created by Moritz Venn on 26.10.09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "CurrentViewController.h"

#import "FuzzyDateFormatter.h"
#import "RemoteConnectorObject.h"

#import "EventTableViewCell.h"
#import "ServiceTableViewCell.h"
#import "CellTextView.h"
#import "DisplayCell.h"
#import "Constants.h"

@interface  CurrentViewController()
- (UITextView *)create_Summary: (NSObject<EventProtocol> *)event;
@end

@implementation CurrentViewController

- (id)init
{
	if (self = [super init])
	{
		self.title = NSLocalizedString(@"Currently playing", @"");
		_dateFormatter = [[FuzzyDateFormatter alloc] init];
		[_dateFormatter setDateStyle:NSDateFormatterMediumStyle];
		[_dateFormatter setTimeStyle:NSDateFormatterShortStyle];
		_now = nil;
		_next = nil;
		_service = nil;
		_currentXMLDoc = nil;
	}
	
	return self;
}

- (void)dealloc
{
	[_now release];
	[_next release];
	[_service release];
	[_dateFormatter release];
	[_currentXMLDoc release];
	[_nowSummary release];
	[_nextSummary release];

	[super dealloc];
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

- (UITextView *)create_Summary: (NSObject<EventProtocol> *)event
{
	UITextView *myTextView = [[UITextView alloc] initWithFrame:CGRectZero];
	myTextView.textColor = [UIColor blackColor];
	myTextView.font = [UIFont fontWithName:kFontName size:kTextViewFontSize];
	myTextView.editable = NO;
	myTextView.backgroundColor = [UIColor whiteColor];
	
	NSString *description = event.edescription;
	if(description != nil)
		myTextView.text = description;
	else
		myTextView.text = @"";

	return [myTextView autorelease];
}

- (void)fetchCurrent
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[_currentXMLDoc release];
	@try {
		_currentXMLDoc = [[[RemoteConnectorObject sharedRemoteConnector] getCurrent: self] retain];
	}
	@catch (NSException * e) {
		_currentXMLDoc = nil;
	}
	[pool release];
}

- (void)addService: (NSObject<ServiceProtocol> *)service
{
	if(_service != nil)
		[_service release];
	_service = [service retain];
	[(UITableView *)self.view reloadData];
}

- (void)addEvent: (NSObject<EventProtocol> *)event
{
	if(_now == nil)
	{
		_now = [event retain];
		_nowSummary = [[self create_Summary: _now] retain];
	}
	else
	{
		if(_next != nil)
			[_next release];
		_next = [event retain];
		_nextSummary = [[self create_Summary: _next] retain];
	}
	[(UITableView *)self.view reloadData];
}

#pragma mark - UITableView delegates

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	return nil;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 3;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	switch (section)
	{
		case 0:
			return NSLocalizedString(@"Service", @"");
		case 1:
			return (_now != nil) ? NSLocalizedString(@"Now", @"") : nil;
		case 2:
			return (_next != nil) ? NSLocalizedString(@"Next", @"") : nil;
		default:
			return nil;
	}
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	switch(section)
	{
		case 0:
			return 1;
		case 1:
			if(_now == nil)
				return 0;
			return 2;
		case 2:
			if(_next == nil)
				return 0;
			return 2;
		default:
			return 0;
	}
}

// to determine specific row height for each cell, override this.  In this example, each row is determined
// buy the its subviews that are embedded.
//
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	switch (indexPath.section)
	{
		case 1:
		{
			if(_now == nil)
				return 0.0;
			if(indexPath.row == 1)
				return kTextViewHeight;
			break;
		}
		case 2:
		{
			if(_next == nil)
				return 0.0;
			if(indexPath.row == 1)
				return kTextViewHeight;
		}
		case 0:
		default:
			break;
	}
	
	return kUIRowHeight;
}

// to determine which UITableViewCell to be used on a given row.
//
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSInteger section = indexPath.section;
	UITableViewCell *sourceCell = nil;

	// we are creating a new cell, setup its attributes
	switch(section)
	{
		case 0:
		{
			sourceCell = [tableView dequeueReusableCellWithIdentifier:kServiceCell_ID];
			if(sourceCell == nil)
				sourceCell = [[[ServiceTableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:kServiceCell_ID] autorelease];
			((ServiceTableViewCell *)sourceCell).service = _service;
			break;
		}
		case 1:
		{
			if(indexPath.row == 0)
			{
				sourceCell = [tableView dequeueReusableCellWithIdentifier:kEventCell_ID];
				if(sourceCell == nil)
					sourceCell = [[[EventTableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:kEventCell_ID] autorelease];
				((EventTableViewCell *)sourceCell).formatter = _dateFormatter;
				((EventTableViewCell *)sourceCell).event = _now;
				sourceCell.accessoryType = UITableViewCellAccessoryNone;
			}
			else
			{
				sourceCell = [tableView dequeueReusableCellWithIdentifier:kCellTextView_ID];
				if(sourceCell == nil)
					sourceCell = [[[CellTextView alloc] initWithFrame:CGRectZero reuseIdentifier:kCellTextView_ID] autorelease];
				
				((CellTextView *)sourceCell).view = _nowSummary;
			}
			break;
		}
		case 2:
		{
			if(indexPath.row == 0)
			{
				sourceCell = [tableView dequeueReusableCellWithIdentifier:kEventCell_ID];
				if(sourceCell == nil)
					sourceCell = [[[EventTableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:kEventCell_ID] autorelease];
				((EventTableViewCell *)sourceCell).formatter = _dateFormatter;
				((EventTableViewCell *)sourceCell).event = _next;
				sourceCell.accessoryType = UITableViewCellAccessoryNone;
			}
			else
			{
				sourceCell = [tableView dequeueReusableCellWithIdentifier:kCellTextView_ID];
				if(sourceCell == nil)
					sourceCell = [[[CellTextView alloc] initWithFrame:CGRectZero reuseIdentifier:kCellTextView_ID] autorelease];
				
				((CellTextView *)sourceCell).view = _nextSummary;
			}
			break;
		}
		default:
			break;
	}
	
	return sourceCell;
}

#pragma mark - UIViewController delegate methods

- (void)viewWillAppear:(BOOL)animated
{
	[(UITableView *)self.view reloadData];

	// Spawn a thread to fetch the event data so that the UI is not blocked while the
	// application parses the XML file.
	if([[RemoteConnectorObject sharedRemoteConnector] hasFeature: kFeaturesCurrent])
		[NSThread detachNewThreadSelector:@selector(fetchCurrent) toTarget:self withObject:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[_service release];
	_service = nil;
	[_now release];
	_now = nil;
	[_next release];
	_next = nil;
	[_currentXMLDoc release];
	_currentXMLDoc = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	// Return YES for supported orientations
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
