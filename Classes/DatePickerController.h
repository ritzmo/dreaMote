//
//  DatePickerController.h
//  Untitled
//
//  Created by Moritz Venn on 13.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DatePickerController : UIViewController
{
	UILabel			*label;
	UITextField		*textField;
	NSDate			*date;
	NSDateFormatter *format;
	UIDatePicker	*datePickerView;
}

+ (DatePickerController *)withDate: (NSDate *)ourDate;

@property (nonatomic, retain) NSDate *date;
@property (nonatomic, retain) NSDateFormatter *format;

@end
