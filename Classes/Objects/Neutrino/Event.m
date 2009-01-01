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

@synthesize timeString;

- (NSString *)edescription
{
	if(_edescription == nil)
	{
		NSArray *resultNodes = [_node nodesForXPath:@"info2" error:nil];
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
	if(_sdescription == nil)
	{
		NSArray *resultNodes = [_node nodesForXPath:@"info1" error:nil];
		for(CXMLElement *resultElement in resultNodes)
		{
			self.sdescription = [resultElement stringValue];
			break;
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
		NSArray *resultNodes = [_node nodesForXPath:@"stop_sec" error:nil];
		for(CXMLElement *resultElement in resultNodes)
		{
			self.end = [NSDate dateWithTimeIntervalSince1970: [[resultElement stringValue] doubleValue]];
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
		NSArray *resultNodes = [_node nodesForXPath:@"start_sec" error:nil];
		for(CXMLElement *resultElement in resultNodes)
		{
			self.begin = [NSDate dateWithTimeIntervalSince1970: [[resultElement stringValue] doubleValue]];
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
	if(_eit == nil)
	{
		NSArray *resultNodes = [_node nodesForXPath:@"eventid" error:nil];
		for(CXMLElement *resultElement in resultNodes)
		{
			self.eit = [resultElement stringValue];
			break;
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
	[NSException raise:@"ExcUnsopportedFunction" format:nil];
}

- (void)setEndFromDurationString: (NSString *)newDuration
{
	[NSException raise:@"ExcUnsopportedFunction" format:nil];
}

@end
