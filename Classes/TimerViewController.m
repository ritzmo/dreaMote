//
//  TimerViewController.m
//  Untitled
//
//  Created by Moritz Venn on 10.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "TimerViewController.h"

#import "RemoteConnectorObject.h"
#import "AppDelegateMethods.h"
#import "Constants.h"

@implementation TimerViewController

// the amount of vertical shift upwards keep the text field in view as the keyboard appears
#define kViewVerticalOffset					(kTextFieldHeight + kTweenMargin*5)

// the duration of the animation for the view shift
#define kVerticalOffsetAnimationDuration	0.30

@synthesize timer = _timer;
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
	UIButton *button = [UIButton buttonWithType:UIButtonTypeNavigationDone];
	[button setTitle:NSLocalizedString(@"Done", @"") forStates:UIControlStateNormal];
	[button addTarget:self action:@selector(doneAction:) forControlEvents:UIControlEventTouchUpInside];
	UINavigationItem *navItem = self.navigationItem;
	navItem.customRightView = button;

	[button release];

	// add our custom cancel button as the nav bar's custom left view
	button = [UIButton buttonWithType:UIButtonTypeNavigation];
	[button setTitle:NSLocalizedString(@"Cancel", @"") forStates:UIControlStateNormal];
	[button addTarget:self action:@selector(cancelAction:) forControlEvents:UIControlEventTouchUpInside];
	navItem.customLeftView = button;
	
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
	timerTitle.borderStyle = UITextFieldBorderStyleRounded;
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
	timerDescription.borderStyle = UITextFieldBorderStyleRounded;
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

	frame = CGRectMake(kLeftMargin,
						yCoord,
						self.view.bounds.size.width - kRightMargin - kLeftMargin,
						kTextFieldHeight);
	timerServiceName = [[UITextField alloc] initWithFrame:frame];
	timerServiceName.borderStyle = UITextFieldBorderStyleRounded;
	timerServiceName.textColor = [UIColor blackColor];
	timerServiceName.font = [UIFont systemFontOfSize:17.0];
	timerServiceName.delegate = self;
	timerServiceName.text = [[self.timer service] sname];
	timerServiceName.placeholder = @"<touch to select service>";
	timerServiceName.enabled = NO; // XXX: we disable this for now as i currently cant figure out how to disable editing :-/
	timerServiceName.backgroundColor = backgroundColor;
	timerServiceName.returnKeyType = UIReturnKeyDone;
	timerServiceName.keyboardType = UIKeyboardTypeDefault;
	[timerServiceName addTarget:self action:@selector(editService:) forControlEvents:UIControlEventAllTouchEvents];
	[self.view addSubview:timerServiceName];
	
	// XXX: I'm not completely satisfied how begin/end look

	// create a label for our begin textfield
	yCoord += kTweenMargin + kTextFieldHeight;

	frame = CGRectMake(kLeftMargin,
						yCoord,
						self.view.bounds.size.width - kRightMargin - kLeftMargin,
						kLabelHeight);
	[self.view addSubview:[TimerViewController fieldLabelWithFrame:frame title:@"Begin:"]];

	// begin
	yCoord += kTweenMargin + kLabelHeight;

	frame = CGRectMake(kLeftMargin,
						yCoord,
						self.view.bounds.size.width - kRightMargin - kLeftMargin,
						kTextFieldHeight);
	timerBeginString = [[UITextField alloc] initWithFrame:frame];
	timerBeginString.borderStyle = UITextFieldBorderStyleRounded;
	timerBeginString.textColor = [UIColor blackColor];
	timerBeginString.font = [UIFont systemFontOfSize:17.0];
	timerBeginString.delegate = self;
	timerBeginString.text = [[_timer begin] descriptionWithCalendarFormat:@"%A, %d.%m.%Y %H:%M" timeZone:nil locale:nil];
	timerBeginString.enabled = NO; // XXX: we disable this for now as i currently cant figure out how to disable editing :-/
	timerBeginString.backgroundColor = backgroundColor;
	timerBeginString.returnKeyType = UIReturnKeyDone;
	timerBeginString.keyboardType = UIKeyboardTypeDefault;
	[self.view addSubview:timerBeginString];

	// create a label for our end textfield
	yCoord += kTweenMargin + kTextFieldHeight;

	frame = CGRectMake(kLeftMargin,
						yCoord,
						self.view.bounds.size.width - kRightMargin - kLeftMargin,
						kLabelHeight);
	[self.view addSubview:[TimerViewController fieldLabelWithFrame:frame title:@"End:"]];
	
	// end
	yCoord += kTweenMargin + kLabelHeight;

	frame = CGRectMake(kLeftMargin,
						yCoord,
						self.view.bounds.size.width - kRightMargin - kLeftMargin,
						kTextFieldHeight);
	timerEndString = [[UITextField alloc] initWithFrame:frame];
	timerEndString.borderStyle = UITextFieldBorderStyleRounded;
	timerEndString.textColor = [UIColor blackColor];
	timerEndString.font = [UIFont systemFontOfSize:17.0];
	timerEndString.delegate = self;
	timerEndString.text = [[_timer end] descriptionWithCalendarFormat:@"%A, %d.%m.%Y %H:%M" timeZone:nil locale:nil];
	timerEndString.enabled = NO;
	timerEndString.backgroundColor = backgroundColor;
	timerEndString.returnKeyType = UIReturnKeyDone;
	timerEndString.keyboardType = UIKeyboardTypeDefault;
	[self.view addSubview:timerEndString];
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
	/*CGRect rect;
	[[notification object] getValue:&rect];

	if (([timerTitle isFirstResponder]) && (rect.origin.y >= timerTitle.frame.origin.y))
	{
		[self setViewMovedUp:YES];
		lastTrackedFirstResponder = timerTitle;
	}
	else
	{
		[self setViewMovedUp:NO];
	}*/
}

- (void)keyboardDidHide:(NSNotification *)notification
{
	// The keyboard was hidden
	//
	// If the view was previously adjusted to prevent the keyboard from covering 
	// the edit fields, restore the original positioning.
	//
	/*if  (self.view.frame.origin.y > 0)
	{
		[self setViewMovedUp:NO];
	}*/
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
	UIAlertView *notification = [[UIAlertView alloc] initWithTitle:@"Notification:" message:@"Not yet implemented." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
	[notification show];
	[notification release];
}

- (void)doneAction:(id)sender
{
	if(_creatingNewTimer)
	{
		NSString *message = @"We should add the new timer now, but that's not yet implemented so we're closing...";

		UIAlertView *notification = [[UIAlertView alloc] initWithTitle:@"Notification:" message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
		[notification show];
		[notification release];
	}
	else
	{
		Timer *oldTimer = [_timer copy];
		
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

		[[RemoteConnectorObject sharedRemoteConnector] editTimer: oldTimer: _timer];


		[oldTimer release];
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
