//
//  Event.m
//  dreaMote
//
//  Created by Moritz Venn on 09.03.08.
//  Copyright 2008-2011 Moritz Venn. All rights reserved.
//

#import "Event.h"

#import "ServiceProtocol.h"

@implementation GenericEvent

@synthesize service = _service;
@synthesize eit = _eit;
@synthesize begin = _begin;
@synthesize end = _end;
@synthesize title = _title;
@synthesize sdescription = _sdescription;
@synthesize edescription = _edescription;
@synthesize timeString = _timeString;

- (BOOL)isValid
{
	return _service || (_begin && _end);
}

- (id)init
{
	if((self = [super init]))
	{
		_duration = -1;
		_begin = nil;
		_end = nil;
		_timeString = nil;
	}
	return self;
}

- (id)initWithEvent:(NSObject <EventProtocol>*)event
{
	if((self = [super init]))
	{
		// don't try to copy service, only one backend knows it anyway
		_eit = [event.eit copy];
		_begin = [event.begin copy];
		_end = [event.end copy];
		_title = [event.title copy];
		_sdescription = [event.sdescription copy];
		_edescription = [event.edescription copy];
	}
	return self;
}


- (NSString *)description
{
	return [NSString stringWithFormat:@"<%@> Title: '%@'.\n Eit: '%@'.\n", [self class], self.title, self.eit];
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

- (void)setEndFromDurationString: (NSString *)newDuration
{
	SafeRetainAssign(_timeString, nil);

	if(_begin == nil) {
		_duration = [newDuration doubleValue];
		return;
	}
	SafeRetainAssign(_end, [_begin dateByAddingTimeInterval:[newDuration doubleValue]]);
}

- (BOOL)isEqualToEvent: (NSObject<EventProtocol> *)otherEvent
{
	return [self.eit isEqualToString: otherEvent.eit] &&
	[self.title isEqualToString: otherEvent.title] &&
	[self.sdescription isEqualToString: otherEvent.sdescription] &&
	[self.edescription isEqualToString: otherEvent.edescription] &&
	[self.begin isEqualToDate: otherEvent.begin] &&
	[self.end isEqualToDate: otherEvent.end];
}

- (NSComparisonResult)compare: (NSObject<EventProtocol> *)otherEvent
{
	return [otherEvent.begin compare: self.begin];
}


#pragma mark -
#pragma mark	Copy
#pragma mark -

- (id)copyWithZone:(NSZone *)zone
{
	id newElement = [[[self class] alloc] initWithEvent: self];

	return newElement;
}

@end
