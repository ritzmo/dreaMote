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

- (id)initWithFile:(NSObject <FileProtocol>*)file
{
	if((self = [super init]))
	{
		_sref = [file.sref copy];
		_title = [file.title copy];
		_isDirectory = file.isDirectory;
		_root = [file.root copy];
		_valid = file.valid;
	}
	return self;
}


- (BOOL)isValid
{
	return _valid;
}

#pragma mark -
#pragma mark	Copy
#pragma mark -

- (id)copyWithZone:(NSZone *)zone
{
	id newElement = [[[self class] alloc] initWithFile: self];
	return newElement;
}

@end
