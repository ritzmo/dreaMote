//
//  Metadata.m
//  dreaMote
//
//  Created by Moritz Venn on 10.01.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import "Metadata.h"


@implementation GenericMetadata

@synthesize title, artist, album, genre, year, coverpath;

- (id)initWithMetadata: (NSObject<MetadataProtocol> *)meta
{
	if((self = [super init]))
	{
		title = [meta.title copy];
		artist = [meta.artist copy];
		album = [meta.album copy];
		genre = [meta.genre copy];
		year = [meta.year copy];
		coverpath = [meta.coverpath copy];
	}
	return self;
}

- (void)dealloc
{
	[title release];
	[artist release];
	[album release];
	[genre release];
	[year release];
	[coverpath release];

	[super dealloc];
}

- (BOOL)isValid
{
	// require title and artist for a valid service, one of them has to be non-empty
	return title && artist && !([title isEqualToString:@""] && [artist isEqualToString:@""]);
}

#pragma mark -
#pragma mark	Copy
#pragma mark -

- (id)copyWithZone:(NSZone *)zone
{
	id newElement = [[[self class] alloc] initWithMetadata: self];
	
	return newElement;
}

@end
