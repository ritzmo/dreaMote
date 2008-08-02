//
//  Timer.m
//  Untitled
//
//  Created by Moritz Venn on 09.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "Timer.h"

@implementation Timer

@synthesize eit = _eit;
@synthesize begin = _begin;
@synthesize end = _end;
@synthesize title = _title;
@synthesize tdescription = _tdescription;
@synthesize disabled = _disabled;
@synthesize repeated = _repeated;
@synthesize justplay = _justplay;
@synthesize service = _service;
@synthesize sref = _sref;
@synthesize state = _state;

+ (Timer *)withEvent: (Event *)ourEvent
{
	Timer *timer = [[Timer alloc] init];
	timer.title = [[ourEvent title] retain];
	timer.tdescription = [[ourEvent sdescription] retain];
	timer.begin = [[ourEvent begin] retain];
	timer.end = [[ourEvent end] retain];
	timer.eit = [[ourEvent eit] retain];
	timer.disabled = NO;
	timer.justplay = NO;
	timer.service = [[Service alloc] init];
	timer.repeated = 0;
	timer.state = 0;

	return timer;
}

+ (Timer *)withEventAndService: (Event *)ourEvent: (Service *)ourService
{
	Timer *timer = [[Timer alloc] init];
	timer.title = [[ourEvent title] retain];
	timer.tdescription = [[ourEvent sdescription] retain];
	timer.begin = [[ourEvent begin] retain];
	timer.end = [[ourEvent end] retain];
	timer.eit = [[ourEvent eit] retain];
	timer.disabled = NO;
	timer.justplay = NO;
	timer.service = [ourService retain];
	timer.repeated = 0;
	timer.state = 0;

	return timer;
}

+ (Timer *)new
{
	Timer *timer = [[Timer alloc] init];
	timer.begin = [NSDate date];
	timer.end = [timer.begin addTimeInterval: (double)3600];
	timer.eit = @"-1";
	timer.title = @"";
	timer.tdescription = @"";
	timer.disabled = NO;
	timer.justplay = NO;
	timer.service = [[Service alloc] init];
	timer.repeated = 0;
	timer.state = 0;

	return timer;
}

- (id)initWithTimer:(Timer *)timer
{
	self = [super init];
	
	if (self) {
		self.begin = [[timer begin] copy];
		self.end = [[timer end] copy];
		self.eit = [[timer eit] copy];
		self.title = [[timer title] copy];
		self.tdescription = [[timer tdescription] copy];
		self.disabled = [timer disabled];
		self.justplay = [timer justplay];
		self.service = [[timer service] copy];
		self.repeated = timer.repeated;
		self.state = timer.state;
	}

	return self;
}

#pragma mark -
#pragma mark	Copy
#pragma mark -

- (id)copyWithZone:(NSZone *)zone
{
	id newElement = [[[self class] alloc] initWithTimer:self];

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

- (void)setBeginFromString: (NSString *)newBegin
{
	[_begin release];
	_begin = [[NSDate dateWithTimeIntervalSince1970: [newBegin doubleValue]] retain];
}

- (void)setEndFromString: (NSString *)newEnd
{
	[_end release];
	_end = [[NSDate dateWithTimeIntervalSince1970: [newEnd doubleValue]] retain];
}

- (void)setDisabledFromString: (NSString *)newDisabled
{
	_disabled = [newDisabled isEqualToString: @"1"];
}

- (void)setJustplayFromString: (NSString *)newJustplay
{
	_justplay = [newJustplay isEqualToString: @"1"];
}

- (void)setRepeatedFromString: (NSString *)newRepeated
{
	_repeated = [newRepeated intValue];
}

- (void)setServiceFromSname: (NSString *)newSname
{
	[_service release];
	_service = [[Service alloc] init];
	_service.sref = _sref;
	_service.sname = newSname;
}

- (void)setStateFromString: (NSString *)newState
{
	_state = [newState intValue];
}

@end
