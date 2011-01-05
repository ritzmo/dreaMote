//
//  File.m
//  dreaMote
//
//  Created by Moritz Venn on 05.01.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import "File.h"

@implementation GenericFile

@synthesize sref = _sref;
@synthesize title = _title;
@synthesize isDirectory = _isDirectory;
@synthesize root = _root;
@synthesize valid = _valid;

- (void)dealloc
{
	[_sref release];
	[_root release];

	[super dealloc];
}

- (BOOL)isValid
{
	return _valid;
}

@end
