//
//  MovieXMLReader.m
//  Untitled
//
//  Created by Moritz Venn on 11.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "MovieXMLReader.h"

#import "../../Objects/Generic/Movie.h"

@implementation EnigmaMovieXMLReader

// Movies are 'heavy'
#define MAX_MOVIES 100

+ (EnigmaMovieXMLReader*)initWithTarget:(id)target action:(SEL)action
{
	EnigmaMovieXMLReader *xmlReader = [[EnigmaMovieXMLReader alloc] init];
	xmlReader.target = target;
	xmlReader.addObject = action;

	return xmlReader;
}

- (void)dealloc
{
	[super dealloc];
}

- (void)sendErroneousObject
{
	Movie *fakeObject = [[Movie alloc] init];
	fakeObject.title = NSLocalizedString(@"Error retrieving Data", @"");
	[self.target performSelectorOnMainThread: self.addObject withObject: fakeObject waitUntilDone: NO];
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
	CXMLNode *currentChild = NULL;
	NSUInteger parsedMovieCounter = 0;
	
	resultNodes = [_parser nodesForXPath:@"/movies/service" error:nil];
	
	for (CXMLElement *resultElement in resultNodes) {
		if(++parsedMovieCounter >= MAX_MOVIES)
			break;
		
		// A service in the xml represents a movie, so create an instance of it.
		Movie *newMovie = [[Movie alloc] init];
		
		for(NSUInteger counter = 0; counter < [resultElement childCount]; ++counter)
		{
			currentChild = (CXMLNode *)[resultElement childAtIndex: counter];
			NSString *elementName = [currentChild name];
			if([elementName isEqualToString:@"reference"])
			{
				newMovie.sref = [currentChild stringValue];
				continue;
			}
			else if([elementName isEqualToString:@"name"])
			{
				// We have to un-escape some characters here...
				newMovie.title = [[currentChild stringValue] stringByReplacingOccurrencesOfString: @"&amp;" withString: @"&"];
				continue;
			}
		}
		
		[self.target performSelectorOnMainThread: self.addObject withObject: newMovie waitUntilDone: NO];
		[newMovie release];
	}
}

@end
