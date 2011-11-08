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
@synthesize format, callback;

/* initialize */
- (id)init
{
	if((self = [super init]))
	{
		// this title will appear in the navigation bar
		self.title = NSLocalizedString(@"Date Picker", @"Title of DatePickerController");
		format = [[NSDateFormatter alloc] init];
		self.datePickerMode = UIDatePickerModeDateAndTime;
		self.modalPresentationStyle = UIModalPresentationFormSheet;
		self.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
		callback = nil;
	}
	
	return self;
}

/* creator */
+ (DatePickerController *)withDate: (NSDate *)ourDate
{
	DatePickerController *datePickerController = [[DatePickerController alloc] init];
	NSDate *newDate = [ourDate copy];
	datePickerController.date = newDate;

	return datePickerController;
}

- (void)setDate:(NSDate *)new
{
	if([_date isEqual:new]) return;

	// ensure there is a date
	if(!new)
		new = [NSDate date];

	_date = new;

	_datePickerView.date = _date;
	_label.text = [format stringFromDate:_date];
}

- (UIDatePickerMode)datePickerMode
{
	return datePickerMode;
}

- (void)setDatePickerMode:(UIDatePickerMode)newDatePickerMode
{
	datePickerMode = newDatePickerMode;
	_datePickerView.datePickerMode = newDatePickerMode;

	switch(newDatePickerMode)
	{
		case UIDatePickerModeDateAndTime:
			[format setDateStyle:NSDateFormatterFullStyle];
			[format setTimeStyle:NSDateFormatterShortStyle];
			break;
		case UIDatePickerModeTime:
			[format setDateStyle:NSDateFormatterNoStyle];
			[format setTimeStyle:NSDateFormatterShortStyle];
			break;
		case UIDatePickerModeDate:
			[format setDateStyle:NSDateFormatterFullStyle];
			[format setTimeStyle:NSDateFormatterNoStyle];
			break;
		default:
			[format setDateStyle:NSDateFormatterNoStyle];
			[format setTimeStyle:NSDateFormatterNoStyle];
			break;
	}
	_label.text = [format stringFromDate:_date];
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

	CGRect frame = CGRectMake(	0,
								0, //kTopMargin + kPickerSegmentControlHeight,
								self.view.bounds.size.width,
								220 );
	_datePickerView = [[UIDatePicker alloc] initWithFrame:frame];
	_datePickerView.autoresizingMask = (UIViewAutoresizingFlexibleWidth);// | UIViewAutoresizingFlexibleHeight);
	_datePickerView.datePickerMode = datePickerMode;
	_datePickerView.date = _date;
	[_datePickerView addTarget:self action:@selector(timeChanged:) forControlEvents:UIControlEventValueChanged];
	[self.view addSubview: _datePickerView];

	UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
														target:self action:@selector(doneAction:)];
	self.navigationItem.rightBarButtonItem = button;

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
	_label.text = [format stringFromDate: _date];
	[self.view addSubview: _label];

	[self theme];
}

- (void)viewDidUnload
{
	_datePickerView = nil;
	_label = nil;

	[super viewDidUnload];
}

/* rotate with device on ipad, otherwise to portrait */
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	if(IS_IPAD())
		return YES;
	return UIInterfaceOrientationIsPortrait(interfaceOrientation);
}

/* finish */
- (void)doneAction:(id)sender
{
	if(callback != nil)
	{
		__unsafe_unretained NSDate *date = [_datePickerView date];
		if(datePickerMode == UIDatePickerModeDate)
		{
			NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
			NSDateComponents *components = [gregorian components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit) fromDate:date];
			date = [gregorian dateFromComponents:components];
		}
		callback(date);
	}

	if(IS_IPAD())
		[self.navigationController dismissModalViewControllerAnimated:YES];
	else
		[self.navigationController popViewControllerAnimated: YES];
}

/* selection changed */
- (void)timeChanged: (id)sender
{
	_label.text = [format stringFromDate: [_datePickerView date]];
}

@end
