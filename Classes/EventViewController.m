//
//  EventViewController.m
//  Untitled
//
//  Created by Moritz Venn on 09.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "EventViewController.h"

#import "TimerViewController.h"
#import "AppDelegateMethods.h"
#import "Constants.h"

@implementation EventViewController

@synthesize event = _event;
@synthesize service = _service;

- (id)init
{
	if (self = [super init])
	{
		self.event = nil;
		self.title = NSLocalizedString(@"Event", @"");
	}
	
	return self;
}

+ (EventViewController *)withEvent: (Event *) newEvent
{
	EventViewController *eventViewController = [[EventViewController alloc] init];

	eventViewController.event = newEvent;
	eventViewController.title = newEvent.title;
	eventViewController.service = [[Service alloc] init];
	
	return eventViewController;
}

+ (EventViewController *)withEventAndService: (Event *) newEvent: (Service *) newService
{
	EventViewController *eventViewController = [[EventViewController alloc] init];

	eventViewController.event = newEvent;
	eventViewController.title = newEvent.title;
	eventViewController.service = newService;
	
	return eventViewController;
}

- (void)dealloc
{
	[myTextView release];
	[_event release];

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
	UIColor *backColor = [UIColor colorWithRed:197.0/255.0 green:204.0/255.0 blue:211.0/255.0 alpha:1.0];
	
	// setup our parent content view and embed it to your view controller
	UIView *contentView = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]];
	contentView.backgroundColor = backColor;
	self.view = contentView;
	self.view.autoresizesSubviews = YES;

	[contentView release];

	CGFloat yCoord = kTopMargin;

	// create a text view
	// TODO: we really need something better looking here :-)
	CGRect frame = CGRectMake(	kLeftMargin,
						yCoord,
						self.view.bounds.size.width - kLeftMargin - kRightMargin,
						kTextViewHeight);
	myTextView = [[UITextView alloc] initWithFrame:frame];
	myTextView.textColor = [UIColor blackColor];
	myTextView.font = [UIFont fontWithName:kFontName size:kTextViewFontSize];
	myTextView.delegate = self;
	myTextView.editable = NO;
	myTextView.backgroundColor = [UIColor whiteColor];

	// We display short description (or title) and extended description (if available) in our textview
	NSMutableString *text = [[NSMutableString alloc] init];
	if([[_event sdescription] length])
	{
		[text appendString: [_event sdescription]];
	}
	else
	{
		[text appendString: [_event title]];
	}

	if([[_event edescription] length])
	{
		[text appendString: @"\n\n"];
		[text appendString: [_event edescription]];
	}

	myTextView.text = text;
	[self.view addSubview:myTextView];

	[text release];

	// XXX: I'm not completely satisfied how begin/end look

	// create a label for our begin textfield
	yCoord += kTweenMargin + kTextViewHeight;

	frame = CGRectMake(kLeftMargin,
						yCoord,
						self.view.bounds.size.width - kRightMargin - kLeftMargin,
						kLabelHeight);
	[self.view addSubview:[EventViewController fieldLabelWithFrame:frame title:@"Begin:"]];

	// Date Formatter
	NSDateFormatter *format = [[[NSDateFormatter alloc] init] autorelease];
	[format setDateStyle:NSDateFormatterMediumStyle];
	[format setTimeStyle:NSDateFormatterShortStyle];
	
	// begin
	yCoord += kTweenMargin + kLabelHeight;

	frame = CGRectMake(kLeftMargin,
						yCoord,
						self.view.bounds.size.width - (kRightMargin*2),
						kTextFieldHeight);
	UITextField *textField = [[UITextField alloc] initWithFrame:frame];
	textField.borderStyle = UITextBorderStyleRoundedRect; // TODO: upgraded sdk
	textField.textColor = [UIColor blackColor];
	textField.font = [UIFont systemFontOfSize:17.0];
	textField.delegate = self;
	textField.text = [format stringFromDate: [_event begin]];

	textField.enabled = NO;
	textField.backgroundColor = backColor;
	textField.returnKeyType = UIReturnKeyDone;
	textField.keyboardType = UIKeyboardTypeDefault;
	[self.view addSubview:textField];

	[textField release];

	// create a label for our end textfield
	yCoord += kTweenMargin + kTextFieldHeight;

	frame = CGRectMake(kLeftMargin,
						yCoord,
						self.view.bounds.size.width - kRightMargin - kLeftMargin,
						kLabelHeight);
	[self.view addSubview:[EventViewController fieldLabelWithFrame:frame title:@"End:"]];
	
	// end
	yCoord += kTweenMargin + kLabelHeight;

	frame = CGRectMake(kLeftMargin,
						yCoord,
						self.view.bounds.size.width - (kRightMargin*2),
						kTextFieldHeight);
	textField = [[UITextField alloc] initWithFrame:frame];
	textField.borderStyle = UITextBorderStyleRoundedRect; // TODO: upgraded sdk
	textField.textColor = [UIColor blackColor];
	textField.font = [UIFont systemFontOfSize:17.0];
	textField.delegate = self;
	textField.text = [format stringFromDate: [_event end]];
	textField.enabled = NO;
	textField.backgroundColor = backColor;
	textField.returnKeyType = UIReturnKeyDone;
	textField.keyboardType = UIKeyboardTypeDefault;
	[self.view addSubview:textField];

	[textField release];

	// add timer button
	yCoord += kTextFieldHeight + kTweenMargin;

	UIButton *roundedButtonType = [UIButton buttonWithType:UIButtonTypeRoundedRect];
	roundedButtonType.frame = CGRectMake(	(self.view.bounds.size.width - kWideButtonWidth) / 2.0,
											yCoord,
											kWideButtonWidth,
											kStdButtonHeight);
	roundedButtonType.backgroundColor = backColor;
	[roundedButtonType setTitle:NSLocalizedString(@"Add Timer", @"") forState:UIControlStateNormal];
	[roundedButtonType addTarget:self action:@selector(addTimer:) forControlEvents:UIControlEventTouchUpInside];
	[self.view addSubview: roundedButtonType];
}

- (void)addTimer: (id)sender
{
	id applicationDelegate = [[UIApplication sharedApplication] delegate];

	TimerViewController *timerViewController = [TimerViewController withEventAndService: _event: _service];
	[[applicationDelegate navigationController] pushViewController: timerViewController animated: YES];

	//[timerViewController release];
}
	
@end
