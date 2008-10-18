//
//  EventXMLReader.m
//  Untitled
//
//  Created by Moritz Venn on 11.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#ifdef ENABLE_NEUTRINO_CONNECTOR

#import "EventXMLReader.h"

#import "Event.h"

static NSUInteger parsedEventsCounter;

@implementation NeutrinoEventXMLReader

@synthesize currentEventObject = _currentEventObject;

// Events are 'heavy'
#define MAX_EVENTS 100

+ (NeutrinoEventXMLReader*)initWithTarget:(id)target action:(SEL)action
{
	NeutrinoEventXMLReader *xmlReader = [[NeutrinoEventXMLReader alloc] init];
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

/*
 Example:
 <?xml version="1.0" encoding="UTF-8"?>
 <epglist>
  <channel_id>44d00016dca</channel_id>
  <channel_name><![CDATA[Das Erste]]></channel_name>
  <prog>
   <eventid>309903955495411052</eventid>
   <eventid_hex>44d00016dcadd6c</eventid_hex>
   <start_sec>1148314800</start_sec>
   <start_t>18:20</start_t>
   <date>02.10.2006</date>
   <stop_sec>1148316600</stop_sec>
   <stop_t>18:50</stop_t>
   <duration_min>30</duration_min>
   <description><![CDATA[Marienhof]]></description>
   <info1><![CDATA[(Folge 2868)]]></info1>
   <info2><![CDATA[Sülo verachtet Constanze wegen ihrer Intrige. Luigi plündert das Konto und haut ab. Jessy will Carlos über ihre Chats aufklären.]]></info2>
  </prog>
 </epglist>
*/
- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
	if (qName) {
		elementName = qName;
	}

	if ([elementName isEqualToString:@"prog"]) {

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
			// An prog in the xml represents an event, so create an instance of it.
			self.currentEventObject = [[Event alloc] init];
		}

		return;
	}


	if (
		[elementName isEqualToString:@"eventid"]			// Eit
		|| [elementName isEqualToString:@"start_sec"]		// Begin
		|| [elementName isEqualToString:@"stop_sec"]		// End
		|| [elementName isEqualToString:@"description"]		// Title
		|| [elementName isEqualToString:@"info1"]			// Description
		|| [elementName isEqualToString:@"info2"]			// Extended Description
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

	if ([elementName isEqualToString:@"eventid"]) {
		self.currentEventObject.eit = self.contentOfCurrentProperty;
	} else if ([elementName isEqualToString:@"start_sec"]) {
		self.currentEventObject.begin = [NSDate dateWithTimeIntervalSince1970: [self.contentOfCurrentProperty doubleValue]];
	} else if ([elementName isEqualToString:@"stop_sec"]) {
		self.currentEventObject.end = [NSDate dateWithTimeIntervalSince1970: [self.contentOfCurrentProperty doubleValue]];
	} else if ([elementName isEqualToString:@"description"]) {
		self.currentEventObject.title = self.contentOfCurrentProperty;
	} else if ([elementName isEqualToString:@"info1"]) {
		self.currentEventObject.sdescription = self.contentOfCurrentProperty;
	} else if ([elementName isEqualToString:@"info2"]) {
		self.currentEventObject.edescription = self.contentOfCurrentProperty;
	} else if ([elementName isEqualToString:@"prog"]) {
		[self.target performSelectorOnMainThread: self.addObject withObject: self.currentEventObject waitUntilDone: NO];
	}
	self.contentOfCurrentProperty = nil;
}

@end

#endif