//
//  DatePickerController.h
//  dreaMote
//
//  Created by Moritz Venn on 13.03.08.
//  Copyright 2008-2011 Moritz Venn. All rights reserved.
//

#import <UIKit/UIKit.h>

/*!
 @brief Our callback type.
 For callbacks we use a block with one (NSDate *) parameter.
 */
typedef void (^datepicker_callback_t)(NSDate *);

/*!
 @brief Date Picker.
 
 Allows to select a date.
 */
@interface DatePickerController : UIViewController
{
@private
	UILabel			*_label; /*!< @brief Label containing a textual representation of selected date. */
	NSDate			*_date; /*!< @brief Date to preselect. */
	UIDatePicker	*_datePickerView; /*!< @brief Actual Date Picker. */
	UIDatePickerMode datePickerMode;
}

/*!
 @brief Standard creator.
 
 @param ourDate Date to preselect.
 @return DatePickerController instance.
 */
+ (DatePickerController *)withDate: (NSDate *)ourDate;



/*!
 @brief Preselected Date.
 */
@property (nonatomic, strong) NSDate *date;

/*!
 @brief Date Picker mode.
 */
@property (nonatomic) UIDatePickerMode datePickerMode;

/*!
 @brief Date Formatter.
 */
@property (nonatomic, strong) NSDateFormatter *format;

/*!
 @brief Callback.
 */
@property (nonatomic, copy) datepicker_callback_t callback;

@end
