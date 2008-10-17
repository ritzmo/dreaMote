//
//  FuzzyDateFormatter.m
//  Untitled
//
//  Created by Moritz Venn on 02.08.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "FuzzyDateFormatter.h"

#define ONEDAY 86400

@implementation FuzzyDateFormatter

// XXX: Ok, this sucks - but the iphone sdk lacks a better way I know about :D
- (NSString *)stringForObjectValue:(id)date
{
	NSDateFormatterStyle dateStyle = [self dateStyle];
	if(dateStyle == NSDateFormatterNoStyle)
		return [super stringForObjectValue:date];

	NSDate *thisNight = [NSDate dateWithTimeIntervalSinceNow: -((NSInteger)[NSDate timeIntervalSinceReferenceDate] + [[self timeZone] secondsFromGMT]) % ONEDAY];

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

	NSInteger secSinceTomorrow = secSinceToday - ONEDAY;
	if (secSinceTomorrow >= 0 && secSinceTomorrow < ONEDAY)
	{
		if([self timeStyle] == NSDateFormatterNoStyle)
			return NSLocalizedString(@"Tomorrow", @"");
		
		[self setDateStyle: NSDateFormatterNoStyle];
		NSString *retVal = [NSString stringWithFormat: @"%@, %@", NSLocalizedString(@"Tomorrow", @""), [super stringForObjectValue: date]];
		[self setDateStyle: dateStyle];
		return retVal;
	}

	NSInteger secSinceYesterday = secSinceToday + ONEDAY;
	if (secSinceYesterday >= 0 && secSinceYesterday < ONEDAY)
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