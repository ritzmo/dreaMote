//
//  Location.m
//  dreaMote
//
//  Created by Moritz Venn on 01.01.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import "Location.h"

#import "CXMLElement.h"

@implementation Enigma2Location

- (NSString *)fullpath
{
	return [_node stringValue];
}

- (void)setFullpath: (NSString *)new
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
	[_node release];
	
	[super dealloc];
}

- (void)setValid: (BOOL)newValid
{
	[NSException raise:@"ExcUnsupportedFunction" format:@""];
}

- (BOOL)valid
{
	return _node && self.fullpath != nil;
}

@end
