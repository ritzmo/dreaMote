//
//  File.m
//  dreaMote
//
//  Created by Moritz Venn on 05.01.11.
//  Copyright 2011-2012 Moritz Venn. All rights reserved.
//

#import "File.h"

@implementation GenericFile

@synthesize sref, title, isDirectory, root, valid;

- (id)initWithFile:(NSObject <FileProtocol>*)file
{
	if((self = [super init]))
	{
		sref = [file.sref copy];
		title = [file.title copy];
		isDirectory = file.isDirectory;
		root = [file.root copy];
		valid = file.valid;
	}
	return self;
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
