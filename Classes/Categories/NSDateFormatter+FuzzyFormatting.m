//
//  NSDateFormatter+FuzzyFormatting.m
//  dreaMote
//
//  Created by Moritz Venn on 02.08.08.
//  Copyright 2008-2011 Moritz Venn. All rights reserved.
//

#import "NSDateFormatter+FuzzyFormatting.h"

#import "UIDevice+SystemVersion.h"

/*!
 @brief Seconds in a day.
 */
#define ONEDAY 86400

/*!
 @brief Seconds in two days.
 */
#define TWODAY 172800

/*!
 @brief Seconds in a week.
 */
#define ONEWEEK 604800

@implementation NSDateFormatter(FuzzyFormatting)

/*!
 @brief Cached NSDate refering to 00:00 today.
 */
static NSDate *_thisNight = nil;

/* reset reference */
- (void)resetReferenceDate
{
	[_thisNight release];
	_thisNight = nil;
}

/* translate date to string */
// NOTE: iOS4 brings its own simple fuzzer, but we want a more specific one.
- (NSString *)fuzzyDate:(NSDate *)date
{
	// Argument error, return nothing
	if(date == nil)
		return nil;

	/*!
	 @note while our approach might be unoptimized and complicated, the one from apple
	 is a little weird too. It uses rarely used relative dates and we want a little more
	 fuzzing anyway.
	 */
#if 0
	// use builtin mechanism on iOS4+, but use old behavior (reset fuzzy before returning)
	if([UIDevice runsIos4OrBetter])
	{
		const BOOL relativeFormatting = [self doesRelativeDateFormatting];
		[self setDoesRelativeDateFormatting:YES];
		NSString *retVal = [self stringFromDate:date];
		[self setDoesRelativeDateFormatting:relativeFormatting];
		return retVal;
	}
#endif

	const NSDateFormatterStyle dateStyle = [self dateStyle];
	if(dateStyle == NSDateFormatterNoStyle)
		return [self stringForObjectValue:date];
	
	// Set reference date if none set
	if(_thisNight == nil)
		_thisNight = [[NSDate dateWithTimeIntervalSinceNow: -((NSInteger)[NSDate timeIntervalSinceReferenceDate] + [[self timeZone] secondsFromGMT]) % ONEDAY] retain];
	
	// Get seconds the event is away from 00:00 today
	const NSInteger secSinceToday = (NSInteger)([date timeIntervalSinceDate: _thisNight]+0.9);
	
	if (secSinceToday >= 0 && secSinceToday < ONEDAY)
	{
		/* Between no day and one day, so its "Today" */
		if([self timeStyle] == NSDateFormatterNoStyle)
			return NSLocalizedString(@"Today", @"");
		
		[self setDateStyle: NSDateFormatterNoStyle];
		NSString *retVal = [NSString stringWithFormat: @"%@, %@", NSLocalizedString(@"Today", @""), [self stringForObjectValue: date]];
		[self setDateStyle: dateStyle];
		return retVal;
	}
	
	if (secSinceToday >= ONEDAY && secSinceToday < TWODAY)
	{
		/* Between one day and two days, so its "Tomorrow" */
		if([self timeStyle] == NSDateFormatterNoStyle)
			return NSLocalizedString(@"Tomorrow", @"");
		
		[self setDateStyle: NSDateFormatterNoStyle];
		NSString *retVal = [NSString stringWithFormat: @"%@, %@", NSLocalizedString(@"Tomorrow", @""), [self stringForObjectValue: date]];
		[self setDateStyle: dateStyle];
		return retVal;
	}
	
	if (secSinceToday >= -ONEDAY && secSinceToday < 0)
	{
		/* One day in the past, so its "Yesterday" */
		if([self timeStyle] == NSDateFormatterNoStyle)
			return NSLocalizedString(@"Yesterday", @"");
		
		[self setDateStyle: NSDateFormatterNoStyle];
		NSString *retVal = [NSString stringWithFormat: @"%@, %@", NSLocalizedString(@"Yesterday", @""), [self stringForObjectValue: date]];
		[self setDateStyle: dateStyle];
		return retVal;
	}

	if(secSinceToday >= TWODAY && secSinceToday < ONEWEEK && dateStyle != NSDateFormatterFullStyle)
	{
		/* Between two days and a week, display weekday. */
		NSCalendar *cal = [NSCalendar currentCalendar];
		NSDateComponents *comps = [cal components:NSWeekdayCalendarUnit fromDate:date];
		NSString *weekday = [[self weekdaySymbols] objectAtIndex:[comps weekday]-1];

		return [NSString stringWithFormat: @"%@, %@", weekday, [self stringForObjectValue:date]];
	}
	
	// No special handling for this date, so return default one
	return [self stringForObjectValue:date];
}

@end
