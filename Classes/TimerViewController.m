//
//  TimerViewController.m
//  Untitled
//
//  Created by Moritz Venn on 10.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "TimerViewController.h"

#import "AppDelegateMethods.h"
#import "Constants.h"

@implementation TimerViewController

// the amount of vertical shift upwards keep the text field in view as the keyboard appears
#define kViewVerticalOffset					(kTextFieldHeight + kTweenMargin*5)

// the duration of the animation for the view shift
#define kVerticalOffsetAnimationDuration	0.30

@synthesize timer = _timer;
@synthesize creatingNewTimer = _creatingNewTimer;

- (id)init
{
	if (self = [super init])
	{
		self.title = NSLocalizedString(@"Timer", @"");
	}
	return self;
}

+ (TimerViewController *)withTimer: (Timer *)ourTimer
{
	TimerViewController *timerViewController = [[TimerViewController alloc] init];
	timerViewController.timer = ourTimer;
	timerViewController.creatingNewTimer = NO;

	return timerViewController;
}

+ (TimerViewController *)newTimer
{
	TimerViewController *timerViewController = [[TimerViewController alloc] init];
	timerViewController.timer = [[Timer alloc] init];
	timerViewController.creatingNewTimer = YES;

	return timerViewController;
}

- (void)dealloc
{
	[_timer release];
	[timerTitle release];

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
	self.view = contentView;
	[contentView release];
	
	self.view.autoresizesSubviews = YES;
	
	// note: for UITextField, if you don't like autocompletion while typing use:
	// aTextField.autocorrectionType = UITextAutocorrectionTypeNo;

	CGFloat yCoord = kTopMargin;

	// create a label for the "rounded" style UITextField
	CGRect frame = CGRectMake(	kLeftMargin,
						yCoord,
						self.view.bounds.size.width - kRightMargin - kLeftMargin,
						kLabelHeight);
	[self.view addSubview:[TimerViewController fieldLabelWithFrame:frame title:@"Name:"]];
	
	// create a text field "rounded" style
	yCoord += kTweenMargin + kLabelHeight;
	frame = CGRectMake(	kLeftMargin,
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
	CGRect rect;
	[[notification object] getValue:&rect];

	if (([timerTitle isFirstResponder]) && (rect.origin.y >= timerTitle.frame.origin.y))
	{
		[self setViewMovedUp:YES];
		lastTrackedFirstResponder = timerTitle;
	}
	else
	{
		[self setViewMovedUp:NO];
	}
}

- (void)keyboardDidHide:(NSNotification *)notification
{
    // The keyboard was hidden
	//
	// If the view was previously adjusted to prevent the keyboard from covering 
    // the edit fields, restore the original positioning.
	//
    if  (self.view.frame.origin.y < 0)
	{
        [self setViewMovedUp:NO];
    }
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

@end
