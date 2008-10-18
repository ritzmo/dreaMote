//
//  FuzzyDateFormatter.m
//  Untitled
//
//  Created by Moritz Venn on 02.08.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "FuzzyDateFormatter.h"

#define ONEDAY 86400
#define TWODAY 172800

@implementation FuzzyDateFormatter

- (id)init
{
	if(self = [super init])
	{
		thisNight = nil;
	}
	return self;
}

- (void)dealloc
{
	[thisNight dealloc];
	[super dealloc];
}

- (void)resetReferenceDate
{
	[thisNight dealloc];
	thisNight = nil;
}

// XXX: Ok, this sucks - but the iphone sdk lacks a better way I know about :D
- (NSString *)stringForObjectValue:(id)date
{
	if(date == nil)
		return nil;

	NSDateFormatterStyle dateStyle = [self dateStyle];
	if(dateStyle == NSDateFormatterNoStyle)
		return [super stringForObjectValue:date];

	if(thisNight == nil)
		thisNight = [[NSDate dateWithTimeIntervalSinceNow: -((NSInteger)[NSDate timeIntervalSinceReferenceDate] + [[self timeZone] secondsFromGMT]) % ONEDAY] retain];

	NSInteger secSinceToday = (NSInteger)([date timeIntervalSinceDate: thisNight]+0.9);
	if (secSinceToday >= 0 && secSinceToday < ONEDAY)
	{
		if([self timeStyle] == NSDateFormatterNoStyle)
			return NSLocalizedString(@"Today", @"");

		[self setDateStyle: NSDateFormatterNoStyle];
		NSString *retVal = [NSString stringWithFormat: @"%@, %@", NSLocalizedString(@"Today", @""), [super stringForObjectValue: date]];
		[self setDateStyle: dateStyle];
		return retVal;
	}

	if (secSinceToday >= ONEDAY && secSinceToday < TWODAY)
	{
		if([self timeStyle] == NSDateFormatterNoStyle)
			return NSLocalizedString(@"Tomorrow", @"");
		
		[self setDateStyle: NSDateFormatterNoStyle];
		NSString *retVal = [NSString stringWithFormat: @"%@, %@", NSLocalizedString(@"Tomorrow", @""), [super stringForObjectValue: date]];
		[self setDateStyle: dateStyle];
		return retVal;
	}

	if (secSinceToday >= -ONEDAY && secSinceToday < 0)
	{
		if([self timeStyle] == NSDateFormatterNoStyle)
			return NSLocalizedString(@"Yesterday", @"");

		[self setDateStyle: NSDateFormatterNoStyle];
		NSString *retVal = [NSString stringWithFormat: @"%@, %@", NSLocalizedString(@"Yesterday", @""), [super stringForObjectValue: date]];
		[self setDateStyle: dateStyle];
		return retVal;
	}

	return [super stringForObjectValue:date];
}

@end