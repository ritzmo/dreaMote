//
//  Location.m
//  dreaMote
//
//  Created by Moritz Venn on 01.01.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import "Location.h"

@implementation GenericLocation

@synthesize fullpath, valid;

- (id)init
{
	if((self = [super init]))
	{
		fullpath = nil;
		valid = NO;
	}
	return self;
}

@end
