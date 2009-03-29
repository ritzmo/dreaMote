//
//  Event.m
//  dreaMote
//
//  Created by Moritz Venn on 09.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "Event.h"

@implementation Event

@synthesize eit = _eit;
@synthesize begin = _begin;
@synthesize end = _end;
@synthesize title = _title;
@synthesize sdescription = _sdescription;
@synthesize edescription = _edescription;
@synthesize timeString;

- (NSObject<ServiceProtocol> *)service
{
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
		timeString = nil;
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
	[timeString release];

	[super dealloc];
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"<%@> Title: '%@'.\n Eit: '%@'.\n", [self class], self.title, self.eit];
}

- (void)setBeginFromString: (NSString *)newBegin
{
	[timeString release];
	timeString = nil;

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
	[timeString release];
	timeString = nil;

	if(_begin == nil) {
		_duration = [newDuration doubleValue];
		return;
	}
	[_end release];
	_end = [[_begin addTimeInterval: [newDuration doubleValue]] retain];
}

@end
