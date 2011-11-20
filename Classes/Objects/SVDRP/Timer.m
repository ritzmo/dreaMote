//
//  Timer.m
//  dreaMote
//
//  Created by Moritz Venn on 04.01.09.
//  Copyright 2009-2011 Moritz Venn. All rights reserved.
//

#import "Timer.h"

#import <Objects/EventProtocol.h>
#import <Objects/ServiceProtocol.h>

@implementation SVDRPTimer

@synthesize auxiliary, eit, begin, end, file, flags, title, tdescription, disabled, repeat, repeated, repeatcount, justplay, lifetime, priority, service, sref, sname, state, afterevent, valid, timeString, tid, hasRepeatBegin;

- (id)init
{
	if((self = [super init]))
	{
		valid = YES;
	}
	return self;
}

- (id)initWithSVDRPTimer:(SVDRPTimer *)timer
{
	if((self = [super init]))
	{
		begin = [timer.begin copy];
		end = [timer.end copy];
		eit = [timer.eit copy];
		title = [timer.title copy];
		tdescription = [timer.tdescription copy];
		disabled = timer.disabled;
		justplay = timer.justplay;
		service = [timer.service copy];
		repeated = timer.repeated;
		repeatcount = timer.repeatcount;
		state = timer.state;
		valid = timer.valid;
		afterevent = timer.afterevent;
		repeat = [timer.repeat copy];
		auxiliary = [timer.auxiliary copy];
		tid = [timer.tid copy];
		hasRepeatBegin = timer.hasRepeatBegin;
		flags = timer.flags;
		lifetime = [timer.lifetime copy];
		priority = [timer.priority copy];
	}
	
	return self;
}

- (NSString *)toString
{
	NSInteger newFlags = flags;
	if(disabled)
		newFlags |= 1;
	else
		newFlags &= ~1;

	const NSCalendar *gregorian = [[NSCalendar alloc]
								initWithCalendarIdentifier:NSGregorianCalendar];
	const NSDateComponents *beginComponents = [gregorian components: NSYearCalendarUnit | NSMonthCalendarUnit |  NSDayCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit fromDate:begin];
	const NSDateComponents *endComponents = [gregorian components: NSYearCalendarUnit | NSMonthCalendarUnit |  NSDayCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit fromDate:end];

	NSString *dayStr;
	if(hasRepeatBegin)
		dayStr = [NSString stringWithFormat: @"%@@%d-%02d-%02d",
					repeat, [beginComponents year], [beginComponents month], [beginComponents day]];
	else if(repeat != nil)
		dayStr = repeat;
	else
		dayStr = [NSString stringWithFormat: @"%d-%02d-%02d",
					[beginComponents year], [beginComponents month], [beginComponents day]];

	return [NSString stringWithFormat: @"%d:%@:%@:%04d:%04d:%@:%@:%@:%@",
		newFlags, service.sref, dayStr, [beginComponents hour] * 100 + [beginComponents minute],
		[endComponents hour] * 100 + [endComponents minute], priority, lifetime,
		file, auxiliary];
}

- (BOOL)isEqualToEvent:(NSObject <EventProtocol>*)event
{
	return NO;
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"<%@> Title: '%@'.\n Eit: '%@'.\n", [self class], self.title, self.eit];
}

#pragma mark -
#pragma mark	Copy
#pragma mark -

- (id)copyWithZone:(NSZone *)zone
{
	id newElement = [[SVDRPTimer alloc] initWithSVDRPTimer: self];

	return newElement;
}

#pragma mark Unsupported

- (NSString *)getStateString
{
#if IS_DEBUG()
	[NSException raise:@"ExcUnsupportedFunction" format:@""];
#endif
	return nil;
}

- (void)setBeginFromString: (NSString *)newBegin
{
#if IS_DEBUG()
	[NSException raise:@"ExcUnsupportedFunction" format:@""];
#endif
}

- (void)setEndFromString: (NSString *)newEnd
{
#if IS_DEBUG()
	[NSException raise:@"ExcUnsupportedFunction" format:@""];
#endif
}

- (void)setEndFromDurationString: (NSString *)newDuration
{
#if IS_DEBUG()
	[NSException raise:@"ExcUnsupportedFunction" format:@""];
#endif
}

- (void)setSref: (NSString *)newSref
{
#if IS_DEBUG()
	[NSException raise:@"ExcUnsupportedFunction" format:@""];
#endif
}

- (void)setSname: (NSString *)newSname
{
#if IS_DEBUG()
	[NSException raise:@"ExcUnsupportedFunction" format:@""];
#endif
}

- (NSString *)location
{
	return nil;
}

- (void)setLocation:(NSString *)new
{
#if IS_DEBUG()
	[NSException raise:@"ExcUnsupportedFunction" format:@""];
#endif
}

- (NSArray *)tags
{
	return nil;
}

- (void)setTags:(NSArray *)tags
{ }

- (void)setTagsFromString:(NSString *)newTags
{ }

@end
