//
//  EventXMLReader.m
//  dreaMote
//
//  Created by Moritz Venn on 31.12.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "EventXMLReader.h"

#import "../../Objects/Enigma2/Event.h"
#import "../../Objects/Generic/Event.h"

@implementation Enigma2EventXMLReader

// Events are 'heavy'
#define MAX_EVENTS 100

- (void)sendErroneousObject
{
	Event *fakeObject = [[Event alloc] init];
	fakeObject.title = NSLocalizedString(@"Error retrieving Data", @"");
	[_target performSelectorOnMainThread: _addObject withObject: fakeObject waitUntilDone: NO];
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
- (void)parseFull
{
	NSArray *resultNodes = NULL;
	NSUInteger parsedEventsCounter = 0;

	resultNodes = [_parser nodesForXPath:@"/e2eventlist/e2event" error:nil];

	for (CXMLElement *resultElement in resultNodes) {
		if(++parsedEventsCounter >= MAX_EVENTS)
			break;

		// An e2event in the xml represents an event, so create an instance of it.
		NSObject<EventProtocol> *newEvent = [[Enigma2Event alloc] initWithNode: (CXMLNode *)resultElement];

		[_target performSelectorOnMainThread: _addObject withObject: newEvent waitUntilDone: NO];
		[newEvent release];
	}
}

@end
