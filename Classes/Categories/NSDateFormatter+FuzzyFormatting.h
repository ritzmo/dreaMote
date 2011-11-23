//
//  NSDateFormatter+FuzzyFormatting.h
//  dreaMote
//
//  Created by Moritz Venn on 02.08.08.
//  Copyright 2008-2011 Moritz Venn. All rights reserved.
//

#import <Foundation/Foundation.h>

/*!
 @brief A "Fuzzy" DateFormatter.
 
 Partially resolves the date to ease readability by a human user.
 */
@interface NSDateFormatter(FuzzyFormatting)

/*!
 @brief Request a fuzzy date.

 @param date Date to format.
 */
- (NSString *)fuzzyDate:(NSDate *)date;

/*!
 @brief Request a reset of the reference date.
 */
- (void)resetReferenceDate;

/*!
 @brief Request a reset of the reference date.
 */
+ (void)resetReferenceDate;

@end
