//
//  TimerViewController.m
//  dreaMote
//
//  Created by Moritz Venn on 10.03.08.
//  Copyright 2008-2011 Moritz Venn. All rights reserved.
//

#import "TimerViewController.h"

#import "BouquetListController.h"
#import "ServiceListController.h"
#import "DatePickerController.h"

#import "RemoteConnectorObject.h"
#import "Constants.h"
#import "FuzzyDateFormatter.h"

#import "DisplayCell.h"

#import "Objects/Generic/Timer.h"
#import "Objects/Generic/Result.h"

/*!
 @brief Private functions of TimerViewController.
 */
@interface TimerViewController()
/*!
 @brief Animate View up or down.
 Animate the entire view up or down, to prevent the keyboard from covering the text field.
 
 @param movedUp YES if moving down again.
 */
- (void)setViewMovedUp:(BOOL)movedUp;

/*!
 @brief stop editing
 @param sender ui element
 */
- (void)cancelEdit:(id)sender;
@property (nonatomic, retain) UIPopoverController *popoverController;
@property (nonatomic, readonly) AfterEventViewController *afterEventViewController;
@property (nonatomic, readonly) UIViewController *afterEventNavigationController;
@property (nonatomic, readonly) UIViewController *bouquetListController;
@property (nonatomic, readonly) DatePickerController *datePickerController;
@property (nonatomic, readonly) UIViewController *datePickerNavigationController;
@property (nonatomic, readonly) UIViewController *locationListController;
@property (nonatomic, readonly) SimpleRepeatedViewController *simpleRepeatedViewController;
@property (nonatomic, readonly) UIViewController *simpleRepeatedNavigationController;

@end

@implementation TimerViewController

/*!
 @brief Keyboard offset.
 The amount of vertical shift upwards to keep the text field in view as the keyboard appears.
 */
#define kOFFSET_FOR_KEYBOARD					100

/*! @brief The duration of the animation for the view shift. */
#define kVerticalOffsetAnimationDuration		(CGFloat)0.30

@synthesize delegate = _delegate;
@synthesize oldTimer = _oldTimer;
@synthesize popoverController;

- (id)init
{
	if((self = [super init]))
	{
		self.title = NSLocalizedString(@"Timer", @"Default title of TimerViewController");

		_creatingNewTimer = NO;
		_bouquetListController = nil;
		_datePickerController = nil;
		_afterEventViewController = nil;
		_simpleRepeatedViewController = nil;
		_timerServiceNameCell = nil;
		_timerBeginCell = nil;
		_timerEndCell = nil;
		_repeatedCell = nil;
		_popoverButtonItem = nil;
	}
	return self;
}

+ (TimerViewController *)newWithEvent: (NSObject<EventProtocol> *)ourEvent
{
	TimerViewController *timerViewController = [[TimerViewController alloc] init];
	NSObject<TimerProtocol> *newTimer = [GenericTimer withEvent: ourEvent];
	timerViewController.timer = newTimer;
	timerViewController.creatingNewTimer = YES;

	return timerViewController;
}

+ (TimerViewController *)newWithEventAndService: (NSObject<EventProtocol> *)ourEvent: (NSObject<ServiceProtocol> *)ourService
{
	TimerViewController *timerViewController = [[TimerViewController alloc] init];
	NSObject<TimerProtocol> *newTimer = [GenericTimer withEventAndService: ourEvent: ourService];
	timerViewController.timer = newTimer;
	timerViewController.creatingNewTimer = YES;

	return timerViewController;
}

+ (TimerViewController *)newWithTimer: (NSObject<TimerProtocol> *)ourTimer
{
	TimerViewController *timerViewController = [[TimerViewController alloc] init];
	timerViewController.timer = ourTimer;
	NSObject<TimerProtocol> *ourCopy = [ourTimer copy];
	timerViewController.oldTimer = ourCopy;
	timerViewController.creatingNewTimer = NO;

	return timerViewController;
}

+ (TimerViewController *)newTimer
{
	TimerViewController *timerViewController = [[TimerViewController alloc] init];
	NSObject<TimerProtocol> *newTimer = [GenericTimer timer];
	timerViewController.timer = newTimer;
	timerViewController.creatingNewTimer = YES;

	return timerViewController;
}

- (void)dealloc
{
	[_timer release];
	[_oldTimer release];
	[_delegate release];

	[_timerTitle release];
	[_timerDescription release];
	[_timerEnabled release];
	[_timerJustplay release];
	[_cancelButtonItem release];
	[_popoverButtonItem release];
	[popoverController release];

	[_afterEventNavigationController release];
	[_afterEventViewController release];
	[_bouquetListController release];
	[_datePickerController release];
	[_datePickerNavigationController release];
	[_locationListController release];
	[_simpleRepeatedNavigationController release];
	[_simpleRepeatedViewController release];

	[super dealloc];
}

- (void)didReceiveMemoryWarning
{
	[_afterEventNavigationController release];
	[_afterEventViewController release];
	[_bouquetListController release];
	[_datePickerController release];
	[_datePickerNavigationController release];
	[_locationListController release];
	[_simpleRepeatedNavigationController release];
	[_simpleRepeatedViewController release];
	
	_afterEventNavigationController = nil;
	_afterEventViewController = nil;
	_bouquetListController = nil;
	_datePickerController = nil;
	_datePickerNavigationController = nil;
	_locationListController = nil;
	_simpleRepeatedNavigationController = nil;
	_simpleRepeatedViewController = nil;
	
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
			[(BouquetListController *)rootViewController setDelegate: self];
		}

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

- (UIViewController *)locationListController
{
	if(_locationListController == nil)
	{
		LocationListController *rootViewController = [[LocationListController alloc] init];
		[rootViewController setDelegate: self];

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

- (UIViewController *)simpleRepeatedNavigationController
{
	if(IS_IPAD())
	{
		if(_simpleRepeatedNavigationController == nil)
		{
			_simpleRepeatedNavigationController = [[UINavigationController alloc] initWithRootViewController:self.simpleRepeatedViewController];
			_simpleRepeatedNavigationController.modalPresentationStyle = _simpleRepeatedViewController.modalPresentationStyle;
			_simpleRepeatedNavigationController.modalTransitionStyle = _simpleRepeatedViewController.modalTransitionStyle;
		}
		return _simpleRepeatedNavigationController;
	}
	return _simpleRepeatedViewController;
}

- (SimpleRepeatedViewController *)simpleRepeatedViewController
{
	if(_simpleRepeatedViewController == nil)
	{
		_simpleRepeatedViewController = [[SimpleRepeatedViewController alloc] init];
		[_simpleRepeatedViewController setDelegate: self];
	}
	return _simpleRepeatedViewController;
}

- (NSObject<TimerProtocol> *)timer
{
	return _timer;
}

- (void)setTimer: (NSObject<TimerProtocol> *)newTimer
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
	
	_timerTitle.text = newTimer.title;
	_timerDescription.text = newTimer.tdescription;
	[_timerEnabled setOn: !newTimer.disabled];
	[_timerJustplay setOn: newTimer.justplay];

	[(UITableView *)self.view reloadData];
	[(UITableView *)self.view
						scrollToRowAtIndexPath: [NSIndexPath indexPathForRow:0 inSection:0]
						atScrollPosition: UITableViewScrollPositionTop
						animated: NO];
	
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
		self.title = NSLocalizedString(@"New Timer", @"");
	else
		self.title = NSLocalizedString(@"Timer", @"Default title of TimerViewController");

	_shouldSave = NO;
	_creatingNewTimer = newValue;

	// start editing here for new, waiting or disabled timers
	if(newValue || _oldTimer.state == kTimerStateWaiting || _oldTimer.disabled)
		[self setEditing:YES animated:YES];
}

#pragma mark -
#pragma mark Helper methods
#pragma mark -

- (NSString *)format_BeginEnd: (NSDate *)dateTime
{
	// Date Formatter
	FuzzyDateFormatter *format = [[[FuzzyDateFormatter alloc] init] autorelease];
	[format setDateStyle:NSDateFormatterMediumStyle];
	[format setTimeStyle:NSDateFormatterShortStyle];

	return [format stringFromDate: dateTime];
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
	UITextField *returnTextField = [self allocTextField];
	returnTextField.text = _timer.title;
	returnTextField.placeholder = NSLocalizedString(@"<enter title>", @"Placeholder of _timerTitle");
	
	return returnTextField;
}

- (UITextField *)newDescriptionField
{
	UITextField *returnTextField = [self allocTextField];
	returnTextField.text = _timer.tdescription;
	returnTextField.placeholder = NSLocalizedString(@"<enter description>", @"Placeholder of _timerDescription");

	return returnTextField;
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

	// setup our content view so that it auto-rotates along with the UViewController
	tableView.autoresizesSubviews = YES;
	tableView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
	
	self.view = tableView;
	[tableView release];

	_timerTitle = [self newTitleField];
	_timerDescription = [self newDescriptionField];

	// Enabled
	_timerEnabled = [[UISwitch alloc] initWithFrame: CGRectMake(0, 0, 300, kSwitchButtonHeight)];
	[_timerEnabled setOn: !_timer.disabled];

	// in case the parent view draws with a custom color or gradient, use a transparent color
	_timerEnabled.backgroundColor = [UIColor clearColor];

	// Justplay
	_timerJustplay = [[UISwitch alloc] initWithFrame: CGRectMake(0, 0, 300, kSwitchButtonHeight)];
	[_timerJustplay setOn: _timer.justplay];

	// in case the parent view draws with a custom color or gradient, use a transparent color
	_timerJustplay.backgroundColor = [UIColor clearColor];

	// default editing mode depends on our mode
	_shouldSave = NO;
	[self setEditing: _creatingNewTimer];
}

#pragma mark -
#pragma mark UIViewController
#pragma mark -

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
	if(!_creatingNewTimer && _oldTimer.state != 0 && !_oldTimer.disabled)
	{
		if(editing)
		{
			UIAlertView *notification = [[UIAlertView alloc]
								initWithTitle:NSLocalizedString(@"Error", @"")
								message:NSLocalizedString(@"Can't edit a running or finished timer.", @"")
								delegate:nil
								cancelButtonTitle:@"OK"
								otherButtonTitles:nil];
			[notification show];
			[notification release];
		}
		else
		{
			self.navigationItem.leftBarButtonItem = _popoverButtonItem;

			[super setEditing: NO animated: animated];
			[self cellShouldBeginEditing: nil];
			[_timerTitleCell setEditing: NO animated: animated];
			[_timerDescriptionCell setEditing: NO animated: animated];
			_timerEnabled.enabled = NO;
			_timerJustplay.enabled = NO;
		}

		[_delegate timerViewController:self editingWasCanceled:_oldTimer];
		return;
	}

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

		// See if we actually have a Service
		if(_timer.service == nil || !_timer.service.valid)
			message = NSLocalizedString(@"Can't save a timer without a service.", @"");

		// Sanity Check Title
		if(_timerTitle.text && [_timerTitle.text length])
			_timer.title = _timerTitle.text;
		else
			message = NSLocalizedString(@"Can't save a timer with an empty title.", @"");

		// Get Description
		if(_timerDescription.text && [_timerDescription.text length])
			_timer.tdescription = _timerDescription.text;
		else
			_timer.tdescription = @"";

		_timer.disabled = !_timerEnabled.on;
		_timer.justplay = _timerJustplay.on;

		// Try to commit changes if no error occured
		if(!message)
		{
			if(_creatingNewTimer)
			{
				Result *result = [[RemoteConnectorObject sharedRemoteConnector] addTimer: _timer];
				if(!result.result)
					message = [NSString stringWithFormat: NSLocalizedString(@"Error adding new timer: %@", @""), result.resulttext];
				else
				{
					[_delegate timerViewController:self timerWasAdded:_timer];
					[self.navigationController popViewControllerAnimated: YES];
				}
			}
			else
			{
				Result *result = [[RemoteConnectorObject sharedRemoteConnector] editTimer: _oldTimer: _timer];
				if(!result.result)
					message = [NSString stringWithFormat: NSLocalizedString(@"Error editing timer: %@", @""), result.resulttext];
				else
				{
					[_delegate timerViewController:self timerWasEdited:_timer :_oldTimer];
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

			[_delegate timerViewController:self editingWasCanceled:_oldTimer];
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

	[_timerTitleCell setEditing:editing animated:animated];
	[_timerDescriptionCell setEditing:editing animated:animated];
	_timerEnabled.enabled = editing;
	_timerJustplay.enabled = editing;

	[(UITableView *)self.view reloadData];
}

- (void)cancelEdit:(id)sender
{
	_shouldSave = NO;
	[self cellShouldBeginEditing: nil];
	[self setEditing: NO animated: YES];
	[self.navigationController popViewControllerAnimated: YES];
}

/* rotate with device */
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

#pragma mark -
#pragma mark DatePickerController callbacks
#pragma mark -

- (void)beginSelected: (NSDate *)newDate
{
	if(newDate == nil)
		return;
	
	_timer.begin = newDate;
	if(_timerBeginCell)
		TABLEVIEWCELL_TEXT(_timerBeginCell) = [self format_BeginEnd: newDate];
}

- (void)endSelected: (NSDate *)newDate
{
	if(newDate == nil)
		return;
	
	_timer.end = newDate;
	if(_timerEndCell)
		TABLEVIEWCELL_TEXT(_timerEndCell) = [self format_BeginEnd: newDate];
}

#pragma mark -
#pragma mark ServiceListDelegate methods
#pragma mark -

- (void)serviceSelected: (NSObject<ServiceProtocol> *)newService
{
	if(newService == nil)
		return;

	// We copy the the service because it might be bound to an xmlnode we might free
	// during our runtime.
	_timer.service = [newService copy];
	if(_timerServiceNameCell)
		TABLEVIEWCELL_TEXT(_timerServiceNameCell) = _timer.service.sname;
}

#pragma mark -
#pragma mark SimpleRepeatedDelegate methods
#pragma mark -

- (void)simpleRepeatedSelected: (NSNumber *)newRepeated
{
	NSInteger repeated = -1;
	if(newRepeated == nil)
		return;

	repeated = [newRepeated integerValue];
	_timer.repeated = repeated;
	
	if(_repeatedCell == nil)
		return;
	
	if(repeated == 0)
	{
		TABLEVIEWCELL_TEXT(_repeatedCell) = NSLocalizedString(@"Never", @"Repeated");
	}
	else
	{
		NSMutableString *text = nil;

		if(repeated == 31)
		{
			TABLEVIEWCELL_TEXT(_repeatedCell) = NSLocalizedString(@"Weekdays", @"Repeated");
			return;
		}
		else if (repeated == 127)
		{
			TABLEVIEWCELL_TEXT(_repeatedCell) = NSLocalizedString(@"Daily", @"Repeated");
			return;
		}

		text = [NSMutableString stringWithCapacity: 10];
		if(repeated & weekdayMon)
			[text appendString: NSLocalizedString(@"Mon", "Weekday")];
		if(repeated & weekdayTue)
			[text appendString: NSLocalizedString(@"Tue", "Weekday")];
		if(repeated & weekdayWed)
			[text appendString: NSLocalizedString(@"Wed", "Weekday")];
		if(repeated & weekdayThu)
			[text appendString: NSLocalizedString(@"Thu", "Weekday")];
		if(repeated & weekdayFri)
			[text appendString: NSLocalizedString(@"Fri", "Weekday")];
		if(repeated & weekdaySat)
			[text appendString: NSLocalizedString(@"Sat", "Weekday")];
		if(repeated & weekdaySun)
			[text appendString: NSLocalizedString(@"Sun", "Weekday")];

		TABLEVIEWCELL_TEXT(_repeatedCell) = text;
	}
}

#pragma mark -
#pragma mark AfterEventDelegate methods
#pragma mark -

- (void)afterEventSelected: (NSNumber *)newAfterEvent
{
	if(newAfterEvent == nil)
		return;
	
	_timer.afterevent = [newAfterEvent integerValue];
	
	if(_afterEventCell == nil)
		return;

	if(_timer.afterevent == kAfterEventNothing)
		TABLEVIEWCELL_TEXT(_afterEventCell) = NSLocalizedString(@"Nothing", @"After Event");
	else if(_timer.afterevent == kAfterEventStandby)
		TABLEVIEWCELL_TEXT(_afterEventCell) = NSLocalizedString(@"Standby", @"");
	else if(_timer.afterevent == kAfterEventDeepstandby)
		TABLEVIEWCELL_TEXT(_afterEventCell) = NSLocalizedString(@"Deep Standby", @"");
	else //if(_timer.afterevent == kFeaturesTimerAfterEventAuto)
		TABLEVIEWCELL_TEXT(_afterEventCell) = NSLocalizedString(@"Auto", @"");
}

#pragma mark -
#pragma mark LocationListDelegate methods
#pragma mark -

- (void)locationSelected:(NSObject <LocationProtocol>*)newLocation
{
	if(newLocation == nil)
		return;

	_timer.location = newLocation.fullpath;

	if(_locationCell == nil)
		return;

	TABLEVIEWCELL_TEXT(_locationCell) = newLocation.fullpath;
}

#pragma mark -
#pragma mark UITableView delegates
#pragma mark -

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	NSInteger sections = 6;
	if([[RemoteConnectorObject sharedRemoteConnector] hasFeature: kFeaturesTimerAfterEvent])
		++sections;
	if([[RemoteConnectorObject sharedRemoteConnector] hasFeature: kFeaturesSimpleRepeated])
		++sections;
	if([[RemoteConnectorObject sharedRemoteConnector] hasFeature: kFeaturesRecordingLocations])
		++sections;
	return sections;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	if(section > 5 && ![[RemoteConnectorObject sharedRemoteConnector] hasFeature: kFeaturesTimerAfterEvent])
		++section;
	if(section > 6 && ![[RemoteConnectorObject sharedRemoteConnector] hasFeature: kFeaturesSimpleRepeated])
		++section;
	if(section > 7 && ![[RemoteConnectorObject sharedRemoteConnector] hasFeature: kFeaturesRecordingLocations])
		++section;
		
	switch (section) {
		case 0:
			return NSLocalizedString(@"Title", @"");
		case 1:
			return NSLocalizedString(@"Description", @"");
		case 2:
			return NSLocalizedString(@"General", @"in timer settings dialog");
		case 3:
			return NSLocalizedString(@"Service", @"");
		case 4:
			return NSLocalizedString(@"Begin", @"");
		case 5:
			return NSLocalizedString(@"End", @"");
		case 6:
			return NSLocalizedString(@"After Event", @"");
		case 7:
			return NSLocalizedString(@"Repeated", @"");
		case 8:
			return NSLocalizedString(@"Location", @"");
		default:
			return nil;
	}
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	if(section == 2
	   && [[RemoteConnectorObject sharedRemoteConnector] hasFeature: kFeaturesDisabledTimers])
		return 2;
	return 1;
}

// utility routine leveraged by 'cellForRowAtIndexPath' to determine which UITableViewCell to be used on a given section.
//
- (UITableViewCell *)obtainTableCellForSection:(UITableView *)tableView: (NSInteger)section
{
	BOOL setEditingStyle = YES;
	UITableViewCell *cell = nil;

	switch (section) {
		case 0:
		case 1:
			cell = [tableView dequeueReusableCellWithIdentifier:kCellTextField_ID];
			if(cell == nil)
				cell = [[[CellTextField alloc] initWithFrame:CGRectZero reuseIdentifier:kCellTextField_ID] autorelease];
			((CellTextField *)cell).delegate = self;	// so we can detect when cell editing starts
			break;
		case 2:
			cell = [tableView dequeueReusableCellWithIdentifier:kDisplayCell_ID];
			if(cell == nil)
				cell = [[[DisplayCell alloc] initWithFrame:CGRectZero reuseIdentifier:kDisplayCell_ID] autorelease];
			break;
		case 3:
		case 4:
		case 5:
		case 6:
		case 7:
		case 8:
			cell = [tableView dequeueReusableCellWithIdentifier:kVanilla_ID];
			if(cell == nil)
				cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:kVanilla_ID] autorelease];
			TABLEVIEWCELL_FONT(cell) = [UIFont systemFontOfSize:kTextViewFontSize];

			if(self.editing)
			{
				cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
				setEditingStyle = NO;
			}
			break;
		default:
			break;
	}

	// no accessory by default
	if(setEditingStyle)
		cell.accessoryType = UITableViewCellAccessoryNone;

	return cell;
}

// to determine which UITableViewCell to be used on a given row.
//
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSInteger section = indexPath.section;
	UITableViewCell *sourceCell = nil;

	if(section > 5 && ![[RemoteConnectorObject sharedRemoteConnector] hasFeature: kFeaturesTimerAfterEvent])
		++section;
	if(section > 6 && ![[RemoteConnectorObject sharedRemoteConnector] hasFeature: kFeaturesSimpleRepeated])
		++section;
	if(section > 7 && ![[RemoteConnectorObject sharedRemoteConnector] hasFeature: kFeaturesRecordingLocations])
		++section;

	sourceCell = [self obtainTableCellForSection: tableView: section];

	// we are creating a new cell, setup its attributes
	switch (section) {
		case 0:
			((CellTextField *)sourceCell).view = _timerTitle;
			_timerTitleCell = (CellTextField *)sourceCell;
			break;
		case 1:
			((CellTextField *)sourceCell).view = _timerDescription;
			_timerDescriptionCell = (CellTextField *)sourceCell;
			break;
		case 2:
			switch (indexPath.row) {
				case 0:
					if([[RemoteConnectorObject sharedRemoteConnector] hasFeature: kFeaturesDisabledTimers])
					{
						((DisplayCell *)sourceCell).nameLabel.text = NSLocalizedString(@"Enabled", @"");
						((DisplayCell *)sourceCell).view = _timerEnabled;
						break;
					}
				case 1:
					((DisplayCell *)sourceCell).nameLabel.text = NSLocalizedString(@"Justplay", @"");
					((DisplayCell *)sourceCell).view = _timerJustplay;
					break;
				default:
					break;
			}
			break;
		case 3:
			if([self.timer.service.sname length])
				TABLEVIEWCELL_TEXT(sourceCell) = _timer.service.sname;
			else
				TABLEVIEWCELL_TEXT(sourceCell) = NSLocalizedString(@"Select Service", @"");
			_timerServiceNameCell = sourceCell;
			break;
		case 4:
			TABLEVIEWCELL_TEXT(sourceCell) = [self format_BeginEnd: _timer.begin];
			_timerBeginCell = sourceCell;
			break;
		case 5:
			TABLEVIEWCELL_TEXT(sourceCell) = [self format_BeginEnd: _timer.end];
			_timerEndCell = sourceCell;
			break;
		case 6:
			_afterEventCell = sourceCell;
			[self afterEventSelected: [NSNumber numberWithInteger: _timer.afterevent]];
			break;
		case 7:
			_repeatedCell = sourceCell;
			[self simpleRepeatedSelected: [NSNumber numberWithInteger: _timer.repeated]];
			break;
		case 8:
			_locationCell = sourceCell;
			TABLEVIEWCELL_TEXT(sourceCell) = (_timer.location) ? _timer.location : NSLocalizedString(@"Default Location", @"");
			break;
		default:
			break;
	}

	return sourceCell;
}

- (NSIndexPath *)tableView:(UITableView *)tv willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if(self.editing)
	{
		NSInteger section = indexPath.section;
		UIViewController *targetViewController = nil;

		if(section > 5 && ![[RemoteConnectorObject sharedRemoteConnector] hasFeature: kFeaturesTimerAfterEvent])
			++section;
		if(section > 6 && ![[RemoteConnectorObject sharedRemoteConnector] hasFeature: kFeaturesSimpleRepeated])
			++section;

		if(section == 3)
		{
			// property takes care of overly complex initialization
			targetViewController = self.bouquetListController;
		}
		else if(section == 4)
		{
			// property takes care of initialization (including navigation controller)
			self.datePickerController.date = [_timer.begin copy];
			[self.datePickerController setTarget: self action: @selector(beginSelected:)];

			targetViewController = self.datePickerNavigationController;
		}
		else if(section == 5)
		{
			// property takes care of initialization (including navigation controller)
			self.datePickerController.date = [_timer.end copy];
			[self.datePickerController setTarget: self action: @selector(endSelected:)];

			targetViewController = self.datePickerNavigationController;
		}
		else if(section == 6)
		{
			self.afterEventViewController.selectedItem = _timer.afterevent;
			// FIXME: why gives directly assigning this an error?
			const BOOL showAuto = [[RemoteConnectorObject sharedRemoteConnector] hasFeature: kFeaturesTimerAfterEventAuto];
			self.afterEventViewController.showAuto = showAuto;

			targetViewController = self.afterEventNavigationController;
		}
		else if(section == 7)
		{
			// property takes care of initialization
			self.simpleRepeatedViewController.repeated = _timer.repeated;
			targetViewController = self.simpleRepeatedNavigationController;
		}
		else if(section == 8)
		{
			// property takes care of initialization
			targetViewController = self.locationListController;
		}
		else
			return nil;

		if(IS_IPAD())
			[self.navigationController presentModalViewController:targetViewController animated:YES];
		else
			[self.navigationController pushViewController: targetViewController animated: YES];
	}

	// We don't want any actual response :-)
	return nil;
}

#pragma mark -
#pragma mark <EditableTableViewCellDelegate> Methods and editing management
#pragma mark -

- (BOOL)cellShouldBeginEditing:(EditableTableViewCell *)cell
{
	// notify other cells to end editing
	if (![cell isEqual:_timerTitleCell])
		[_timerTitleCell stopEditing];
	if (![cell isEqual:_timerDescriptionCell])
		[_timerDescriptionCell stopEditing];

	return self.editing;
}

- (void)cellDidEndEditing:(EditableTableViewCell *)cell
{
	if ([cell isEqual:_timerTitleCell] || [cell isEqual:_timerDescriptionCell])
	{
		// Restore the position of the main view if it was animated to make room for the keyboard.
		if  (self.view.frame.origin.y < 0)
			[self setViewMovedUp:NO];
	}
}

// Animate the entire view up or down, to prevent the keyboard from covering the author field.
- (void)setViewMovedUp:(BOOL)movedUp
{
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:kVerticalOffsetAnimationDuration];
	// Make changes to the view's frame inside the animation block. They will be animated instead
	// of taking place immediately.
	CGRect rect = self.view.frame;
	if (movedUp)
	{
		// If moving up, not only decrease the origin but increase the height so the view 
		// covers the entire screen behind the keyboard.
		rect.origin.y -= kOFFSET_FOR_KEYBOARD;
		rect.size.height += kOFFSET_FOR_KEYBOARD;
	}
	else
	{
		// If moving down, not only increase the origin but decrease the height.
		rect.origin.y += kOFFSET_FOR_KEYBOARD;
		rect.size.height -= kOFFSET_FOR_KEYBOARD;
	}
	self.view.frame = rect;

	[UIView commitAnimations];
}

- (void)keyboardWillShow:(NSNotification *)notif
{
	// The keyboard will be shown. If the user is editing the description, adjust the display so
	// that the description field will not be covered by the keyboard.
	if ((_timerDescriptionCell.isInlineEditing) && self.view.frame.origin.y >= 0)
		[self setViewMovedUp:YES];
	else if (!_timerDescriptionCell.isInlineEditing && self.view.frame.origin.y < 0)
		[self setViewMovedUp:NO];
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
	[_datePickerController release];
	[_datePickerNavigationController release];
	[_locationListController release];
	[_simpleRepeatedNavigationController release];
	[_simpleRepeatedViewController release];

	_afterEventNavigationController = nil;
	_afterEventViewController = nil;
	_bouquetListController = nil;
	_datePickerController = nil;
	_datePickerNavigationController = nil;
	_locationListController = nil;
	_simpleRepeatedNavigationController = nil;
	_simpleRepeatedViewController = nil;
}

#pragma mark -
#pragma mark Split view support
#pragma mark -

- (void)splitViewController: (UISplitViewController*)svc willHideViewController:(UIViewController *)aViewController withBarButtonItem:(UIBarButtonItem*)barButtonItem forPopoverController: (UIPopoverController*)pc
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
- (void)splitViewController: (UISplitViewController*)svc willShowViewController:(UIViewController *)aViewController invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem
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
