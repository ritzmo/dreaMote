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
			[self setTagsFromString: [currentChild stringValue]];
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
	if(_size == nil)
	{
		NSArray *resultNodes = [_node nodesForXPath:@"e2filesize" error:nil];
		for(CXMLElement *currentChild in resultNodes)
		{
			self.size = [NSNumber numberWithLongLong: [[currentChild stringValue] longLongValue]];
			break;
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
	if(_sname == nil)
	{
		NSArray *resultNodes = [_node nodesForXPath:@"e2servicename" error:nil];
		for(CXMLElement *currentChild in resultNodes)
		{
			self.sname = [currentChild stringValue];
			break;
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
		NSArray *resultNodes = [_node nodesForXPath:@"e2servicereference" error:nil];
		for(CXMLElement *currentChild in resultNodes)
		{
			self.sref = [currentChild stringValue];
			break;
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
		NSArray *resultNodes = [_node nodesForXPath:@"e2descriptionextended" error:nil];
		for(CXMLElement *currentChild in resultNodes)
		{
			self.edescription = [currentChild stringValue];
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
		NSArray *resultNodes = [_node nodesForXPath:@"e2description" error:nil];
		for(CXMLElement *currentChild in resultNodes)
		{
			self.sdescription = [currentChild stringValue];
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
		NSArray *resultNodes = [_node nodesForXPath:@"e2title" error:nil];
		for(CXMLElement *currentChild in resultNodes)
		{
			self.title = [currentChild stringValue];
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
	return _node && self.sref != nil;
}

- (void)setTimeFromString: (NSString *)newTime
{
	[NSException raise:@"ExcUnsopportedFunction" format:nil];
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
