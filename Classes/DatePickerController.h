//
//  DatePickerController.h
//  dreaMote
//
//  Created by Moritz Venn on 13.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

/*!
 @brief Date Picker.
 
 Allows to select a date.
 */
@interface DatePickerController : UIViewController
{
@private
	UILabel			*label; /*!< @brief Label containing a textual representation of selected date. */
	NSDate			*date; /*!< @brief Date to preselect. */
	NSDateFormatter *format; /*!< @brief Cached DateFormatter for textual representation. */
	UIDatePicker	*datePickerView; /*!< @brief Actual Date Picker. */
	SEL _selectCallback; /*!< @brief Callback selector. */
	id _selectTarget; /*!< @brief Callback object. */
}

/*!
 @brief Standard creator.
 
 @param ourDate Date to preselect.
 @return DatePickerController instance.
 */
+ (DatePickerController *)withDate: (NSDate *)ourDate;

/*!
 @brief Set Callback Target.
 
 @param target Target object.
 @param action Target selector.
 */
- (void)setTarget: (id)target action: (SEL)action;



/*!
 @brief Preselected Date.
 */
@property (nonatomic, retain) NSDate *date;

/*!
 @brief Date Formatter.
 */
@property (nonatomic, retain) NSDateFormatter *format;

@end
