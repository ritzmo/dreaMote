//
//  AboutXMLReader.m
//  dreaMote
//
//  Created by Moritz Venn on 08.01.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import "AboutXMLReader.h"

#import "../../Objects/Enigma2/About.h"

@implementation Enigma2AboutXMLReader

/* initialize */
- (id)initWithDelegate:(NSObject<AboutSourceDelegate> *)delegate
{
	if((self = [super init]))
	{
		_delegate = [delegate retain];
	}
	return self;
}

/* send fake object */
- (void)sendErroneousObject
{
	[_delegate performSelectorOnMainThread: @selector(addAbout:)
								withObject: nil
							 waitUntilDone: NO];
}

/*
Example:
<?xml version="1.0" encoding="UTF-8"?> 
<e2about> 
 <e2enigmaversion>2010-12-21-experimental</e2enigmaversion>
 [...] 
</e2about> 
*/
- (void)parseFull
{
	const NSArray *resultNodes = [_parser nodesForXPath:@"/e2abouts/e2about" error:nil];

	for(CXMLElement *resultElement in resultNodes)
	{
		// An e2movie in the xml represents a movie, so create an instance of it.
		NSObject<AboutProtocol> *newAbout = [[Enigma2About alloc] initWithNode: (CXMLNode *)resultElement];
		
		[_delegate performSelectorOnMainThread: @selector(addAbout:)
									withObject: newAbout
								 waitUntilDone: NO];
		[newAbout release];
	}
}

@end
