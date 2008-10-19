//
//  Timer.m
//  Untitled
//
//  Created by Moritz Venn on 09.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "Timer.h"

#import "Service.h"
#import "Event.h"

@implementation Timer

@synthesize eit = _eit;
@synthesize begin = _begin;
@synthesize end = _end;
@synthesize title = _title;
@synthesize tdescription = _tdescription;
@synthesize disabled = _disabled;
@synthesize repeated = _repeated;
@synthesize repeatcount = _repeatcount;
@synthesize justplay = _justplay;
@synthesize service = _service;
@synthesize sref = _sref;
@synthesize sname = _sname;
@synthesize state = _state;
@synthesize afterevent = _afterevent;

+ (Timer *)withEvent: (Event *)ourEvent
{
	Timer *timer = [[Timer alloc] init];
	timer.title = ourEvent.title;
	timer.tdescription = ourEvent.sdescription;
	timer.begin = ourEvent.begin;
	timer.end = ourEvent.end;
	timer.eit = ourEvent.eit;
	timer.disabled = NO;
	timer.justplay = NO;
	timer.service = [[Service alloc] init];
	timer.repeated = 0;
	timer.repeatcount = 0;
	timer.state = 0;
	timer.afterevent = 0;

	return timer;
}

+ (Timer *)withEventAndService: (Event *)ourEvent: (Service *)ourService
{
	Timer *timer = [[Timer alloc] init];
	timer.title = ourEvent.title;
	timer.tdescription = ourEvent.sdescription;
	timer.begin = ourEvent.begin;
	timer.end = ourEvent.end;
	timer.eit = ourEvent.eit;
	timer.disabled = NO;
	timer.justplay = NO;
	timer.service = ourService;
	timer.repeated = 0;
	timer.repeatcount = 0;
	timer.state = 0;

	return timer;
}

+ (Timer *)timer
{
	Timer *timer = [[Timer alloc] init];
	timer.begin = [NSDate date];
	timer.end = [timer.begin addTimeInterval: (NSTimeInterval)3600];
	timer.eit = @"-1";
	timer.title = @"";
	timer.tdescription = @"";
	timer.disabled = NO;
	timer.justplay = NO;
	timer.service = [[Service alloc] init];
	timer.repeated = 0;
	timer.repeatcount = 0;
	timer.state = 0;

	return timer;
}

- (id)init
{
	if (self = [super init])
	{
		_duration = -1;
	}
	return self;
}

- (id)initWithTimer:(Timer *)timer
{
	self = [super init];
	
	if (self) {
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
		_duration = -1;
	}

	return self;
}

- (void)dealloc
{
	[_begin release];
	[_end release];
	[_eit release];
	[_title release];
	[_tdescription release];
	[_service release];
	[_sname release];
	[_sref release];

	[super dealloc];
}

#pragma mark -
#pragma mark	Copy
#pragma mark -

- (id)copyWithZone:(NSZone *)zone
{
	id newElement = [[[self class] alloc] initWithTimer: self];

	return newElement;
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"<%@> Title: '%@'.\n Eit: '%@'.\n", [self class], self.title, self.eit];
}

- (NSString *)getStateString
{
	return [[NSString stringWithFormat: @"%d", _state] autorelease];
}

- (NSInteger)getEnigmaAfterEvent
{
	if(_afterevent == kAfterEventStandby)
		return doGoSleep;
	else if(_afterevent == kAfterEventDeepstandby)
		return doShutdown;
	else // _afterevent == kAfterEventNothing or unhandled
		return 0;
}

- (void)setBeginFromString: (NSString *)newBegin
{
	[_begin release];
	_begin = [[NSDate dateWithTimeIntervalSince1970: [newBegin doubleValue]] retain];
	if(_duration != -1){
		[_end release];
		_end = [[_begin addTimeInterval: _duration] retain];
		_duration = -1;
	}
}

- (void)setEndFromString: (NSString *)newEnd
{
	[_end release];
	_end = [[NSDate dateWithTimeIntervalSince1970: [newEnd doubleValue]] retain];
}

- (void)setEndFromDurationString: (NSString *)newDuration
{
	if(_begin == nil) {
		_duration = [newDuration doubleValue];
		return;
	}
	[_end release];
	_end = [[_begin addTimeInterval: [newDuration doubleValue]] retain];
}

- (void)setSref: (NSString *)newSref
{
	if(_sname)
	{
		[_service release];
		_service = [[Service alloc] init];
		_service.sref = newSref;
		_service.sname = _sname;

		[_sname release];
		_sname = nil;
	}
	else
	{
		[_sref release];
		_sref = [newSref retain];
	}
}

- (void)setSname: (NSString *)newSname
{
	if(_sref)
	{
		[_service release];
		_service = [[Service alloc] init];
		_service.sref = _sref;
		_service.sname = newSname;

		[_sref release];
		_sref = nil;
	}
	else
	{
		[_sname release];
		_sname = [newSname retain];
	}
}

@end
