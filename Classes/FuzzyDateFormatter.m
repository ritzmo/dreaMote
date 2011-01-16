//
//  FuzzyDateFormatter.m
//  dreaMote
//
//  Created by Moritz Venn on 02.08.08.
//  Copyright 2008-2011 Moritz Venn. All rights reserved.
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

static FuzzyDateFormatter *_sharedFormatter = nil;

@implementation FuzzyDateFormatter

/* return shared formatter */
+ (FuzzyDateFormatter *)sharedFormatter
{
	if(_sharedFormatter == nil)
		_sharedFormatter = [[FuzzyDateFormatter alloc] init];
	[_sharedFormatter setTimeStyle:NSDateFormatterShortStyle];
	return _sharedFormatter;
}

/* initialize */
- (id)init
{
	if((self = [super init]))
	{
		_thisNight = nil;
	}
	return self;
}

/* dealloc */
- (void)dealloc
{
	[_thisNight release];
	[super dealloc];
}

/* reset reference */
- (void)resetReferenceDate
{
	[_thisNight release];
	_thisNight = nil;
}

/* translate date to string */
// NOTE: Ok, this sucks - but the iphone sdk lacks a better way I know about :D
// TODO: recheck with 3.0 sdk, I know there is some new stuff on SL that does so, maybe we also have it.
- (NSString *)stringForObjectValue:(id)date
{
	// Argument error, return nothing
	if(date == nil)
		return nil;

	const NSDateFormatterStyle dateStyle = [self dateStyle];
	if(dateStyle == NSDateFormatterNoStyle)
		return [super stringForObjectValue:date];

	// Set reference date if none set
	if(_thisNight == nil)
		_thisNight = [[NSDate dateWithTimeIntervalSinceNow: -((NSInteger)[NSDate timeIntervalSinceReferenceDate] + [[self timeZone] secondsFromGMT]) % ONEDAY] retain];

	// Get seconds the event is away from 00:00 today
	const NSInteger secSinceToday = (NSInteger)([date timeIntervalSinceDate: _thisNight]+0.9);

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
