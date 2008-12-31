//
//  Event.m
//  Untitled
//
//  Created by Moritz Venn on 09.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "Event.h"

@implementation Enigma2Event

@synthesize timeString;

- (NSString *)edescription
{
	if(_edescription == nil)
	{
		CXMLNode *currentChild = nil;
		for(NSUInteger counter = 0; counter < [_node childCount]; ++counter)
		{
			currentChild = (CXMLNode *)[_node childAtIndex: counter];
			NSString *elementName = [currentChild name];
			if([elementName isEqualToString:@"e2eventdescriptionextended"])
			{
				self.edescription = [currentChild stringValue];
				break;
			}
		}
	}
	return _edescription;
}

- (void)setEdescription: (NSString *)new
{
	if(_edescription == new)
		return;
	[_edescription release];
	_edescription = [new retain];
}

- (NSString *)sdescription
{
	if(_sdescription == nil)
	{
		CXMLNode *currentChild = nil;
		for(NSUInteger counter = 0; counter < [_node childCount]; ++counter)
		{
			currentChild = (CXMLNode *)[_node childAtIndex: counter];
			NSString *elementName = [currentChild name];
			if([elementName isEqualToString:@"e2eventdescription"])
			{
				self.sdescription = [currentChild stringValue];
				break;
			}
		}
	}
	return _sdescription;
}

- (void)setSdescription: (NSString *)new
{
	if(_sdescription == new)
		return;
	[_sdescription release];
	_sdescription = [new retain];
}

- (NSString *)title
{
	if(_title == nil)
	{
		CXMLNode *currentChild = nil;
		for(NSUInteger counter = 0; counter < [_node childCount]; ++counter)
		{
			currentChild = (CXMLNode *)[_node childAtIndex: counter];
			NSString *elementName = [currentChild name];
			if([elementName isEqualToString:@"e2eventtitle"])
			{
				self.title = [currentChild stringValue];
				break;
			}
		}
	}
	return _title;
}

- (void)setTitle: (NSString *)new
{
	if(_title == new)
		return;
	[_title release];
	_title = [new retain];
}

- (NSDate *)end
{
	if(_end == nil)
	{
		CXMLNode *currentChild = nil;
		for(NSUInteger counter = 0; counter < [_node childCount]; ++counter)
		{
			currentChild = (CXMLNode *)[_node childAtIndex: counter];
			NSString *elementName = [currentChild name];
			if([elementName isEqualToString:@"e2eventduration"])
			{
				[self setEndFromDurationString: [currentChild stringValue]];
				break;
			}
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
		CXMLNode *currentChild = nil;
		for(NSUInteger counter = 0; counter < [_node childCount]; ++counter)
		{
			currentChild = (CXMLNode *)[_node childAtIndex: counter];
			NSString *elementName = [currentChild name];
			if([elementName isEqualToString:@"e2eventstart"])
			{
				[self setBeginFromString: [currentChild stringValue]];
				break;
			}
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
	if(_eit == nil)
	{
		CXMLNode *currentChild = nil;
		for(NSUInteger counter = 0; counter < [_node childCount]; ++counter)
		{
			currentChild = (CXMLNode *)[_node childAtIndex: counter];
			NSString *elementName = [currentChild name];
			if([elementName isEqualToString:@"e2eventid"])
			{
				self.eit = [currentChild stringValue];
				break;
			}
		}
	}
	return _eit;
}

- (void)setEit: (NSString *)new
{
	if(_eit == new)
		return;
	[_eit release];
	_eit = [new retain];
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
	[_eit release];
	[_begin release];
	[_end release];
	[_title release];
	[_sdescription release];
	[_edescription release];
	[_node release];
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
	[_end release];
	if(self.end == nil)
	{
		// XXX: should never happen
		return;
	}
}

- (void)setEndFromDurationString: (NSString *)newDuration
{
	[timeString release];
	timeString = nil;

	if(self.begin == nil)
	{
		// XXX: should never happen
		return;
	}
	[_end release];
	_end = [[_begin addTimeInterval: [newDuration doubleValue]] retain];
}

@end
