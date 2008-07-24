//
//  EventXMLReader.m
//  Untitled
//
//  Created by Moritz Venn on 11.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "EventXMLReader.h"

static NSUInteger parsedEventsCounter;

@implementation EventXMLReader

@synthesize currentEventObject = _currentEventObject;

// Events are 'heavy'
#define MAX_EVENTS 100

+ (EventXMLReader*)initWithTarget:(id)target action:(SEL)action
{
	EventXMLReader *xmlReader = [[EventXMLReader alloc] init];
	xmlReader.target = target;
	xmlReader.addObject = action;

	return xmlReader;
}

- (void)parserDidStartDocument:(NSXMLParser *)parser
{
	parsedEventsCounter = 0;
}

/*
 Example:
 <?xml version="1.0" encoding="UTF-8"?>
 <e2eventlist>
 <e2event>
 <e2eventid>40710</e2eventid>
 <e2eventstart>1205037000</e2eventstart>
 <e2eventduration>1500</e2eventduration>
 <e2eventtitle>Aktion Schulstreich</e2eventtitle>
 <e2eventdescription>1. Hauptschule Sonthofen - Motto: Wir nageln Deutsch und Mathe an die Wand</e2eventdescription>
 <e2eventdescriptionextended>In dieser ersten Folge kommt der Notruf aus dem Allgäu. Die Räume der Hauptschule in der Alpenstadt Sonthofen sind ziemlich farblos und erinnern mehr an ein Kloster, als an eine fröhliche Schule.</e2eventdescriptionextended>
 <e2eventservicereference>1:0:1:6DCA:44D:1:C00000:0:0:0:</e2eventservicereference>
 <e2eventservicename>Das Erste</e2eventservicename>
 </e2event>
 </e2eventlist>
*/
- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
	if (qName) {
		elementName = qName;
	}

	// If the number of parsed services is greater than MAX_ELEMENTS, abort the parse.
	// Otherwise the application runs very slowly on the device.
	if (parsedEventsCounter >= MAX_EVENTS) {
		[parser abortParsing];
	}
	
	if ([elementName isEqualToString:@"e2event"]) {
		
		parsedEventsCounter++;
		
		// An e2event in the xml represents a service, so create an instance of it.
		self.currentEventObject = [[Event alloc] init];

		return;
	}

	/*if ([elementName isEqualToString:@"e2servicereference"]) {
		// Create a mutable string to hold the contents of the 'e2servicereference' element.
		// The contents are collected in parser:foundCharacters:.
		self.contentOfCurrentProperty = [NSMutableString string];

	} else if ([elementName isEqualToString:@"e2servicename"]) {
		// Create a mutable string to hold the contents of the 'e2servicename' element.
		// The contents are collected in parser:foundCharacters:.
		self.contentOfCurrentProperty = [NSMutableString string];

	} else*/ if ([elementName isEqualToString:@"e2eventid"]) {
		// Create a mutable string to hold the contents of the 'e2eventid' element.
		// The contents are collected in parser:foundCharacters:.
		self.contentOfCurrentProperty = [NSMutableString string];

	} else if ([elementName isEqualToString:@"e2eventstart"]) {
		// Create a mutable string to hold the contents of the 'e2eventstart' element.
		// The contents are collected in parser:foundCharacters:.
		self.contentOfCurrentProperty = [NSMutableString string];

	} else if ([elementName isEqualToString:@"e2eventduration"]) {
		// Create a mutable string to hold the contents of the 'e2eventduration' element.
		// The contents are collected in parser:foundCharacters:.
		self.contentOfCurrentProperty = [NSMutableString string];

	} else if ([elementName isEqualToString:@"e2eventtitle"]) {
		// Create a mutable string to hold the contents of the 'e2eventtitle' element.
		// The contents are collected in parser:foundCharacters:.
		self.contentOfCurrentProperty = [NSMutableString string];

	} else if ([elementName isEqualToString:@"e2eventdescription"]) {
		// Create a mutable string to hold the contents of the 'e2eventdescription' element.
		// The contents are collected in parser:foundCharacters:.
		self.contentOfCurrentProperty = [NSMutableString string];

	} else if ([elementName isEqualToString:@"e2eventdescriptionextended"]) {
		// Create a mutable string to hold the contents of the 'e2eventdescriptionextended' element.
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
	
	if ([elementName isEqualToString:@"e2eventid"]) {
		[[self currentEventObject] setEit: [self contentOfCurrentProperty]];
	} else if ([elementName isEqualToString:@"e2eventstart"]) {
		[[self currentEventObject] setBeginFromString: [self contentOfCurrentProperty]];
	} else if ([elementName isEqualToString:@"e2eventduration"]) {
		// XXX: this relies on begin being set before, we might wanna fix this someday
		[[self currentEventObject] setEndFromDurationString: [self contentOfCurrentProperty]];
	} else if ([elementName isEqualToString:@"e2eventtitle"]) {
		[[self currentEventObject] setTitle: [self contentOfCurrentProperty]];
	} else if ([elementName isEqualToString:@"e2eventdescription"]) {
		[[self currentEventObject] setSdescription: [self contentOfCurrentProperty]];
	} else if ([elementName isEqualToString:@"e2eventdescriptionextended"]) {
		[[self currentEventObject] setEdescription: [self contentOfCurrentProperty]];
	} else if ([elementName isEqualToString:@"e2event"]) {
		[self.target performSelectorOnMainThread:self.addObject withObject:self.currentEventObject waitUntilDone:YES];
	}
	self.contentOfCurrentProperty = nil;
}

@end
