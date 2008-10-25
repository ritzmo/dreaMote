//
//  EventXMLReader.m
//  Untitled
//
//  Created by Moritz Venn on 11.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "EventXMLReader.h"

#import "Event.h"

static NSUInteger parsedEventsCounter;

@implementation EnigmaEventXMLReader

@synthesize currentEventObject = _currentEventObject;

// Events are 'heavy'
#define MAX_EVENTS 100

+ (EnigmaEventXMLReader*)initWithTarget:(id)target action:(SEL)action
{
	EnigmaEventXMLReader *xmlReader = [[EnigmaEventXMLReader alloc] init];
	xmlReader.target = target;
	xmlReader.addObject = action;

	return xmlReader;
}

- (void)dealloc
{
	[_currentEventObject release];
	[super dealloc];
}

- (void)parserDidStartDocument:(NSXMLParser *)parser
{
	parsedEventsCounter = 0;
}

- (void)sendErroneousObject
{
	Event *fakeObject = [[Event alloc] init];
	fakeObject.title = NSLocalizedString(@"Error retrieving Data", @"");
	[self.target performSelectorOnMainThread: self.addObject withObject: fakeObject waitUntilDone: NO];
	[fakeObject release];
}

/*
 Enigma2 Example:
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

 Enigma1 Example:
 <?xml version="1.0" encoding="UTF-8"?>
 <?xml-stylesheet type="text/xsl" href="/xml/serviceepg.xsl"?>
 <service_epg>
  <service>
   <reference>1:0:1:445d:453:1:c00000:0:0:0:</reference>
   <name>ProSieben</name>
  </service>
  <event id="0">
   <date>18.09.2008</date>
   <time>16:02</time>
   <duration>3385</duration>
   <description>Deine Chance! 3 Bewerber - 1 Job</description>
   <genre>n/a</genre>
   <genrecategory>00</genrecategory>
   <start>1221746555</start>
   <details>Starfotograf Jack 'Tin lichtet die deutsche Schowprominenz in seiner Fotoagentur in Hamburg ab. Dafür sucht er einen neuen Assistenten. Wer macht die besten Fotos: Sabrina (27), Thomas (28) oder Dominique (21)?</details>
  </event>
 </service_epg>
*/
- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
	if (qName) {
		elementName = qName;
	}
	
	if ([elementName isEqualToString:@"e2event"] || [elementName isEqualToString:@"event"]) {

		// If the number of parsed services is greater than MAX_ELEMENTS, abort the parse.
		// Otherwise the application runs very slowly on the device.
		if(++parsedEventsCounter >= MAX_EVENTS)
		{
			self.currentEventObject = nil;
			self.contentOfCurrentProperty = nil;

			[parser abortParsing];
		}
		else
		{
			// An (e2)event in the xml represents an event, so create an instance of it.
			Event *newEvent = [[Event alloc] init];
			self.currentEventObject = newEvent;
			[newEvent release];
		}

		return;
	}

	if (
		/* Enigma 2 */
		/* [elementName isEqualToString:@"e2servicereference"]	// Sref
		|| [elementName isEqualToString:@"e2servicename"]		// Sname
		|| */[elementName isEqualToString:@"e2eventid"]			// Eit
		|| [elementName isEqualToString:@"e2eventstart"]		// Begin
		|| [elementName isEqualToString:@"e2eventduration"]		// Duration
		|| [elementName isEqualToString:@"e2eventtitle"]		// Title
		|| [elementName isEqualToString:@"e2eventdescription"]	// Description
		|| [elementName isEqualToString:@"e2eventdescriptionextended"]	// Extended Description
		/* Enigma 1 */
		|| [elementName isEqualToString:@"start"]			// Begin
		|| [elementName isEqualToString:@"duration"]		// Duration
		|| [elementName isEqualToString:@"description"]		// Title
		|| [elementName isEqualToString:@"details"]			// Extended Description

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

	if ([elementName isEqualToString:@"e2eventid"]) {
		self.currentEventObject.eit = self.contentOfCurrentProperty;
	} else if ([elementName isEqualToString:@"e2eventstart"] || [elementName isEqualToString:@"start"]) {
		[self.currentEventObject setBeginFromString: self.contentOfCurrentProperty];
	} else if ([elementName isEqualToString:@"e2eventduration"] || [elementName isEqualToString:@"duration"]) {
		[self.currentEventObject setEndFromDurationString: self.contentOfCurrentProperty];
	} else if ([elementName isEqualToString:@"e2eventtitle"] || [elementName isEqualToString:@"description"]) {
		self.currentEventObject.title = self.contentOfCurrentProperty;
	} else if ([elementName isEqualToString:@"e2eventdescription"]) {
		self.currentEventObject.sdescription = self.contentOfCurrentProperty;
	} else if ([elementName isEqualToString:@"e2eventdescriptionextended"] || [elementName isEqualToString:@"details"]) {
		self.currentEventObject.edescription = self.contentOfCurrentProperty;
	} else if ([elementName isEqualToString:@"e2event"] || [elementName isEqualToString:@"event"]) {
		[self.target performSelectorOnMainThread: self.addObject withObject: self.currentEventObject waitUntilDone: NO];
	}
	self.contentOfCurrentProperty = nil;
}

@end
