//
//  MovieViewController.m
//  Untitled
//
//  Created by Moritz Venn on 09.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "MovieViewController.h"

#import "RemoteConnectorObject.h"
#import "TimerViewController.h"
#import "Constants.h"

@implementation MovieViewController

@synthesize movie = _movie;

- (id)init
{
	if (self = [super init])
	{
		self.movie = nil;
		self.title = NSLocalizedString(@"Movie", @"Default title of MovieViewController");
	}
	
	return self;
}

+ (MovieViewController *)withMovie: (Movie *) newMovie
{
	MovieViewController *movieViewController = [[MovieViewController alloc] init];

	movieViewController.movie = newMovie;
	movieViewController.title = [newMovie title];
	
	return movieViewController;
}

- (void)dealloc
{
	[myTextView release];
	[playButton release];
	[_movie release];

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
	if([[_movie sdescription] length])
	{
		[text appendString: [_movie sdescription]];
	}
	else
	{
		[text appendString: [_movie title]];
	}

	if([[_movie edescription] length])
	{
		[text appendString: @"\n\n"];
		[text appendString: [_movie edescription]];
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
	[self.view addSubview:[MovieViewController fieldLabelWithFrame:frame title:NSLocalizedString(@"Begin:", @"")]];

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
	textField.borderStyle = UITextBorderStyleRoundedRect;
	textField.textColor = [UIColor blackColor];
	textField.font = [UIFont systemFontOfSize:14.0];
	textField.delegate = self;
	textField.text = [format stringFromDate: [_movie time]];

	textField.enabled = NO;
	textField.backgroundColor = backColor;
	textField.returnKeyType = UIReturnKeyDone;
	textField.keyboardType = UIKeyboardTypeDefault;
	[self.view addSubview:textField];

	[textField release];

	if([[_movie length] intValue] != -1)
	{
		// create a label for our end textfield
		yCoord += kTweenMargin + kTextFieldHeight;

		frame = CGRectMake(kLeftMargin,
							yCoord,
							self.view.bounds.size.width - kRightMargin - kLeftMargin,
							kLabelHeight);
		[self.view addSubview:[MovieViewController fieldLabelWithFrame:frame title:NSLocalizedString(@"End:", @"")]];
	
		// end
		yCoord += kTweenMargin + kLabelHeight;

		frame = CGRectMake(kLeftMargin,
						   yCoord,
						   self.view.bounds.size.width - (kRightMargin*2),
						   kTextFieldHeight);
		textField = [[UITextField alloc] initWithFrame:frame];
		textField.borderStyle = UITextBorderStyleRoundedRect;
		textField.textColor = [UIColor blackColor];
		textField.font = [UIFont systemFontOfSize:14.0];
		textField.delegate = self;
		textField.text = [format stringFromDate: [[_movie time] addTimeInterval: (NSTimeInterval)[[_movie length] intValue]]];
		textField.enabled = NO;
		textField.backgroundColor = backColor;
		textField.returnKeyType = UIReturnKeyDone;
		textField.keyboardType = UIKeyboardTypeDefault;
		[self.view addSubview:textField];

		[textField release];
	}
	
	// play
	yCoord += 2*kTweenMargin + kStdButtonHeight;
	
	playButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
	playButton.frame = CGRectMake(	(self.view.bounds.size.width - kWideButtonWidth) / 2.0,
									yCoord,
									kWideButtonWidth,
									kStdButtonHeight);
	[playButton setFont: [UIFont systemFontOfSize:14.0]];
	[playButton setBackgroundColor: backColor];
	[playButton setTitle:NSLocalizedString(@"Play", @"") forState:UIControlStateNormal];
	[playButton addTarget:self action:@selector(playAction:) forControlEvents:UIControlEventTouchUpInside];
	[self.view addSubview: playButton];
}

- (void)playAction: (id)sender
{
	Service *movieService = [[Service alloc] init];
	[movieService setSref: [_movie sref]];

	[[RemoteConnectorObject sharedRemoteConnector] zapTo: movieService];
	
	[movieService release];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	// Return YES for supported orientations
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
