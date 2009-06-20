//
//  DatePickerController.m
//  dreaMote
//
//  Created by Moritz Venn on 13.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "TimerViewController.h"
#import "DatePickerController.h"

#import "Constants.h"

@implementation DatePickerController

#define kPickerSegmentControlHeight 30.0

@synthesize date;
@synthesize format;

/* initialize */
- (id)init
{
	if (self = [super init])
	{
		// this title will appear in the navigation bar
		self.title = NSLocalizedString(@"Date Picker", @"");
		self.format = [[NSDateFormatter alloc] init];
		[format setDateStyle:NSDateFormatterFullStyle];
		[format setTimeStyle:NSDateFormatterShortStyle];
	}
	
	return self;
}

/* creator */
+ (DatePickerController *)withDate: (NSDate *)ourDate
{
	DatePickerController *datePickerController = [[DatePickerController alloc] init];
	datePickerController.date = [ourDate copy];
	
	return datePickerController;
}

/* layout */
- (void)loadView
{		
	// setup our parent content view and embed it to your view controller
	UIView *contentView = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]];
	contentView.backgroundColor = [UIColor blackColor];

	self.view = contentView;
	[contentView release];

	CGRect frame = CGRectMake(	0.0,
								0.0, //kTopMargin + kPickerSegmentControlHeight,
								self.view.bounds.size.width - (kRightMargin * 2.0),
								self.view.bounds.size.height - 110.0);
	datePickerView = [[UIDatePicker alloc] initWithFrame:frame];
	datePickerView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	datePickerView.datePickerMode = UIDatePickerModeDateAndTime;
	datePickerView.date = date;
	[datePickerView addTarget:self action:@selector(timeChanged:) forControlEvents:UIControlEventValueChanged];
	[self.view addSubview:datePickerView];

	UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
														target:self action:@selector(doneAction:)];
	self.navigationItem.rightBarButtonItem = button;

	[button release];
	
	// label for picker selection output
	frame = CGRectMake(	kLeftMargin,
									kTweenMargin + 220.0,
									self.view.bounds.size.width - (kRightMargin * 2.0),
									kTextFieldHeight);
	label = [[UILabel alloc] initWithFrame:frame];
	label.font = [UIFont systemFontOfSize:14];
	label.textAlignment = UITextAlignmentCenter;
	label.textColor = [UIColor whiteColor];
	label.backgroundColor = [UIColor clearColor];
	label.text = [format stringFromDate: date];
	[self.view addSubview:label];
}

/* finish */
- (void)doneAction:(id)sender
{
	if(_selectTarget != nil && _selectCallback != nil)
	{
		[_selectTarget performSelector:(SEL)_selectCallback withObject: [datePickerView date]];
	}

	[self.navigationController popViewControllerAnimated: YES];
}

/* dealloc */
- (void)dealloc
{
	[datePickerView release];
	[date release];
	[label release];
	[format release];

	[super dealloc];
}

/* selection changed */
- (void)timeChanged: (id)sender
{
	label.text = [format stringFromDate: [datePickerView date]];
}

/* set callback */
- (void)setTarget: (id)target action: (SEL)action
{
	_selectTarget = target;
	_selectCallback = action;
}

@end
