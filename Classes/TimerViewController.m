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
#import "AppDelegateMethods.h"
#import "Constants.h"

@implementation TimerViewController

// the amount of vertical shift upwards keep the text field in view as the keyboard appears
#define kViewVerticalOffset					(kTextFieldHeight + kTweenMargin*5)

// the duration of the animation for the view shift
#define kVerticalOffsetAnimationDuration	0.30

@synthesize timer = _timer;
@synthesize oldTimer = _oldTimer;
@synthesize creatingNewTimer = _creatingNewTimer;
@synthesize service = _service;
@synthesize begin = _begin;
@synthesize end = _end;

- (id)init
{
	if (self = [super init])
	{
		self.title = NSLocalizedString(@"Timer", @"");
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
	[_oldTimer release];
	[timerTitle release];
	[timerDescription release];
	[timerServiceName release];
	[timerBeginString release];
	[timerEndString release];
	[lastTrackedFirstResponder release];

	[_service release];
	[_begin release];
	[_end release];

	[super dealloc];
}

+ (UILabel *)fieldLabelWithFrame:(CGRect)frame title:(NSString *)title
{
	UILabel *label = [[[UILabel alloc] initWithFrame:frame] autorelease];
	
	label.textAlignment = UITextAlignmentLeft;
	label.text = title;
	label.font = [UIFont boldSystemFontOfSize:17.0];
	label.textColor = [UIColor colorWithRed:76.0/255.0 green:86.0/255.0 blue:108.0/255.0 alpha:1.0];
	label.backgroundColor = [UIColor clearColor];

	return label;
}

- (void)loadView
{
	UIColor *backgroundColor = [UIColor colorWithRed:197.0/255.0 green:204.0/255.0 blue:211.0/255.0 alpha:1.0];
	
	// setup our parent content view and embed it to your view controller
	UIView *contentView = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]];
	contentView.backgroundColor = backgroundColor;

	// important for view orientation rotation
	contentView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);	
	self.view = contentView;
	self.view.autoresizesSubviews = YES;
	
	[contentView release];

	// add our custom done button as the nav bar's custom right view
	UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
												target:self action:@selector(doneAction:)];
	UINavigationItem *navItem = self.navigationItem;
	navItem.rightBarButtonItem = button;

	[button release];

	// add our custom cancel button as the nav bar's custom left view
	// TODO: do we really want this?
	/*
	button = [UIButton buttonWithType:UIButtonTypeContactAdd];
	[button setTitle:NSLocalizedString(@"Cancel", @"") forState:UIControlStateNormal];
	[button addTarget:self action:@selector(cancelAction:) forControlEvents:UIControlEventTouchUpInside];
	navItem.leftBarButtonItem = button;
	*/
	
	[navItem release];

	// note: for UITextField, if you don't like autocompletion while typing use:
	// aTextField.autocorrectionType = UITextAutocorrectionTypeNo;

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

	CGFloat yCoord = kTopMargin;

	// create a label for our title textfield
	CGRect frame = CGRectMake(kLeftMargin,
						yCoord,
						self.view.bounds.size.width - kRightMargin - kLeftMargin,
						kLabelHeight);
	[self.view addSubview:[TimerViewController fieldLabelWithFrame:frame title:@"Name:"]];
	
	// title
	yCoord += kTweenMargin + kLabelHeight;

	frame = CGRectMake(kLeftMargin,
						yCoord,
						self.view.bounds.size.width - (kRightMargin*2),
						kTextFieldHeight);
	timerTitle = [[UITextField alloc] initWithFrame:frame];
	timerTitle.borderStyle = UITextBorderStyleRoundedRect; // TODO: upgraded sdk
	timerTitle.textColor = [UIColor blackColor];
	timerTitle.font = [UIFont systemFontOfSize:17.0];
	timerTitle.delegate = self;
	timerTitle.text = [self.timer title];
	timerTitle.placeholder = @"<enter title>";
	timerTitle.backgroundColor = backgroundColor;
	timerTitle.returnKeyType = UIReturnKeyDone;
	timerTitle.keyboardType = UIKeyboardTypeDefault;
	[self.view addSubview:timerTitle];

	// create a label for our description textfield
	yCoord += kTweenMargin + kTextFieldHeight;

	frame = CGRectMake(kLeftMargin,
						yCoord,
						self.view.bounds.size.width - kRightMargin - kLeftMargin,
						kLabelHeight);
	[self.view addSubview:[TimerViewController fieldLabelWithFrame:frame title:@"Description:"]];
	
	// description
	yCoord += kTweenMargin + kLabelHeight;

	frame = CGRectMake(kLeftMargin,
						yCoord,
						self.view.bounds.size.width - (kRightMargin*2),
						kTextFieldHeight);
	timerDescription = [[UITextField alloc] initWithFrame:frame];
	timerDescription.borderStyle = UITextBorderStyleRoundedRect; // TODO: upgraded sdk
	timerDescription.textColor = [UIColor blackColor];
	timerDescription.font = [UIFont systemFontOfSize:17.0];
	timerDescription.delegate = self;
	timerDescription.text = [self.timer tdescription];
	timerDescription.placeholder = @"<enter description>";
	timerDescription.backgroundColor = backgroundColor;
	timerDescription.returnKeyType = UIReturnKeyDone;
	timerDescription.keyboardType = UIKeyboardTypeDefault;
	[self.view addSubview:timerDescription];

	// create a label for our service textfield
	yCoord += kTweenMargin + kTextFieldHeight;

	frame = CGRectMake(kLeftMargin,
						yCoord,
						self.view.bounds.size.width - kRightMargin - kLeftMargin,
						kLabelHeight);
	[self.view addSubview:[TimerViewController fieldLabelWithFrame:frame title:@"Service:"]];

	// service
	yCoord += kTweenMargin + kLabelHeight;

	timerServiceName = [UIButton buttonWithType:UIButtonTypeRoundedRect];
	timerServiceName.frame = CGRectMake(	(self.view.bounds.size.width - kWideButtonWidth) / 2.0,
											yCoord,
											kWideButtonWidth,
											kStdButtonHeight);
	timerServiceName.backgroundColor = backgroundColor;
	NSString *buttonTitle = @"";
	if([[[self.timer service] sname] length])
		buttonTitle = [[self.timer service] sname];
	else
		buttonTitle = NSLocalizedString(@"Select Service", @"");
	[timerServiceName setTitle:buttonTitle forState:UIControlStateNormal];
	[timerServiceName addTarget:self action:@selector(editService:) forControlEvents:UIControlEventTouchUpInside];
	[self.view addSubview: timerServiceName];
	
	[buttonTitle release];
	
	// XXX: I'm not completely satisfied how begin/end look

	// create a label for our begin textfield
	yCoord += kTweenMargin + kStdButtonHeight;

	frame = CGRectMake(kLeftMargin,
						yCoord,
						self.view.bounds.size.width - kRightMargin - kLeftMargin,
						kLabelHeight);
	[self.view addSubview:[TimerViewController fieldLabelWithFrame:frame title:@"Begin:"]];

	// Date Formatter
	NSDateFormatter *format = [[[NSDateFormatter alloc] init] autorelease];
	[format setDateFormat: @"%A, %d.%m.%Y %H:%M"];
	
	// begin
	yCoord += kTweenMargin + kLabelHeight;

	timerBeginString = [UIButton buttonWithType:UIButtonTypeRoundedRect];
	timerBeginString.frame = CGRectMake(	(self.view.bounds.size.width - kWideButtonWidth) / 2.0,
											yCoord,
											kWideButtonWidth,
											kStdButtonHeight);
	timerBeginString.backgroundColor = backgroundColor;
	[timerBeginString setTitle:[format stringFromDate: [_timer begin]] forState:UIControlStateNormal];
	[timerBeginString addTarget:self action:@selector(editBegin:) forControlEvents:UIControlEventTouchUpInside];
	[self.view addSubview: timerBeginString];

	// create a label for our end textfield
	yCoord += kTweenMargin + kStdButtonHeight;

	frame = CGRectMake(kLeftMargin,
						yCoord,
						self.view.bounds.size.width - kRightMargin - kLeftMargin,
						kLabelHeight);
	[self.view addSubview:[TimerViewController fieldLabelWithFrame:frame title:@"End:"]];
	
	// end
	yCoord += kTweenMargin + kLabelHeight;

	timerEndString = [UIButton buttonWithType:UIButtonTypeRoundedRect];
	timerEndString.frame = CGRectMake(	(self.view.bounds.size.width - kWideButtonWidth) / 2.0,
											yCoord,
											kWideButtonWidth,
											kStdButtonHeight);
	timerEndString.backgroundColor = backgroundColor;
	[timerEndString setTitle:[format stringFromDate: [_timer end]] forState:UIControlStateNormal];
	[timerEndString addTarget:self action:@selector(editEnd:) forControlEvents:UIControlEventTouchUpInside];
	[self.view addSubview: timerEndString];

/*
	// this is a template :-)
	// create a label for our  textfield
	yCoord += kTweenMargin + kTextFieldHeight;

	frame = CGRectMake(kLeftMargin,
						yCoord,
						self.view.bounds.size.width - kRightMargin - kLeftMargin,
						kLabelHeight);
	[self.view addSubview:[TimerViewController fieldLabelWithFrame:frame title:@":"]];
	
	// 
	yCoord += kTweenMargin + kLabelHeight;

	frame = CGRectMake(kLeftMargin,
						yCoord,
						self.view.bounds.size.width - (kRightMargin*2),
						kTextFieldHeight);
	timer = [[UITextField alloc] initWithFrame:frame];
	timer.borderStyle = UITextFieldBorderStyleRounded;
	timer.textColor = [UIColor blackColor];
	timer.font = [UIFont systemFontOfSize:17.0];
	timer.delegate = self;
	timer.text = [self.timer ];
	timer.placeholder = @"<enter >";
	timer.backgroundColor = backgroundColor;
	timer.returnKeyType = UIReturnKeyDone;
	timer.keyboardType = UIKeyboardTypeDefault;
	[ addTarget:self action:@selector(:) forControlEvents:UIControlEventEditingBegin];
	[self.view addSubview:timer];
*/
}

// Animate the entire view up or down, to prevent the keyboard from covering the summary field
//
- (void)setViewMovedUp:(BOOL)movedUp
{
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:kVerticalOffsetAnimationDuration];
	
	// Make changes to the view's frame inside the animation block.
	// They will be animated instead of taking place immediately.
	CGRect rect = self.view.frame;
	if (movedUp)
	{
		// If moving up, not only decrease the origin but increase the height so the view 
		// covers the entire screen behind the keyboard.
		rect.origin.y -= kViewVerticalOffset;
		rect.size.height += kViewVerticalOffset;
	}
	else
	{
		// If moving down, not only increase the origin but decrease the height.
		rect.origin.y += kViewVerticalOffset;
		rect.size.height -= kViewVerticalOffset;
	}
	self.view.frame = rect;
	
	[UIView commitAnimations];
}

- (void)keyboardWillShow:(NSNotification *)notification
{
	// The keyboard will be shown
	//
	// If the user is editing either of the two text fields placed under the keyboard area,
	// adjust the display so that the each of them will not be covered by the keyboard.
	//
	// We do this by examining the notification's object to get the keyboard's frame
	//
	/*
	if (([timerTitle isFirstResponder]) && (self.view.frame.origin.y >= 0))
	{
		[self setViewMovedUp:YES];
	}
	else
	{
		[self setViewMovedUp:NO];
	}
	*/
}

- (void)keyboardDidHide:(NSNotification *)notification
{
	// The keyboard was hidden
	//
	// If the view was previously adjusted to prevent the keyboard from covering 
	// the edit fields, restore the original positioning.
	//
	/*
	if  (self.view.frame.origin.y > 0)
	{
		[self setViewMovedUp:NO];
	}
	*/
}

// this helps dismiss the keyboard then the "done" button is clicked
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	[textField resignFirstResponder];
	return YES;
}

- (void)viewWillAppear:(BOOL)animated
{
	// Watch the keyboard so we can adjust the user interface if necessary.
  
	// since 'textFieldSecure' will be obscured when its keyboard shows up, we need to move it out of the way
	// back back again each time the keyboard appears and disappears, so these two notification will help us
	// with this effort:
	//
	[[NSNotificationCenter defaultCenter]
		addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:self.view.window];
	[[NSNotificationCenter defaultCenter]
		addObserver:self selector:@selector(keyboardDidHide:) name:UIKeyboardDidHideNotification object:self.view.window];
}

- (void)viewWillDisappear:(BOOL)animated
{
	// Unregister for keyboard notifications while not visible.
	[[NSNotificationCenter defaultCenter]
		removeObserver:self name:UIKeyboardWillShowNotification object:self.view.window];
	[[NSNotificationCenter defaultCenter]
		removeObserver:self name:UIKeyboardDidHideNotification object:self.view.window];
}

- (void)editService:(id)sender
{
	id applicationDelegate = [[UIApplication sharedApplication] delegate];

	ServiceListController *serviceListController = [[ServiceListController alloc] init];
	serviceListController.justSelecting = YES;
	[serviceListController setTarget: self action: @selector(serviceSelected:)];
	[[applicationDelegate navigationController] pushViewController: serviceListController animated: YES];
	
	//[serviceListController release];
}

- (void)serviceSelected:(id)object
{
	// XXX: we might want to check for an invalid service here (unable to receive list ?)
	self.timer.service = [(Service*)object retain];
	[timerServiceName setTitle: [[_timer service] sname] forState:UIControlStateNormal];
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
	NSDateFormatter *format = [[[NSDateFormatter alloc] init] autorelease];
	[format setDateFormat: @"%A, %d.%m.%Y %H:%M"];

	self.timer.begin = [(NSDate*)object retain];
	[timerBeginString setTitle:[format stringFromDate: [_timer begin]] forState:UIControlStateNormal];
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
	NSDateFormatter *format = [[[NSDateFormatter alloc] init] autorelease];
	[format setDateFormat: @"%A, %d.%m.%Y %H:%M"];

	self.timer.end = [(NSDate*)object retain];
	[timerEndString setTitle:[format stringFromDate: [_timer end]] forState:UIControlStateNormal];
}

- (void)doneAction:(id)sender
{
	if([[timerTitle text] length])
	{
		_timer.title = [timerTitle text];
	}
	else
	{
		// XXX: this might be better of at another place as we might want to catch more errors...
		NSString *message = @"Can't save a timer with an empty title.";
		
		UIAlertView *notification = [[UIAlertView alloc] initWithTitle:@"Error:" message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
		[notification show];
		[notification release];
		
		return;
	}

	if([[timerDescription text] length])
		_timer.tdescription = [timerDescription text];
	else
		_timer.tdescription = @"";

	if(_creatingNewTimer)
	{
		[[RemoteConnectorObject sharedRemoteConnector] addTimer: _timer];
	}
	else
	{
		[[RemoteConnectorObject sharedRemoteConnector] editTimer: _oldTimer: _timer];
	}

	id applicationDelegate = [[UIApplication sharedApplication] delegate];

	[[applicationDelegate navigationController] popViewControllerAnimated: YES];
}

- (void)cancelAction:(id)sender
{
	id applicationDelegate = [[UIApplication sharedApplication] delegate];

	[[applicationDelegate navigationController] popViewControllerAnimated: YES];
}

@end
