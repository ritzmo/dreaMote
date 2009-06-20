//
//  FuzzyDateFormatter.m
//  dreaMote
//
//  Created by Moritz Venn on 02.08.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "FuzzyDateFormatter.h"

/*!
 @brief Seconds in a day.
 */
#define ONEDAY 86400

/*!
 @brief Seconds in two days.
 */
#define TWODAY 172800

@implementation FuzzyDateFormatter

/* initialize */
- (id)init
{
	if(self = [super init])
	{
		thisNight = nil;
	}
	return self;
}

/* dealloc */
- (void)dealloc
{
	[thisNight release];
	[super dealloc];
}

/* reset reference */
- (void)resetReferenceDate
{
	[thisNight release];
	thisNight = nil;
}

// XXX: Ok, this sucks - but the iphone sdk lacks a better way I know about :D
- (NSString *)stringForObjectValue:(id)date
{
	// Argument error, return nothing
	if(date == nil)
		return nil;

	NSDateFormatterStyle dateStyle = [self dateStyle];
	if(dateStyle == NSDateFormatterNoStyle)
		return [super stringForObjectValue:date];

	// Set reference date if none set
	if(thisNight == nil)
		thisNight = [[NSDate dateWithTimeIntervalSinceNow: -((NSInteger)[NSDate timeIntervalSinceReferenceDate] + [[self timeZone] secondsFromGMT]) % ONEDAY] retain];

	// Get seconds the event is away from 00:00 today
	NSInteger secSinceToday = (NSInteger)([date timeIntervalSinceDate: thisNight]+0.9);

	if (secSinceToday >= 0 && secSinceToday < ONEDAY)
	{
		/* Between one day, so its "Today" */
		if([self timeStyle] == NSDateFormatterNoStyle)
			return NSLocalizedString(@"Today", @"");

		[self setDateStyle: NSDateFormatterNoStyle];
		NSString *retVal = [NSString stringWithFormat: @"%@, %@", NSLocalizedString(@"Today", @""), [super stringForObjectValue: date]];
		[self setDateStyle: dateStyle];
		return retVal;
	}

	if (secSinceToday >= ONEDAY && secSinceToday < TWODAY)
	{
		/* Between one day and two days, so its "Tomorrow" */
		if([self timeStyle] == NSDateFormatterNoStyle)
			return NSLocalizedString(@"Tomorrow", @"");
		
		[self setDateStyle: NSDateFormatterNoStyle];
		NSString *retVal = [NSString stringWithFormat: @"%@, %@", NSLocalizedString(@"Tomorrow", @""), [super stringForObjectValue: date]];
		[self setDateStyle: dateStyle];
		return retVal;
	}

	if (secSinceToday >= -ONEDAY && secSinceToday < 0)
	{
		/* One day in the past, so its "Yesterday" */
		if([self timeStyle] == NSDateFormatterNoStyle)
			return NSLocalizedString(@"Yesterday", @"");

		[self setDateStyle: NSDateFormatterNoStyle];
		NSString *retVal = [NSString stringWithFormat: @"%@, %@", NSLocalizedString(@"Yesterday", @""), [super stringForObjectValue: date]];
		[self setDateStyle: dateStyle];
		return retVal;
	}

	// No special handling for this date, so return default one
	return [super stringForObjectValue:date];
}

@end
