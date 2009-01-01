//
//  Movie.m
//  dreaMote
//
//  Created by Moritz Venn on 31.12.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "Movie.h"

#import "CXMLElement.h"

@implementation EnigmaMovie

// XXX: does the gui really depend on this being an empty array
- (NSArray *)tags
{
	if(_tags == nil)
		_tags = [NSArray array];
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
		_size = [NSNumber numberWithInt: -1];
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
		_length = [NSNumber numberWithInt: -1];
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
	return nil;
}

- (void)setTime: (NSDate *)new
{
	return;
}

- (NSString *)sname
{
	return nil;
}

- (void)setSname: (NSString *)new
{
	return;
}

- (NSString *)sref
{
	if(_sref == nil)
	{
		NSArray *resultNodes = [_node nodesForXPath:@"reference" error:nil];
		for(CXMLElement *resultElement in resultNodes)
		{
			self.sref = [resultElement stringValue];
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
	return NSLocalizedString(@"N/A", @"");
}

- (void)setEdescription: (NSString *)new
{
	return;
}

- (NSString *)sdescription
{
	return NSLocalizedString(@"N/A", @"");
}

- (void)setSdescription: (NSString *)new
{
	return;
}

- (NSString *)title
{
	if(_title == nil)
	{
		NSArray *resultNodes = [_node nodesForXPath:@"name" error:nil];
		for(CXMLElement *resultElement in resultNodes)
		{
			// We have to un-escape some characters here...
			self.title = [[resultElement stringValue] stringByReplacingOccurrencesOfString: @"&amp;" withString: @"&"];
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
	[_title release];
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
	[NSException raise:@"ExcUnsopportedFunction" format:nil];
}

@end
