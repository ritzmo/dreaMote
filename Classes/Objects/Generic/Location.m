//
//  Location.m
//  dreaMote
//
//  Created by Moritz Venn on 01.01.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import "Location.h"

@implementation GenericLocation

@synthesize fullpath = _fullpath;
@synthesize valid = _isValid;

- (id)init
{
	if((self = [super init]))
	{
		_fullpath = nil;
		_isValid = NO;
	}
	return self;
}

- (void)dealloc
{
	[_fullpath release];

	[super dealloc];
}

@end
