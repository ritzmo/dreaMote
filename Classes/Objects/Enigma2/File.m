//
//  File.m
//  dreaMote
//
//  Created by Moritz Venn on 05.01.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import "File.h"

#import "../Generic/File.h"
#import "CXMLElement.h"

@implementation Enigma2File

- (NSString *)sref
{
	const NSArray *resultNodes = [_node nodesForXPath:@"e2servicereference" error:nil];
	for(CXMLElement *currentChild in resultNodes)
	{
		NSString *stringValue = [currentChild stringValue];
		if([stringValue isEqualToString: @"None"])
			return @"Filesystems";
		return stringValue;
	}
	return nil;
}

- (void)setSref: (NSString *)new
{
	[NSException raise:@"ExcUnsupportedFunction" format:@""];
}

- (NSString *)title
{
	const NSArray *resultNodes = [_node nodesForXPath:@"e2servicereference" error:nil];
	for(CXMLElement *currentChild in resultNodes)
	{
		NSString *stringValue = [currentChild stringValue];
		if([stringValue isEqualToString: @"None"])
			return NSLocalizedString(@"Filesystems", @"Label for Filesystems Item in MediaPlayer Filelist");
		return [stringValue stringByReplacingOccurrencesOfString:self.root withString:@""];
	}
	return nil;
}

- (void)setTitle: (NSString *)new
{
	[NSException raise:@"ExcUnsupportedFunction" format:@""];
}

- (BOOL)isDirectory
{
	const NSArray *resultNodes = [_node nodesForXPath:@"e2isdirectory" error:nil];
	for(CXMLElement *currentChild in resultNodes)
	{
		return [[currentChild stringValue] isEqualToString: @"True"];
	}
	return NO;
}

- (void)setIsDirectory:(BOOL)new
{
	[NSException raise:@"ExcUnsupportedFunction" format:@""];
}

- (NSString *)root
{
	const NSArray *resultNodes = [_node nodesForXPath:@"e2root" error:nil];
	for(CXMLElement *currentChild in resultNodes)
	{
		return [currentChild stringValue];
	}
	return nil;
}

- (void)setRoot: (NSString *)new
{
	[NSException raise:@"ExcUnsupportedFunction" format:@""];
}

- (BOOL)valid
{
	return _node != nil;
}

- (void)setValid: (BOOL)new
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

@end
