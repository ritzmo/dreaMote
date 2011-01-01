//
//  Movie.m
//  dreaMote
//
//  Created by Moritz Venn on 31.12.08.
//  Copyright 2008-2011 Moritz Venn. All rights reserved.
//

#import "Movie.h"

#import "CXMLElement.h"

@implementation Enigma2Movie

- (NSArray *)tags
{
	if(_tags == nil)
	{
		const NSArray *resultNodes = [_node nodesForXPath:@"e2tags" error:nil];
		for(CXMLElement *currentChild in resultNodes)
		{
			const NSString *newTags = [currentChild stringValue];
			[_tags release];
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
	const NSArray *resultNodes = [_node nodesForXPath:@"e2filesize" error:nil];
	for(CXMLElement *currentChild in resultNodes)
	{
		return [NSNumber numberWithLongLong: [[currentChild stringValue] longLongValue]];
	}
	return nil;
}

- (void)setSize: (NSNumber *)new
{
	[NSException raise:@"ExcUnsupportedFunction" format:@""];
}

- (NSNumber *)length
{
	if(_length == nil)
	{
		const NSArray *resultNodes = [_node nodesForXPath:@"e2length" error:nil];
		for(CXMLElement *currentChild in resultNodes)
		{
			const NSString *elementValue = [currentChild stringValue];
			if([elementValue isEqualToString: @"disabled"] || [elementValue isEqualToString: @"?:??"])
			{
				self.length = [NSNumber numberWithInteger: -1];
			}
			else
			{
				const NSRange range = [elementValue rangeOfString: @":"];
				const NSInteger minutes = [[elementValue substringToIndex: range.location] integerValue];
				const NSInteger seconds = [[elementValue substringFromIndex: range.location + 1] integerValue];
				self.length = [NSNumber numberWithInteger: (minutes * 60) + seconds];
			}
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
		const NSArray *resultNodes = [_node nodesForXPath:@"e2time" error:nil];
		for(CXMLElement *currentChild in resultNodes)
		{
			self.time = [[NSDate dateWithTimeIntervalSince1970: [[currentChild stringValue] doubleValue]] retain];
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
	const NSArray *resultNodes = [_node nodesForXPath:@"e2servicename" error:nil];
	for(CXMLElement *currentChild in resultNodes)
	{
		return [currentChild stringValue];
	}
	return nil;
}

- (void)setSname: (NSString *)new
{
	[NSException raise:@"ExcUnsupportedFunction" format:@""];
}

- (NSString *)sref
{
	const NSArray *resultNodes = [_node nodesForXPath:@"e2servicereference" error:nil];
	for(CXMLElement *currentChild in resultNodes)
	{
		return [currentChild stringValue];
	}
	return nil;
}

- (void)setSref: (NSString *)new
{
	[NSException raise:@"ExcUnsupportedFunction" format:@""];
}

- (NSString *)edescription
{
	const NSArray *resultNodes = [_node nodesForXPath:@"e2descriptionextended" error:nil];
	for(CXMLElement *currentChild in resultNodes)
	{
		return [currentChild stringValue];
	}
	return nil;
}

- (void)setEdescription: (NSString *)new
{
	[NSException raise:@"ExcUnsupportedFunction" format:@""];
}

- (NSString *)sdescription
{
	const NSArray *resultNodes = [_node nodesForXPath:@"e2description" error:nil];
	for(CXMLElement *currentChild in resultNodes)
	{
		return [currentChild stringValue];
	}
	return nil;
}

- (void)setSdescription: (NSString *)new
{
	[NSException raise:@"ExcUnsupportedFunction" format:@""];
}

- (NSString *)title
{
	const NSArray *resultNodes = [_node nodesForXPath:@"e2title" error:nil];
	for(CXMLElement *currentChild in resultNodes)
	{
		return [currentChild stringValue];
	}
	return nil;
}

- (void)setTitle: (NSString *)new
{
	[NSException raise:@"ExcUnsupportedFunction" format:@""];
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
	[NSException raise:@"ExcUnsupportedFunction" format:@""];
}

- (void)setTagsFromString: (NSString *)newTags
{
	[NSException raise:@"ExcUnsupportedFunction" format:@""];
}

@end
