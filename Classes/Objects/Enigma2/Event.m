//
//  Event.m
//  dreaMote
//
//  Created by Moritz Venn on 31.12.08.
//  Copyright 2008-2011 Moritz Venn. All rights reserved.
//

#import "Event.h"

#import "Service.h"
#import "../Generic/Event.h"

#import "CXMLElement.h"

@implementation Enigma2Event

@synthesize timeString = _timeString;

- (NSObject<ServiceProtocol> *)service
{
	if(_service == nil)
		_service = [[Enigma2Service alloc] initWithNode:_node];
	return _service;
}

- (void)setService: (NSObject<ServiceProtocol> *)service
{
	return;
}

- (NSString *)edescription
{
	const NSArray *resultNodes = [_node nodesForXPath:@"e2eventdescriptionextended" error:nil];
	for(CXMLElement *resultElement in resultNodes)
	{
		return [resultElement stringValue];
		break;
	}
	return nil;
}

- (void)setEdescription: (NSString *)new
{
#if IS_DEBUG()
	[NSException raise:@"ExcUnsupportedFunction" format:@""];
#endif
}

- (NSString *)sdescription
{
	const NSArray *resultNodes = [_node nodesForXPath:@"e2eventdescription" error:nil];
	for(CXMLElement *resultElement in resultNodes)
	{
		return [resultElement stringValue];
		break;
	}
	return nil;
}

- (void)setSdescription: (NSString *)new
{
#if IS_DEBUG()
	[NSException raise:@"ExcUnsupportedFunction" format:@""];
#endif
}

- (NSString *)title
{
	NSArray *resultNodes = [_node nodesForXPath:@"e2eventtitle" error:nil];
	for(CXMLElement *resultElement in resultNodes)
	{
		NSString *title = [resultElement stringValue];
		if([title isEqualToString:@"None"])
			return nil;
		return title;
	}
	// NOTE: Workaround for old WebInterface
	// FIXME: remove after some time, but we should at least wait for the "major images" to ship a more recent WebInterface...
	resultNodes = [_node nodesForXPath:@"e2eventname" error:nil];
	for(CXMLElement *resultElement in resultNodes)
	{
		NSString *title = [resultElement stringValue];
		if([title isEqualToString:@"None"])
			return nil;
		return title;
	}
	return nil;
}

- (void)setTitle: (NSString *)new
{
#if IS_DEBUG()
	[NSException raise:@"ExcUnsupportedFunction" format:@""];
#endif
}

- (NSDate *)end
{
	if(_end == nil)
	{
		const NSArray *resultNodes = [_node nodesForXPath:@"e2eventduration" error:nil];
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
	[_end release];
	_end = [new retain];
}

- (NSDate *)begin
{
	if(_begin == nil)
	{
		const NSArray *resultNodes = [_node nodesForXPath:@"e2eventstart" error:nil];
		for(CXMLElement *resultElement in resultNodes)
		{
			double begin = [[resultElement stringValue] doubleValue];
			[_timeString release];
			_timeString = nil;
			if(begin)
				_begin = [[NSDate dateWithTimeIntervalSince1970: [[resultElement stringValue] doubleValue]] retain];
			break;
		}
	}
	return _begin;
}

- (void)setBegin: (NSDate *)new
{
	if(_begin == new)
		return;
	[_begin release];
	_begin = [new retain];
}

- (NSString *)eit
{
	const NSArray *resultNodes = [_node nodesForXPath:@"e2eventid" error:nil];
	for(CXMLElement *resultElement in resultNodes)
	{
		return [resultElement stringValue];
	}
	return nil;
}

- (void)setEit: (NSString *)new
{
#if IS_DEBUG()
	[NSException raise:@"ExcUnsupportedFunction" format:@""];
#endif
}

- (BOOL)isValid
{
	return _node != nil;
}

- (id)initWithNode: (CXMLNode *)node
{
	if((self = [super init]))
	{
		_begin = nil;
		_end = nil;
		_node = [node retain];
	}
	return self;
}

- (void)dealloc
{
	[_begin release];
	[_end release];
	[_node release];
	[_timeString release];
	[_service release];

	[super dealloc];
}

- (NSString *)description
{
	// NOTE: because we don't cache values this might lag a little...
	return [NSString stringWithFormat:@"<%@> Title: '%@'.\n Eit: '%@'.\n", [self class], self.title, self.eit];
}

- (void)setBeginFromString: (NSString *)newBegin
{
#if IS_DEBUG()
	[NSException raise:@"ExcUnsupportedFunction" format:@""];
#endif
}

- (void)setEndFromDurationString: (NSString *)newDuration
{
	[_timeString release];
	_timeString = nil;

	// no begin, die quietly
	if(self.begin == nil)
	{
		_end = nil;
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
		[self.end isEqualToDate: otherEvent.end] &&
		[self.service isEqualToService: otherEvent.service];
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
	id newElement = [[GenericEvent alloc] initWithEvent: self];

	return newElement;
}

@end
