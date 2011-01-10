//
//  MetadataXMLReader.m
//  dreaMote
//
//  Created by Moritz Venn on 10.01.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import "MetadataXMLReader.h"

#import "../../Objects/Enigma2/Metadata.h"
#import "../../Objects/Generic/Metadata.h"

@implementation Enigma2MetadataXMLReader

/* initialize */
- (id)initWithDelegate:(NSObject<MetadataSourceDelegate> *)delegate
{
	if((self = [super init]))
	{
		_delegate = [delegate retain];
	}
	return self;
}

/* dealloc */
- (void)dealloc
{
	[_delegate release];
	[super dealloc];
}

/* send fake object */
- (void)sendErroneousObject
{
	NSObject<MetadataProtocol> *fakeObject = [[GenericMetadata alloc] init];
	fakeObject.title = NSLocalizedString(@"Error retrieving Data", @"");
	[_delegate performSelectorOnMainThread: @selector(addMetadata:)
								withObject: fakeObject
							 waitUntilDone: NO];
	[fakeObject release];
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
- (void)parseFull
{
	const NSArray *resultNodes = [_parser nodesForXPath:@"/e2mediaplayercurrent/e2currenttrack" error:nil];

	for(CXMLElement *resultElement in resultNodes)
	{
		// An e2movie in the xml represents a movie, so create an instance of it.
		NSObject<MetadataProtocol> *newMetadata = [[Enigma2Metadata alloc] initWithNode: (CXMLNode *)resultElement];
		
		[_delegate performSelectorOnMainThread: @selector(addMetadata:)
									withObject: newMetadata
								 waitUntilDone: NO];
		[newMetadata release];
	}
	[_delegate performSelectorOnMainThread: @selector(addMetadata:)
								withObject: nil
							 waitUntilDone: NO];
}

@end
