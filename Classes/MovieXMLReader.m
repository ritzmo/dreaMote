// Header

#import "MovieXMLReader.h"

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

- (void)parserDidStartDocument:(NSXMLParser *)parser
{
	parsedMoviesCounter = 0;
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
- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
	if (qName) {
		elementName = qName;
	}

	// If the number of parsed services is greater than MAX_ELEMENTS, abort the parse.
	// Otherwise the application runs very slowly on the device.
	if (parsedMoviesCounter >= MAX_MOVIES) {
		[parser abortParsing];
	}
	
	if ([elementName isEqualToString:@"e2movie"]) {
		
		parsedMoviesCounter++;
		
		// An e2event in the xml represents a service, so create an instance of it.
		self.currentMovieObject = [[Movie alloc] init];

		return;
	}

	if ([elementName isEqualToString:@"e2servicereference"]) {
		// Create a mutable string to hold the contents of the 'e2servicereference' element.
		// The contents are collected in parser:foundCharacters:.
		self.contentOfCurrentProperty = [NSMutableString string];

	} else if ([elementName isEqualToString:@"e2servicename"]) {
		// Create a mutable string to hold the contents of the 'e2servicename' element.
		// The contents are collected in parser:foundCharacters:.
		self.contentOfCurrentProperty = [NSMutableString string];

	} else if ([elementName isEqualToString:@"e2length"]) {
		// Create a mutable string to hold the contents of the 'e2length' element.
		// The contents are collected in parser:foundCharacters:.
		self.contentOfCurrentProperty = [NSMutableString string];

	} else if ([elementName isEqualToString:@"e2time"]) {
		// Create a mutable string to hold the contents of the 'e2time' element.
		// The contents are collected in parser:foundCharacters:.
		self.contentOfCurrentProperty = [NSMutableString string];

	} else if ([elementName isEqualToString:@"e2title"]) {
		// Create a mutable string to hold the contents of the 'e2title' element.
		// The contents are collected in parser:foundCharacters:.
		self.contentOfCurrentProperty = [NSMutableString string];

	} else if ([elementName isEqualToString:@"e2description"]) {
		// Create a mutable string to hold the contents of the 'e2description' element.
		// The contents are collected in parser:foundCharacters:.
		self.contentOfCurrentProperty = [NSMutableString string];

	} else if ([elementName isEqualToString:@"e2descriptionextended"]) {
		// Create a mutable string to hold the contents of the 'e2descriptionextended' element.
		// The contents are collected in parser:foundCharacters:.
		self.contentOfCurrentProperty = [NSMutableString string];
		
	} else if ([elementName isEqualToString:@"e2tags"]) {
		// Create a mutable string to hold the contents of the 'e2tags' element.
		// The contents are collected in parser:foundCharacters:.
		self.contentOfCurrentProperty = [NSMutableString string];
		
	} else if ([elementName isEqualToString:@"e2filesize"]) {
		// Create a mutable string to hold the contents of the 'e2filesize' element.
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
	
	if ([elementName isEqualToString:@"e2servicereference"]) {
		[[self currentMovieObject] setSref: [self contentOfCurrentProperty]];
	} else if ([elementName isEqualToString:@"e2servicename"]) {
		[[self currentMovieObject] setSname: [self contentOfCurrentProperty]];
	} else if ([elementName isEqualToString:@"e2length"]) {
		if([[self contentOfCurrentProperty] isEqualToString: @"disabled"])
			[[self currentMovieObject] setLength: [NSNumber numberWithInt: -1]];
		else
			[[self currentMovieObject] setLength: [NSNumber numberWithInt: [[self contentOfCurrentProperty] intValue]]];
	} else if ([elementName isEqualToString:@"e2time"]) {
		[[self currentMovieObject] setTimeFromString: [self contentOfCurrentProperty]];
	} else if ([elementName isEqualToString:@"e2title"]) {
		[[self currentMovieObject] setTitle: [self contentOfCurrentProperty]];
	} else if ([elementName isEqualToString:@"e2description"]) {
		[[self currentMovieObject] setSdescription: [self contentOfCurrentProperty]];
	} else if ([elementName isEqualToString:@"e2descriptionextended"]) {
		[[self currentMovieObject] setEdescription: [self contentOfCurrentProperty]];
	} else if ([elementName isEqualToString:@"e2tags"]) {
		[[self currentMovieObject] setTagsFromString: [self contentOfCurrentProperty]];
	} else if ([elementName isEqualToString:@"e2filesize"]) {
		[[self currentMovieObject] setSize: [NSNumber numberWithInt: [[self contentOfCurrentProperty] intValue]]];
	} else if ([elementName isEqualToString:@"e2movie"]) {
		[self.target performSelectorOnMainThread:self.addObject withObject:self.currentMovieObject waitUntilDone:YES];
	}
	self.contentOfCurrentProperty = nil;
}

@end
