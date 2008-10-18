//
//  FuzzyDateFormatter.h
//  Untitled
//
//  Created by Moritz Venn on 02.08.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

@interface FuzzyDateFormatter : NSDateFormatter
{
@private
	NSDate *thisNight;
}

- (void)resetReferenceDate;

@end