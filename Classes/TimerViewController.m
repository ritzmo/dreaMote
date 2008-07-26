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

#import "RemoteConnectorObject.h"
#import "Constants.h"

@interface TimerViewController()
- (void)setViewMovedUp:(BOOL)movedUp;
@end

@implementation TimerViewController

// the amount of vertical shift upwards keep the text field in view as the keyboard appears
#define kOFFSET_FOR_KEYBOARD					150.0

#define kTextFieldWidth							100.0	// initial width, but the table cell will dictact the actual width

// the duration of the animation for the view shift
#define kVerticalOffsetAnimationDuration		0.30

@synthesize timer = _timer;
@synthesize oldTimer = _oldTimer;
@synthesize creatingNewTimer = _creatingNewTimer;
@synthesize service = _service;
@synthesize myTableView;

- (id)init
{
	if (self = [super init])
	{
		self.title = NSLocalizedString(@"Timer", @"Default title of TimerViewController");
	}
	return self;
}

+ (TimerViewController *)withEvent: (Event *)ourEvent
{
	TimerViewController *timerViewController = [[TimerViewController alloc] init];
	timerViewController.title = NSLocalizedString(@"New Timer", @"");
	timerViewController.timer = [Timer withEvent: ourEvent];
	timerViewController.creatingNewTimer = YES;

	return timerViewController;
}

+ (TimerViewController *)withEventAndService: (Event *)ourEvent: (Service *)ourService
{
	TimerViewController *timerViewController = [[TimerViewController alloc] init];
	timerViewController.title = NSLocalizedString(@"New Timer", @"");
	timerViewController.timer = [Timer withEventAndService: ourEvent: ourService];
	timerViewController.creatingNewTimer = YES;

	return timerViewController;
}

+ (TimerViewController *)withTimer: (Timer *)ourTimer
{
	TimerViewController *timerViewController = [[TimerViewController alloc] init];
	timerViewController.timer = [ourTimer retain];
	timerViewController.oldTimer = [ourTimer copy];
	timerViewController.creatingNewTimer = NO;

	return timerViewController;
}

+ (TimerViewController *)newTimer
{
	TimerViewController *timerViewController = [[TimerViewController alloc] init];
	timerViewController.title = NSLocalizedString(@"New Timer", @"");
	timerViewController.timer = [[Timer new] autorelease];
	timerViewController.creatingNewTimer = YES;

	return timerViewController;
}

- (void)dealloc
{
	[_timer release];
	[_service release];
	[_oldTimer release];

	[myTableView release];
	[timerTitle release];
	[timerDescription release];
	[timerServiceName release];
	[timerBegin release];
	[timerEnd release];
	[deleteButton release];

	[super dealloc];
}

- (NSString *)format_BeginEnd: (NSDate *)dateTime
{
	// Date Formatter
	NSDateFormatter *format = [[[NSDateFormatter alloc] init] autorelease];
	[format setDateStyle:NSDateFormatterMediumStyle];
	[format setTimeStyle:NSDateFormatterShortStyle];
	
	return [format stringFromDate: dateTime];
}

- (UITextField *)create_TextField
{
	CGRect frame = CGRectMake(0.0, 0.0, kTextFieldWidth, kTextFieldHeight);
	UITextField *returnTextField = [[UITextField alloc] initWithFrame:frame];

	returnTextField.leftView = nil;
	returnTextField.leftViewMode = UITextFieldViewModeNever;
	returnTextField.borderStyle = UITextBorderStyleRoundedRect;
    returnTextField.textColor = [UIColor blackColor];
	returnTextField.font = [UIFont systemFontOfSize:17.0];
    returnTextField.backgroundColor = [UIColor whiteColor];
	returnTextField.autocorrectionType = UITextAutocorrectionTypeNo;	// no auto correction support

	returnTextField.keyboardType = UIKeyboardTypeDefault;
	returnTextField.returnKeyType = UIReturnKeyDone;

	returnTextField.clearButtonMode = UITextFieldViewModeWhileEditing;	// has a clear 'x' button to the right

	return returnTextField;
}

- (UITextField *)create_TitleField
{
	UITextField *returnTextField = [self create_TextField];
	
    returnTextField.text = [_timer title];
	returnTextField.placeholder = NSLocalizedString(@"<enter title>", @"Placeholder of timerTitle");
	
	return returnTextField;
}

- (UITextField *)create_DescriptionField
{
	UITextField *returnTextField = [self create_TextField];
	
    returnTextField.text = [_timer tdescription];
	returnTextField.placeholder = NSLocalizedString(@"<enter description>", @"Placeholder of timerDescription");
	
	return returnTextField;
}

- (UIButton *)create_ServiceButton
{
	UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect]; // XXX: an icon would be nice ;)
	button.frame = CGRectMake(0.0, 0.0, 25.0, 25.0);
	[button addTarget:self action:@selector(editService:) forControlEvents:UIControlEventTouchUpInside];
	
	return button;
}

- (UIButton *)create_DeleteButton
{
	UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect]; // XXX: an icon would be nice ;)
	button.frame = CGRectMake(0.0, 0.0, 25.0, 25.0);
	[button addTarget:self action:@selector(deleteAction:) forControlEvents:UIControlEventTouchUpInside];

	return button;
}

- (UIButton *)create_BeginButton
{
	UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect]; // XXX: an icon would be nice ;)
	button.frame = CGRectMake(0.0, 0.0, 25.0, 25.0);
	[button addTarget:self action:@selector(editBegin:) forControlEvents:UIControlEventTouchUpInside];
	
	return button;
}

- (UIButton *)create_EndButton
{
	UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect]; // XXX: an icon would be nice ;)
	button.frame = CGRectMake(0.0, 0.0, 25.0, 25.0);
	[button addTarget:self action:@selector(editEnd:) forControlEvents:UIControlEventTouchUpInside];
	
	return button;
}

- (void)loadView
{
	_shouldSave = NO;

	self.navigationItem.rightBarButtonItem = self.editButtonItem;

	// create and configure the table view
	myTableView = [[UITableView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame] style:UITableViewStyleGrouped];	
	myTableView.delegate = self;
	myTableView.dataSource = self;
	myTableView.autoresizesSubviews = YES;
	
	self.view = myTableView;

	timerTitle = [self create_TitleField];
	timerDescription = [self create_DescriptionField];
	timerServiceName = [[self create_ServiceButton] retain];
	timerBegin = [[self create_BeginButton] retain];
	timerEnd = [[self create_EndButton] retain];
	deleteButton = [[self create_DeleteButton] retain];

	// default editing mode depends on our mode
	[self setEditing: _creatingNewTimer];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated;
{
	if(!_creatingNewTimer && [_oldTimer state] != 0)
	{
		if(editing)
		{
			UIAlertView *notification = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", @"") message:NSLocalizedString(@"Can't edit a running or finished timer.", @"") delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
			[notification show];
			[notification release];
		}
		else
		{
			[timerTitleCell stopEditing];
			[timerDescriptionCell stopEditing];
			timerServiceName.enabled = NO;
			timerBegin.enabled = NO;
			timerEnd.enabled = NO;
			deleteButton.enabled = YES;
		}
	}
	else
	{
		[super setEditing: editing animated: animated];

		[(UITableView*)self.view reloadData];

		[timerTitleCell setEditing:editing animated:animated];
		[timerDescriptionCell setEditing:editing animated:animated];
		timerServiceName.enabled = editing;
		timerBegin.enabled = editing;
		timerEnd.enabled = editing;
		deleteButton.enabled = editing;

		// editing stopped, commit changes
		if(_shouldSave && !editing)
		{
			NSString *message = nil;

			// Sanity Check Title
			if([[timerTitle text] length])
			{
				_timer.title = [timerTitle text];
			}
			else
			{
				message = NSLocalizedString(@"Can't save a timer with an empty title.", @"");
			}

			// Get Description
			if([[timerDescription text] length])
				_timer.tdescription = [timerDescription text];
			else
				_timer.tdescription = @"";

			// Try to commit changes if no error occured
			if(!message)
			{
				if(_creatingNewTimer)
				{
					if(![[RemoteConnectorObject sharedRemoteConnector] addTimer: _timer])
					{
						message = NSLocalizedString(@"Error adding new timer.", @"");
					}
					else
					{
						id applicationDelegate = [[UIApplication sharedApplication] delegate];
						[[applicationDelegate navigationController] popViewControllerAnimated: YES];
					}
				}
				else
				{
					if(![[RemoteConnectorObject sharedRemoteConnector] editTimer: _oldTimer: _timer])
						message = NSLocalizedString(@"Error editing timer.", @"");
				}
			}

			// Show error message if one occured
			if(message != nil)
			{
				UIAlertView *notification = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", @"") message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
				[notification show];
				[notification release];
			}
		}
	}
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	// Return YES for supported orientations
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)editService:(id)sender
{
	id applicationDelegate = [[UIApplication sharedApplication] delegate];

	ServiceListController *serviceListController = [[ServiceListController alloc] init];
	[serviceListController setTarget: self action: @selector(serviceSelected:)];
	[[applicationDelegate navigationController] pushViewController: serviceListController animated: YES];

	//[serviceListController release];
}

- (void)serviceSelected:(id)object
{
	if(object == nil)
		return;

	[_timer setService: [(Service*)object retain]];
	timerServiceNameCell.nameLabel.text = [[_timer service] sname];
}

- (void)editBegin:(id)sender
{
	id applicationDelegate = [[UIApplication sharedApplication] delegate];

	DatePickerController *datePickerController = [DatePickerController withDate: [_timer begin]];
	[datePickerController setTarget: self action: @selector(beginSelected:)];
	[[applicationDelegate navigationController] pushViewController: datePickerController animated: YES];
}

- (void)beginSelected:(id)object
{
	if(object == nil)
		return;

	[_timer setBegin: [(NSDate*)object retain]];
	timerBeginCell.nameLabel.text = [self format_BeginEnd: [_timer begin]];
}

- (void)editEnd:(id)sender
{
	id applicationDelegate = [[UIApplication sharedApplication] delegate];

	DatePickerController *datePickerController = [DatePickerController withDate: [_timer end]];
	[datePickerController setTarget: self action: @selector(endSelected:)];
	[[applicationDelegate navigationController] pushViewController: datePickerController animated: YES];
}

- (void)endSelected:(id)object
{
	if(object == nil)
		return;

	[_timer setEnd: [(NSDate*)object retain]];
	timerEndCell.nameLabel.text = [self format_BeginEnd: [_timer end]];
}

- (void)deleteAction: (id)sender
{
	UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Do you really want to delete the selected timer?", @"")
														delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", @"") destructiveButtonTitle:nil otherButtonTitles: NSLocalizedString(@"Delete", @""), nil];
	[actionSheet showInView:self.view];
	[actionSheet release];
}

#pragma mark - UIActionSheet delegates

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if (buttonIndex == 0)
	{
		// Custom Button: Delete
		if([[RemoteConnectorObject sharedRemoteConnector] delTimer: _oldTimer])
		{
			// Close when timer deleted
			id applicationDelegate = [[UIApplication sharedApplication] delegate];

			[[applicationDelegate navigationController] popViewControllerAnimated: YES];
		}
		else
		{
			// Alert otherwise
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Delete failed", @"") message:nil
													delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
			[alert show];
			[alert release];
		}
	}
}

#pragma mark - UITableView delegates

// if you want the entire table to just be re-orderable then just return UITableViewCellEditingStyleNone
//
- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return UITableViewCellEditingStyleNone;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	if(_creatingNewTimer || ([_oldTimer state] == 0 && !self.editing))
		return 5;
	return 6;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	/*
	 Order of E2 Timer Editing Screen is:
	 - Name
	 - Description
	 - Type
	 - Repeated
	 - Begin
	 - End
	 - (Location)
	 - afterEvent
	 - Service
	*/

	switch (section) {
		case 0:
			return NSLocalizedString(@"Title", @"");
		case 1:
			return NSLocalizedString(@"Description", @"");
		case 2:
			return NSLocalizedString(@"Service", @"");
		case 3:
			return NSLocalizedString(@"Begin", @"");
		case 4:
			return NSLocalizedString(@"End", @"");
		default:
			return nil;
	}
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return 1;
}

// to determine specific row height for each cell, override this.  In this example, each row is determined
// buy the its subviews that are embedded.
//
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return kUIRowHeight;
}

// utility routine leveraged by 'cellForRowAtIndexPath' to determine which UITableViewCell to be used on a given section.
//
- (UITableViewCell *)obtainTableCellForSection:(NSInteger)section
{
	UITableViewCell *cell = nil;

	switch (section) {
		case 0:
		case 1:
			cell = [myTableView dequeueReusableCellWithIdentifier:kCellTextField_ID];
			if(cell == nil)
				cell = [[[CellTextField alloc] initWithFrame:CGRectZero reuseIdentifier:kCellTextField_ID] autorelease];
			((CellTextField *)cell).delegate = self;	// so we can detect when cell editing starts
			break;
		case 2:
		case 3:
		case 4:
		case 5:
			cell = [myTableView dequeueReusableCellWithIdentifier:kDisplayCell_ID];
			if(cell == nil)
				cell = [[[DisplayCell alloc] initWithFrame:CGRectZero reuseIdentifier:kDisplayCell_ID] autorelease];
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
	NSInteger section = [indexPath section];
	UITableViewCell *sourceCell = [self obtainTableCellForSection: section];

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
			if([[[self.timer service] sname] length])
				((DisplayCell *)sourceCell).nameLabel.text = [[_timer service] sname];
			else
				((DisplayCell *)sourceCell).nameLabel.text = NSLocalizedString(@"Select Service", @"");
			((DisplayCell *)sourceCell).view = timerServiceName;
			timerServiceNameCell = (DisplayCell *)sourceCell;
			break;
		case 3:
			((DisplayCell *)sourceCell).nameLabel.text = [self format_BeginEnd: [_timer begin]];
			((DisplayCell *)sourceCell).view = timerBegin;
			timerBeginCell = (DisplayCell *)sourceCell;
			break;
		case 4:
			((DisplayCell *)sourceCell).nameLabel.text = [self format_BeginEnd: [_timer end]];
			((DisplayCell *)sourceCell).view = timerEnd;
			timerEndCell = (DisplayCell *)sourceCell;
			break;
		case 5:
			((DisplayCell *)sourceCell).nameLabel.text = NSLocalizedString(@"Delete", @"");
			((DisplayCell *)sourceCell).view = deleteButton;
		default:
			break;
	}

	return sourceCell;
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
		{
            [self setViewMovedUp:NO];
        }
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
    // The keyboard will be shown. If the user is editing the author, adjust the display so that the
    // author field will not be covered by the keyboard.
    if ((timerDescriptionCell.isInlineEditing) && self.view.frame.origin.y >= 0)
	{
        [self setViewMovedUp:YES];
    }
	else if (!timerDescriptionCell.isInlineEditing && self.view.frame.origin.y < 0)
	{
        [self setViewMovedUp:NO];
    }
}

#pragma mark - UIViewController delegate methods

- (void)viewWillAppear:(BOOL)animated
{
    // watch the keyboard so we can adjust the user interface if necessary.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) 
												 name:UIKeyboardWillShowNotification object:self.view.window]; 
}

- (void)viewDidAppear:(BOOL)animated
{
	_shouldSave = YES;
}

- (void)viewWillDisappear:(BOOL)animated
{
    // unregister for keyboard notifications while not visible.
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil]; 
}

@end
