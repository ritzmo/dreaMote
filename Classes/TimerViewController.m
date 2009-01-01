//
//  TimerViewController.m
//  Untitled
//
//  Created by Moritz Venn on 10.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "TimerViewController.h"

#import "ServiceListController.h"
#import "DatePickerController.h"
#import "AfterEventViewController.h"

#import "RemoteConnectorObject.h"
#import "Constants.h"
#import "FuzzyDateFormatter.h"

#import "DisplayCell.h"

#import "Objects/Generic/Timer.h"
#import "Objects/Generic/Service.h"

@interface TimerViewController()
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
		serviceListController = nil;
		datePickerController = nil;
		afterEventViewController = nil;
	}
	return self;
}

+ (TimerViewController *)withEvent: (NSObject<EventProtocol> *)ourEvent
{
	TimerViewController *timerViewController = [[TimerViewController alloc] init];
	NSObject<TimerProtocol> *newTimer = [Timer withEvent: ourEvent];
	timerViewController.timer = newTimer;
	[newTimer release];
	timerViewController.creatingNewTimer = YES;

	return timerViewController;
}

+ (TimerViewController *)withEventAndService: (NSObject<EventProtocol> *)ourEvent: (Service *)ourService
{
	TimerViewController *timerViewController = [[TimerViewController alloc] init];
	NSObject<TimerProtocol> *newTimer = [Timer withEventAndService: ourEvent: ourService];
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
	NSObject<TimerProtocol> *newTimer = [Timer timer];
	timerViewController.timer = newTimer;
	[newTimer release];
	timerViewController.creatingNewTimer = YES;

	return timerViewController;
}

- (void)dealloc
{
	[_timer release];
	[_oldTimer release];

	[timerTitle release];
	[timerDescription release];
	[timerEnabled release];
	[timerJustplay release];

	[serviceListController release];
	[afterEventViewController release];
	[datePickerController release];

	[super dealloc];
}

- (void)didReceiveMemoryWarning
{
	[serviceListController release];
	[afterEventViewController release];
	[datePickerController release];
	
	serviceListController = nil;
	afterEventViewController = nil;
	datePickerController = nil;
	
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

	timerTitle.text = newTimer.title;
	timerDescription.text = newTimer.tdescription;
	[timerEnabled setOn: !newTimer.disabled];
	[timerJustplay setOn: newTimer.justplay];

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
	returnTextField.placeholder = NSLocalizedString(@"<enter title>", @"Placeholder of timerTitle");
	
	return returnTextField;
}

- (UITextField *)create_DescriptionField
{
	UITextField *returnTextField = [self create_TextField];
	returnTextField.text = _timer.tdescription;
	returnTextField.placeholder = NSLocalizedString(@"<enter description>", @"Placeholder of timerDescription");

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

	timerTitle = [self create_TitleField];
	timerDescription = [self create_DescriptionField];

	// Enabled
	timerEnabled = [[UISwitch alloc] initWithFrame: CGRectMake(0, 0, 300, kSwitchButtonHeight)];
	[timerEnabled setOn: !_timer.disabled];

	// in case the parent view draws with a custom color or gradient, use a transparent color
	timerEnabled.backgroundColor = [UIColor clearColor];

	// Justplay
	timerJustplay = [[UISwitch alloc] initWithFrame: CGRectMake(0, 0, 300, kSwitchButtonHeight)];
	[timerJustplay setOn: _timer.justplay];

	// in case the parent view draws with a custom color or gradient, use a transparent color
	timerJustplay.backgroundColor = [UIColor clearColor];

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
			[timerTitleCell setEditing: NO animated: animated];
			[timerDescriptionCell setEditing: NO animated: animated];
			timerEnabled.enabled = NO;
			timerJustplay.enabled = NO;
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
		if(timerTitle.text && [timerTitle.text length])
			_timer.title = timerTitle.text;
		else
			message = NSLocalizedString(@"Can't save a timer with an empty title.", @"");

		// Get Description
		if(timerDescription.text && [timerDescription.text length])
			_timer.tdescription = timerDescription.text;
		else
			_timer.tdescription = @"";

		_timer.disabled = !timerEnabled.on;
		_timer.justplay = timerJustplay.on;

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

	[timerTitleCell setEditing:editing animated:animated];
	[timerDescriptionCell setEditing:editing animated:animated];
	timerEnabled.enabled = editing;
	timerJustplay.enabled = editing;

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

- (void)serviceSelected: (Service *)newService
{
	if(newService == nil)
		return;

	_timer.service = newService;
	timerServiceNameCell.text = newService.sname;
}

- (void)beginSelected: (NSDate *)newDate
{
	if(newDate == nil)
		return;

	_timer.begin = newDate;
	timerBeginCell.text = [self format_BeginEnd: newDate];
}

- (void)endSelected: (NSDate *)newDate
{
	if(newDate == nil)
		return;

	_timer.end = newDate;
	timerEndCell.text = [self format_BeginEnd: newDate];
}

- (void)afterEventSelected: (NSNumber *)newAfterEvent
{
	if(newAfterEvent == nil)
		return;
	
	_timer.afterevent = [newAfterEvent integerValue];
	
	if(_timer.afterevent == kAfterEventNothing)
		afterEventCell.text = NSLocalizedString(@"Nothing", @"After Event");
	else if(_timer.afterevent == kAfterEventStandby)
		afterEventCell.text = NSLocalizedString(@"Standby", @"");
	else if(_timer.afterevent == kAfterEventDeepstandby)
		afterEventCell.text = NSLocalizedString(@"Deep Standby", @"");
	else //if(_timer.afterevent == kFeaturesTimerAfterEventAuto)
		afterEventCell.text = NSLocalizedString(@"Auto", @"");
}

#pragma mark - UITableView delegates

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	if([[RemoteConnectorObject sharedRemoteConnector] hasFeature: kFeaturesTimerAfterEvent])
		return 7;
	return 6;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
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
			cell = [tableView dequeueReusableCellWithIdentifier:kVanilla_ID];
			if(cell == nil)
				cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:kVanilla_ID] autorelease];
			cell.font = [UIFont systemFontOfSize:kTextViewFontSize];
			break;
		default:
			break;
	}

	return cell;
}

// to determine which UITableViewCell to be used on a given row.
//
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSInteger section = indexPath.section;
	UITableViewCell *sourceCell = [self obtainTableCellForSection: tableView: section];

	// we are creating a new cell, setup its attributes
	switch (section) {
		case 0:
			((CellTextField *)sourceCell).view = timerTitle;
			timerTitleCell = (CellTextField *)sourceCell;
			break;
		case 1:
			((CellTextField *)sourceCell).view = timerDescription;
			timerDescriptionCell = (CellTextField *)sourceCell;
			break;
		case 2:
			switch (indexPath.row) {
				case 0:
					if([[RemoteConnectorObject sharedRemoteConnector] hasFeature: kFeaturesDisabledTimers])
					{
						((DisplayCell *)sourceCell).nameLabel.text = NSLocalizedString(@"Enabled", @"");
						((DisplayCell *)sourceCell).view = timerEnabled;
						break;
					}
				case 1:
					((DisplayCell *)sourceCell).nameLabel.text = NSLocalizedString(@"Justplay", @"");
					((DisplayCell *)sourceCell).view = timerJustplay;
					break;
				default:
					break;
			}
			break;
		case 3:
			if([self.timer.service.sname length])
				sourceCell.text = _timer.service.sname;
			else
				sourceCell.text = NSLocalizedString(@"Select Service", @"");
			timerServiceNameCell = sourceCell;
			break;
		case 4:
			sourceCell.text = [self format_BeginEnd: _timer.begin];
			timerBeginCell = sourceCell;
			break;
		case 5:
			sourceCell.text = [self format_BeginEnd: _timer.end];
			timerEndCell = sourceCell;
			break;
		case 6:
			if(_timer.afterevent == kAfterEventNothing)
				sourceCell.text = NSLocalizedString(@"Nothing", @"After Event");
			else if(_timer.afterevent == kAfterEventStandby)
				sourceCell.text = NSLocalizedString(@"Standby", @"");
			else if(_timer.afterevent == kAfterEventDeepstandby)
				sourceCell.text = NSLocalizedString(@"Deep Standby", @"");
			else //if(_timer.afterevent == kFeaturesTimerAfterEventAuto)
				sourceCell.text = NSLocalizedString(@"Auto", @"");

			afterEventCell = sourceCell;
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

		if(section == 3)
		{
			if(serviceListController == nil)
				serviceListController = [[ServiceListController alloc] init];
			[serviceListController setTarget: self action: @selector(serviceSelected:)];

			targetViewController = serviceListController;
		}
		else if(section == 4)
		{
			if(datePickerController == nil)
				datePickerController = [[DatePickerController alloc] init];
 			datePickerController.date = [_timer.begin copy];
			[datePickerController setTarget: self action: @selector(beginSelected:)];

			targetViewController = datePickerController;
		}
		else if(section == 5)
		{
			if(datePickerController == nil)
				datePickerController = [[DatePickerController alloc] init];
 			datePickerController.date = [_timer.end copy];
			[datePickerController setTarget: self action: @selector(endSelected:)];

			targetViewController = datePickerController;
		}
		else if(section == 6)
		{
			if(afterEventViewController == nil)
				afterEventViewController = [[AfterEventViewController alloc] init];
			afterEventViewController.selectedItem = _timer.afterevent;
			// XXX: why gives directly assigning this an error?
			BOOL showAuto = [[RemoteConnectorObject sharedRemoteConnector] hasFeature: kFeaturesTimerAfterEventAuto];
			afterEventViewController.showAuto = showAuto;
			[afterEventViewController setTarget: self action: @selector(afterEventSelected:)];

			targetViewController = afterEventViewController;
		}
		else
			return nil;

		[self.navigationController pushViewController: targetViewController animated: YES];
	}

	// We don't want any actual response :-)
	return nil;
}

- (UITableViewCellAccessoryType)tableView:(UITableView *)tv accessoryTypeForRowWithIndexPath:(NSIndexPath *)indexPath {
	// Show the disclosure indicator in section 3..6 if editing.
	NSInteger section = indexPath.section;
	if(self.editing && section > 2 && section < 7)
		return UITableViewCellAccessoryDisclosureIndicator;
	return UITableViewCellAccessoryNone;
}

#pragma mark -
#pragma mark <EditableTableViewCellDelegate> Methods and editing management

- (BOOL)cellShouldBeginEditing:(EditableTableViewCell *)cell
{
	// notify other cells to end editing
	if (![cell isEqual:timerTitleCell])
		[timerTitleCell stopEditing];
	if (![cell isEqual:timerDescriptionCell])
		[timerDescriptionCell stopEditing];

	return self.editing;
}

- (void)cellDidEndEditing:(EditableTableViewCell *)cell
{
	if ([cell isEqual:timerTitleCell] || [cell isEqual:timerDescriptionCell])
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
	if ((timerDescriptionCell.isInlineEditing) && self.view.frame.origin.y >= 0)
		[self setViewMovedUp:YES];
	else if (!timerDescriptionCell.isInlineEditing && self.view.frame.origin.y < 0)
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
	[serviceListController release];
	[afterEventViewController release];
	[datePickerController release];
	
	serviceListController = nil;
	afterEventViewController = nil;
	datePickerController = nil;
}

@end
