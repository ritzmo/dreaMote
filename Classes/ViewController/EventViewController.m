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
#import "UITableViewCell+EasyInit.h"

#import "EventTableViewCell.h"
#import "CellTextView.h"
#import "DisplayCell.h"
#import "Constants.h"

#import <XMLReader/BaseXMLReader.h>

#if IS_FULL()
	#import "AutoTimerViewController.h"
#endif

#import "SHK.h"

@interface EventViewController()
- (UITextView *)create_Summary;
- (UIButton *)createButtonForSelector:(SEL)selector withType:(UIButtonType)type;
/*!
 @brief initiate zap
 @param sender ui element
 */
- (void)zapAction:(id)sender;
@property (nonatomic, strong) UIPopoverController *popoverController;
@end

@interface EventViewController(IMDb)
- (void)openIMDb:(id)sender;
@end

@interface EventViewController(Sharing)
- (void)share:(id)sender;
@end

@interface EventViewController(Calendar)
- (void)openCalendarEditor:(id)sender;
@end

#if IS_FULL()
@interface EventViewController(AutoTimer)
- (void)addAutoTimer:(id)sender;
@end
#endif

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
		_similarEvents = [NSMutableArray array];
		_isSearch = NO;
		_xmlReader = nil;
		self.hidesBottomBarWhenPushed = YES;

		if([self respondsToSelector:@selector(modalPresentationStyle)])
		{
			self.modalPresentationStyle = UIModalPresentationFormSheet;
			self.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
		}
	}
	
	return self;
}

- (void)dealloc
{
	[self stopObservingThemeChanges];
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


- (NSObject<EventProtocol> *)event
{
	return _event;
}

- (void)setEvent: (NSObject<EventProtocol> *)newEvent
{
	if(_event != newEvent)
		_event = newEvent;

	_similarFetched = NO;
	[_similarEvents removeAllObjects];
	_summaryView = [self create_Summary];

	if(newEvent != nil)
		self.title = newEvent.title;

	[(UITableView *)self.view reloadData];
	[(UITableView *)self.view scrollToRowAtIndexPath: [NSIndexPath indexPathForRow:0 inSection:0]
								atScrollPosition: UITableViewScrollPositionTop
								animated: NO];
	
	_xmlReader = nil;
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

	// Create zap button
	UIBarButtonItem *zapButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Zap", @"") style:UIBarButtonItemStylePlain target:self action:@selector(zapAction:)];
	self.navigationItem.rightBarButtonItem = zapButton;

	[self theme];
}

- (void)viewDidLoad
{
	[self startObservingThemeChanges];
	[super viewDidLoad];
}

- (void)viewDidUnload
{
	[self stopObservingThemeChanges];
	[super viewDidUnload];
}

- (void)addTimer: (id)sender
{
	NSUInteger section = 3;
	if([[RemoteConnectorObject sharedRemoteConnector] hasFeature: kFeaturesEPGSearchSimilar])
		++section;
	if(_isSearch)
		++section;
	NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:section];

	[(UITableView *)self.view selectRowAtIndexPath: indexPath
								animated: YES
								scrollPosition: UITableViewScrollPositionNone];

	TimerViewController *targetViewController = [TimerViewController newWithEventAndService: _event: _service];
	[self.navigationController pushViewController: targetViewController animated: YES];

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


	return myTextView;
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
	BaseXMLReader *newReader = nil;
	@try {
		newReader = [[RemoteConnectorObject sharedRemoteConnector] searchEPGSimilar:self event:_event];
	}
	@catch (NSException * e) {
#if IS_DEBUG()
		[e raise];
#endif
	}
	_xmlReader = newReader;
}

#pragma mark -
#pragma mark DataSourceDelegate
#pragma mark -

- (void)dataSourceDelegate:(BaseXMLReader *)dataSource errorParsingDocument:(NSError *)error
{
	// ignore error
}

- (void)dataSourceDelegateFinishedParsingDocument:(BaseXMLReader *)dataSource
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
		if(tableView.lastSwipe & swipeTypeRight)
			newEvent = [[EPGCache sharedInstance] getPreviousEvent:_event onService:_service];
		else // if(tableView.lastSwipe & swipeTypeLeft)
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
		}
	}
}

#endif
#pragma mark - UITableView delegates

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
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
			[RemoteConnectorObject queueInvocationWithTarget:self selector:@selector(fetchEvents)];

			// XXX: animated reload looks weird
			[(UITableView *)self.view reloadData];
		}
	}
	else
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
		NSUInteger rows = 3;
		if([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"imdb:///"]])
			++rows;
#if IS_FULL()
		if([[RemoteConnectorObject sharedRemoteConnector] hasFeature: kFeaturesAutoTimer])
			++rows;
#endif

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
			sourceCell = [CellTextView reusableTableViewCellInView:tableView withIdentifier:kCellTextView_ID];

			((CellTextView *)sourceCell).view = _summaryView;
			_summaryView.backgroundColor = sourceCell.backgroundColor;
			break;
		case 1:
		case 2:
			sourceCell = [UITableViewCell reusableTableViewCellInView:tableView withIdentifier:kVanilla_ID];
			
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
			sourceCell = [UITableViewCell reusableTableViewCellInView:tableView withIdentifier:kVanilla_ID];

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
				sourceCell = [UITableViewCell reusableTableViewCellInView:tableView withIdentifier:kVanilla_ID];

				TABLEVIEWCELL_ALIGN(sourceCell) = UITextAlignmentCenter;
				TABLEVIEWCELL_COLOR(sourceCell) = [UIColor blackColor];
				TABLEVIEWCELL_FONT(sourceCell) = [UIFont systemFontOfSize:kTextViewFontSize];
				sourceCell.selectionStyle = UITableViewCellSelectionStyleNone;
				sourceCell.indentationLevel = 1;
				TABLEVIEWCELL_TEXT(sourceCell) = NSLocalizedString(@"No similar Events", @"");
			}
			else
			{
				sourceCell = [EventTableViewCell reusableTableViewCellInView:tableView withIdentifier:kEventCell_ID];

				sourceCell.accessoryType = UITableViewCellAccessoryNone;
				((EventTableViewCell*)sourceCell).formatter = _dateFormatter;
				((EventTableViewCell*)sourceCell).showService = YES;
				((EventTableViewCell*)sourceCell).event = (NSObject<EventProtocol> *)[_similarEvents objectAtIndex: indexPath.row];
			}
			break;
		case 5:
		{
			NSInteger row = indexPath.row;
			sourceCell = [DisplayCell reusableTableViewCellInView:tableView withIdentifier:kDisplayCell_ID];

#if IS_FULL()
			if(![[RemoteConnectorObject sharedRemoteConnector] hasFeature: kFeaturesAutoTimer] && row > 0)
				++row;
#else
			if(row > 0)
				++row;
#endif
			if(![[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"imdb:///"]] && row > 1)
				++row;

			switch(row)
			{
				default:
				case 0:
					((DisplayCell *)sourceCell).nameLabel.text = NSLocalizedString(@"Add Timer", @"");
					((DisplayCell *)sourceCell).view = [self createButtonForSelector:@selector(addTimer:) withType:UIButtonTypeContactAdd];
					break;
#if IS_FULL()
				case 1:
					((DisplayCell *)sourceCell).nameLabel.text = NSLocalizedString(@"Add AutoTimer", @"Add new AutoTimer based on this event");
					((DisplayCell *)sourceCell).view = [self createButtonForSelector:@selector(addAutoTimer:) withType:UIButtonTypeCustom];
					break;
#endif
				case 2:
					((DisplayCell *)sourceCell).nameLabel.text = NSLocalizedString(@"IMDb", @"");
					((DisplayCell *)sourceCell).view = [self createButtonForSelector:@selector(openIMDb:) withType:UIButtonTypeCustom];
					break;
				case 3:
					((DisplayCell *)sourceCell).nameLabel.text = NSLocalizedString(@"Share", @"");
					((DisplayCell *)sourceCell).view = [self createButtonForSelector:@selector(share:) withType:UIButtonTypeCustom];
					break;
				case 4:
					((DisplayCell *)sourceCell).nameLabel.text = NSLocalizedString(@"Add to calendar", @"Create calendar entry for this event");
					((DisplayCell *)sourceCell).view = [self createButtonForSelector:@selector(openCalendarEditor:) withType:UIButtonTypeCustom];
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
			[RemoteConnectorObject queueInvocationWithTarget:self selector:@selector(fetchEvents)];
		}

		_similarFetched = YES;
	}
}

/* about to disappear */
- (void)viewWillDisappear:(BOOL)animated
{
	// eventually remove popover
	if(popoverController)
	{
		[popoverController dismissPopoverAnimated:animated];
		self.popoverController = nil;
	}
	[super viewWillDisappear:animated];
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

#pragma mark Sharing

- (void)share:(id)sender
{
	SHKItem *item = [SHKItem text:[NSString stringWithFormat:NSLocalizedString(@"Hey, check out %@ on %@. %@", @"Default sharing string for events"), _event.title, _event.service.sname, [self format_BeginEnd:_event.begin]]];
	if(!_summaryView)
		_summaryView = [self create_Summary];
	[item setAlternateText:[[item text] stringByAppendingFormat:@" <br/><br/>%@", _summaryView.text] toShareOn:@"Email"];
	SHKActionSheet *actionSheet = [SHKActionSheet actionSheetForItem:item];

	[actionSheet showInView:self.view];
}

#pragma mark Calendar

- (void)openCalendarEditor:(id)sender
{
	EKEventStore *eventDB = [[EKEventStore alloc] init];
	EKEvent *myEvent  = [EKEvent eventWithEventStore:eventDB];
	myEvent.title = _event.title;
	myEvent.startDate = _event.begin;
	myEvent.endDate = _event.end;
	myEvent.allDay = NO;
	[myEvent setCalendar:[eventDB defaultCalendarForNewEvents]];

	EKEventEditViewController* controller = [[EKEventEditViewController alloc] init];
	controller.eventStore = eventDB;
	controller.event = myEvent;
	controller.editViewDelegate = self;
	controller.modalPresentationStyle = UIModalPresentationFormSheet;
	controller.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
	[self presentModalViewController:controller animated:YES];

}

- (void)eventEditViewController:(EKEventEditViewController *)controller didCompleteWithAction:(EKEventEditViewAction)action
{
#if IS_DEBUG()
	NSLog(@"editing completed with action: %d", action);
#endif
	[self dismissModalViewControllerAnimated:YES];
}

#pragma mark AutoTimer
#if IS_FULL()

- (void)addAutoTimer:(id)sender
{
	AutoTimerViewController *avc = [[AutoTimerViewController alloc] init];
	avc.timer = [AutoTimer timerFromEvent:_event];
	// NOTE: no need to set the delegate

	[self.navigationController pushViewController:avc animated:YES];
	// NOTE: set this here so the edit button won't get screwed
	avc.creatingNewTimer = YES;

}

#endif
# pragma mark Zapping

/* zap */
- (void)zapAction:(id)sender
{
	// if streaming supported, show popover on ipad and action sheet on iphone
	if([ServiceZapListController canStream])
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
			popoverController = [[UIPopoverController alloc] initWithContentViewController:zlc];

			[popoverController presentPopoverFromBarButtonItem:sender
									  permittedArrowDirections:UIPopoverArrowDirectionUp
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
		[[RemoteConnectorObject sharedRemoteConnector] zapTo: _service];
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
