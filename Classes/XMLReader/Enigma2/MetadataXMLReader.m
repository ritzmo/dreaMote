//
//  MetadataXMLReader.m
//  dreaMote
//
//  Created by Moritz Venn on 10.01.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import "MetadataXMLReader.h"

#import <Objects/Generic/Metadata.h>

static const char *kEnigma2Currenttrack = "e2currenttrack";
static const NSUInteger kEnigma2CurrenttrackLength = 15;
static const char *kEnigma2Artist = "e2artist";
static const NSUInteger kEnigma2ArtistLength = 9;
static const char *kEnigma2Title = "e2title";
static const NSUInteger kEnigma2TitleLength = 8;
static const char *kEnigma2Album = "e2album";
static const NSUInteger kEnigma2AlbumLength = 8;
static const char *kEnigma2Year = "e2year";
static const NSUInteger kEnigma2YearLength = 7;
static const char *kEnigma2Genre = "e2genre";
static const NSUInteger kEnigma2GenreLength = 8;
static const char *kEnigma2Coverfile = "e2coverfile";
static const NSUInteger kEnigma2CoverfileLength = 12;

@interface Enigma2MetadataXMLReader()
@property (nonatomic, strong) GenericMetadata *metadata;
@end

@implementation Enigma2MetadataXMLReader

@synthesize metadata;

/* initialize */
- (id)initWithDelegate:(NSObject<MetadataSourceDelegate> *)delegate
{
	if((self = [super init]))
	{
		_delegate = delegate;
	}
	return self;
}

/* send fake object */
- (void)sendErroneousObject
{
	NSObject<MetadataProtocol> *fakeObject = [[GenericMetadata alloc] init];
	fakeObject.title = NSLocalizedString(@"Error retrieving Data", @"");
	[_delegate performSelectorOnMainThread:@selector(addMetadata:)
								withObject:fakeObject
							 waitUntilDone:NO];
}

/*
Example:
<?xml version="1.0" encoding="UTF-8"?> 
<e2mediaplayercurrent> 
 <e2currenttrack> 
  <e2artist>The Lonely Island</e2artist> 
  <e2title>I'm On A Boat (ft. T-Pain)</e2title> 
  <e2album>Incredibad</e2album> 
  <e2year>2009</e2year> 
  <e2genre>Pop</e2genre> 
  <e2coverfile>/tmp/.id3coverart</e2coverfile> 
 </e2currenttrack> 
</e2mediaplayercurrent> 
*/
- (void)elementFound:(const xmlChar *)localname prefix:(const xmlChar *)prefix uri:(const xmlChar *)URI namespaceCount:(int)namespaceCount namespaces:(const xmlChar **)namespaces attributeCount:(int)attributeCount defaultAttributeCount:(int)defaultAttributeCount attributes:(xmlSAX2Attributes *)attributes
{
	if(!strncmp((const char *)localname, kEnigma2Currenttrack, kEnigma2CurrenttrackLength))
	{
		metadata = [[GenericMetadata alloc] init];
	}
	else if(	!strncmp((const char *)localname, kEnigma2Artist, kEnigma2ArtistLength)
			||	!strncmp((const char *)localname, kEnigma2Title, kEnigma2TitleLength)
			||	!strncmp((const char *)localname, kEnigma2Album, kEnigma2AlbumLength)
			||	!strncmp((const char *)localname, kEnigma2Year, kEnigma2YearLength)
			||	!strncmp((const char *)localname, kEnigma2Genre, kEnigma2GenreLength)
			||	!strncmp((const char *)localname, kEnigma2Coverfile, kEnigma2CoverfileLength)
			)
	{
		currentString = [[NSMutableString alloc] init];
	}
}

- (void)endElement:(const xmlChar *)localname prefix:(const xmlChar *)prefix uri:(const xmlChar *)URI
{
	if(!strncmp((const char *)localname, kEnigma2Currenttrack, kEnigma2CurrenttrackLength))
	{
		[_delegate performSelectorOnMainThread:@selector(addMetadata:)
									withObject:metadata
								 waitUntilDone:NO];
	}
	else if(!strncmp((const char *)localname, kEnigma2Artist, kEnigma2ArtistLength))
	{
		metadata.artist = currentString;
	}
	else if(!strncmp((const char *)localname, kEnigma2Title, kEnigma2TitleLength))
	{
		metadata.title = currentString;
	}
	else if(!strncmp((const char *)localname, kEnigma2Album, kEnigma2AlbumLength))
	{
		metadata.album = currentString;
	}
	else if(!strncmp((const char *)localname, kEnigma2Year, kEnigma2YearLength))
	{
		metadata.year = currentString;
	}
	else if(!strncmp((const char *)localname, kEnigma2Genre, kEnigma2GenreLength))
	{
		metadata.genre = currentString;
	}
	else if(!strncmp((const char *)localname, kEnigma2Coverfile, kEnigma2CoverfileLength))
	{
		metadata.coverpath = currentString;
	}
	self.currentString = nil;
}

@end
