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
	if([self dateStyle] == NSDateFormatterNoStyle)
		return [super stringForObjectValue:date];

	NSDate *thisNight = [NSDate dateWithTimeIntervalSinceNow: -(((long)[NSDate timeIntervalSinceReferenceDate]) + [[self timeZone] secondsFromGMT]) % ONEDAY];

	NSTimeInterval secSinceToday = [date timeIntervalSinceDate: thisNight];
	if (secSinceToday > 0 && secSinceToday < ONEDAY)
	{
		if([self timeStyle] == NSDateFormatterNoStyle)
			return NSLocalizedString(@"Today", @"");
		NSDateFormatterStyle tempStyle = [self dateStyle];
		[self setDateStyle: NSDateFormatterNoStyle];
		NSString *retVal = [NSString stringWithFormat: @"%@, %@", NSLocalizedString(@"Today", @""), [super stringForObjectValue: date]];
		[self setDateStyle: tempStyle];
		return retVal;
	}

	NSTimeInterval secSinceTomorrow = [date timeIntervalSinceDate: [thisNight addTimeInterval: ONEDAY]];
	if (secSinceTomorrow > 0 && secSinceTomorrow < ONEDAY)
	{
		if([self timeStyle] == NSDateFormatterNoStyle)
			return NSLocalizedString(@"Tomorrow", @"");
		NSDateFormatterStyle tempStyle = [self dateStyle];
		[self setDateStyle: NSDateFormatterNoStyle];
		NSString *retVal = [NSString stringWithFormat: @"%@, %@", NSLocalizedString(@"Tomorrow", @""), [super stringForObjectValue: date]];
		[self setDateStyle: tempStyle];
		return retVal;
	}

	NSTimeInterval secSinceYesterday = [date timeIntervalSinceDate: [thisNight addTimeInterval: -ONEDAY]];
	if (secSinceYesterday > 0 && secSinceYesterday < ONEDAY)
	{
		if([self timeStyle] == NSDateFormatterNoStyle)
			return NSLocalizedString(@"Yesterday", @"");
		NSDateFormatterStyle tempStyle = [self dateStyle];
		[self setDateStyle: NSDateFormatterNoStyle];
		NSString *retVal = [NSString stringWithFormat: @"%@, %@", NSLocalizedString(@"Yesterday", @""), [super stringForObjectValue: date]];
		[self setDateStyle: tempStyle];
		return retVal;
	}

	return [super stringForObjectValue:date];
}

@end