//
//  AutoTimerViewController.m
//  dreaMote
//
//  Created by Moritz Venn on 15.04.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import "AutoTimerViewController.h"

#import "BouquetListController.h"
#import "ServiceListController.h"
#import "DatePickerController.h"

#import "RemoteConnectorObject.h"
#import "Constants.h"

#import "CellTextField.h"
#import "DisplayCell.h"
#import "ServiceTableViewCell.h"

#import "NSDateFormatter+FuzzyFormatting.h"
#import "UITableViewCell+EasyInit.h"

#import "Objects/Generic/Result.h"
#import "Objects/Generic/Service.h"
#import "Objects/Generic/AutoTimer.h"

enum sectionIds
{
	titleSection = 0,
	matchSection = 1,
	generalSection = 2,
	timespanSection = 3,
	timeframeSection = 4,
	durationSection = 5,
	servicesSection = 6,
	bouquetSection = 7,
	aftereventSection = 8,
	locationSection = 9,
	filterTitleSection = 10,
	filterSdescSection = 11,
	filterDescSection = 12,
	filterWeekdaySection = 13,
	maxSection = 14,
};

/*!
 @brief Private functions of AutoTimerViewController.
 */
@interface AutoTimerViewController()
/*!
 @brief stop editing
 @param sender ui element
 */
- (void)cancelEdit:(id)sender;

/*!
 @brief Toggle visibility of rows
 @param sender ui element
 */
- (void)showHideDetails:(id)sender;

@property (nonatomic, retain) UIPopoverController *popoverController;
@property (nonatomic, readonly) AfterEventViewController *afterEventViewController;
@property (nonatomic, readonly) UIViewController *afterEventNavigationController;
@property (nonatomic, readonly) UIViewController *bouquetListController;
@property (nonatomic, readonly) UINavigationController *filterNavigationController;
@property (nonatomic, readonly) AutoTimerFilterViewController *filterViewController;
@property (nonatomic, readonly) UIViewController *serviceListController;
@property (nonatomic, readonly) DatePickerController *datePickerController;
@property (nonatomic, readonly) UIViewController *datePickerNavigationController;
@property (nonatomic, readonly) UIViewController *locationListController;
@end

@implementation AutoTimerViewController

@synthesize delegate = _delegate;
@synthesize popoverController;

- (id)init
{
	if((self = [super init]))
	{
		self.title = NSLocalizedString(@"AutoTimer", @"Default title of AutoTimerViewController");

		_dateFormatter = [[NSDateFormatter alloc] init];
		_creatingNewTimer = NO;
		_bouquetListController = nil;
		_datePickerController = nil;
		_afterEventViewController = nil;
		_popoverButtonItem = nil;
	}
	return self;
}

+ (AutoTimerViewController *)newWithAutoTimer:(AutoTimer *)ourTimer
{
	AutoTimerViewController *autoTimerViewController = [[AutoTimerViewController alloc] init];
	autoTimerViewController.timer = ourTimer;
	autoTimerViewController.creatingNewTimer = NO;

	return autoTimerViewController;
}

+ (AutoTimerViewController *)newAutoTimer
{
	AutoTimerViewController *autoTimerViewController = [[AutoTimerViewController alloc] init];
	AutoTimer *newTimer = [AutoTimer timer];
	autoTimerViewController.timer = newTimer;
	autoTimerViewController.creatingNewTimer = YES;

	return autoTimerViewController;
}

- (void)dealloc
{
	[_timer release];
	[_dateFormatter release];
	[_delegate release];

	[_titleField release];
	[_matchField release];
	[_maxdurationField release];
	[_timerEnabled release];
	[_exactSearch release];
	[_sensitiveSearch release];
	[_overrideAlternatives release];
	[_timeframeSwitch release];
	[_timerJustplay release];
	[_timespanSwitch release];
	[_avoidDuplicateDescription release];

	[_titleCell release];
	[_matchCell release];
	[_maxdurationCell release];

	[_cancelButtonItem release];
	[_popoverButtonItem release];
	[popoverController release];

	[_afterEventNavigationController release];
	[_afterEventViewController release];
	[_bouquetListController release];
	[_serviceListController release];
	[_datePickerController release];
	[_datePickerNavigationController release];
	[_locationListController release];
	[_filterViewController release];
	[_filterNavigationController release];

	[super dealloc];
}

- (void)didReceiveMemoryWarning
{
	[_afterEventNavigationController release];
	[_afterEventViewController release];
	[_bouquetListController release];
	[_serviceListController release];
	[_datePickerController release];
	[_datePickerNavigationController release];
	[_locationListController release];
	[_filterViewController release];
	[_filterNavigationController release];

	_afterEventNavigationController = nil;
	_afterEventViewController = nil;
	_bouquetListController = nil;
	_serviceListController = nil;
	_datePickerController = nil;
	_datePickerNavigationController = nil;
	_locationListController = nil;
	_filterViewController = nil;
	_filterNavigationController = nil;

	[super didReceiveMemoryWarning];
}

#pragma mark -
#pragma mark Properties
#pragma mark -

- (UIViewController *)afterEventNavigationController
{
	if(IS_IPAD())
	{
		if(_afterEventNavigationController == nil)
		{
			_afterEventNavigationController = [[UINavigationController alloc] initWithRootViewController:self.afterEventViewController];
			_afterEventNavigationController.modalPresentationStyle = _afterEventViewController.modalPresentationStyle;
			_afterEventNavigationController.modalTransitionStyle = _afterEventViewController.modalTransitionStyle;
		}
		return _afterEventNavigationController;
	}
	return _afterEventViewController;
}

- (AfterEventViewController *)afterEventViewController
{
	if(_afterEventViewController == nil)
	{
		_afterEventViewController = [[AfterEventViewController alloc] init];
		[_afterEventViewController setDelegate: self];
	}
	return _afterEventViewController;
}

- (UIViewController *)bouquetListController
{
	if(_bouquetListController == nil)
	{
		BouquetListController *rootViewController = [[BouquetListController alloc] init];
		[rootViewController setBouquetDelegate:self];

		if(IS_IPAD())
		{
			_bouquetListController = [[UINavigationController alloc] initWithRootViewController:rootViewController];
			_bouquetListController.modalPresentationStyle = rootViewController.modalPresentationStyle;
			_bouquetListController.modalPresentationStyle = rootViewController.modalPresentationStyle;

			[rootViewController release];
		}
		else
			_bouquetListController = rootViewController;
	}
	return _bouquetListController;
}

- (UIViewController *)serviceListController
{
	if(_serviceListController == nil)
	{
		UIViewController *rootViewController = nil;
		const BOOL forceSingleBouquet =
			[[RemoteConnectorObject sharedRemoteConnector] hasFeature: kFeaturesSingleBouquet]
			&& ![[RemoteConnectorObject sharedRemoteConnector] hasFeature: kFeaturesBouquets];

		if(forceSingleBouquet || (!IS_IPAD() && [RemoteConnectorObject isSingleBouquet]))
		{
			rootViewController = [[ServiceListController alloc] init];
			[(ServiceListController *)rootViewController setDelegate: self];
		}
		else
		{
			rootViewController = [[BouquetListController alloc] init];
			[(BouquetListController *)rootViewController setServiceDelegate: self];
		}

		if(IS_IPAD())
		{
			_serviceListController = [[UINavigationController alloc] initWithRootViewController:rootViewController];
			_serviceListController.modalPresentationStyle = rootViewController.modalPresentationStyle;
			_serviceListController.modalPresentationStyle = rootViewController.modalPresentationStyle;

			[rootViewController release];
		}
		else
			_serviceListController = rootViewController;
	}
	return _serviceListController;
}

- (UIViewController *)datePickerNavigationController
{
	if(IS_IPAD())
	{
		if(_datePickerNavigationController == nil)
		{
			_datePickerNavigationController = [[UINavigationController alloc] initWithRootViewController:self.datePickerController];
			_datePickerNavigationController.modalPresentationStyle = _datePickerController.modalPresentationStyle;
			_datePickerNavigationController.modalTransitionStyle = _datePickerController.modalTransitionStyle;
		}
		return _datePickerNavigationController;
	}
	return _datePickerController;
}

- (DatePickerController *)datePickerController
{
	if(_datePickerController == nil)
		_datePickerController = [[DatePickerController alloc] init];
	return _datePickerController;
}

- (UIViewController *)filterNavigationController
{
	if(IS_IPAD())
	{
		if(_filterNavigationController == nil)
		{
			_filterNavigationController = [[UINavigationController alloc] initWithRootViewController:self.filterViewController];
			_filterNavigationController.modalPresentationStyle = _filterViewController.modalPresentationStyle;
			_filterNavigationController.modalTransitionStyle = _filterViewController.modalTransitionStyle;
		}
		return _filterNavigationController;
	}
	return self.filterViewController;
}

- (AutoTimerFilterViewController *)filterViewController
{
	if(_filterViewController == nil)
	{
		_filterViewController = [[AutoTimerFilterViewController alloc] init];
		[_filterViewController setDelegate:self];
	}
	return _filterViewController;
}

- (UIViewController *)locationListController
{
	if(_locationListController == nil)
	{
		LocationListController *rootViewController = [[LocationListController alloc] init];
		[rootViewController setDelegate: self];
		rootViewController.showDefault = YES;

		if(IS_IPAD())
		{
			_locationListController = [[UINavigationController alloc] initWithRootViewController:rootViewController];
			_locationListController.modalPresentationStyle = rootViewController.modalPresentationStyle;
			_locationListController.modalTransitionStyle = rootViewController.modalTransitionStyle;
		}
		else
			_locationListController = rootViewController;
	}
	return _locationListController;
}

- (AutoTimer *)timer
{
	return _timer;
}

- (void)setTimer:(AutoTimer *)newTimer
{
	if(_timer != newTimer)
	{
		[_timer release];
		_timer = [newTimer retain];

		// stop editing
		_shouldSave = NO;
		[self cellShouldBeginEditing: nil];
		[self setEditing: NO animated: YES];
	}

	_titleField.text = _timer.name;
	_matchField.text = _timer.match;
	if(_timer.maxduration == -1)
		_maxdurationField.text = nil;
	else
		_maxdurationField.text = [NSString stringWithFormat:@"%d", _timer.maxduration];
	_timerEnabled.on = _timer.enabled;
	_exactSearch.on = _timer.searchType == SEARCH_TYPE_EXACT;
	_sensitiveSearch.on = _timer.searchCase == CASE_SENSITIVE;
	_overrideAlternatives.on = _timer.overrideAlternatives;
	_timeframeSwitch.on = (_timer.after != nil && _timer.before != nil);
	_timerJustplay.on = _timer.justplay;
	_timespanSwitch.on = (_timer.from != nil && _timer.to != nil);
	_avoidDuplicateDescription.on = _timer.avoidDuplicateDescription > 0;
	_maxdurationSwitch.on = (_timer.maxduration > 0);

	[(UITableView *)self.view reloadData];
	[(UITableView *)self.view
						scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]
						atScrollPosition:UITableViewScrollPositionTop
						animated:NO];

	// Eventually remove popover
	if(self.popoverController != nil) {
        [self.popoverController dismissPopoverAnimated:YES];
    }
}

- (BOOL)creatingNewTimer
{
	return _creatingNewTimer;
}

- (void)setCreatingNewTimer: (BOOL)newValue
{
	if(newValue)
		self.title = NSLocalizedString(@"New AutoTimer", @"");
	else
		self.title = NSLocalizedString(@"AutoTimer", @"Default title of AutoTimerViewController");

	_shouldSave = NO;
	_creatingNewTimer = newValue;

	[self setEditing:YES animated:YES];
}

#pragma mark -
#pragma mark Helper methods
#pragma mark -

- (NSString *)format_Time:(NSDate *)dateTime withDateStyle:(NSDateFormatterStyle)dateStyle
{
	NSString *dateString = nil;
	if(dateTime)
	{
		[_dateFormatter setDateStyle:dateStyle];
		[_dateFormatter setTimeStyle:NSDateFormatterShortStyle];
		dateString = [_dateFormatter fuzzyDate:dateTime];
	}
	else
		dateString = NSLocalizedStringFromTable(@"unset", @"AutoTimer", @"option (e.g. timespan or timeframe) unset");
	return dateString;
}

- (UITextField *)allocTextField
{
	UITextField *returnTextField = [[UITextField alloc] initWithFrame:CGRectZero];

	returnTextField.leftView = nil;
	returnTextField.leftViewMode = UITextFieldViewModeNever;
	returnTextField.borderStyle = UITextBorderStyleRoundedRect;
	returnTextField.textColor = [UIColor blackColor];
	returnTextField.font = [UIFont systemFontOfSize:kTextFieldFontSize];
	returnTextField.backgroundColor = [UIColor whiteColor];
	// no auto correction support
	returnTextField.autocorrectionType = UITextAutocorrectionTypeNo;

	returnTextField.keyboardType = UIKeyboardTypeDefault;
	returnTextField.returnKeyType = UIReturnKeyDone;

	// has a clear 'x' button to the right
	returnTextField.clearButtonMode = UITextFieldViewModeWhileEditing;

	return returnTextField;
}

- (UITextField *)newTitleField
{
	UITextField *field = [self allocTextField];
	field.text = _timer.name;
	field.placeholder = NSLocalizedStringFromTable(@"<enter title>", @"AutoTimer", @"Placeholder of AutoTimer Title field");
	return field;
}

- (UITextField *)newMatchField
{
	UITextField *field = [self allocTextField];
	field.text = _timer.match;
	field.placeholder = NSLocalizedStringFromTable(@"<text to find in title>", @"AutoTimer", @"Placeholder of AutoTimer Match field");
	return field;
}

- (UITextField *)newMaxdurationField
{
	UITextField *field = [self allocTextField];
	if(_timer.maxduration == -1)
		field.text = nil;
	else
		field.text = [NSString stringWithFormat:@"%d", _timer.maxduration];
	field.placeholder = NSLocalizedStringFromTable(@"<maximum duration>", @"AutoTimer", @"Placeholder of AutoTimer Maxduration field");
	field.keyboardType = UIKeyboardTypeNumberPad;
	return field;
}

- (void)showHideDetails:(id)sender
{
	NSIndexSet *idxSet = nil;
	if([sender isEqual:_maxdurationSwitch])
	{
		idxSet = [NSIndexSet indexSetWithIndex:durationSection];
	}
	else if([sender isEqual:_timespanSwitch])
	{
		idxSet = [NSIndexSet indexSetWithIndex:timespanSection];
	}
	else if([sender isEqual:_timeframeSwitch])
	{
		idxSet = [NSIndexSet indexSetWithIndex:timeframeSection];
	}

	if(idxSet)
		[(UITableView *)self.view reloadSections:idxSet withRowAnimation:UITableViewScrollPositionMiddle];
}

#pragma mark -
#pragma mark UView
#pragma mark -

- (void)loadView
{
	self.navigationItem.rightBarButtonItem = self.editButtonItem;

	_cancelButtonItem = [[UIBarButtonItem alloc]
						initWithBarButtonSystemItem: UIBarButtonSystemItemCancel
						target: self
						action: @selector(cancelEdit:)];
	self.navigationItem.leftBarButtonItem = _cancelButtonItem;

	// create and configure the table view
	UITableView *tableView = [[UITableView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame] style:UITableViewStyleGrouped];
	tableView.delegate = self;
	tableView.dataSource = self;
	tableView.rowHeight = kUIRowHeight;
	tableView.allowsSelectionDuringEditing = YES;

	// setup our content view so that it auto-rotates along with the UViewController
	tableView.autoresizesSubviews = YES;
	tableView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);

	self.view = tableView;
	[tableView release];

	_titleField = [self newTitleField];
	_matchField = [self newMatchField];
	_maxdurationField = [self newMaxdurationField];

	// Enabled
	_timerEnabled = [[UISwitch alloc] initWithFrame:CGRectMake(0, 0, 300, kSwitchButtonHeight)];
	_timerEnabled.on = _timer.enabled;
	_timerEnabled.backgroundColor = [UIColor clearColor];

	// Exact
	_exactSearch = [[UISwitch alloc] initWithFrame:CGRectMake(0, 0, 300, kSwitchButtonHeight)];
	_exactSearch.on = (_timer.searchType == SEARCH_TYPE_EXACT);
	_exactSearch.backgroundColor = [UIColor clearColor];

	// Case-Sensitive
	_sensitiveSearch = [[UISwitch alloc] initWithFrame:CGRectMake(0, 0, 300, kSwitchButtonHeight)];
	_sensitiveSearch.on = (_timer.searchCase == CASE_SENSITIVE);
	_sensitiveSearch.backgroundColor = [UIColor clearColor];

	// overrideAlternatives
	_overrideAlternatives = [[UISwitch alloc] initWithFrame:CGRectMake(0, 0, 300, kSwitchButtonHeight)];
	_overrideAlternatives.on = _timer.overrideAlternatives;
	_overrideAlternatives.backgroundColor = [UIColor clearColor];

	// Timeframe
	_timeframeSwitch = [[UISwitch alloc] initWithFrame: CGRectMake(0, 0, 300, kSwitchButtonHeight)];
	[_timeframeSwitch addTarget:self action:@selector(showHideDetails:) forControlEvents:UIControlEventValueChanged];
	_timeframeSwitch.on = (_timer.after != nil && _timer.before != nil);
	_timeframeSwitch.backgroundColor = [UIColor clearColor];

	// Justplay
	_timerJustplay = [[UISwitch alloc] initWithFrame: CGRectMake(0, 0, 300, kSwitchButtonHeight)];
	_timerJustplay.on = _timer.justplay;
	_timerJustplay.backgroundColor = [UIColor clearColor];

	// Timespan
	_timespanSwitch = [[UISwitch alloc] initWithFrame: CGRectMake(0, 0, 300, kSwitchButtonHeight)];
	[_timespanSwitch addTarget:self action:@selector(showHideDetails:) forControlEvents:UIControlEventValueChanged];
	_timespanSwitch.on = (_timer.from != nil && _timer.to != nil);
	_timespanSwitch.backgroundColor = [UIColor clearColor];

	// avoidDuplicateDescription
	_avoidDuplicateDescription = [[UISwitch alloc] initWithFrame: CGRectMake(0, 0, 300, kSwitchButtonHeight)];
	_avoidDuplicateDescription.on = _timer.avoidDuplicateDescription > 0;
	_avoidDuplicateDescription.backgroundColor = [UIColor clearColor];

	// maxduration enable/disable
	_maxdurationSwitch = [[UISwitch alloc] initWithFrame: CGRectMake(0, 0, 300, kSwitchButtonHeight)];
	[_maxdurationSwitch addTarget:self action:@selector(showHideDetails:) forControlEvents:UIControlEventValueChanged];
	_maxdurationSwitch.on = (_timer.maxduration > 0);
	_maxdurationSwitch.backgroundColor = [UIColor clearColor];

	// default editing mode depends on our mode
	_shouldSave = NO;
	[self setEditing: _creatingNewTimer];
}

#pragma mark -
#pragma mark UIViewController
#pragma mark -

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
	if(editing)
	{
		/*!
		 @note don't show cancel button on ipad, it should be clear that unless you confirm
		 the changes through the "done" button they are not applied. on the iphone however
		 we might be deeper into the navigation stack and therefore have a back button there
		 that we prefer to override. the ipad either has no button or the popover button
		 which we'd rather keep.
		 */
		if(IS_IPAD())
			self.navigationItem.leftBarButtonItem = _popoverButtonItem;
		else
			self.navigationItem.leftBarButtonItem = _cancelButtonItem;
	}
	else if(_shouldSave)
	{
		NSString *message = nil;

		// Sanity Check Title
		if(_matchField.text && [_matchField.text length])
			_timer.match = _matchField.text;
		else
			message = NSLocalizedString(@"The match attribute is mandatory.", @"");

		// Get Description
		if(_titleField.text && [_titleField.text length])
			_timer.name = _titleField.text;
		else
			_timer.name = @"";

		// maxduration
		if(_maxdurationSwitch.on)
			_timer.maxduration = [_maxdurationField.text integerValue];
		else
			_timer.maxduration = -1;

		// timespan
		if(!_timespanSwitch.on)
		{
			_timer.from = nil;
			_timer.to = nil;
		}

		// timeframe
		if(!_timeframeSwitch.on)
		{
			_timer.after = nil;
			_timer.before = nil;
		}
		// no timeframe given
		else if(_timer.after == nil || _timer.before == nil)
			message = NSLocalizedString(@"No timeframe given.", @"User requested AutoTimer timeframe but none was setup.");
		// check timeframe sanity
		else if([_timer.after compare:_timer.before] != NSOrderedAscending)
			message = NSLocalizedString(@"Timeframe has to be ascending.", @"User requested AutoTimer timeframe but before if equal to or earlier than end.");

		_timer.enabled = _timerEnabled.on;
		_timer.justplay = _timerJustplay.on;
		_timer.searchType = _exactSearch.on ? SEARCH_TYPE_EXACT : SEARCH_TYPE_PARTIAL;
		_timer.searchCase = _sensitiveSearch.on ? CASE_SENSITIVE : CASE_INSENSITIVE;
		_timer.overrideAlternatives = _overrideAlternatives.on;
		_timer.avoidDuplicateDescription = _avoidDuplicateDescription.on > 0;

		// Try to commit changes if no error occured
		if(!message)
		{
			if(_creatingNewTimer)
			{
				Result *result = [[RemoteConnectorObject sharedRemoteConnector] addAutoTimer:_timer];
				if(!result.result)
					message = [NSString stringWithFormat: NSLocalizedString(@"Error adding AutoTimer: %@", @""), result.resulttext];
				else
				{
					[_delegate AutoTimerViewController:self timerWasAdded:_timer];
					[self.navigationController popViewControllerAnimated: YES];
				}
			}
			else
			{
				Result *result = [[RemoteConnectorObject sharedRemoteConnector] editAutoTimer:_timer];
				if(!result.result)
					message = [NSString stringWithFormat: NSLocalizedString(@"Error editing AutoTimer: %@", @""), result.resulttext];
				else
				{
					[_delegate AutoTimerViewController:self timerWasEdited:_timer];
					[self.navigationController popViewControllerAnimated: YES];
				}
			}
		}

		// Show error message if one occured
		if(message != nil)
		{
			const UIAlertView *notification = [[UIAlertView alloc]
										 initWithTitle:NSLocalizedString(@"Error", @"")
										 message:message
										 delegate:nil
										 cancelButtonTitle:@"OK"
										 otherButtonTitles:nil];
			[notification show];
			[notification release];

			[_delegate AutoTimerViewController:self editingWasCanceled:_timer];
			return;
		}

		self.navigationItem.leftBarButtonItem = _popoverButtonItem;
	}
	else
	{
		self.navigationItem.leftBarButtonItem = _popoverButtonItem;
	}

	_shouldSave = editing;
	[super setEditing: editing animated: animated];
	[(UITableView *)self.view setEditing:editing animated:animated];

	[_titleCell setEditing:editing animated:animated];
	[_matchCell setEditing:editing animated:animated];
	[_maxdurationCell setEditing:editing animated:animated];

	_timerEnabled.enabled = editing;
	_exactSearch.enabled = editing;
	_sensitiveSearch.enabled = editing;
	_overrideAlternatives.enabled = editing;
	_timerJustplay.enabled = editing;
	_timeframeSwitch.enabled = editing;
	_timerJustplay.enabled = editing;
	_timespanSwitch.enabled = editing;
	_avoidDuplicateDescription.enabled = editing;
	_maxdurationSwitch.enabled = editing;

	[(UITableView *)self.view reloadData];
}

- (void)cancelEdit:(id)sender
{
	_shouldSave = NO;
	[self cellShouldBeginEditing:nil];
	[self setEditing:NO animated:YES];
	[self.navigationController popViewControllerAnimated:YES];
}

/* rotate with device */
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

#pragma mark -
#pragma mark DatePickerController callbacks
#pragma mark -

- (void)fromSelected: (NSDate *)newDate
{
	if(newDate == nil)
		return;

	_timer.from = newDate;

	UITableViewCell *cell = [(UITableView *)self.view cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:timespanSection]];
	cell.textLabel.text = [NSString stringWithFormat:NSLocalizedStringFromTable(@"From: %@", @"AutoTimer", @"timespan from"), [self format_Time:_timer.from withDateStyle:NSDateFormatterNoStyle]];
}

- (void)toSelected: (NSDate *)newDate
{
	if(newDate == nil)
		return;

	_timer.to = newDate;

	UITableViewCell *cell = [(UITableView *)self.view cellForRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:timespanSection]];
	cell.textLabel.text = [NSString stringWithFormat:NSLocalizedStringFromTable(@"To: %@", @"AutoTimer", @"timespan to"), [self format_Time:_timer.to withDateStyle:NSDateFormatterNoStyle]];
}

- (void)beforeSelected: (NSDate *)newDate
{
	if(newDate == nil)
		return;

	_timer.before = newDate;

	UITableViewCell *cell = [(UITableView *)self.view cellForRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:timeframeSection]];
	cell.textLabel.text = [NSString stringWithFormat:NSLocalizedStringFromTable(@"Before: %@", @"AutoTimer", @"timeframe before"), [self format_Time:_timer.before withDateStyle:NSDateFormatterFullStyle]];
}

- (void)afterSelected: (NSDate *)newDate
{
	if(newDate == nil)
		return;

	_timer.after = newDate;

	UITableViewCell *cell = [(UITableView *)self.view cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:timeframeSection]];
	cell.textLabel.text = [NSString stringWithFormat:NSLocalizedStringFromTable(@"After: %@", @"AutoTimer", @"timeframe after"), [self format_Time:_timer.after withDateStyle:NSDateFormatterFullStyle]];
}

#pragma mark -
#pragma mark BouquetListDelegate methods
#pragma mark -

- (void)bouquetSelected:(NSObject<ServiceProtocol> *)newBouquet
{
	if(newBouquet == nil)
		return;

	for(NSObject<ServiceProtocol> *bouquet in _timer.bouquets)
	{
		if([bouquet isEqualToService:newBouquet]) return;
	}

	// copy service for convenience reasons
	[_timer.bouquets addObject:[[newBouquet copy] autorelease]];
	[(UITableView *)self.view reloadSections:[NSIndexSet indexSetWithIndex:bouquetSection] withRowAnimation:UITableViewRowAnimationFade];
}

#pragma mark -
#pragma mark ServiceListDelegate methods
#pragma mark -

- (void)serviceSelected: (NSObject<ServiceProtocol> *)newService
{
	if(newService == nil)
		return;

	for(NSObject<ServiceProtocol> *service in _timer.services)
	{
		if([service isEqualToService:newService]) return;
	}

	// copy service for convenience reasons
	[_timer.services addObject:[[newService copy] autorelease]];
	[(UITableView *)self.view reloadSections:[NSIndexSet indexSetWithIndex:servicesSection] withRowAnimation:UITableViewRowAnimationFade];
}

#pragma mark -
#pragma mark AfterEventDelegate methods
#pragma mark -

- (void)setAfterEventText:(UITableViewCell *)cell
{
	if(cell == nil)
		return;

	if(_timer.afterEventAction == kAfterEventNothing)
		TABLEVIEWCELL_TEXT(cell) = NSLocalizedString(@"Nothing", @"After Event");
	else if(_timer.afterEventAction == kAfterEventStandby)
		TABLEVIEWCELL_TEXT(cell) = NSLocalizedString(@"Standby", @"");
	else if(_timer.afterEventAction == kAfterEventDeepstandby)
		TABLEVIEWCELL_TEXT(cell) = NSLocalizedString(@"Deep Standby", @"");
	else if(_timer.afterEventAction == kAfterEventAuto)
		TABLEVIEWCELL_TEXT(cell) = NSLocalizedString(@"Auto", @"");
	else //if(_timer.afterEventAction == kAfterEventMax)
		TABLEVIEWCELL_TEXT(cell) = NSLocalizedString(@"Default Action", @"Default After Event action (usually auto on enigma2 receivers)");
}

- (void)afterEventSelected: (NSNumber *)newAfterEvent
{
	if(newAfterEvent == nil)
		return;

	_timer.afterEventAction = [newAfterEvent integerValue];

	UITableViewCell *cell = [(UITableView *)self.view cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:aftereventSection]];
	[self setAfterEventText:cell];
}

#pragma mark -
#pragma mark LocationListDelegate methods
#pragma mark -

- (void)locationSelected:(NSObject <LocationProtocol>*)newLocation
{
	UITableViewCell *cell = [(UITableView *)self.view cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:locationSection]];

	if(newLocation)
	{
		_timer.location = newLocation.fullpath;
		cell.textLabel.text = newLocation.fullpath;
	}
	else
	{
		_timer.location = nil;
		cell.textLabel.text = NSLocalizedString(@"Default Location", @"");
	}
}

#pragma mark -
#pragma mark AutoTimerFilterDelegate
#pragma mark -

- (void)filterSelected:(NSString *)newFilter filterType:(autoTimerWhereType)filterType include:(BOOL)include oldFilter:(NSString *)oldFilter oldInclude:(BOOL)oldInclude
{
	if(newFilter == nil)
		return;

	switch(filterType)
	{
		case autoTimerWhereTitle:
		{
			if(oldFilter)
			{
				if(oldInclude)
					[_timer.includeTitle removeObject:oldFilter];
				else
					[_timer.excludeTitle removeObject:oldFilter];
			}

			const NSMutableArray *list = include ? _timer.includeTitle : _timer.excludeTitle;
			for(NSString *filter in list)
			{
				if([filter isEqualToString:newFilter]) return;
			}
			[list addObject:newFilter];
			[(UITableView *)self.view reloadSections:[NSIndexSet indexSetWithIndex:filterTitleSection] withRowAnimation:UITableViewRowAnimationFade];
			break;
		}
		case autoTimerWhereShortdescription:
		{
			if(oldFilter)
			{
				if(oldInclude)
					[_timer.includeShortdescription removeObject:oldFilter];
				else
					[_timer.excludeShortdescription removeObject:oldFilter];
			}

			const NSMutableArray *list = include ? _timer.includeShortdescription : _timer.excludeShortdescription;
			for(NSString *filter in list)
			{
				if([filter isEqualToString:newFilter]) return;
			}
			[list addObject:newFilter];
			[(UITableView *)self.view reloadSections:[NSIndexSet indexSetWithIndex:filterSdescSection] withRowAnimation:UITableViewRowAnimationFade];
			break;
		}
		case autoTimerWhereDescription:
		{
			if(oldFilter)
			{
				if(oldInclude)
					[_timer.includeDescription removeObject:oldFilter];
				else
					[_timer.excludeDescription removeObject:oldFilter];
			}

			const NSMutableArray *list = include ? _timer.includeDescription : _timer.excludeDescription;
			for(NSString *filter in list)
			{
				if([filter isEqualToString:newFilter]) return;
			}
			[list addObject:newFilter];
			[(UITableView *)self.view reloadSections:[NSIndexSet indexSetWithIndex:filterDescSection] withRowAnimation:UITableViewRowAnimationFade];
			break;
		}
		case autoTimerWhereDayOfWeek:
		{
			if(oldFilter)
			{
				if(oldInclude)
					[_timer.includeDayOfWeek removeObject:oldFilter];
				else
					[_timer.excludeDayOfWeek removeObject:oldFilter];
			}

			const NSMutableArray *list = include ? _timer.includeDayOfWeek : _timer.excludeDayOfWeek;
			for(NSString *filter in list)
			{
				if([filter isEqualToString:newFilter]) return;
			}
			[list addObject:newFilter];
			[(UITableView *)self.view reloadSections:[NSIndexSet indexSetWithIndex:filterWeekdaySection] withRowAnimation:UITableViewRowAnimationFade];
			break;
		}
		default:
			NSLog(@"invalid filter type");
			break;
	}
}

#pragma mark -
#pragma mark UITableView delegates
#pragma mark -

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return maxSection;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	switch(section)
	{
		case titleSection:
			return NSLocalizedString(@"Title", @"");
		case matchSection:
			return NSLocalizedString(@"Match", @"Title of section with AutoTimer match-Attribute. String to find in EPG-Title.");
		case generalSection:
			return NSLocalizedString(@"General", @"in timer settings dialog");
		case durationSection:
			return NSLocalizedString(@"Max. Duration", @"Title of section with AutoTimer max Duration-Attribute. Maximum Duration a event can have to match this AutoTimer.");
		case timespanSection:
			return NSLocalizedStringFromTable(@"Timespan", @"AutoTimer", @"section header for timespan");
		case timeframeSection:
			return NSLocalizedStringFromTable(@"Timeframe", @"AutoTimer", @"section header for timeframe");
		case servicesSection:
			return NSLocalizedStringFromTable(@"Services", @"AutoTimer", @"section header for service restriction");
		case bouquetSection:
			return NSLocalizedStringFromTable(@"Bouquets", @"AutoTimer", @"section header for bouquet restriction");
		case aftereventSection:
			return NSLocalizedString(@"After Event", @"");
		case locationSection:
			return NSLocalizedString(@"Location", @"");
		case filterSdescSection:
			return NSLocalizedString(@"Filter: Shortdescription", @"");
		case filterDescSection:
			return NSLocalizedString(@"Filter: Description", @"");
		case filterTitleSection:
			return NSLocalizedString(@"Filter: Title", @"");
		case filterWeekdaySection:
			return NSLocalizedString(@"Filter: Weekday", @"");
		default:
			return nil;
	}
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	switch(section)
	{
		case titleSection:
		case matchSection:
		case aftereventSection:
		case locationSection:
			return 1;
		case generalSection:
			return 6;
		case durationSection:
			return _maxdurationSwitch.on ? 2 : 1;
		case timespanSection:
			return _timespanSwitch.on ? 3 : 1;
		case timeframeSection:
			return _timeframeSwitch.on ? 3 : 1;
		case servicesSection:
			return _timer.services.count + (self.editing ? 1 : 0);
		case bouquetSection:
			return _timer.bouquets.count + (self.editing ? 1 : 0);
		case filterSdescSection:
			return _timer.includeShortdescription.count + _timer.excludeShortdescription.count + (self.editing ? 1 : 0);
		case filterDescSection:
			return _timer.includeDescription.count + _timer.excludeDescription.count + (self.editing ? 1 : 0);
		case filterTitleSection:
			return _timer.includeTitle.count + _timer.excludeTitle.count + (self.editing ? 1 : 0);
		case filterWeekdaySection:
			return _timer.includeDayOfWeek.count + _timer.excludeDayOfWeek.count + (self.editing ? 1 : 0);
		default:
			return 0;
	}
}

// to determine which UITableViewCell to be used on a given row.
//
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	const NSInteger section = indexPath.section;
	NSUInteger row = indexPath.row;
	UITableViewCell *cell = nil;

	switch(section)
	{
		case titleSection:
			if(!_titleCell)
				_titleCell = [[CellTextField alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
			_titleCell.delegate = self;
			_titleCell.view = _titleField;
			cell = _titleCell;
			break;
		case matchSection:
			if(!_matchCell)
				_matchCell = [[CellTextField alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
			_matchCell.delegate = self;
			_matchCell.view = _matchField;
			cell = _matchCell;
			break;
		case generalSection:
		{
			cell = [DisplayCell reusableTableViewCellInView:tableView withIdentifier:kDisplayCell_ID];
			switch(row)
			{
				case 0:
					((DisplayCell *)cell).view = _timerEnabled;
					cell.textLabel.text = NSLocalizedString(@"Enabled", @"");
					break;
				case 1:
					((DisplayCell *)cell).view = _exactSearch;
					cell.textLabel.text = NSLocalizedString(@"Exact Title", @"");
					break;
				case 2:
					((DisplayCell *)cell).view = _sensitiveSearch;
					cell.textLabel.text = NSLocalizedString(@"Case-Sensitive", @"case-sensitive matching (of autotimers)");
					break;
				case 3:
					((DisplayCell *)cell).view = _overrideAlternatives;
					cell.textLabel.text = NSLocalizedString(@"Prefer Alternatives", @"");
					break;
				case 4:
					((DisplayCell *)cell).view = _timerJustplay;
					cell.textLabel.text = NSLocalizedString(@"Justplay", @"");
					break;
				case 5:
					((DisplayCell *)cell).view = _avoidDuplicateDescription;
					cell.textLabel.text = NSLocalizedString(@"Unique Description", @"avoidDuplicateDescription attribute of autotimer. Event (short)description has to be unique among set timers.");
					/* FALL THROUGH */
				default:
					break;
			}
			break;
		}
		case durationSection:
			if(row == 0)
			{
				cell = [DisplayCell reusableTableViewCellInView:tableView withIdentifier:kDisplayCell_ID];
				((DisplayCell *)cell).view = _maxdurationSwitch;
				cell.textLabel.text = NSLocalizedString(@"Enabled", @"");
			}
			else
			{
				if(!_maxdurationCell)
					_maxdurationCell = [[CellTextField alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
				_maxdurationCell.delegate = self;
				_maxdurationCell.view = _maxdurationField;
				cell = _maxdurationCell;
			}
			break;
		case timespanSection:
		{
			switch(row)
			{
				case 0:
					cell = [DisplayCell reusableTableViewCellInView:tableView withIdentifier:kDisplayCell_ID];
					((DisplayCell *)cell).view = _timespanSwitch;
					cell.textLabel.text = NSLocalizedString(@"Enabled", @"");
					break;
				case 1:
					cell = [UITableViewCell reusableTableViewCellInView:tableView withIdentifier:kVanilla_ID];
					cell.textLabel.text = [NSString stringWithFormat:NSLocalizedStringFromTable(@"From: %@", @"AutoTimer", @"timespan from"), [self format_Time:_timer.from withDateStyle:NSDateFormatterNoStyle]];
					cell.accessoryType = UITableViewCellAccessoryNone;
					cell.editingAccessoryType = UITableViewCellAccessoryDisclosureIndicator;
					cell.textLabel.font = [UIFont systemFontOfSize:kTextViewFontSize];
					break;
				case 2:
					cell = [UITableViewCell reusableTableViewCellInView:tableView withIdentifier:kVanilla_ID];
					cell.textLabel.text = [NSString stringWithFormat:NSLocalizedStringFromTable(@"To: %@", @"AutoTimer", @"timespan to"), [self format_Time:_timer.to withDateStyle:NSDateFormatterNoStyle]];
					cell.accessoryType = UITableViewCellAccessoryNone;
					cell.editingAccessoryType = UITableViewCellAccessoryDisclosureIndicator;
					cell.textLabel.font = [UIFont systemFontOfSize:kTextViewFontSize];
					break;
			}
			break;
		}
		case timeframeSection:
		{
			switch(row)
			{
				case 0:
					cell = [DisplayCell reusableTableViewCellInView:tableView withIdentifier:kDisplayCell_ID];
					((DisplayCell *)cell).view = _timeframeSwitch;
					cell.textLabel.text = NSLocalizedString(@"Enabled", @"");
					break;
				case 1:
					cell = [UITableViewCell reusableTableViewCellInView:tableView withIdentifier:kVanilla_ID];
					cell.textLabel.adjustsFontSizeToFitWidth = YES;
					cell.textLabel.text = [NSString stringWithFormat:NSLocalizedStringFromTable(@"After: %@", @"AutoTimer", @"timeframe after"), [self format_Time:_timer.after withDateStyle:NSDateFormatterFullStyle]];
					cell.accessoryType = UITableViewCellAccessoryNone;
					cell.editingAccessoryType = UITableViewCellAccessoryDisclosureIndicator;
					cell.textLabel.font = [UIFont systemFontOfSize:kTextViewFontSize];
					break;
				case 2:
					cell = [UITableViewCell reusableTableViewCellInView:tableView withIdentifier:kVanilla_ID];
					cell.textLabel.adjustsFontSizeToFitWidth = YES;
					cell.textLabel.text = [NSString stringWithFormat:NSLocalizedStringFromTable(@"Before: %@", @"AutoTimer", @"timeframe before"), [self format_Time:_timer.before withDateStyle:NSDateFormatterFullStyle]];
					cell.accessoryType = UITableViewCellAccessoryNone;
					cell.editingAccessoryType = UITableViewCellAccessoryDisclosureIndicator;
					cell.textLabel.font = [UIFont systemFontOfSize:kTextViewFontSize];
					break;
			}
			break;
		}
		case servicesSection:
		{
			if(self.editing)
			{
				if(row == 0)
				{
					cell = [UITableViewCell reusableTableViewCellInView:tableView withIdentifier:kVanilla_ID];
					cell.textLabel.text = NSLocalizedStringFromTable(@"New Service", @"AutoTimer", @"add new service filter");
					cell.editingAccessoryType = UITableViewCellAccessoryDisclosureIndicator;
					cell.textLabel.font = [UIFont systemFontOfSize:kTextViewFontSize];
					break;
				}
				else
					--row;
			}

			cell = [ServiceTableViewCell reusableTableViewCellInView:tableView withIdentifier:kServiceCell_ID];
			((ServiceTableViewCell *)cell).serviceNameLabel.font = [UIFont systemFontOfSize:kTextViewFontSize];
			((ServiceTableViewCell *)cell).service = [_timer.services objectAtIndex:row];
			cell.accessoryType = UITableViewCellAccessoryNone;
			cell.editingAccessoryType = UITableViewCellAccessoryNone;
			break;
		}
		case bouquetSection:
		{
			if(self.editing)
			{
				if(row == 0)
				{
					cell = [UITableViewCell reusableTableViewCellInView:tableView withIdentifier:kVanilla_ID];
					cell.textLabel.text = NSLocalizedStringFromTable(@"New Bouquet", @"AutoTimer", @"add new bouquet filter");
					cell.editingAccessoryType = UITableViewCellAccessoryDisclosureIndicator;
					cell.textLabel.font = [UIFont systemFontOfSize:kTextViewFontSize];
					break;
				}
				else
					--row;
			}

			cell = [ServiceTableViewCell reusableTableViewCellInView:tableView withIdentifier:kServiceCell_ID];
			((ServiceTableViewCell *)cell).serviceNameLabel.font = [UIFont systemFontOfSize:kTextViewFontSize];
			((ServiceTableViewCell *)cell).service = [_timer.bouquets objectAtIndex:row];
			cell.accessoryType = UITableViewCellAccessoryNone;
			cell.editingAccessoryType = UITableViewCellAccessoryNone;
			break;
		}
		case aftereventSection:
			cell = [UITableViewCell reusableTableViewCellInView:tableView withIdentifier:kVanilla_ID];
			cell.accessoryType = UITableViewCellAccessoryNone;
			cell.editingAccessoryType = UITableViewCellAccessoryDisclosureIndicator;
			cell.textLabel.font = [UIFont systemFontOfSize:kTextViewFontSize];
			[self setAfterEventText:cell];
			break;
		case locationSection:
			cell = [UITableViewCell reusableTableViewCellInView:tableView withIdentifier:kVanilla_ID];
			cell.accessoryType = UITableViewCellAccessoryNone;
			cell.editingAccessoryType = UITableViewCellAccessoryDisclosureIndicator;
			cell.textLabel.text = (_timer.location) ? _timer.location : NSLocalizedString(@"Default Location", @"");
			cell.textLabel.font = [UIFont systemFontOfSize:kTextViewFontSize];
			break;
		case filterSdescSection:
		{
			cell = [UITableViewCell reusableTableViewCellInView:tableView withIdentifier:kVanilla_ID];
			cell.textLabel.font = [UIFont systemFontOfSize:kTextViewFontSize];
			if(self.editing)
			{
				if(row == 0)
				{
					cell.textLabel.text = NSLocalizedStringFromTable(@"New Filter", @"AutoTimer", @"add new filter");
					cell.editingAccessoryType = UITableViewCellAccessoryDisclosureIndicator;
					break;
				}
				else
					--row;
			}

			if(row < _timer.includeShortdescription.count)
			{
				cell.textLabel.text = [_timer.includeShortdescription objectAtIndex:row];
				cell.accessoryType = UITableViewCellAccessoryCheckmark;
				cell.editingAccessoryType = UITableViewCellAccessoryCheckmark;
				break;
			}

			row -= _timer.includeShortdescription.count;
			cell.textLabel.text = [_timer.excludeShortdescription objectAtIndex:row];
			cell.accessoryType = UITableViewCellAccessoryNone;
			cell.editingAccessoryType = UITableViewCellAccessoryNone;
			break;
		}
		case filterDescSection:
		{
			cell = [UITableViewCell reusableTableViewCellInView:tableView withIdentifier:kVanilla_ID];
			cell.textLabel.font = [UIFont systemFontOfSize:kTextViewFontSize];
			if(self.editing)
			{
				if(row == 0)
				{
					cell.textLabel.text = NSLocalizedStringFromTable(@"New Filter", @"AutoTimer", @"add new filter");
					cell.editingAccessoryType = UITableViewCellAccessoryDisclosureIndicator;
					break;
				}
				else
					--row;
			}

			if(row < _timer.includeDescription.count)
			{
				cell.textLabel.text = [_timer.includeDescription objectAtIndex:row];
				cell.accessoryType = UITableViewCellAccessoryCheckmark;
				cell.editingAccessoryType = UITableViewCellAccessoryCheckmark;
				break;
			}

			row -= _timer.includeDescription.count;
			cell.textLabel.text = [_timer.excludeDescription objectAtIndex:row];
			cell.accessoryType = UITableViewCellAccessoryNone;
			cell.editingAccessoryType = UITableViewCellAccessoryNone;
			break;
		}
		case filterTitleSection:
		{
			cell = [UITableViewCell reusableTableViewCellInView:tableView withIdentifier:kVanilla_ID];
			cell.textLabel.font = [UIFont systemFontOfSize:kTextViewFontSize];
			if(self.editing)
			{
				if(row == 0)
				{
					cell.textLabel.text = NSLocalizedStringFromTable(@"New Filter", @"AutoTimer", @"add new filter");
					cell.editingAccessoryType = UITableViewCellAccessoryDisclosureIndicator;
					break;
				}
				else
					--row;
			}

			if(row < _timer.includeTitle.count)
			{
				cell.textLabel.text = [_timer.includeTitle objectAtIndex:row];
				cell.accessoryType = UITableViewCellAccessoryCheckmark;
				cell.editingAccessoryType = UITableViewCellAccessoryCheckmark;
				break;
			}

			row -= _timer.includeTitle.count;
			cell.textLabel.text = [_timer.excludeTitle objectAtIndex:row];
			cell.accessoryType = UITableViewCellAccessoryNone;
			cell.editingAccessoryType = UITableViewCellAccessoryNone;
			break;
		}
		case filterWeekdaySection:
		{
			cell = [UITableViewCell reusableTableViewCellInView:tableView withIdentifier:kVanilla_ID];
			cell.textLabel.font = [UIFont systemFontOfSize:kTextViewFontSize];
			if(self.editing)
			{
				if(row == 0)
				{
					cell.textLabel.text = NSLocalizedStringFromTable(@"New Filter", @"AutoTimer", @"add new filter");
					cell.editingAccessoryType = UITableViewCellAccessoryDisclosureIndicator;
					break;
				}
				else
					--row;
			}

			NSString *text = nil;
			if(row < _timer.includeDayOfWeek.count)
			{
				text = [_timer.includeDayOfWeek objectAtIndex:row];
				cell.accessoryType = UITableViewCellAccessoryCheckmark;
				cell.editingAccessoryType = UITableViewCellAccessoryCheckmark;
			}
			else
			{
				row -= _timer.includeDayOfWeek.count;
				text = [_timer.excludeDayOfWeek objectAtIndex:row];
				cell.accessoryType = UITableViewCellAccessoryNone;
				cell.editingAccessoryType = UITableViewCellAccessoryNone;
			}

			if([text isEqualToString:@"weekend"])
			{
				cell.textLabel.text = NSLocalizedStringFromTable(@"Sat-Sun", @"AutoTimer", @"weekday filter");
			}
			else if([text isEqualToString:@"weekday"])
			{
				cell.textLabel.text = NSLocalizedStringFromTable(@"Mon-Fri", @"AutoTimer", @"weekday filter");
			}
			else
			{
				NSInteger day = ([text integerValue] + 1) % 7;
				NSString *weekday = [[_dateFormatter weekdaySymbols] objectAtIndex:day];
				cell.textLabel.text = weekday;
			}
		}
	}

	return cell;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if(!tableView.editing)
		return UITableViewCellEditingStyleNone;

	// services, bouquets, filters can be removed
	switch(indexPath.section)
	{
		case servicesSection:
		case bouquetSection:
		case filterTitleSection:
		case filterSdescSection:
		case filterDescSection:
		case filterWeekdaySection:
			if(tableView.editing && indexPath.row == 0)
				return UITableViewCellEditingStyleInsert;
			return UITableViewCellEditingStyleDelete;
		default:
			return UITableViewCellEditingStyleNone;
	}
}

- (BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath
{
	// services, bouquets, filters can be removed
	switch(indexPath.section)
	{
		case servicesSection:
		case bouquetSection:
		case filterTitleSection:
		case filterSdescSection:
		case filterDescSection:
		case filterWeekdaySection:
			return YES;
		default:
			return NO;
	}
}

- (void)tableView:(UITableView *)tv commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
	UIViewController *targetViewController = nil;
	NSUInteger row = indexPath.row;
	if(tv.editing) --row;

	switch(indexPath.section)
	{
		case servicesSection:
		{
			if(editingStyle == UITableViewCellEditingStyleInsert)
			{
				targetViewController = self.serviceListController;
			}
			else
			{
				[_timer.services removeObjectAtIndex:row];
				[tv deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
						  withRowAnimation:UITableViewRowAnimationFade];
			}
			break;
		}
		case bouquetSection:
		{
			if(editingStyle == UITableViewCellEditingStyleInsert)
			{
				targetViewController = self.bouquetListController;
			}
			else
			{
				[_timer.bouquets removeObjectAtIndex:row];
				[tv deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
						  withRowAnimation:UITableViewRowAnimationFade];
			}
			break;
		}
		case filterTitleSection:
		{
			if(editingStyle == UITableViewCellEditingStyleInsert)
			{
				targetViewController = self.filterNavigationController;
				self.filterViewController.filterType = autoTimerWhereTitle;
				self.filterViewController.currentText = nil;
				self.filterViewController.include = YES;
			}
			else
			{
				if(row < _timer.includeTitle.count)
					[_timer.includeTitle removeObjectAtIndex:row];
				else
				{
					row -= _timer.includeTitle.count;
					[_timer.excludeTitle removeObjectAtIndex:row];
				}

				[tv deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
						  withRowAnimation:UITableViewRowAnimationFade];
			}
			break;
		}
		case filterSdescSection:
		{
			if(editingStyle == UITableViewCellEditingStyleInsert)
			{
				targetViewController = self.filterNavigationController;
				self.filterViewController.filterType = autoTimerWhereShortdescription;
				self.filterViewController.currentText = nil;
				self.filterViewController.include = YES;
			}
			else
			{
				if(row < _timer.includeShortdescription.count)
					[_timer.includeShortdescription removeObjectAtIndex:row];
				else
				{
					row -= _timer.includeShortdescription.count;
					[_timer.excludeShortdescription removeObjectAtIndex:row];
				}

				[tv deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
						  withRowAnimation:UITableViewRowAnimationFade];
			}
			break;
		}
		case filterDescSection:
		{
			if(editingStyle == UITableViewCellEditingStyleInsert)
			{
				targetViewController = self.filterNavigationController;
				self.filterViewController.filterType = autoTimerWhereDescription;
				self.filterViewController.currentText = nil;
				self.filterViewController.include = YES;
			}
			else
			{
				if(row < _timer.includeDescription.count)
					[_timer.includeDescription removeObjectAtIndex:row];
				else
				{
					row -= _timer.includeDescription.count;
					[_timer.excludeDescription removeObjectAtIndex:row];
				}

				[tv deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
						  withRowAnimation:UITableViewRowAnimationFade];
			}
			break;
		}
		case filterWeekdaySection:
		{
			if(editingStyle == UITableViewCellEditingStyleInsert)
			{
				targetViewController = self.filterNavigationController;
				self.filterViewController.filterType = autoTimerWhereDayOfWeek;
				self.filterViewController.currentText = nil;
				self.filterViewController.include = YES;
			}
			else
			{
				if(row < _timer.includeDayOfWeek.count)
					[_timer.includeDayOfWeek removeObjectAtIndex:row];
				else
				{
					row -= _timer.includeDayOfWeek.count;
					[_timer.excludeDayOfWeek removeObjectAtIndex:row];
				}

				[tv deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
						  withRowAnimation:UITableViewRowAnimationFade];
			}
			break;
		}
		default:
			break;
	}

	if(targetViewController)
	{
		if(IS_IPAD())
			[self.navigationController presentModalViewController:targetViewController animated:YES];
		else
			[self.navigationController pushViewController: targetViewController animated:YES];
	}
}

- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSUInteger row = indexPath.row;
	UIViewController *targetViewController = nil;
	switch(indexPath.section)
	{
		case timespanSection:
		{
			if(row == 0)
				break;

			else if(row == 1)
			{
				self.datePickerController.date = [[_timer.from copy] autorelease];
				[self.datePickerController setTarget: self action: @selector(fromSelected:)];
			}
			else
			{
				self.datePickerController.date = [[_timer.to copy] autorelease];
				[self.datePickerController setTarget: self action: @selector(toSelected:)];
			}

			[self.datePickerController setDatePickerMode:UIDatePickerModeTime];
			targetViewController = self.datePickerNavigationController;
			break;
		}
		case timeframeSection:
		{
			if(row == 0)
				break;

			else if(row == 1)
			{
				self.datePickerController.date = [[_timer.after copy] autorelease];
				[self.datePickerController setTarget: self action: @selector(afterSelected:)];
			}
			else
			{
				self.datePickerController.date = [[_timer.before copy] autorelease];
				[self.datePickerController setTarget: self action: @selector(beforeSelected:)];
			}

			[self.datePickerController setDatePickerMode:UIDatePickerModeDateAndTime];
			targetViewController = self.datePickerNavigationController;
			break;
		}
		case servicesSection:
			if(self.editing && row == 0)
				targetViewController = self.serviceListController;
			break;
		case bouquetSection:
			if(self.editing && row == 0)
				targetViewController = self.bouquetListController;
			break;
		case aftereventSection:
		{
			self.afterEventViewController.selectedItem = _timer.afterEventAction;
			// FIXME: why gives directly assigning this an error?
			const BOOL showAuto = [[RemoteConnectorObject sharedRemoteConnector] hasFeature: kFeaturesTimerAfterEventAuto];
			self.afterEventViewController.showAuto = showAuto;
			self.afterEventViewController.showDefault = YES;

			targetViewController = self.afterEventNavigationController;
			break;
		}
		case locationSection:
			targetViewController = self.locationListController;
			break;
		case filterTitleSection:
		{
			targetViewController = self.filterNavigationController;
			self.filterViewController.filterType = autoTimerWhereTitle;
			if(self.editing && row-- == 0)
			{
				self.filterViewController.currentText = nil;
				self.filterViewController.include = YES;
			}
			else
			{
				if(row < _timer.includeTitle.count)
				{
					self.filterViewController.currentText = [_timer.includeTitle objectAtIndex:row];
					self.filterViewController.include = YES;
					break;
				}

				row -= _timer.includeTitle.count;
				self.filterViewController.currentText = [_timer.excludeTitle objectAtIndex:row];
				self.filterViewController.include = NO;
			}
			break;
		}
		case filterSdescSection:
		{
			targetViewController = self.filterNavigationController;
			self.filterViewController.filterType = autoTimerWhereShortdescription;
			if(self.editing && row-- == 0)
			{
				self.filterViewController.currentText = nil;
				self.filterViewController.include = YES;
			}
			else
			{
				if(row < _timer.includeShortdescription.count)
				{
					self.filterViewController.currentText = [_timer.includeShortdescription objectAtIndex:row];
					self.filterViewController.include = YES;
					break;
				}

				row -= _timer.includeShortdescription.count;
				self.filterViewController.currentText = [_timer.excludeShortdescription objectAtIndex:row];
				self.filterViewController.include = NO;
			}
			break;
		}
		case filterDescSection:
		{
			targetViewController = self.filterNavigationController;
			self.filterViewController.filterType = autoTimerWhereDescription;
			if(self.editing && row-- == 0)
			{
				self.filterViewController.currentText = nil;
				self.filterViewController.include = YES;
			}
			else
			{
				if(row < _timer.includeDescription.count)
				{
					self.filterViewController.currentText = [_timer.includeDescription objectAtIndex:row];
					self.filterViewController.include = YES;
					break;
				}

				row -= _timer.includeDescription.count;
				self.filterViewController.currentText = [_timer.excludeDescription objectAtIndex:row];
				self.filterViewController.include = NO;
			}
			break;
		}
		case filterWeekdaySection:
		{
			targetViewController = self.filterNavigationController;
			self.filterViewController.filterType = autoTimerWhereDayOfWeek;
			if(self.editing && row-- == 0)
			{
				self.filterViewController.currentText = nil;
				self.filterViewController.include = YES;
			}
			else
			{
				if(row < _timer.includeDayOfWeek.count)
				{
					self.filterViewController.currentText = [_timer.includeDayOfWeek objectAtIndex:row];
					self.filterViewController.include = YES;
					break;
				}

				row -= _timer.includeDayOfWeek.count;
				self.filterViewController.currentText = [_timer.excludeDayOfWeek objectAtIndex:row];
				self.filterViewController.include = NO;
			}
			break;
		}
		default:
			break;
	}

	if(targetViewController)
	{
		if(IS_IPAD())
			[self.navigationController presentModalViewController:targetViewController animated:YES];
		else
			[self.navigationController pushViewController: targetViewController animated:YES];
	}
	[tv deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark -
#pragma mark <EditableTableViewCellDelegate> Methods and editing management
#pragma mark -

- (BOOL)cellShouldBeginEditing:(EditableTableViewCell *)cell
{
	if(![cell isEqual:_titleCell])
		[_titleCell stopEditing];
	if(![cell isEqual:_matchCell])
		[_matchCell stopEditing];
	if(![cell isEqual:_maxdurationCell])
		[_maxdurationCell stopEditing];

	return self.editing;
}

- (void)cellDidEndEditing:(EditableTableViewCell *)cell
{
	//
}

- (void)keyboardWillShow:(NSNotification *)notif
{
	NSIndexPath *indexPath;
	UITableViewScrollPosition scrollPosition = UITableViewScrollPositionMiddle;
	if(_titleCell.isInlineEditing)
		indexPath = [NSIndexPath indexPathForRow:0 inSection:titleSection];
	else if(_matchCell.isInlineEditing)
		indexPath = [NSIndexPath indexPathForRow:0 inSection:matchSection];
	else if(_maxdurationCell.isInlineEditing)
		indexPath = [NSIndexPath indexPathForRow:1 inSection:durationSection];
	else return;

	if(UIInterfaceOrientationIsLandscape(self.interfaceOrientation))
		scrollPosition = UITableViewScrollPositionTop;
	[(UITableView *)self.view scrollToRowAtIndexPath:indexPath atScrollPosition:scrollPosition animated:YES];
}

#pragma mark -
#pragma mark UIViewController delegate methods
#pragma mark -

- (void)viewWillAppear:(BOOL)animated
{
	// watch the keyboard so we can adjust the user interface if necessary.
	[[NSNotificationCenter defaultCenter] addObserver:self
												selector:@selector(keyboardWillShow:)
												name:UIKeyboardWillShowNotification
												object:self.view.window];
}

- (void)viewWillDisappear:(BOOL)animated
{
	// unregister for keyboard notifications while not visible.
	[[NSNotificationCenter defaultCenter] removeObserver:self
												name:UIKeyboardWillShowNotification
												object:nil];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[_afterEventNavigationController release];
	[_afterEventViewController release];
	[_bouquetListController release];
	[_serviceListController release];
	[_datePickerController release];
	[_datePickerNavigationController release];
	[_locationListController release];
	[_filterViewController release];
	[_filterNavigationController release];

	_afterEventNavigationController = nil;
	_afterEventViewController = nil;
	_bouquetListController = nil;
	_serviceListController = nil;
	_datePickerController = nil;
	_datePickerNavigationController = nil;
	_locationListController = nil;
	_filterViewController = nil;
	_filterNavigationController = nil;
}

#pragma mark -
#pragma mark Split view support
#pragma mark -

- (void)splitViewController:(MGSplitViewController*)svc willHideViewController:(UIViewController *)aViewController withBarButtonItem:(UIBarButtonItem*)barButtonItem forPopoverController: (UIPopoverController*)pc
{
	barButtonItem.title = aViewController.title;
	[_popoverButtonItem release];
	_popoverButtonItem = [barButtonItem retain];

	// assign popover button if there is no left button assigned.
	if(!self.navigationItem.leftBarButtonItem)
	{
		self.navigationItem.leftBarButtonItem = barButtonItem;
	}
	self.popoverController = pc;
}


// Called when the view is shown again in the split view, invalidating the button and popover controller.
- (void)splitViewController:(MGSplitViewController*)svc willShowViewController:(UIViewController *)aViewController invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem
{
	[_popoverButtonItem release];
	_popoverButtonItem = nil;
	if([self.navigationItem.leftBarButtonItem isEqual: barButtonItem])
	{
		[self.navigationItem setLeftBarButtonItem:nil animated:YES];
	}
	self.popoverController = nil;
}

@end
