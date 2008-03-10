//
//  EventViewController.m
//  Untitled
//
//  Created by Moritz Venn on 09.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "EventViewController.h"

#import "Constants.h"

@implementation EventViewController

@synthesize event = _event;

- (id)init
{
	if (self = [super init])
	{
		self.event = nil;
		self.title = @"Event";
	}
	
	return self;
}

+ (EventViewController*)withEvent: (Event*) newEvent
{
	EventViewController *eventViewController = [[EventViewController alloc] init];

	eventViewController.event = newEvent;
	eventViewController.title = newEvent.title;
	
	return eventViewController;
}

- (void)dealloc
{
	[myTextView release];
	[_event release];

	[super dealloc];
}

- (void)loadView
{
	UIColor *backColor = [UIColor colorWithRed:197.0/255.0 green:204.0/255.0 blue:211.0/255.0 alpha:1.0];
	
	// setup our parent content view and embed it to your view controller
	UIView *contentView = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]];
	contentView.backgroundColor = backColor;
	self.view = contentView;
	[contentView release];
	
	self.view.autoresizesSubviews = YES;

	// create a text view
	// TODO: we really need something better looking here :-)
	CGRect frame = CGRectMake(	kLeftMargin,
						kTopMargin,
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
	if([_event.sdescription length])
	{
		[text appendString: _event.sdescription];
	}
	else
	{
		[text appendString: _event.title];
	}

	if([_event.edescription length])
	{
		[text appendString: @"\n\n"];
		[text appendString: _event.edescription];
	}

	myTextView.text = text;
	[text release];

	// TODO: display begin/end, allow creating a timer
	// XXX: this would require to know the service so keep that in mind :-)

	[self.view addSubview:myTextView];
}

@end
