//
//  EventXMLReader.m
//  Untitled
//
//  Created by Moritz Venn on 11.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "EventXMLReader.h"

#import "Event.h"

@implementation EventXMLReader

// Events are 'heavy'
#define MAX_EVENTS 100

+ (EventXMLReader*)initWithTarget:(id)target action:(SEL)action
{
	EventXMLReader *xmlReader = [[EventXMLReader alloc] init];
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
	Event *fakeObject = [[Event alloc] init];
	fakeObject.title = NSLocalizedString(@"Error retrieving Data", @"");
	[self.target performSelectorOnMainThread: self.addObject withObject: fakeObject waitUntilDone: NO];
	[fakeObject release];
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
- (void)parseAllEnigma2
{
	NSArray *resultNodes = NULL;
	CXMLNode *currentChild = NULL;
	NSUInteger parsedEventsCounter = 0;

	resultNodes = [_parser nodesForXPath:@"/e2eventlist/e2event" error:nil];

	for (CXMLElement *resultElement in resultNodes) {
		if(++parsedEventsCounter >= MAX_EVENTS)
			break;

		// An e2event in the xml represents an event, so create an instance of it.
		Event *newEvent = [[Event alloc] init];

		for(NSUInteger counter = 0; counter < [resultElement childCount]; ++counter)
		{
			currentChild = (CXMLNode *)[resultElement childAtIndex: counter];
			NSString *elementName = [currentChild name];
			if([elementName isEqualToString:@"e2eventid"])
			{
				newEvent.eit = [currentChild stringValue];
				continue;
			}
			else if([elementName isEqualToString:@"e2eventstart"])
			{
				[newEvent setBeginFromString: [currentChild stringValue]];
				continue;
			}
			else if([elementName isEqualToString:@"e2eventduration"])
			{
				[newEvent setEndFromDurationString: [currentChild stringValue]];
				continue;
			}
			else if([elementName isEqualToString:@"e2eventtitle"])
			{
				newEvent.title = [currentChild stringValue];
				continue;
			}
			else if([elementName isEqualToString:@"e2eventdescription"])
			{
				newEvent.sdescription = [currentChild stringValue];
				continue;
			}
			else if([elementName isEqualToString:@"e2eventdescriptionextended"])
			{
				newEvent.edescription = [currentChild stringValue];
				continue;
			}
		}
		
		[self.target performSelectorOnMainThread: self.addObject withObject: newEvent waitUntilDone: NO];
		[newEvent release];
	}
}

/*
 Example:
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
- (void)parseAllEnigma1
{
	NSArray *resultNodes = NULL;
	CXMLNode *currentChild = NULL;
	NSUInteger parsedEventsCounter = 0;
	
	resultNodes = [_parser nodesForXPath:@"/service_epg/service" error:nil];
	
	for (CXMLElement *resultElement in resultNodes) {
		if(++parsedEventsCounter >= MAX_EVENTS)
			break;

		// An service in the xml represents an event, so create an instance of it.
		Event *newEvent = [[Event alloc] init];

		for(NSUInteger counter = 0; counter < [resultElement childCount]; ++counter)
		{
			currentChild = (CXMLNode *)[resultElement childAtIndex: counter];
			NSString *elementName = [currentChild name];
			if([elementName isEqualToString:@"start"])
			{
				[newEvent setBeginFromString: [currentChild stringValue]];
				continue;
			}
			else if([elementName isEqualToString:@"duration"])
			{
				[newEvent setEndFromDurationString: [currentChild stringValue]];
				continue;
			}
			else if([elementName isEqualToString:@"description"])
			{
				newEvent.title = [currentChild stringValue];
				continue;
			}
			else if([elementName isEqualToString:@"details"])
			{
				newEvent.edescription = [currentChild stringValue];
				continue;
			}
		}
		
		[self.target performSelectorOnMainThread: self.addObject withObject: newEvent waitUntilDone: NO];
		[newEvent release];
	}
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
- (void)parseAllNeutrino
{
	NSArray *resultNodes = NULL;
	CXMLNode *currentChild = NULL;
	NSUInteger parsedEventsCounter = 0;
	
	resultNodes = [_parser nodesForXPath:@"/epglist/prog" error:nil];
	
	for (CXMLElement *resultElement in resultNodes) {
		if(++parsedEventsCounter >= MAX_EVENTS)
			break;
		
		// An service in the xml represents an event, so create an instance of it.
		Event *newEvent = [[Event alloc] init];
		
		for(NSUInteger counter = 0; counter < [resultElement childCount]; ++counter)
		{
			currentChild = (CXMLNode *)[resultElement childAtIndex: counter];
			NSString *elementName = [currentChild name];
			if([elementName isEqualToString:@"eventid"])
			{
				newEvent.eit = [currentChild stringValue];
				continue;
			}
			if([elementName isEqualToString:@"start_sec"])
			{
				newEvent.begin = [NSDate dateWithTimeIntervalSince1970: [[currentChild stringValue] doubleValue]];
				continue;
			}
			else if([elementName isEqualToString:@"stop_sec"])
			{
				newEvent.end = [NSDate dateWithTimeIntervalSince1970: [[currentChild stringValue] doubleValue]];
				continue;
			}
			else if([elementName isEqualToString:@"description"])
			{
				newEvent.title = [currentChild stringValue];
				continue;
			}
			else if([elementName isEqualToString:@"info1"])
			{
				newEvent.sdescription = [currentChild stringValue];
				continue;
			}
			else if([elementName isEqualToString:@"info2"])
			{
				newEvent.edescription = [currentChild stringValue];
				continue;
			}
		}
		
		[self.target performSelectorOnMainThread: self.addObject withObject: newEvent waitUntilDone: NO];
		[newEvent release];
	}
}

@end
