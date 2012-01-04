//
//  Timer.m
//  dreaMote
//
//  Created by Moritz Venn on 09.03.08.
//  Copyright 2008-2011 Moritz Venn. All rights reserved.
//

#import "Timer.h"

#import "RemoteConnectorObject.h"
#import <Objects/Generic/Service.h>

@implementation GenericTimer

@synthesize eit, begin, end, tags, title, tdescription, disabled, repeated, repeatcount, justplay, service, sref, sname, state, afterevent, location, valid, timeString, vpsplugin_enabled, vpsplugin_overwrite, vpsplugin_time;

+ (NSObject<TimerProtocol> *)withEvent: (NSObject<EventProtocol> *)ourEvent
{
	NSObject<ServiceProtocol> *newService = [[GenericService alloc] init];
	NSObject<TimerProtocol> *timer = [GenericTimer withEventAndService:ourEvent :newService];

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

	return timer;
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
	timer.repeated = 0;
	timer.repeatcount = 0;
	timer.state = 0;

	// use "auto" by default if backend supports it
	if([[RemoteConnectorObject sharedRemoteConnector] hasFeature:kFeaturesTimerAfterEventAuto])
		timer.afterevent = kAfterEventAuto;
	else
		timer.afterevent = kAfterEventNothing;

	return timer;
}

- (id)init
{
	if((self = [super init]))
	{
		_duration = -1;
		valid = YES;
		vpsplugin_time = -1; // "none"
	}
	return self;
}

- (id)initWithTimer:(NSObject<TimerProtocol> *)timer
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
		_duration = -1;
		valid = timer.valid;
		afterevent = timer.afterevent;
		location = [timer.location copy];
		vpsplugin_enabled = timer.vpsplugin_enabled;
		vpsplugin_overwrite = timer.vpsplugin_overwrite;
		vpsplugin_time = timer.vpsplugin_time;
	}

	return self;
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"<%@> Title: '%@'.\n Eit: '%@'.\n", [self class], self.title, self.eit];
}

- (NSString *)getStateString
{
	return [NSString stringWithFormat:@"%d", state];
}

- (void)setBeginFromString: (NSString *)newBegin
{
	self.timeString = nil;

	self.begin = [NSDate dateWithTimeIntervalSince1970:[newBegin doubleValue]];
	if(_duration != -1){
		self.end = [begin dateByAddingTimeInterval:_duration];
		_duration = -1;
	}
}

- (void)setEndFromString: (NSString *)newEnd
{
	self.timeString = nil;
	self.end = [NSDate dateWithTimeIntervalSince1970:[newEnd doubleValue]];
}

- (void)setEndFromDurationString: (NSString *)newDuration
{
	self.timeString = nil;

	if(begin == nil) {
		_duration = [newDuration doubleValue];
		return;
	}
	self.end = [begin dateByAddingTimeInterval:[newDuration doubleValue]];
}

- (void)setSref: (NSString *)newSref
{
	if(sname)
	{
		self.service = [[GenericService alloc] init];
		service.sref = newSref;
		service.sname = sname;

		self.sname = nil;
	}
	else
	{
		self.sref = newSref;
	}
}

- (NSString *)sref
{
	if(sref)
		return sref;
	return service.sref;
}

- (void)setSname: (NSString *)newSname
{
	if(sref)
	{
		self.service = [[GenericService alloc] init];
		service.sref = sref;
		service.sname = newSname;

		self.sref = nil;
	}
	else
	{
		self.sname = newSname;
	}
}

- (NSString *)sname
{
	if(sname)
		return sname;
	return service.sname;
}

- (void)setTagsFromString: (NSString *)newTags
{
	if([newTags isEqualToString: @""])
		self.tags = [NSArray array];
	else
		self.tags = [newTags componentsSeparatedByString:@" "];
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
