//
//  Event.m
//  dreaMote
//
//  Created by Moritz Venn on 31.12.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "Event.h"
#import "../Generic/Service.h"

#import "CXMLElement.h"

@implementation Enigma2Event

@synthesize timeString = _timeString;

- (NSObject<ServiceProtocol> *)service
{
	NSObject<ServiceProtocol> *service = nil;
	NSArray *resultNodes = nil;
	NSString *sname = nil;
	NSString *sref = nil;

	resultNodes = [_node nodesForXPath:@"e2eventservicename" error:nil];
	for(CXMLElement *currentChild in resultNodes)
	{
		sname = [[currentChild stringValue] retain];
		break;
	}

	resultNodes = [_node nodesForXPath:@"e2eventservicereference" error:nil];
	for(CXMLElement *currentChild in resultNodes)
	{
		sref = [[currentChild stringValue] retain];
		break;
	}

	if(sname && sref)
	{
		service = [[[GenericService alloc] init] autorelease];
		service.sname = sname;
		service.sref = sref;
	}
	[sname release];
	[sref release];

	return service;
}

- (void)setService: (NSObject<ServiceProtocol> *)service
{
	[NSException raise:@"ExcUnsupportedFunction" format:nil];
}

- (NSString *)edescription
{
	NSArray *resultNodes = [_node nodesForXPath:@"e2eventdescriptionextended" error:nil];
	for(CXMLElement *resultElement in resultNodes)
	{
		return [resultElement stringValue];
		break;
	}
	return nil;
}

- (void)setEdescription: (NSString *)new
{
	[NSException raise:@"ExcUnsupportedFunction" format:nil];
}

- (NSString *)sdescription
{
	NSArray *resultNodes = [_node nodesForXPath:@"e2eventdescription" error:nil];
	for(CXMLElement *resultElement in resultNodes)
	{
		return [resultElement stringValue];
		break;
	}
	return nil;
}

- (void)setSdescription: (NSString *)new
{
	[NSException raise:@"ExcUnsupportedFunction" format:nil];
}

- (NSString *)title
{
	NSArray *resultNodes = [_node nodesForXPath:@"e2eventtitle" error:nil];
	for(CXMLElement *resultElement in resultNodes)
	{
		return [resultElement stringValue];
	}
	return nil;
}

- (void)setTitle: (NSString *)new
{
	[NSException raise:@"ExcUnsupportedFunction" format:nil];
}

- (NSDate *)end
{
	if(_end == nil)
	{
		NSArray *resultNodes = [_node nodesForXPath:@"e2eventduration" error:nil];
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
		NSArray *resultNodes = [_node nodesForXPath:@"e2eventstart" error:nil];
		for(CXMLElement *resultElement in resultNodes)
		{
			[_timeString release];
			_timeString = nil;
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
	NSArray *resultNodes = [_node nodesForXPath:@"e2eventid" error:nil];
	for(CXMLElement *resultElement in resultNodes)
	{
		return [resultElement stringValue];
	}
	return nil;
}

- (void)setEit: (NSString *)new
{
	[NSException raise:@"ExcUnsupportedFunction" format:nil];
}

- (id)initWithNode: (CXMLNode *)node
{
	if (self = [super init])
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

	[super dealloc];
}

- (NSString *)description
{
	// XXX: because we don't cache values this might lag a little...
	return [NSString stringWithFormat:@"<%@> Title: '%@'.\n Eit: '%@'.\n", [self class], self.title, self.eit];
}

- (void)setBeginFromString: (NSString *)newBegin
{
	[NSException raise:@"ExcUnsupportedFunction" format:nil];
}

- (void)setEndFromDurationString: (NSString *)newDuration
{
	[_timeString release];
	_timeString = nil;

	if(self.begin == nil)
		[NSException raise:@"ExcBeginNull" format:nil];

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

@end
