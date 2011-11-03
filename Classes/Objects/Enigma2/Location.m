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
#if IS_DEBUG()
	[NSException raise:@"ExcUnsupportedFunction" format:@""];
#endif
}

- (id)initWithNode: (CXMLNode *)node
{
	if((self = [super init]))
	{
		_node = node;
	}
	return self;
}


- (void)setValid: (BOOL)newValid
{
#if IS_DEBUG()
	[NSException raise:@"ExcUnsupportedFunction" format:@""];
#endif
}

- (BOOL)valid
{
	return _node && self.fullpath != nil;
}

@end
