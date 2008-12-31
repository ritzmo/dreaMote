//
//  MovieXMLReader.m
//  Untitled
//
//  Created by Moritz Venn on 11.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "MovieXMLReader.h"

#import "Movie.h"

@implementation MovieXMLReader

// Movies are 'heavy'
#define MAX_MOVIES 100

+ (MovieXMLReader*)initWithTarget:(id)target action:(SEL)action
{
	MovieXMLReader *xmlReader = [[MovieXMLReader alloc] init];
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
 <e2movielist>
 <e2movie>
 <e2servicereference>1:0:0:0:0:0:0:0:0:0:/hdd/movie/20080723 0916 - ProSieben - Scrubs - Die Anfänger.ts</e2servicereference>
 <e2title>Scrubs - Die Anfänger</e2title>
 <e2description>Scrubs - Die Anfänger</e2description>
 <e2descriptionextended>Ted stellt sich gegen Kelso, als er sich für höhere Löhne für die Schwestern einsetzt. Todd hat seine Berufung in der plastischen Chirurgie gefunden. Als Turk sich dagegen einsetzt, dass ein sechzehnjähriges Mädchen eine Brust-OP bekommt, sieht Todd sich gezwungen, seinen Freund umzustimmen, denn dessen Job hängt davon ab. Jordan mischt sich in Keith und Elliotts Beziehung ein, was sich als nicht so gute Idee herausstellt.</e2descriptionextended>
 <e2servicename>ProSieben</e2servicename>
 <e2time>1216797360</e2time>
 <e2length>disabled</e2length>
 <e2tags></e2tags>
 <e2filename>/hdd/movie/20080723 0916 - ProSieben - Scrubs - Die Anfänger.ts</e2filename>
 <e2filesize>1649208192</e2filesize>
 </e2movie>
 </e2movielist>
*/
- (void)parseAllEnigma2
{
	NSArray *resultNodes = NULL;
	CXMLNode *currentChild = NULL;
	NSUInteger parsedMovieCounter = 0;
	
	resultNodes = [_parser nodesForXPath:@"/e2movielist/e2movie" error:nil];
	
	for (CXMLElement *resultElement in resultNodes) {
		if(++parsedMovieCounter >= MAX_MOVIES)
			break;

		// An e2movie in the xml represents a movie, so create an instance of it.
		Movie *newMovie = [[Movie alloc] init];

		for(NSUInteger counter = 0; counter < [resultElement childCount]; ++counter)
		{
			currentChild = (CXMLNode *)[resultElement childAtIndex: counter];
			NSString *elementName = [currentChild name];
			if([elementName isEqualToString:@"e2servicereference"])
			{
				newMovie.sref = [currentChild stringValue];
				continue;
			}
			else if([elementName isEqualToString:@"e2time"])
			{
				[newMovie setTimeFromString: [currentChild stringValue]];
				continue;
			}
			else if([elementName isEqualToString:@"e2length"])
			{
				NSString *elementValue = [currentChild stringValue];
				if([elementValue isEqualToString: @"disabled"])
					newMovie.length = [NSNumber numberWithInteger: -1];
				else
					newMovie.length = [NSNumber numberWithInteger: [elementValue integerValue]];
				continue;
			}
			else if([elementName isEqualToString:@"e2title"])
			{
				newMovie.title = [currentChild stringValue];
				continue;
			}
			else if([elementName isEqualToString:@"e2description"])
			{
				newMovie.sdescription = [currentChild stringValue];
				continue;
			}
			else if([elementName isEqualToString:@"e2descriptionextended"])
			{
				newMovie.edescription = [currentChild stringValue];
				continue;
			}
			else if ([elementName isEqualToString:@"e2tags"]) {
				[newMovie setTagsFromString: [currentChild stringValue]];
			}
			else if ([elementName isEqualToString:@"e2filesize"]) {
				newMovie.size = [NSNumber numberWithLongLong: [[currentChild stringValue] longLongValue]];
			}
		}
		
		[self.target performSelectorOnMainThread: self.addObject withObject: newMovie waitUntilDone: NO];
		[newMovie release];
	}
}

/*
 Example:
 <?xml version="1.0" encoding="UTF-8"?>
 <movies>
  <service><reference>1:0:1:6dcf:44d:1:c00000:93d2d1:0:0:/hdd/movie/WDR Köln - Rockpalast - Haldern Pop 2006 - 26_08_06.ts</reference><name>Rockpalast - Haldern Pop 2006</name><orbital_position>192</orbital_position></service>
 </movies>
*/
- (void)parseAllEnigma1
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

- (void)parseAllNeutrino
{
}

@end
