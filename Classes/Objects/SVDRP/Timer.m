//
//  Timer.m
//  dreaMote
//
//  Created by Moritz Venn on 04.01.09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "Timer.h"

#import "Service.h"

@implementation SVDRPTimer

@synthesize auxiliary = _auxiliary;
@synthesize eit = _eit;
@synthesize begin = _begin;
@synthesize end = _end;
@synthesize file = _file;
@synthesize flags = _flags;
@synthesize title = _title;
@synthesize tdescription = _tdescription;
@synthesize disabled = _disabled;
@synthesize repeat = _repeat;
@synthesize repeated = _repeated;
@synthesize repeatcount = _repeatcount;
@synthesize justplay = _justplay;
@synthesize lifetime = _lifetime;
@synthesize priority = _priority;
@synthesize service = _service;
@synthesize sref = _sref;
@synthesize sname = _sname;
@synthesize state = _state;
@synthesize afterevent = _afterevent;
@synthesize valid = _isValid;
@synthesize timeString = _timeString;
@synthesize tid = _tid;
@synthesize hasRepeatBegin = _hasRepeatBegin;

- (id)init
{
	if (self = [super init])
	{
		_service = nil;
		_isValid = YES;
		_timeString = nil;
	}
	return self;
}


- (id)initWithSVDRPTimer:(SVDRPTimer *)timer
{
	if(self = [super init])
	{
		_begin = [timer.begin copy];
		_end = [timer.end copy];
		_eit = [timer.eit copy];
		_title = [timer.title copy];
		_tdescription = [timer.tdescription copy];
		_disabled = timer.disabled;
		_justplay = timer.justplay;
		_service = [timer.service copy];
		_repeated = timer.repeated;
		_repeatcount = timer.repeatcount;
		_state = timer.state;
		_isValid = timer.valid;
		_afterevent = timer.afterevent;
		_repeat = [timer.repeat copy];
		_auxiliary = [timer.auxiliary copy];
		_tid = [timer.tid copy];
		_hasRepeatBegin = timer.hasRepeatBegin;
		_flags = timer.flags;
		_lifetime = [timer.lifetime copy];
		_priority = [timer.priority copy];
	}
	
	return self;
}

- (void)dealloc
{
	[_auxiliary release];
	[_begin release];
	[_end release];
	[_eit release];
	[_file release];
	[_title release];
	[_tdescription release];
	[_repeat release];
	[_lifetime release];
	[_priority release];
	[_service release];
	[_sname release];
	[_sref release];
	[_timeString release];
	[_tid release];

	[super dealloc];
}

- (NSString *)toString
{
	NSInteger newFlags = _flags;
	if(_disabled)
		newFlags |= 1;
	else
		newFlags &= ~1;

	const NSCalendar *gregorian = [[NSCalendar alloc]
								initWithCalendarIdentifier:NSGregorianCalendar];
	const NSDateComponents *beginComponents = [gregorian components: NSYearCalendarUnit | NSMonthCalendarUnit |  NSDayCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit fromDate: _begin];
	const NSDateComponents *endComponents = [gregorian components: NSYearCalendarUnit | NSMonthCalendarUnit |  NSDayCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit fromDate: _end];
	[gregorian release];

	NSString *dayStr;
	if(_hasRepeatBegin)
		dayStr = [NSString stringWithFormat: @"%@@%d-%d-%d",
					_repeat, [beginComponents year], [beginComponents month], [beginComponents day]];
	else if(_repeat != nil)
		dayStr = _repeat;
	else
		dayStr = [NSString stringWithFormat: @"%d-%d-%d",
					[beginComponents year], [beginComponents month], [beginComponents day]];

	return [NSString stringWithFormat: @"%d:%@:%@:%d:%d:%@:%@:%@:%@",
		newFlags, _service.sref, dayStr, [beginComponents hour] * 100 + [beginComponents minute],
		[endComponents hour] * 100 + [endComponents minute], _priority, _lifetime,
		_file, _auxiliary];
}

#pragma mark -
#pragma mark	Copy
#pragma mark -

- (id)copyWithZone:(NSZone *)zone
{
	id newElement = [[SVDRPTimer alloc] initWithSVDRPTimer: self];

	return newElement;
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"<%@> Title: '%@'.\n Eit: '%@'.\n", [self class], self.title, self.eit];
}

- (NSString *)getStateString
{
	[NSException raise:@"ExcUnsupportedFunction" format:nil];
	return nil;
}

- (void)setBeginFromString: (NSString *)newBegin
{
	[NSException raise:@"ExcUnsupportedFunction" format:nil];
}

- (void)setEndFromString: (NSString *)newEnd
{
	[NSException raise:@"ExcUnsupportedFunction" format:nil];
}

- (void)setEndFromDurationString: (NSString *)newDuration
{
	[NSException raise:@"ExcUnsupportedFunction" format:nil];
}

- (void)setSref: (NSString *)newSref
{
	[NSException raise:@"ExcUnsupportedFunction" format:nil];
}

- (void)setSname: (NSString *)newSname
{
	[NSException raise:@"ExcUnsupportedFunction" format:nil];
}

@end
