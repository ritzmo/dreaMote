//
//  MovieXMLReader.m
//  Untitled
//
//  Created by Moritz Venn on 11.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "MovieXMLReader.h"

#import "Movie.h"

static NSUInteger parsedMoviesCounter;

@implementation MovieXMLReader

@synthesize currentMovieObject = _currentMovieObject;

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
	[_currentMovieObject release];
	[super dealloc];
}

- (void)parserDidStartDocument:(NSXMLParser *)parser
{
	parsedMoviesCounter = 0;
}

/*
 Enigma2 Example:
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

 Enigma1 Example:
 <?xml version="1.0" encoding="UTF-8"?>
 <movies>
  <service><reference>1:0:1:6dcf:44d:1:c00000:93d2d1:0:0:/hdd/movie/WDR Köln - Rockpalast - Haldern Pop 2006 - 26_08_06.ts</reference><name>Rockpalast - Haldern Pop 2006</name><orbital_position>192</orbital_position></service>
 </movies>
*/
- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
	if (qName) {
		elementName = qName;
	}
	
	if ([elementName isEqualToString:@"e2movie"] || [elementName isEqualToString:@"service"]) {

		// If the number of parsed services is greater than MAX_ELEMENTS, abort the parse.
		// Otherwise the application runs very slowly on the device.
		if(++parsedMoviesCounter >= MAX_MOVIES)
		{
			self.currentMovieObject = nil;
			self.contentOfCurrentProperty = nil;

			[parser abortParsing];
		}
		else
		{
			// An e2movie/service in the xml represents a movie, so create an instance of it.
			self.currentMovieObject = [[Movie alloc] init];
		}

		return;
	}

	if (
		/* Enigma 2 */
		[elementName isEqualToString:@"e2servicereference"]	// Sref to movie
		|| [elementName isEqualToString:@"e2servicename"]	// Service Name
		|| [elementName isEqualToString:@"e2length"]		// Length of Movie
		|| [elementName isEqualToString:@"e2time"]			// When the movie was recorded
		|| [elementName isEqualToString:@"e2title"]			// Title
		|| [elementName isEqualToString:@"e2description"]	// Description
		|| [elementName isEqualToString:@"e2descriptionextended"]	// Extended Description
		|| [elementName isEqualToString:@"e2tags"]			// Tags
		|| [elementName isEqualToString:@"e2filesize"]		// Filesize
		/* Enigma 1 */
		|| [elementName isEqualToString:@"reference"]		// Sref to movie
		|| [elementName isEqualToString:@"name"]			// Title

		) {
		// Create a mutable string to hold the contents of this element.
		// The contents are collected in parser:foundCharacters:.
		self.contentOfCurrentProperty = [NSMutableString string];
		
	} else {
		// The element isn't one that we care about, so set the property that holds the 
		// character content of the current element to nil. That way, in the parser:foundCharacters:
		// callback, the string that the parser reports will be ignored.
		self.contentOfCurrentProperty = nil;
	}
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{	 
	if (qName) {
		elementName = qName;
	}
	
	if ([elementName isEqualToString:@"e2servicereference"] || [elementName isEqualToString:@"reference"]) {
		self.currentMovieObject.sref = self.contentOfCurrentProperty;
	} else if ([elementName isEqualToString:@"e2servicename"]) {
		self.currentMovieObject.sname = self.contentOfCurrentProperty;
	} else if ([elementName isEqualToString:@"e2length"]) {
		if([self.contentOfCurrentProperty isEqualToString: @"disabled"])
			self.currentMovieObject.length = [NSNumber numberWithInteger: -1];
		else
			self.currentMovieObject.length = [NSNumber numberWithInteger: [self.contentOfCurrentProperty integerValue]];
	} else if ([elementName isEqualToString:@"e2time"]) {
		[self.currentMovieObject setTimeFromString: self.contentOfCurrentProperty];
	} else if ([elementName isEqualToString:@"e2title"]) {
		self.currentMovieObject.title = self.contentOfCurrentProperty;
	} else if ([elementName isEqualToString:@"name"]) {
		// We have to un-escape some characters here...
		self.currentMovieObject.title = [self.contentOfCurrentProperty stringByReplacingOccurrencesOfString: @"&amp;" withString: @"&"];
	} else if ([elementName isEqualToString:@"e2description"]) {
		self.currentMovieObject.sdescription = self.contentOfCurrentProperty;
	} else if ([elementName isEqualToString:@"e2descriptionextended"]) {
		self.currentMovieObject.edescription = self.contentOfCurrentProperty;
	} else if ([elementName isEqualToString:@"e2tags"]) {
		[self.currentMovieObject setTagsFromString: self.contentOfCurrentProperty];
	} else if ([elementName isEqualToString:@"e2filesize"]) {
		self.currentMovieObject.size = [NSNumber numberWithLongLong: [self.contentOfCurrentProperty longLongValue]];
	} else if ([elementName isEqualToString:@"e2movie"] || [elementName isEqualToString:@"service"]) {
		[self.target performSelectorOnMainThread: self.addObject withObject: self.currentMovieObject waitUntilDone: NO];
	}
	self.contentOfCurrentProperty = nil;
}

@end
