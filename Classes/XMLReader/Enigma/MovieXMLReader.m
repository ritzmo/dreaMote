//
//  MovieXMLReader.m
//  dreaMote
//
//  Created by Moritz Venn on 31.12.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "MovieXMLReader.h"

#import "../../Objects/Enigma/Movie.h"
#import "../../Objects/Generic/Movie.h"

@implementation EnigmaMovieXMLReader

/*!
 @brief Upper bound for parsed Movies.
 
 @note Movies are considered 'heavy'
 @todo Do we actually still care? We keep the whole structure in our memory anyway...
 */
#define MAX_MOVIES 100

/* send fake object */
- (void)sendErroneousObject
{
	Movie *fakeObject = [[Movie alloc] init];
	fakeObject.title = NSLocalizedString(@"Error retrieving Data", @"");
	[_target performSelectorOnMainThread: _addObject withObject: fakeObject waitUntilDone: NO];
	[fakeObject release];
}

/*
 Example:
 <?xml version="1.0" encoding="UTF-8"?>
 <movies>
  <service><reference>1:0:1:6dcf:44d:1:c00000:93d2d1:0:0:/hdd/movie/WDR Köln - Rockpalast - Haldern Pop 2006 - 26_08_06.ts</reference><name>Rockpalast - Haldern Pop 2006</name><orbital_position>192</orbital_position></service>
 </movies>
*/
- (void)parseFull
{
	NSArray *resultNodes = NULL;
	NSUInteger parsedMovieCounter = 0;
	
	resultNodes = [_parser nodesForXPath:@"/movies/service" error:nil];
	
	for (CXMLElement *resultElement in resultNodes) {
		if(++parsedMovieCounter >= MAX_MOVIES)
			break;

		// A service in the xml represents a movie, so create an instance of it.
		EnigmaMovie *newMovie = [[EnigmaMovie alloc] initWithNode: (CXMLNode *)resultElement];

		[_target performSelectorOnMainThread: _addObject withObject: newMovie waitUntilDone: NO];
		[newMovie release];
	}
}

@end
