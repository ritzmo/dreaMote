//
//  Movie.m
//  dreaMote
//
//  Created by Moritz Venn on 31.12.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "Movie.h"

#import "CXMLElement.h"

@implementation Enigma2Movie

- (NSArray *)tags
{
	if(_tags == nil)
	{
		NSArray *resultNodes = [_node nodesForXPath:@"e2tags" error:nil];
		for(CXMLElement *currentChild in resultNodes)
		{
			[_tags release];
			NSString *newTags = [currentChild stringValue];
			if([newTags isEqualToString: @""])
				_tags = [[NSArray array] retain];
			else
				_tags = [[newTags componentsSeparatedByString:@" "] retain];
			break;
		}
	}
	return _tags;
}

- (void)setTags: (NSArray *)new
{
	if(_tags == new)
		return;
	[_tags release];
	_tags = [new retain];
}

- (NSNumber *)size
{
	NSArray *resultNodes = [_node nodesForXPath:@"e2filesize" error:nil];
	for(CXMLElement *currentChild in resultNodes)
	{
		return [NSNumber numberWithLongLong: [[currentChild stringValue] longLongValue]];
	}
	return nil;
}

- (void)setSize: (NSNumber *)new
{
	[NSException raise:@"ExcUnsupportedFunction" format:nil];
}

- (NSNumber *)length
{
	if(_length == nil)
	{
		NSArray *resultNodes = [_node nodesForXPath:@"e2length" error:nil];
		for(CXMLElement *currentChild in resultNodes)
		{
			NSString *elementValue = [currentChild stringValue];
			if([elementValue isEqualToString: @"disabled"])
				self.length = [NSNumber numberWithInteger: -1];
			else
				self.length = [NSNumber numberWithInteger: [elementValue integerValue]];
			break;
		}
	}
	return _length;
}

- (void)setLength: (NSNumber *)new
{
	if(_length == new)
		return;
	[_length release];
	_length = [new retain];
}

- (NSDate *)time
{
	if(_time == nil)
	{
		NSArray *resultNodes = [_node nodesForXPath:@"e2time" error:nil];
		for(CXMLElement *currentChild in resultNodes)
		{
			_time = [[NSDate dateWithTimeIntervalSince1970: [[currentChild stringValue] doubleValue]] retain];
			break;
		}
	}
	return _time;
}

- (void)setTime: (NSDate *)new
{
	if(_time == new)
		return;
	[_time release];
	_time = [new retain];
}

- (NSString *)sname
{
	NSArray *resultNodes = [_node nodesForXPath:@"e2servicename" error:nil];
	for(CXMLElement *currentChild in resultNodes)
	{
		return [currentChild stringValue];
	}
	return nil;
}

- (void)setSname: (NSString *)new
{
	[NSException raise:@"ExcUnsupportedFunction" format:nil];
}

- (NSString *)sref
{
	NSArray *resultNodes = [_node nodesForXPath:@"e2servicereference" error:nil];
	for(CXMLElement *currentChild in resultNodes)
	{
		return [currentChild stringValue];
	}
	return nil;
}

- (void)setSref: (NSString *)new
{
	[NSException raise:@"ExcUnsupportedFunction" format:nil];
}

- (NSString *)edescription
{
	NSArray *resultNodes = [_node nodesForXPath:@"e2descriptionextended" error:nil];
	for(CXMLElement *currentChild in resultNodes)
	{
		return [currentChild stringValue];
	}
	return nil;
}

- (void)setEdescription: (NSString *)new
{
	[NSException raise:@"ExcUnsupportedFunction" format:nil];
}

- (NSString *)sdescription
{
	NSArray *resultNodes = [_node nodesForXPath:@"e2description" error:nil];
	for(CXMLElement *currentChild in resultNodes)
	{
		return [currentChild stringValue];
	}
	return nil;
}

- (void)setSdescription: (NSString *)new
{
	[NSException raise:@"ExcUnsupportedFunction" format:nil];
}

- (NSString *)title
{
	NSArray *resultNodes = [_node nodesForXPath:@"e2title" error:nil];
	for(CXMLElement *currentChild in resultNodes)
	{
		return [currentChild stringValue];
	}
	return nil;
}

- (void)setTitle: (NSString *)new
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
	[_time release];
	[_length release];
	[_tags release];
	[_node release];

	[super dealloc];
}

- (BOOL)isValid
{
	return _node && self.sref != nil;
}

- (void)setTimeFromString: (NSString *)newTime
{
	[NSException raise:@"ExcUnsupportedFunction" format:nil];
}

- (void)setTagsFromString: (NSString *)newTags
{
	[NSException raise:@"ExcUnsupportedFunction" format:nil];
}

@end
