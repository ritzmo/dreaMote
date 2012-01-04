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

@synthesize auxiliary, file, flags, repeat, lifetime, priority, tid, hasRepeatBegin;

- (id)init
{
	if((self = [super init]))
	{
		self.valid = YES;
	}
	return self;
}

- (id)initWithTimer:(NSObject<TimerProtocol> *)timer
{
	if((self = [super initWithTimer:timer]))
	{
		if([timer isKindOfClass:[SVDRPTimer class]])
		{
			SVDRPTimer *t = (SVDRPTimer *)timer;
			repeat = [t.repeat copy];
			file = [t.file copy];
			auxiliary = [t.auxiliary copy];
			tid = [t.tid copy];
			hasRepeatBegin = t.hasRepeatBegin;
			flags = t.flags;
			lifetime = [t.lifetime copy];
			priority = [t.priority copy];
		}
	}
	return self;
}

- (NSString *)toString
{
	NSInteger newFlags = flags;
	if(self.disabled)
		newFlags |= 1;
	else
		newFlags &= ~1;

	const NSCalendar *gregorian = [[NSCalendar alloc]
								initWithCalendarIdentifier:NSGregorianCalendar];
	const NSDateComponents *beginComponents = [gregorian components: NSYearCalendarUnit | NSMonthCalendarUnit |  NSDayCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit fromDate:self.begin];
	const NSDateComponents *endComponents = [gregorian components: NSYearCalendarUnit | NSMonthCalendarUnit |  NSDayCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit fromDate:self.end];

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
		newFlags, self.service.sref, dayStr, [beginComponents hour] * 100 + [beginComponents minute],
		[endComponents hour] * 100 + [endComponents minute], priority, lifetime,
		file, auxiliary];
}

- (BOOL)isEqualToEvent:(NSObject <EventProtocol>*)event
{
	return NO;
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
