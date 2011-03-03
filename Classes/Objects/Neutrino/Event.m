//
//  Event.m
//  dreaMote
//
//  Created by Moritz Venn on 01.01.09.
//  Copyright 2008-2011 Moritz Venn. All rights reserved.
//

#import "Event.h"

#import "CXMLElement.h"
#import "../Generic/Event.h"

@implementation NeutrinoEvent

@synthesize timeString = _timeString;

- (NSObject<ServiceProtocol> *)service
{
	return nil;
}

- (void)setService: (NSObject<ServiceProtocol> *)service
{
	return;
}

- (NSString *)edescription
{
	const NSArray *resultNodes = [_node nodesForXPath:@"info2" error:nil];
	for(CXMLElement *resultElement in resultNodes)
	{
		return [resultElement stringValue];
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
	const NSArray *resultNodes = [_node nodesForXPath:@"info1" error:nil];
	for(CXMLElement *resultElement in resultNodes)
	{
		return [resultElement stringValue];
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
	const NSArray *resultNodes = [_node nodesForXPath:@"description" error:nil];
	for(CXMLElement *resultElement in resultNodes)
	{
		return [resultElement stringValue];
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
	const NSArray *resultNodes = [_node nodesForXPath:@"stop_sec" error:nil];
	for(CXMLElement *resultElement in resultNodes)
	{
		return [NSDate dateWithTimeIntervalSince1970: [[resultElement stringValue] doubleValue]];
	}
	return nil;
}

- (void)setEnd: (NSDate *)new
{
#if IS_DEBUG()
	[NSException raise:@"ExcUnsupportedFunction" format:@""];
#endif
}

- (NSDate *)begin
{
	const NSArray *resultNodes = [_node nodesForXPath:@"start_sec" error:nil];
	for(CXMLElement *resultElement in resultNodes)
	{
			return [NSDate dateWithTimeIntervalSince1970: [[resultElement stringValue] doubleValue]];
	}
	return nil;
}

- (void)setBegin: (NSDate *)new
{
#if IS_DEBUG()
	[NSException raise:@"ExcUnsupportedFunction" format:@""];
#endif
}

- (NSString *)eit
{
	const NSArray *resultNodes = [_node nodesForXPath:@"eventid" error:nil];
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
		_node = [node retain];
	}
	return self;
}

- (void)dealloc
{
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
#if IS_DEBUG()
	[NSException raise:@"ExcUnsupportedFunction" format:@""];
#endif
}

- (void)setEndFromDurationString: (NSString *)newDuration
{
#if IS_DEBUG()
	[NSException raise:@"ExcUnsupportedFunction" format:@""];
#endif
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
