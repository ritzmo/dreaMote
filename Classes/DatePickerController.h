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
@private
	UILabel			*label;
	NSDate			*date;
	NSDateFormatter *format;
	UIDatePicker	*datePickerView;
	SEL _selectCallback;
	id _selectTarget;
}

+ (DatePickerController *)withDate: (NSDate *)ourDate;
- (void)setTarget: (id)target action: (SEL)action;

@property (nonatomic, retain) NSDate *date;
@property (nonatomic, retain) NSDateFormatter *format;

@end
