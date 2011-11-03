//
//  Timer.m
//  dreaMote
//
//  Created by Moritz Venn on 01.01.09.
//  Copyright 2008-2011 Moritz Venn. All rights reserved.
//

#import "Timer.h"

#import "CXMLElement.h"

#import "EventProtocol.h"
#import "../Generic/Service.h"

@implementation EnigmaTimer

@synthesize valid = _isValid;
@synthesize timeString = _timeString;

- (NSInteger)repeatcount
{
	return 0;
}

- (void)setRepeatcount: (NSInteger)new
{
	return;
}

- (NSString *)tdescription
{
	return nil;
}

- (void)setTdescription: (NSString *)new
{
	return;
}

- (NSString *)title
{
	if(_title == nil)
	{
		const NSArray *resultNodes = [_node nodesForXPath:@"event/description" error:nil];
		for(CXMLElement *resultElement in resultNodes)
		{
			self.title = [resultElement stringValue];
			break;
		}
	}
	return _title;
}

- (void)setTitle: (NSString *)new
{
	if(_title == new)
		return;
	SafeRetainAssign(_title, new);
}

- (NSString *)location
{
	return nil;
}

- (void)setLocation:(NSString *)new
{
	// IGNORE
}

- (NSObject<ServiceProtocol> *)service
{
	if(_service == nil)
	{
		NSArray *resultNodes = nil;
		NSString *sname = nil;
		NSString *sref = nil;

		resultNodes = [_node nodesForXPath:@"service/name" error:nil];
		for(CXMLElement *resultElement in resultNodes)
		{
			sname = [resultElement stringValue];
			break;
		}

		resultNodes = [_node nodesForXPath:@"service/reference" error:nil];
		for(CXMLElement *resultElement in resultNodes)
		{
			sref = [resultElement stringValue];
			break;
		}
		
		if(sname && sref)
		{
			_service = [[GenericService alloc] init];
			_service.sname = sname;
			_service.sref = sref;
		}
	}
	return _service;
}

- (void)setService: (NSObject<ServiceProtocol> *)new
{
	if(_service == new)
		return;
	SafeRetainAssign(_service, new);
}

- (NSString *)sname
{
	return nil;
}

- (NSString *)sref
{
	return nil;
}

- (NSDate *)end
{
	if(_end == nil)
	{
		const NSArray *resultNodes = [_node nodesForXPath:@"event/duration" error:nil];
		for(CXMLElement *resultElement in resultNodes)
		{
			[self setEndFromDurationString: [resultElement stringValue]];
			break;
		}
	}
	return _end;
}

- (void)setEnd: (NSDate *)new
{
	if(_end == new)
		return;
	SafeRetainAssign(_end, new);
}

- (NSDate *)begin
{
	if(_begin == nil)
	{
		const NSArray *resultNodes = [_node nodesForXPath:@"event/start" error:nil];
		for(CXMLElement *resultElement in resultNodes)
		{
			[self setBeginFromString: [resultElement stringValue]];
			break;
		}
	}
	return _begin;
}

- (void)setBegin: (NSDate *)new
{
	if(_begin == new)
		return;
	SafeRetainAssign(_begin, new);
}

- (NSString *)eit
{
	return nil;
}

- (void)setEit: (NSString *)new
{
	return;
}

- (BOOL)disabled
{
	return NO;
}

- (void)setDisabled: (BOOL)new
{
	return;
}

- (BOOL)justplay
{
	if(!_typedataSet)
	{
		[self getTypedata];
	}
	return _justplay;
}

- (void)setJustplay: (BOOL)new
{
	_justplay = new;
}

- (NSInteger)repeated
{
	if(!_typedataSet)
	{
		[self getTypedata];
	}

	return _repeated;
}

- (void)setRepeated: (NSInteger)new
{
	_repeated = new;
}

- (NSInteger)afterevent
{
	if(!_typedataSet)
	{
		[self getTypedata];
	}
	return _afterevent;
}

- (void)setAfterevent: (NSInteger)new
{
	_afterevent = new;
}

- (NSInteger)state
{
	if(!_typedataSet)
	{
		[self getTypedata];
	}
	return _state;
}

- (void)setState: (NSInteger)new
{
	_state = new;
}

- (id)init
{
	if((self = [super init]))
	{
		_duration = -1;
		_service = nil;
		_isValid = YES;
		_timeString = nil;
		_repeated = 0;

		_typedataSet = NO;
	}
	return self;
}

- (id)initWithNode: (CXMLNode *)node
{
	if((self = [self init]))
	{
		_node = node;
	}
	return self;
}

- (id)initWithTimer:(NSObject<TimerProtocol> *)timer
{
	if((self = [super init]))
	{
		_typedataSet = YES;

		_begin = [timer.begin copy];
		_end = [timer.end copy];
		_title = [timer.title copy];
		_justplay = timer.justplay;
		_service = [timer.service copy];
		_state = timer.state;
		_duration = -1;
		_isValid = timer.valid;
		_afterevent = timer.afterevent;

		// NOTE: we don't copy the node...
		// by accessing the properties we can be sure to have all the values though :P
	}

	return self;
}


- (BOOL)isEqualToEvent:(NSObject <EventProtocol>*)event
{
	return NO;
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

	SafeRetainAssign(_begin, [NSDate dateWithTimeIntervalSince1970: [newBegin doubleValue]]);
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
	return;
}

- (void)setSname: (NSString *)newSname
{
	return;
}

- (NSInteger)getTypedata
{
	const NSArray *resultNodes = [_node nodesForXPath:@"typedata" error:nil];
	for(CXMLElement *currentChild in resultNodes)
	{
		const NSInteger typeData = [[currentChild stringValue] integerValue];
		
		// We translate to Enigma2 States here
		if(typeData & stateRunning)
			_state = kTimerStateRunning;
		else if(typeData & stateFinished)
			_state = kTimerStateFinished;
		else // stateWaiting or unknown
			_state =  kTimerStateWaiting;

		if(typeData & doGoSleep)
			_afterevent = kAfterEventStandby;
		else if(typeData & doShutdown)
			_afterevent = kAfterEventDeepstandby;
		else
			_afterevent = kAfterEventNothing;

		if(typeData & SwitchTimerEntry)
			_justplay = YES;
		else // We assume RecTimerEntry here
			_justplay = NO;

		if(typeData & isRepeating)
		{
			if(typeData & Su)
				_repeated |= weekdaySun;
			if(typeData & Mo)
				_repeated |= weekdayMon;
			if(typeData & Tue)
				_repeated |= weekdayTue;
			if(typeData & Wed)
				_repeated |= weekdayWed;
			if(typeData & Thu)
				_repeated |= weekdayThu;
			if(typeData & Fr)
				_repeated |= weekdayFri;
			if(typeData & Sa)
				_repeated |= weekdaySat;
		}
		else
			_repeated = 0;

		_typedataSet = YES;
		return typeData;
	}
	return 0;
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
