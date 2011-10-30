//
//  Timer.m
//  dreaMote
//
//  Created by Moritz Venn on 09.03.08.
//  Copyright 2008-2011 Moritz Venn. All rights reserved.
//

#import "Timer.h"

#import "RemoteConnectorObject.h"
#import "Service.h"

@implementation GenericTimer

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
@synthesize location = _location;
@synthesize valid = _isValid;
@synthesize timeString = _timeString;

+ (NSObject<TimerProtocol> *)withEvent: (NSObject<EventProtocol> *)ourEvent
{
	NSObject<ServiceProtocol> *newService = [[GenericService alloc] init];
	NSObject<TimerProtocol> *timer = [GenericTimer withEventAndService:ourEvent :newService];
	[newService release];

	return timer;
}

+ (NSObject<TimerProtocol> *)withEventAndService: (NSObject<EventProtocol> *)ourEvent: (NSObject<ServiceProtocol> *)ourService
{
	NSObject<TimerProtocol> *timer = [[GenericTimer alloc] init];
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

	// use "auto" by default if backend supports it
	if([[RemoteConnectorObject sharedRemoteConnector] hasFeature:kFeaturesTimerAfterEventAuto])
		timer.afterevent = kAfterEventAuto;
	else
		timer.afterevent = kAfterEventNothing;

	return [timer autorelease];
}

+ (NSObject<TimerProtocol> *)timer
{
	NSObject<TimerProtocol> *timer = [[GenericTimer alloc] init];
	timer.begin = [NSDate date];
	timer.end = [timer.begin dateByAddingTimeInterval:(NSTimeInterval)3600];
	timer.eit = nil;
	timer.title = @"";
	timer.tdescription = @"";
	timer.disabled = NO;
	timer.justplay = NO;
	NSObject<ServiceProtocol> *newService = [[GenericService alloc] init];
	timer.service = newService;
	[newService release];
	timer.repeated = 0;
	timer.repeatcount = 0;
	timer.state = 0;

	// use "auto" by default if backend supports it
	if([[RemoteConnectorObject sharedRemoteConnector] hasFeature:kFeaturesTimerAfterEventAuto])
		timer.afterevent = kAfterEventAuto;
	else
		timer.afterevent = kAfterEventNothing;

	return [timer autorelease];
}

- (id)init
{
	if((self = [super init]))
	{
		_duration = -1;
		_service = nil;
		_isValid = YES;
		_timeString = nil;
	}
	return self;
}

- (id)initWithTimer:(NSObject<TimerProtocol> *)timer
{
	if((self = [super init]))
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
		_duration = -1;
		_isValid = timer.valid;
		_afterevent = timer.afterevent;
		_location = [timer.location copy];
	}

	return self;
}

- (void)dealloc
{
	[_begin release];
	[_eit release];
	[_end release];
	[_location release];
	[_service release];
	[_sname release];
	[_sref release];
	[_title release];
	[_timeString release];
	[_tdescription release];

	[super dealloc];
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"<%@> Title: '%@'.\n Eit: '%@'.\n", [self class], self.title, self.eit];
}

- (NSString *)getStateString
{
	return [NSString stringWithFormat: @"%d", _state];
}

- (void)setBeginFromString: (NSString *)newBegin
{
	SafeRetainAssign(_timeString, nil);

	SafeRetainAssign(_begin, [NSDate dateWithTimeIntervalSince1970:[newBegin doubleValue]]);
	if(_duration != -1){
		SafeRetainAssign(_end, [_begin dateByAddingTimeInterval:_duration]);
		_duration = -1;
	}
}

- (void)setEndFromString: (NSString *)newEnd
{
	SafeRetainAssign(_timeString, nil);
	SafeRetainAssign(_end, [NSDate dateWithTimeIntervalSince1970:[newEnd doubleValue]]);
}

- (void)setEndFromDurationString: (NSString *)newDuration
{
	SafeRetainAssign(_timeString, nil);

	if(_begin == nil) {
		_duration = [newDuration doubleValue];
		return;
	}
	SafeRetainAssign(_end, [_begin dateByAddingTimeInterval:[newDuration doubleValue]]);
}

- (void)setSref: (NSString *)newSref
{
	if(_sname)
	{
		[_service release];
		_service = [[GenericService alloc] init];
		_service.sref = newSref;
		_service.sname = _sname;

		SafeRetainAssign(_sname, nil);
	}
	else
	{
		SafeRetainAssign(_sref, newSref);
	}
}

- (void)setSname: (NSString *)newSname
{
	if(_sref)
	{
		[_service release];
		_service = [[GenericService alloc] init];
		_service.sref = _sref;
		_service.sname = newSname;

		SafeRetainAssign(_sref, nil);
	}
	else
	{
		SafeRetainAssign(_sname, newSname);
	}
}

- (BOOL)isEqualToEvent:(NSObject <EventProtocol>*)event
{
	// service is taken care of in TimerViewController
	if(self.repeated) return NO;
	if(self.disabled) return NO;
	if(![self.title isEqualToString:event.title]) return NO;
	if(![self.tdescription isEqualToString:event.sdescription]) return NO;
	if(![self.begin isEqualToDate:event.begin]) return NO;
	if(![self.end isEqualToDate:event.end]) return NO;
	if([[RemoteConnectorObject sharedRemoteConnector] hasFeature:kFeaturesTimerAfterEventAuto])
	{
		if(self.afterevent != kAfterEventAuto)
			return NO;
	}
	else
	{
		if(self.afterevent != kAfterEventNothing)
			return NO;
	}
	return YES;
}

#pragma mark -
#pragma mark	Copy
#pragma mark -

- (id)copyWithZone:(NSZone *)zone
{
	id newElement = [[[self class] alloc] initWithTimer: self];

	return newElement;
}

@end
