//
//  EventXMLReader.m
//  dreaMote
//
//  Created by Moritz Venn on 31.12.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "EventXMLReader.h"

#import "../../Objects/Enigma/Event.h"

@implementation EnigmaEventXMLReader

// Events are 'heavy'
#define MAX_EVENTS 100

- (void)dealloc
{
	[super dealloc];
}

- (void)sendErroneousObject
{
	EnigmaEvent *fakeObject = [[EnigmaEvent alloc] init];
	fakeObject.title = NSLocalizedString(@"Error retrieving Data", @"");
	[_target performSelectorOnMainThread: _addObject withObject: fakeObject waitUntilDone: NO];
	[fakeObject release];
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
- (void)parseFull
{
	NSArray *resultNodes = NULL;
	NSUInteger parsedEventsCounter = 0;

	resultNodes = [_parser nodesForXPath:@"/service_epg/event" error:nil];

	for (CXMLElement *resultElement in resultNodes) {
		if(++parsedEventsCounter >= MAX_EVENTS)
			break;

		// An service in the xml represents an event, so create an instance of it.
		EnigmaEvent *newEvent = [[EnigmaEvent alloc] initWithNode: (CXMLNode *)resultElement];
		
		[_target performSelectorOnMainThread: _addObject withObject: newEvent waitUntilDone: NO];
		[newEvent release];
	}
}

@end
