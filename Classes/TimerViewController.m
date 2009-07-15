//
//  TimerViewController.m
//  dreaMote
//
//  Created by Moritz Venn on 10.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "TimerViewController.h"

#import "BouquetListController.h"
#import "DatePickerController.h"

#import "RemoteConnectorObject.h"
#import "Constants.h"
#import "FuzzyDateFormatter.h"

#import "DisplayCell.h"

#import "Objects/Generic/Timer.h"

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
@end

@implementation TimerViewController

// the amount of vertical shift upwards keep the text field in view as the keyboard appears
#define kOFFSET_FOR_KEYBOARD					100.0

// the duration of the animation for the view shift
#define kVerticalOffsetAnimationDuration		0.30

@synthesize oldTimer = _oldTimer;

- (id)init
{
	if (self = [super init])
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
	}
	return self;
}

+ (TimerViewController *)withEvent: (NSObject<EventProtocol> *)ourEvent
{
	TimerViewController *timerViewController = [[TimerViewController alloc] init];
	NSObject<TimerProtocol> *newTimer = [GenericTimer withEvent: ourEvent];
	timerViewController.timer = newTimer;
	[newTimer release];
	timerViewController.creatingNewTimer = YES;

	return timerViewController;
}

+ (TimerViewController *)withEventAndService: (NSObject<EventProtocol> *)ourEvent: (NSObject<ServiceProtocol> *)ourService
{
	TimerViewController *timerViewController = [[TimerViewController alloc] init];
	NSObject<TimerProtocol> *newTimer = [GenericTimer withEventAndService: ourEvent: ourService];
	timerViewController.timer = newTimer;
	[newTimer release];
	timerViewController.creatingNewTimer = YES;

	return timerViewController;
}

+ (TimerViewController *)withTimer: (NSObject<TimerProtocol> *)ourTimer
{
	TimerViewController *timerViewController = [[TimerViewController alloc] init];
	timerViewController.timer = ourTimer;
	NSObject<TimerProtocol> *ourCopy = [ourTimer copy];
	timerViewController.oldTimer = ourCopy;
	[ourCopy release];
	timerViewController.creatingNewTimer = NO;

	return timerViewController;
}

+ (TimerViewController *)newTimer
{
	TimerViewController *timerViewController = [[TimerViewController alloc] init];
	NSObject<TimerProtocol> *newTimer = [GenericTimer timer];
	timerViewController.timer = newTimer;
	[newTimer release];
	timerViewController.creatingNewTimer = YES;

	return timerViewController;
}

- (void)dealloc
{
	[_timer release];
	[_oldTimer release];

	[_timerTitle release];
	[_timerDescription release];
	[_timerEnabled release];
	[_timerJustplay release];

	[_bouquetListController release];
	[_afterEventViewController release];
	[_datePickerController release];
	[_simpleRepeatedViewController release];

	[super dealloc];
}

- (void)didReceiveMemoryWarning
{
	[_bouquetListController release];
	[_afterEventViewController release];
	[_datePickerController release];
	[_simpleRepeatedViewController release];
	
	_bouquetListController = nil;
	_afterEventViewController = nil;
	_datePickerController = nil;
	_simpleRepeatedViewController = nil;
	
	[super didReceiveMemoryWarning];
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
	[self setEditing: newValue animated: YES];
}

- (NSString *)format_BeginEnd: (NSDate *)dateTime
{
	// Date Formatter
	FuzzyDateFormatter *format = [[[FuzzyDateFormatter alloc] init] autorelease];
	[format setDateStyle:NSDateFormatterMediumStyle];
	[format setTimeStyle:NSDateFormatterShortStyle];

	return [format stringFromDate: dateTime];
}

- (UITextField *)create_TextField
{
	UITextField *returnTextField = [[UITextField alloc] initWithFrame:CGRectZero];

	returnTextField.leftView = nil;
	returnTextField.leftViewMode = UITextFieldViewModeNever;
	returnTextField.borderStyle = UITextBorderStyleRoundedRect;
	returnTextField.textColor = [UIColor blackColor];
	returnTextField.font = [UIFont systemFontOfSize:17.0];
	returnTextField.backgroundColor = [UIColor whiteColor];
	// no auto correction support
	returnTextField.autocorrectionType = UITextAutocorrectionTypeNo;

	returnTextField.keyboardType = UIKeyboardTypeDefault;
	returnTextField.returnKeyType = UIReturnKeyDone;

	// has a clear 'x' button to the right
	returnTextField.clearButtonMode = UITextFieldViewModeWhileEditing;

	return returnTextField;
}

- (UITextField *)create_TitleField
{
	UITextField *returnTextField = [self create_TextField];
	returnTextField.text = _timer.title;
	returnTextField.placeholder = NSLocalizedString(@"<enter title>", @"Placeholder of _timerTitle");
	
	return returnTextField;
}

- (UITextField *)create_DescriptionField
{
	UITextField *returnTextField = [self create_TextField];
	returnTextField.text = _timer.tdescription;
	returnTextField.placeholder = NSLocalizedString(@"<enter description>", @"Placeholder of _timerDescription");

	return returnTextField;
}

- (void)loadView
{
	self.navigationItem.rightBarButtonItem = self.editButtonItem;
	UIBarButtonItem *cancelButtonItem = [[UIBarButtonItem alloc]
							initWithBarButtonSystemItem: UIBarButtonSystemItemCancel
							target: self
							action: @selector(cancelEdit:)];
	self.navigationItem.leftBarButtonItem = cancelButtonItem;
	[cancelButtonItem release];

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

	_timerTitle = [self create_TitleField];
	_timerDescription = [self create_DescriptionField];

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

- (void)setEditing:(BOOL)editing animated:(BOOL)animated;
{
	if(!_creatingNewTimer && _oldTimer.state != 0)
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
			self.navigationItem.leftBarButtonItem = nil;
			[super setEditing: NO animated: animated];
			[self cellShouldBeginEditing: nil];
			[_timerTitleCell setEditing: NO animated: animated];
			[_timerDescriptionCell setEditing: NO animated: animated];
			_timerEnabled.enabled = NO;
			_timerJustplay.enabled = NO;
		}

		return;
	}

	if(editing)
	{
		UIBarButtonItem *cancelButtonItem = [[UIBarButtonItem alloc]
											 initWithBarButtonSystemItem: UIBarButtonSystemItemCancel
											 target: self
											 action: @selector(cancelEdit:)];
		self.navigationItem.leftBarButtonItem = cancelButtonItem;
		[cancelButtonItem release];
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
				if(![[RemoteConnectorObject sharedRemoteConnector] addTimer: _timer])
					message = NSLocalizedString(@"Error adding new timer.", @"");
				else
					[self.navigationController popViewControllerAnimated: YES];
			}
			else
			{
				if(![[RemoteConnectorObject sharedRemoteConnector] editTimer: _oldTimer: _timer])
					message = NSLocalizedString(@"Error editing timer.", @"");
				else
					[self.navigationController popViewControllerAnimated: YES];
			}
		}

		// Show error message if one occured
		if(message != nil)
		{
			UIAlertView *notification = [[UIAlertView alloc]
										 initWithTitle:NSLocalizedString(@"Error", @"")
										 message:message
										 delegate:nil
										 cancelButtonTitle:@"OK"
										 otherButtonTitles:nil];
			[notification show];
			[notification release];

			return;
		}

		self.navigationItem.leftBarButtonItem = nil;
	}
	else
		self.navigationItem.leftBarButtonItem = nil;

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

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	// Return YES for supported orientations
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

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

#pragma mark - UITableView delegates

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	NSInteger sections = 6;
	if([[RemoteConnectorObject sharedRemoteConnector] hasFeature: kFeaturesTimerAfterEvent])
		++sections;
	if([[RemoteConnectorObject sharedRemoteConnector] hasFeature: kFeaturesSimpleRepeated])
		++sections;
	return sections;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	if(section > 5 && ![[RemoteConnectorObject sharedRemoteConnector] hasFeature: kFeaturesTimerAfterEvent])
		++section;
	if(section > 6 && ![[RemoteConnectorObject sharedRemoteConnector] hasFeature: kFeaturesSimpleRepeated])
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
	static NSString *kVanilla_ID = @"Vanilla_ID";
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
			if(_bouquetListController == nil)
				_bouquetListController = [[BouquetListController alloc] init];
			[_bouquetListController setDelegate: self];

			targetViewController = _bouquetListController;
		}
		else if(section == 4)
		{
			if(_datePickerController == nil)
				_datePickerController = [[DatePickerController alloc] init];
 			_datePickerController.date = [_timer.begin copy];
			[_datePickerController setTarget: self action: @selector(beginSelected:)];

			targetViewController = _datePickerController;
		}
		else if(section == 5)
		{
			if(_datePickerController == nil)
				_datePickerController = [[DatePickerController alloc] init];
 			_datePickerController.date = [_timer.end copy];
			[_datePickerController setTarget: self action: @selector(endSelected:)];

			targetViewController = _datePickerController;
		}
		else if(section == 6)
		{
			if(_afterEventViewController == nil)
				_afterEventViewController = [[AfterEventViewController alloc] init];
			_afterEventViewController.selectedItem = _timer.afterevent;
			// XXX: why gives directly assigning this an error?
			BOOL showAuto = [[RemoteConnectorObject sharedRemoteConnector] hasFeature: kFeaturesTimerAfterEventAuto];
			_afterEventViewController.showAuto = showAuto;
			[_afterEventViewController setDelegate: self];

			targetViewController = _afterEventViewController;
		}
		else if(section == 7)
		{
			if(_simpleRepeatedViewController == nil)
				_simpleRepeatedViewController = [[SimpleRepeatedViewController alloc] init];
			_simpleRepeatedViewController.repeated = _timer.repeated;
			[_simpleRepeatedViewController setDelegate: self];
			
			targetViewController = _simpleRepeatedViewController;
		}
		else
			return nil;

		[self.navigationController pushViewController: targetViewController animated: YES];
	}

	// We don't want any actual response :-)
	return nil;
}

#pragma mark -
#pragma mark <EditableTableViewCellDelegate> Methods and editing management

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
	[UIView setAnimationDuration:0.3];
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

#pragma mark - UIViewController delegate methods

- (void)viewWillAppear:(BOOL)animated
{
	// watch the keyboard so we can adjust the user interface if necessary.
	[[NSNotificationCenter defaultCenter] addObserver:self
												selector:@selector(keyboardWillShow:) 
												name:UIKeyboardWillShowNotification
												object:self.view.window]; 
}

- (void)viewDidAppear:(BOOL)animated
{
	_shouldSave = YES;
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
	[_bouquetListController release];
	[_afterEventViewController release];
	[_datePickerController release];
	[_simpleRepeatedViewController release];
	
	_bouquetListController = nil;
	_afterEventViewController = nil;
	_datePickerController = nil;
	_simpleRepeatedViewController = nil;
}

@end
