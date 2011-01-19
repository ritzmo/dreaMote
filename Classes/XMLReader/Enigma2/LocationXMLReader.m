//
//  LocationXMLReader.m
//  dreaMote
//
//  Created by Moritz Venn on 01.01.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import "LocationXMLReader.h"

#import "../../Objects/Enigma2/Location.h"
#import "../../Objects/Generic/Location.h"

@implementation Enigma2LocationXMLReader

/* initialize */
- (id)initWithDelegate:(NSObject<LocationSourceDelegate> *)delegate
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
	NSObject<LocationProtocol> *fakeObject = [[GenericLocation alloc] init];
	fakeObject.fullpath = NSLocalizedString(@"Error retrieving Data", @"");
	fakeObject.valid = NO;
	[_delegate performSelectorOnMainThread: @selector(addLocation:)
								withObject: fakeObject
							 waitUntilDone: NO];
	[fakeObject release];
}

/*
Example:
<?xml version="1.0" encoding="UTF-8"?> 
<e2locations> 
 <e2location>/hdd/movie/</e2location> 
</e2locations> 
*/
- (void)parseFull
{
	const NSArray *resultNodes = [_parser nodesForXPath:@"/e2locations/e2location" error:nil];

	for(CXMLElement *resultElement in resultNodes)
	{
		// An e2movie in the xml represents a movie, so create an instance of it.
		NSObject<LocationProtocol> *newLocation = [[Enigma2Location alloc] initWithNode: (CXMLNode *)resultElement];
		
		[_delegate performSelectorOnMainThread: @selector(addLocation:)
									withObject: newLocation
								 waitUntilDone: NO];
		[newLocation release];
	}
}

@end
