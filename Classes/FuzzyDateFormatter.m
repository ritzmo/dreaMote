//
//  FuzzyDateFormatter.m
//  Untitled
//
//  Created by Moritz Venn on 02.08.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "FuzzyDateFormatter.h"

@implementation FuzzyDateFormatter

- (NSString *)stringForObjectValue:(id)date
{
	int todaysDayOfCommonEra, datesDayOfCommonEra;

	if (![date isKindOfClass:[NSCalendarDate class]])
		return [super stringForObjectValue:date];

	todaysDayOfCommonEra = [[NSCalendarDate date] dayOfCommonEra];
	datesDayOfCommonEra = [date dayOfCommonEra];

	if (datesDayOfCommonEra == todaysDayOfCommonEra)
	{
		if([self timeStyle] == NSDateFormatterNoStyle)
			return NSLocalizedString(@"Today", @"");
		NSDateFormatterStyle tempStyle = [self timeStyle];
		[self setDateStyle: NSDateFormatterNoStyle];
		NSString *retVal = [NSString stringWithFormat: @"%@, %@", NSLocalizedString(@"Today", @""), [super stringForObjectValue: date]];
		[self setDateStyle: tempStyle];
		return retVal;
	}
	else if (datesDayOfCommonEra == (todaysDayOfCommonEra - 1))
	{
		if([self timeStyle] == NSDateFormatterNoStyle)
			return NSLocalizedString(@"Yesterday", @"");
		NSDateFormatterStyle tempStyle = [self timeStyle];
		[self setDateStyle: NSDateFormatterNoStyle];
		NSString *retVal = [NSString stringWithFormat: @"%@, %@", NSLocalizedString(@"Yesterday", @""), [super stringForObjectValue: date]];
		[self setDateStyle: tempStyle];
		return retVal;
	}
	else if (datesDayOfCommonEra == (todaysDayOfCommonEra + 1))
	{
		if([self timeStyle] == NSDateFormatterNoStyle)
			return NSLocalizedString(@"Tomorrow", @"");
		NSDateFormatterStyle tempStyle = [self timeStyle];
		[self setDateStyle: NSDateFormatterNoStyle];
		NSString *retVal = [NSString stringWithFormat: @"%@, %@", NSLocalizedString(@"Tomorrow", @""), [super stringForObjectValue: date]];
		[self setDateStyle: tempStyle];
		return retVal;
	}
	else
		return [super stringForObjectValue:date];
}

@end