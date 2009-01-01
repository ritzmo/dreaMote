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
	NSArray *resultNodes = [_node nodesForXPath:@"info2" error:nil];
	for(CXMLElement *resultElement in resultNodes)
	{
		return [resultElement stringValue];
	}
	return nil;
}

- (void)setEdescription: (NSString *)new
{
	[NSException raise:@"ExcUnsopportedFunction" format:nil];
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
	[NSException raise:@"ExcUnsopportedFunction" format:nil];
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
	[NSException raise:@"ExcUnsopportedFunction" format:nil];
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
	[NSException raise:@"ExcUnsopportedFunction" format:nil];
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
	[NSException raise:@"ExcUnsopportedFunction" format:nil];
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
	[NSException raise:@"ExcUnsopportedFunction" format:nil];
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
	[timeString release];

	[super dealloc];
}

- (NSString *)description
{
	// XXX: because we don't cache values this might lag a little...
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
