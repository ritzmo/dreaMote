//
//  Movie.m
//  Untitled
//
//  Created by Moritz Venn on 09.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "Movie.h"

@implementation Enigma2Movie

- (NSArray *)tags
{
	if(_tags == nil)
	{
		CXMLNode *currentChild = nil;
		for(NSUInteger counter = 0; counter < [_node childCount]; ++counter)
		{
			currentChild = (CXMLNode *)[_node childAtIndex: counter];
			NSString *elementName = [currentChild name];
			if([elementName isEqualToString:@"e2tags"])
			{
				[self setTagsFromString: [currentChild stringValue]];
				break;
			}
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
	if(_size == nil)
	{
		CXMLNode *currentChild = nil;
		for(NSUInteger counter = 0; counter < [_node childCount]; ++counter)
		{
			currentChild = (CXMLNode *)[_node childAtIndex: counter];
			NSString *elementName = [currentChild name];
			if([elementName isEqualToString:@"e2filesize"])
			{
				self.size = [NSNumber numberWithLongLong: [[currentChild stringValue] longLongValue]];
				break;
			}
		}
	}
	return _size;
}

- (void)setSize: (NSNumber *)new
{
	if(_size == new)
		return;
	[_size release];
	_size = [new retain];
}

- (NSNumber *)length
{
	if(_length == nil)
	{
		CXMLNode *currentChild = nil;
		for(NSUInteger counter = 0; counter < [_node childCount]; ++counter)
		{
			currentChild = (CXMLNode *)[_node childAtIndex: counter];
			NSString *elementName = [currentChild name];
			if([elementName isEqualToString:@"e2length"])
			{
				NSString *elementValue = [currentChild stringValue];
				if([elementValue isEqualToString: @"disabled"])
					self.length = [NSNumber numberWithInteger: -1];
				else
					self.length = [NSNumber numberWithInteger: [elementValue integerValue]];
				break;
			}
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
		CXMLNode *currentChild = nil;
		for(NSUInteger counter = 0; counter < [_node childCount]; ++counter)
		{
			currentChild = (CXMLNode *)[_node childAtIndex: counter];
			NSString *elementName = [currentChild name];
			if([elementName isEqualToString:@"e2time"])
			{
				[self setTimeFromString: [currentChild stringValue]];
				break;
			}
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
	if(_sname == nil)
	{
		CXMLNode *currentChild = nil;
		for(NSUInteger counter = 0; counter < [_node childCount]; ++counter)
		{
			currentChild = (CXMLNode *)[_node childAtIndex: counter];
			NSString *elementName = [currentChild name];
			if([elementName isEqualToString:@"e2servicename"])
			{
				self.sname = [currentChild stringValue];
				break;
			}
		}
	}
	return _sname;
}

- (void)setSname: (NSString *)new
{
	if(_sname == new)
		return;
	[_sname release];
	_sname = [new retain];
}

- (NSString *)sref
{
	if(_sref == nil)
	{
		CXMLNode *currentChild = nil;
		for(NSUInteger counter = 0; counter < [_node childCount]; ++counter)
		{
			currentChild = (CXMLNode *)[_node childAtIndex: counter];
			NSString *elementName = [currentChild name];
			if([elementName isEqualToString:@"e2servicereference"])
			{
				self.sref = [currentChild stringValue];
				break;
			}
		}
	}
	return _sref;
}

- (void)setSref: (NSString *)new
{
	if(_sref == new)
		return;
	[_sref release];
	_sref = [new retain];
}


- (NSString *)edescription
{
	if(_edescription == nil)
	{
		CXMLNode *currentChild = nil;
		for(NSUInteger counter = 0; counter < [_node childCount]; ++counter)
		{
			currentChild = (CXMLNode *)[_node childAtIndex: counter];
			NSString *elementName = [currentChild name];
			if([elementName isEqualToString:@"e2descriptionextended"])
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
			if([elementName isEqualToString:@"e2description"])
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
			if([elementName isEqualToString:@"e2title"])
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
	[_sref release];
	[_sname release];
	[_time release];
	[_title release];
	[_sdescription release];
	[_edescription release];
	[_length release];
	[_size release];
	[_tags release];
	[_node release];

	[super dealloc];
}

- (BOOL)isValid
{
	return self.sref != nil;
}

- (void)setTimeFromString: (NSString *)newTime
{
	[_time release];
	_time = [[NSDate dateWithTimeIntervalSince1970: [newTime doubleValue]] retain];
}

- (void)setTagsFromString: (NSString *)newTags
{
	[_tags release];
	if([newTags isEqualToString: @""])
		_tags = [[NSArray array] retain];
	else
		_tags = [[newTags componentsSeparatedByString:@" "] retain];
}

@end
