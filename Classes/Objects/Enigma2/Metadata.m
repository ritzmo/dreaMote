//
//  Metadata.m
//  dreaMote
//
//  Created by Moritz Venn on 10.01.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import "Metadata.h"

#import "../Generic/Metadata.h"
#import "CXMLElement.h"

@implementation Enigma2Metadata

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

- (BOOL)isValid
{
	// require at least artist or title
	return !([self.title isEqualToString:@""] && [self.artist isEqualToString:@""]);
}

- (NSString *)artist
{
	const NSArray *resultNodes = [_node nodesForXPath:@"e2artist" error:nil];
	for(CXMLElement *currentChild in resultNodes)
	{
		return [currentChild stringValue];
	}
	return nil;
}

- (void)setArtist: (NSString *)new
{
#if IS_DEBUG()
	[NSException raise:@"ExcUnsupportedFunction" format:@""];
#endif
}

- (NSString *)album
{
	const NSArray *resultNodes = [_node nodesForXPath:@"e2album" error:nil];
	for(CXMLElement *currentChild in resultNodes)
	{
		return [currentChild stringValue];
	}
	return nil;
}

- (void)setAlbum: (NSString *)new
{
#if IS_DEBUG()
	[NSException raise:@"ExcUnsupportedFunction" format:@""];
#endif
}

- (NSString *)genre
{
	const NSArray *resultNodes = [_node nodesForXPath:@"e2genre" error:nil];
	for(CXMLElement *currentChild in resultNodes)
	{
		return [currentChild stringValue];
	}
	return nil;
}

- (void)setGenre: (NSString *)new
{
#if IS_DEBUG()
	[NSException raise:@"ExcUnsupportedFunction" format:@""];
#endif
}

- (NSString *)title
{
	const NSArray *resultNodes = [_node nodesForXPath:@"e2title" error:nil];
	for(CXMLElement *currentChild in resultNodes)
	{
		return [currentChild stringValue];
	}
	return nil;
}

- (void)setTitle: (NSString *)new
{
#if IS_DEBUG()
	[NSException raise:@"ExcUnsupportedFunction" format:@""];
#endif
}

- (NSString *)year
{
	const NSArray *resultNodes = [_node nodesForXPath:@"e2year" error:nil];
	for(CXMLElement *currentChild in resultNodes)
	{
		return [currentChild stringValue];
	}
	return nil;
}

- (void)setYear: (NSString *)new
{
#if IS_DEBUG()
	[NSException raise:@"ExcUnsupportedFunction" format:@""];
#endif
}

- (NSString *)coverpath
{
	const NSArray *resultNodes = [_node nodesForXPath:@"e2coverfile" error:nil];
	for(CXMLElement *currentChild in resultNodes)
	{
		NSString *stringValue = [currentChild stringValue];
		if([stringValue isEqualToString:@"None"])
			return nil;
		return stringValue;
	}
	return nil;
}

- (void)setCoverpath: (NSString *)new
{
#if IS_DEBUG()
	[NSException raise:@"ExcUnsupportedFunction" format:@""];
#endif
}

#pragma mark -
#pragma mark	Copy
#pragma mark -

- (id)copyWithZone:(NSZone *)zone
{
	id newElement = [[GenericMetadata alloc] initWithMetadata: self];
	
	return newElement;
}

@end
