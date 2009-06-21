//
//  Event.m
//  dreaMote
//
//  Created by Moritz Venn on 01.01.09.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "Event.h"

#import "CXMLElement.h"

@implementation NeutrinoEvent

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

- (NSString *)edescription
{
	NSArray *resultNodes = [_node nodesForXPath:@"info2" error:nil];
	for(CXMLElement *resultElement in resultNodes)
	{
		return [resultElement stringValue];
	}
	return nil;
}

- (void)setEdescription: (NSString *)new
{
	[NSException raise:@"ExcUnsupportedFunction" format:nil];
}

- (NSString *)sdescription
{
	NSArray *resultNodes = [_node nodesForXPath:@"info1" error:nil];
	for(CXMLElement *resultElement in resultNodes)
	{
		return [resultElement stringValue];
	}
	return nil;
}

- (void)setSdescription: (NSString *)new
{
	[NSException raise:@"ExcUnsupportedFunction" format:nil];
}

- (NSString *)title
{
	NSArray *resultNodes = [_node nodesForXPath:@"description" error:nil];
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
	NSArray *resultNodes = [_node nodesForXPath:@"stop_sec" error:nil];
	for(CXMLElement *resultElement in resultNodes)
	{
		return [NSDate dateWithTimeIntervalSince1970: [[resultElement stringValue] doubleValue]];
	}
	return nil;
}

- (void)setEnd: (NSDate *)new
{
	[NSException raise:@"ExcUnsupportedFunction" format:nil];
}

- (NSDate *)begin
{
	NSArray *resultNodes = [_node nodesForXPath:@"start_sec" error:nil];
	for(CXMLElement *resultElement in resultNodes)
	{
			return [NSDate dateWithTimeIntervalSince1970: [[resultElement stringValue] doubleValue]];
	}
	return nil;
}

- (void)setBegin: (NSDate *)new
{
	[NSException raise:@"ExcUnsupportedFunction" format:nil];
}

- (NSString *)eit
{
	NSArray *resultNodes = [_node nodesForXPath:@"eventid" error:nil];
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
	[NSException raise:@"ExcUnsupportedFunction" format:nil];
}

- (void)setEndFromDurationString: (NSString *)newDuration
{
	[NSException raise:@"ExcUnsupportedFunction" format:nil];
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
