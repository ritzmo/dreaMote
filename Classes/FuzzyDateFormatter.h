//
//  FuzzyDateFormatter.h
//  dreaMote
//
//  Created by Moritz Venn on 02.08.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

/*!
 @brief A "Fuzzy" DateFormatter.
 
 Partially resolves the date to ease readability by a human user.
 */
@interface FuzzyDateFormatter : NSDateFormatter
{
@private
	NSDate *_thisNight; /*!< @brief Cached NSDate refering to 00:00 today. */
}

/*!
 @brief Request a reset of the reference date.
 */
- (void)resetReferenceDate;

@end
