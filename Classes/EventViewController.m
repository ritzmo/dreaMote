//
//  EventViewController.m
//  dreaMote
//
//  Created by Moritz Venn on 09.03.08.
//  Copyright 2008-2011 Moritz Venn. All rights reserved.
//

#import "EventViewController.h"

#import "TimerViewController.h"
#import "RemoteConnectorObject.h"

#import "NSDateFormatter+FuzzyFormatting.h"
#import "NSString+URLEncode.h"

#import "EventTableViewCell.h"
#import "CellTextView.h"
#import "DisplayCell.h"
#import "Constants.h"

@interface EventViewController()
- (UITextView *)create_Summary;
- (UIButton *)createButtonForSelector:(SEL)selector withType:(UIButtonType)type;
/*!
 @brief initiate zap
 @param sender ui element
 */
- (void)zapAction:(id)sender;
@property (nonatomic, retain) UIPopoverController *popoverController;
@end

@interface EventViewController(IMDb)
- (void)openIMDb:(id)sender;
@end

@implementation EventViewController

@synthesize popoverController;
@synthesize service = _service;

- (id)init
{
	if((self = [super init]))
	{
		self.title = NSLocalizedString(@"Event", @"");
		_dateFormatter = [[NSDateFormatter alloc] init];
		_event = nil;
		_similarFetched = NO;
		_similarEvents = [[NSMutableArray array] retain];
		_isSearch = NO;
		_eventXMLDoc = nil;
		self.hidesBottomBarWhenPushed = YES;

		if([self respondsToSelector:@selector(modalPresentationStyle)])
		{
			self.modalPresentationStyle = UIModalPresentationFormSheet;
			self.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
		}
	}
	
	return self;
}

+ (EventViewController *)withEventAndService: (NSObject<EventProtocol> *) newEvent: (NSObject<ServiceProtocol> *) newService
{
	EventViewController *eventViewController = [[EventViewController alloc] init];

	eventViewController.event = newEvent;
	eventViewController.service = newService;

	return [eventViewController autorelease];
}

+ (EventViewController *)withEvent: (NSObject<EventProtocol> *) newEvent
{
	EventViewController *eventViewController = [[EventViewController alloc] init];

	eventViewController.event = newEvent;
	eventViewController.service = newEvent.service;

	return [eventViewController autorelease];
}

- (void)dealloc
{
	[_event release];
	[_service release];
	[_similarEvents release];
	[_dateFormatter release];
	[_eventXMLDoc release];
	[_summaryView release];

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
	[_summaryView release];
	_summaryView = [[self create_Summary] retain];

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
	const BOOL oldSearch = _isSearch;
	_isSearch = newSearch;

	// reload data if value changed
	if(oldSearch != newSearch)
		[(UITableView *)self.view reloadData];
}

- (void)loadView
{
	// create and configure the table view
	UITableView *tableView = [[SwipeTableView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame] style:UITableViewStyleGrouped];
	tableView.delegate = self;
	tableView.dataSource = self;

	// setup our content view so that it auto-rotates along with the UViewController
	tableView.autoresizesSubviews = YES;
	tableView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);

	self.view = tableView;
	[tableView release];

	// Create zap button
	UIBarButtonItem *zapButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Zap", @"") style:UIBarButtonItemStylePlain target:self action:@selector(zapAction:)];
	self.navigationItem.rightBarButtonItem = zapButton;
	[zapButton release];
}

- (void)addTimer: (id)sender
{
	NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:3];
	[(UITableView *)self.view selectRowAtIndexPath: indexPath
								animated: YES
								scrollPosition: UITableViewScrollPositionNone];

	TimerViewController *targetViewController = [TimerViewController newWithEventAndService: _event: _service];
	[self.navigationController pushViewController: targetViewController animated: YES];
	[targetViewController release];

	[(UITableView *)self.view deselectRowAtIndexPath: indexPath animated: YES];
}

- (UITextView *)create_Summary
{
	UITextView *myTextView = [[UITextView alloc] initWithFrame:CGRectZero];
	myTextView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
	myTextView.textColor = [UIColor blackColor];
	myTextView.font = [UIFont fontWithName:kFontName size:kTextViewFontSize];
	myTextView.editable = NO;
	
	// We display short description (or title) and extended description (if available) in our textview
	NSMutableString *text = [[NSMutableString alloc] init];
	NSString *description = _event.sdescription;
	if([description length])
		[text appendString: description];
	else
		[text appendString: _event.title];

	description = _event.edescription;
	if([description length])
	{
		[text appendString: @"\n\n"];
		[text appendString: description];
	}

	myTextView.text = text;

	[text release];

	return [myTextView autorelease];
}

- (NSString *)format_BeginEnd: (NSDate *)dateTime
{
	[_dateFormatter setDateStyle:NSDateFormatterFullStyle];
	[_dateFormatter setTimeStyle:NSDateFormatterShortStyle];
	return [_dateFormatter fuzzyDate: dateTime];
}

- (UIButton *)createButtonForSelector:(SEL)selector withType:(UIButtonType)type
{
	UIButton *button = [UIButton buttonWithType:type];
	button.frame = CGRectMake(0, 0, 25, 25);
	[button addTarget:self action:selector forControlEvents:UIControlEventTouchUpInside];

	return button;
}

- (void)fetchEvents
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[_eventXMLDoc release];
	@try {
		_eventXMLDoc = [[[RemoteConnectorObject sharedRemoteConnector] searchEPGSimilar: self event: _event] retain];
	}
	@catch (NSException * e) {
		_eventXMLDoc = nil;
	}
	[pool release];
}

- (void)doZap:(id)sender
{
	[[RemoteConnectorObject sharedRemoteConnector] zapTo:_service];
}

#pragma mark -
#pragma mark DataSourceDelegate
#pragma mark -

- (void)dataSourceDelegate:(BaseXMLReader *)dataSource errorParsingDocument:(CXMLDocument *)document error:(NSError *)error
{
	// ignore error
}

- (void)dataSourceDelegate:(BaseXMLReader *)dataSource finishedParsingDocument:(CXMLDocument *)document
{
	//[(UITableView*)self.view reloadData];
}

#pragma mark -
#pragma mark EventSourceDelegate
#pragma mark -

- (void)addEvent: (NSObject<EventProtocol> *)event
{
	[_similarEvents addObject: event];
	[(UITableView*)self.view reloadData];
}

#pragma mark -
#pragma mark SwipeTableViewDelegate
#pragma mark -
#if IS_FULL()

- (void)tableView:(SwipeTableView *)tableView didSwipeRowAtIndexPath:(NSIndexPath *)indexPath
{
	/*!
	 @note the way we handle swipes leads to unintuitive results
	 for searches, so just do nothing instead
	 */
	if(_isSearch) return;

	//if(tableView.lastSwipe & twoFingers)
	{
		NSObject<EventProtocol> *newEvent = nil;
		if(tableView.lastSwipe & swipeTypeLeft)
			newEvent = [[EPGCache sharedInstance] getPreviousEvent:_event onService:_service];
		else // if(tableView.lastSwipe & swipeTypeRight)
			newEvent = [[EPGCache sharedInstance] getNextEvent:_event onService:_service];

		if(newEvent)
			self.event = newEvent;
		else
		{
			const UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"No events found", @"Title of message when trying to select next/previous event by swiping but cache did not return results.")
																  message:NSLocalizedString(@"A search did not return any event.\nTry refreshing the cache by reloading the event list for this service.", @"")
																 delegate:nil
														cancelButtonTitle:@"OK"
														otherButtonTitles:nil];
			[alert show];
			[alert release];
		}
	}
}

#endif
#pragma mark - UITableView delegates

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
#if 0
	NSInteger section = indexPath.section;
	if(section > 2 && !_isSearch)
		section++;
	if(section == 4 && [[RemoteConnectorObject sharedRemoteConnector] hasFeature: kFeaturesEPGSearchSimilar])
	{
		if([_similarEvents count])
		{
			self.event = [_similarEvents objectAtIndex:indexPath.row];

			// override local service if event has one
			if(_event.service != nil)
				self.service = _event.service;
			[NSThread detachNewThreadSelector:@selector(fetchEvents) toTarget:self withObject:nil];

			// XXX: animated reload looks weird
			[(UITableView *)self.view reloadData];
		}
	}
	else
#endif
	{
		const UITableViewCell *cell = [tableView cellForRowAtIndexPath: indexPath];
		if([cell respondsToSelector: @selector(view)]
		   && [((DisplayCell *)cell).view respondsToSelector:@selector(sendActionsForControlEvents:)])
		{
			[(UIButton *)((DisplayCell *)cell).view sendActionsForControlEvents: UIControlEventTouchUpInside];
		}
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
		const NSUInteger count = [_similarEvents count];
		return count ? count : 1;
	}
	else if(section == 5)
	{
		NSUInteger rows = 2;
		if([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"imdb:///"]])
			++rows;

		return rows;
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
		default:
		{
			result = kUIRowHeight;
		}
	}
	
	return result;
}

// to determine which UITableViewCell to be used on a given row.
//
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
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

			((CellTextView *)sourceCell).view = _summaryView;
			_summaryView.backgroundColor = sourceCell.backgroundColor;
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
			sourceCell.indentationLevel = 0;
			sourceCell.textLabel.adjustsFontSizeToFitWidth = YES;

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
		{
			NSInteger row = indexPath.row;
			sourceCell = [tableView dequeueReusableCellWithIdentifier:kDisplayCell_ID];
			if(sourceCell == nil)
				sourceCell = [[[DisplayCell alloc] initWithFrame:CGRectZero reuseIdentifier:kDisplayCell_ID] autorelease];

			if(![[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"imdb:///"]] && row > 0)
				++row;

			switch(row)
			{
				default:
				case 0:
					((DisplayCell *)sourceCell).nameLabel.text = NSLocalizedString(@"Add Timer", @"");
					((DisplayCell *)sourceCell).view = [self createButtonForSelector:@selector(addTimer:) withType:UIButtonTypeContactAdd];
					break;
				case 1:
					((DisplayCell *)sourceCell).nameLabel.text = NSLocalizedString(@"Zap on receiver", @"");
					((DisplayCell *)sourceCell).view = [self createButtonForSelector:@selector(doZap:) withType:UIButtonTypeCustom];
					break;
				case 2:
					((DisplayCell *)sourceCell).nameLabel.text = NSLocalizedString(@"IMDb", @"");
					((DisplayCell *)sourceCell).view = [self createButtonForSelector:@selector(openIMDb:) withType:UIButtonTypeCustom];
					break;
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
	if(_similarFetched == NO)
	{
		// Spawn a thread to fetch the event data so that the UI is not blocked while the
		// application parses the XML file.
		if([[RemoteConnectorObject sharedRemoteConnector] hasFeature: kFeaturesEPGSearchSimilar])
		{
			// if there is no service yet, try to assign local one
			if(_event.service == nil)
				_event.service = _service;
			[NSThread detachNewThreadSelector:@selector(fetchEvents) toTarget:self withObject:nil];
		}

		_similarFetched = YES;
	}
}

/* rotate with device */
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

#pragma mark IMDb

- (void)openIMDb:(id)sender
{
	NSString *encoded = [_event.title urlencode];
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"imdb:///find?q=%@", encoded]];

	[[UIApplication sharedApplication] openURL:url];
}

# pragma mark Zapping

/* zap */
- (void)zapAction:(id)sender
{
	// if streaming supported, show popover on ipad and action sheet on iphone
	if([[RemoteConnectorObject sharedRemoteConnector] hasFeature:kFeaturesStreaming])
	{
		if(IS_IPAD())
		{
			// hide popover if already visible
			if([popoverController isPopoverVisible])
			{
				[popoverController dismissPopoverAnimated:YES];
				self.popoverController = nil;
				return;
			}

			ServiceZapListController *zlc = [[ServiceZapListController alloc] init];
			zlc.zapDelegate = self;
			[popoverController release];
			popoverController = [[UIPopoverController alloc] initWithContentViewController:zlc];
			[zlc release];

			[popoverController presentPopoverFromBarButtonItem:sender
									  permittedArrowDirections:UIPopoverArrowDirectionUp
													  animated:YES];
		}
		else
		{
			const UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Select type of zap", @"")
																		   delegate:self
																  cancelButtonTitle:nil
															 destructiveButtonTitle:nil
																  otherButtonTitles:nil];
			[actionSheet addButtonWithTitle:NSLocalizedString(@"Zap on receiver", @"")];
			if([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"oplayer:///"]])
				[actionSheet addButtonWithTitle:@"OPlayer"];
			if([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"oplayerlite:///"]])
				[actionSheet addButtonWithTitle:@"OPlayer Lite"];
			if([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"buzzplayer:///"]])
				[actionSheet addButtonWithTitle:@"BUZZ Player"];
			if([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"yxp:///"]])
				[actionSheet addButtonWithTitle:@"yxplayer"];

			actionSheet.cancelButtonIndex = [actionSheet addButtonWithTitle:NSLocalizedString(@"Cancel", @"")];
			[actionSheet showFromTabBar:self.tabBarController.tabBar];
			[actionSheet release];
		}
	}
	// else just zap on remote host
	else
	{
		[[RemoteConnectorObject sharedRemoteConnector] zapTo: _service];
	}
}

#pragma mark -
#pragma mark ServiceZapListDelegate methods
#pragma mark -

- (void)serviceZapListController:(ServiceZapListController *)zapListController selectedAction:(zapAction)selectedAction
{
	NSURL *streamingURL = nil;
	NSURL *url = nil;

	if(selectedAction == zapActionRemote)
	{
		[[RemoteConnectorObject sharedRemoteConnector] zapTo: _service];
		return;
	}
	streamingURL = [[RemoteConnectorObject sharedRemoteConnector] getStreamURLForService:_service];

	switch(selectedAction)
	{
		default: break;
		case zapActionOPlayer:
			url = [NSURL URLWithString:[NSString stringWithFormat:@"oplayer://%@", [streamingURL absoluteURL]]];
			break;
		case zapActionOPlayerLite:
			url = [NSURL URLWithString:[NSString stringWithFormat:@"oplayerlite://%@", [streamingURL absoluteURL]]];
			break;
		case zapActionBuzzPlayer:
			url = [NSURL URLWithString:[NSString stringWithFormat:@"buzzplayer://%@", [streamingURL absoluteURL]]];
			break;
		case zapActionYxplayer:
			url = [NSURL URLWithString:[NSString stringWithFormat:@"yxp://%@", [streamingURL absoluteURL]]];
			break;
	}
	if(url)
		[[UIApplication sharedApplication] openURL:url];
}

#pragma mark -
#pragma mark UIActionSheetDelegate methods
#pragma mark -

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if(buttonIndex == actionSheet.cancelButtonIndex)
	{
		// do nothing
	}
	else
	{
		buttonIndex = 1;
		//if([[RemoteConnectorObject sharedRemoteConnector] hasFeature:kFeaturesStreaming])
		{
			if(![[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"oplayer:///"]] && buttonIndex > 0)
				++buttonIndex;
			if(![[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"oplayerlite:///"]] && buttonIndex > 1)
				++buttonIndex;
			if(![[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"buzzplayer:///"]] && buttonIndex > 2)
				++buttonIndex;
			//if(![[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"yxp:///"]] && buttonIndex > 3)
			//	++buttonIndex;
		}
		[self serviceZapListController:nil selectedAction:(zapAction)buttonIndex];
	}
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

@end
