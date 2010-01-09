//
//  Event.m
//  dreaMote
//
//  Created by Moritz Venn on 09.03.08.
//  Copyright 2008-2010 Moritz Venn. All rights reserved.
//

#import "Event.h"

@implementation GenericEvent

@synthesize eit = _eit;
@synthesize begin = _begin;
@synthesize end = _end;
@synthesize title = _title;
@synthesize sdescription = _sdescription;
@synthesize edescription = _edescription;
@synthesize timeString = _timeString;

- (NSObject<ServiceProtocol> *)service
{
	[NSException raise:@"ExcUnsupportedFunction" format:nil];
	return nil;
}

- (void)setService: (NSObject<ServiceProtocol> *)service
{
	[NSException raise:@"ExcUnsupportedFunction" format:nil];
}

- (id)init
{
	if (self = [super init])
	{
		_duration = -1;
		_begin = nil;
		_end = nil;
		_timeString = nil;
	}
	return self;
}

- (void)dealloc
{
	[_eit release];
	[_begin release];
	[_end release];
	[_title release];
	[_sdescription release];
	[_edescription release];
	[_timeString release];

	[super dealloc];
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"<%@> Title: '%@'.\n Eit: '%@'.\n", [self class], self.title, self.eit];
}

- (void)setBeginFromString: (NSString *)newBegin
{
	[_timeString release];
	_timeString = nil;

	[_begin release];
	_begin = [[NSDate dateWithTimeIntervalSince1970: [newBegin doubleValue]] retain];
	if(_duration != -1){
		[_end release];
		_end = [[_begin addTimeInterval: _duration] retain];
		_duration = -1;
	}
}

- (void)setEndFromDurationString: (NSString *)newDuration
{
	[_timeString release];
	_timeString = nil;

	if(_begin == nil) {
		_duration = [newDuration doubleValue];
		return;
	}
	[_end release];
	_end = [[_begin addTimeInterval: [newDuration doubleValue]] retain];
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

@end
