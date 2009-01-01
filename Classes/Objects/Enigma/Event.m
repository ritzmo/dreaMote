//
//  Event.m
//  dreaMote
//
//  Created by Moritz Venn on 01.01.09.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "Event.h"

#import "CXMLElement.h"

@implementation EnigmaEvent

@synthesize timeString;

- (NSString *)edescription
{
	if(_edescription == nil)
	{
		NSArray *resultNodes = [_node nodesForXPath:@"details" error:nil];
		for(CXMLElement *resultElement in resultNodes)
		{
			self.edescription = [resultElement stringValue];
			break;
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
	return nil;
}

- (void)setSdescription: (NSString *)new
{
	return;
}

- (NSString *)title
{
	if(_title == nil)
	{
		NSArray *resultNodes = [_node nodesForXPath:@"description" error:nil];
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
	[_title release];
	_title = [new retain];
}

- (NSDate *)end
{
	if(_end == nil)
	{
		NSArray *resultNodes = [_node nodesForXPath:@"duration" error:nil];
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
		NSArray *resultNodes = [_node nodesForXPath:@"start" error:nil];
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
	[_begin release];
	_begin = [new retain];
}

- (NSString *)eit
{
	return nil;
}

- (void)setEit: (NSString *)new
{
	return;
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
