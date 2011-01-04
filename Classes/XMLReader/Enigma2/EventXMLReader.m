//
//  EventXMLReader.m
//  dreaMote
//
//  Created by Moritz Venn on 31.12.08.
//  Copyright 2008-2011 Moritz Venn. All rights reserved.
//

#import "EventXMLReader.h"

#import "../../Objects/Enigma2/Event.h"
#import "../../Objects/Generic/Event.h"

@implementation Enigma2EventXMLReader

/* initialize */
- (id)initWithDelegate:(NSObject<EventSourceDelegate> *)delegate
{
	if((self = [super init]))
	{
		_delegate = [delegate retain];
	}
	return self;
}

/* dealloc */
- (void)dealloc
{
	[_delegate release];
	[super dealloc];
}

/* send fake object */
- (void)sendErroneousObject
{
	NSObject<EventProtocol> *fakeObject = [[GenericEvent alloc] init];
	fakeObject.title = NSLocalizedString(@"Error retrieving Data", @"");
	[_delegate performSelectorOnMainThread: @selector(addEvent:)
								withObject: fakeObject
							 waitUntilDone: NO];
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
	const NSArray *resultNodes = [_parser nodesForXPath:@"/e2eventlist/e2event" error:nil];

	for(CXMLElement *resultElement in resultNodes)
	{
		// An e2event in the xml represents an event, so create an instance of it.
		NSObject<EventProtocol> *newEvent = [[Enigma2Event alloc] initWithNode: (CXMLNode *)resultElement];

		[_delegate performSelectorOnMainThread: @selector(addEvent:)
									withObject: newEvent
								 waitUntilDone: NO];
		[newEvent release];
	}

	// send invalid element to indicate that we're done with parsing
	[_delegate performSelectorOnMainThread: @selector(addEvent:)
								withObject: nil
							 waitUntilDone: NO];
}

@end
