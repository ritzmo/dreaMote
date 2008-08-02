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
	// XXX: Ok, this sucks - but the iphone sdk lacks a better way I know about :D
	NSDate *thisNight = [NSDate dateWithTimeIntervalSinceNow: -((long)[[NSDate date] timeIntervalSince1970] % 86400)];
	NSTimeInterval secSinceToday = [date timeIntervalSinceDate: thisNight];
	NSTimeInterval secSinceYesterday = [date timeIntervalSinceDate: [thisNight addTimeInterval: -86400]];
	NSTimeInterval secSinceTomorrow = [date timeIntervalSinceDate: [thisNight addTimeInterval: 86400]];
	
	if (secSinceToday > 0 && secSinceToday < 86400)
	{
		if([self dateStyle] == NSDateFormatterNoStyle)
			return [super stringForObjectValue:date];
		if([self timeStyle] == NSDateFormatterNoStyle)
			return NSLocalizedString(@"Today", @"");
		NSDateFormatterStyle tempStyle = [self timeStyle];
		[self setDateStyle: NSDateFormatterNoStyle];
		NSString *retVal = [NSString stringWithFormat: @"%@, %@", NSLocalizedString(@"Today", @""), [super stringForObjectValue: date]];
		[self setDateStyle: tempStyle];
		return retVal;
	}
	else if (secSinceYesterday > 0 && secSinceYesterday < 86400)
	{
		if([self dateStyle] == NSDateFormatterNoStyle)
			return [super stringForObjectValue:date];
		if([self timeStyle] == NSDateFormatterNoStyle)
			return NSLocalizedString(@"Yesterday", @"");
		NSDateFormatterStyle tempStyle = [self timeStyle];
		[self setDateStyle: NSDateFormatterNoStyle];
		NSString *retVal = [NSString stringWithFormat: @"%@, %@", NSLocalizedString(@"Yesterday", @""), [super stringForObjectValue: date]];
		[self setDateStyle: tempStyle];
		return retVal;
	}
	else if (secSinceTomorrow > 0 && secSinceTomorrow < 86400)
	{
		if([self dateStyle] == NSDateFormatterNoStyle)
			return [super stringForObjectValue:date];
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