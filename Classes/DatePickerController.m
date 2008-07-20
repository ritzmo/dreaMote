//
//  DatePickerController.m
//  Untitled
//
//  Created by Moritz Venn on 13.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "DatePickerController.h"

#import "Constants.h"

@implementation DatePickerController

#define kPickerSegmentControlHeight 30.0

@synthesize date;
@synthesize format;

- (id)init
{
	if (self = [super init])
	{
		// this title will appear in the navigation bar
		self.title = NSLocalizedString(@"Date Picker", @"");
		self.format = [[NSDateFormatter alloc] init];
		[self.format setDateFormat: @"%A, %d.%m.%Y %H:%M"];
	}
	
	return self;
}

+ (DatePickerController *)withDate: (NSDate *)ourDate
{
	DatePickerController *datePickerController = [[DatePickerController alloc] init];
	datePickerController.date = [ourDate retain];
	
	return datePickerController;
}

- (void)loadView
{		
	// setup our parent content view and embed it to your view controller
	UIView *contentView = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]];
	contentView.backgroundColor = [UIColor blackColor];

	self.view = contentView;
	[contentView release];

	CGRect frame = CGRectMake(	0.0,
								kTopMargin + kPickerSegmentControlHeight,
								self.view.bounds.size.width - (kRightMargin * 2.0),
								self.view.bounds.size.height - 110.0);
	datePickerView = [[UIDatePicker alloc] initWithFrame:frame];
	datePickerView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	datePickerView.datePickerMode = UIDatePickerModeDateAndTime;
	datePickerView.date = date;
	[datePickerView addTarget:self action:@selector(timeChanged:) forControlEvents:UIControlEventValueChanged];
	[self.view addSubview:datePickerView];
	
	// label for picker selection output
	frame = CGRectMake(	kLeftMargin,
									kTopMargin + kPickerSegmentControlHeight + 220.0,
									self.view.bounds.size.width - (kRightMargin * 2.0),
									kTextFieldHeight);
	label = [[UILabel alloc] initWithFrame:frame];
    label.font = [UIFont systemFontOfSize:14];
	label.textAlignment = UITextAlignmentCenter;
	label.textColor = [UIColor whiteColor];
	label.backgroundColor = [UIColor clearColor];
	label.text = @"asdf";
	[self.view addSubview:label];
}

- (void)dealloc
{
	[textField release];
	[datePickerView release];
	[label release];
	[format release];

	[super dealloc];
}

- (void)timeChanged: (id)sender
{
	label.text = [format stringFromDate: [datePickerView date]];
}

@end
