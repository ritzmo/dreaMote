//
//  DatePickerController.m
//  dreaMote
//
//  Created by Moritz Venn on 13.03.08.
//  Copyright 2008-2011 Moritz Venn. All rights reserved.
//

#import "TimerViewController.h"
#import "DatePickerController.h"

#import "Constants.h"

@interface  DatePickerController()
/*!
 @brief selected date was changed
 */
- (void)timeChanged: (id)sender;

/*!
 @brief done editing
 */
- (void)doneAction:(id)sender;
@end


@implementation DatePickerController

#define kPickerSegmentControlHeight 30.0

@synthesize date = _date;
@synthesize format = _format;

/* initialize */
- (id)init
{
	if((self = [super init]))
	{
		// this title will appear in the navigation bar
		self.title = NSLocalizedString(@"Date Picker", @"");
		_format = [[NSDateFormatter alloc] init];
		[_format setDateStyle:NSDateFormatterFullStyle];
		[_format setTimeStyle:NSDateFormatterShortStyle];
	}
	
	return self;
}

/* creator */
+ (DatePickerController *)withDate: (NSDate *)ourDate
{
	DatePickerController *datePickerController = [[DatePickerController alloc] init];
	datePickerController.date = [ourDate copy];
	
	return [datePickerController autorelease];
}

/* layout */
- (void)loadView
{		
	// setup our parent content view and embed it to your view controller
	UIView *contentView = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]];
	contentView.backgroundColor = [UIColor blackColor];
	contentView.autoresizesSubviews = YES;
	contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	self.view = contentView;
	[contentView release];

	CGRect frame = CGRectMake(	0,
								0, //kTopMargin + kPickerSegmentControlHeight,
								self.view.bounds.size.width,
								220 );
	_datePickerView = [[UIDatePicker alloc] initWithFrame:frame];
	_datePickerView.autoresizingMask = (UIViewAutoresizingFlexibleWidth);// | UIViewAutoresizingFlexibleHeight);
	_datePickerView.datePickerMode = UIDatePickerModeDateAndTime;
	_datePickerView.date = _date;
	[_datePickerView addTarget:self action:@selector(timeChanged:) forControlEvents:UIControlEventValueChanged];
	[self.view addSubview: _datePickerView];

	UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
														target:self action:@selector(doneAction:)];
	self.navigationItem.rightBarButtonItem = button;
	[button release];

	// label for picker selection output
	frame = CGRectMake(	kLeftMargin,
						_datePickerView.frame.size.height + 3 * kTweenMargin,
						self.view.bounds.size.width - kLeftMargin - kRightMargin,
						kDatePickerFontSize + 2);
	_label = [[UILabel alloc] initWithFrame:frame];
	_label.autoresizingMask = (UIViewAutoresizingFlexibleWidth);
	_label.font = [UIFont systemFontOfSize:kDatePickerFontSize];
	_label.textAlignment = UITextAlignmentCenter;
	_label.textColor = [UIColor whiteColor];
	_label.backgroundColor = [UIColor clearColor];
	_label.text = [_format stringFromDate: _date];
	[self.view addSubview: _label];
}

/* finish */
- (void)doneAction:(id)sender
{
	if(_selectTarget != nil && _selectCallback != nil)
	{
		[_selectTarget performSelector:(SEL)_selectCallback withObject: [_datePickerView date]];
	}

	[self.navigationController popViewControllerAnimated: YES];
}

/* dealloc */
- (void)dealloc
{
	[_datePickerView release];
	[_date release];
	[_label release];
	[_format release];

	[super dealloc];
}

/* selection changed */
- (void)timeChanged: (id)sender
{
	_label.text = [_format stringFromDate: [_datePickerView date]];
}

/* set callback */
- (void)setTarget: (id)target action: (SEL)action
{
	_selectTarget = target;
	_selectCallback = action;
}

@end
