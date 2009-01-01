//
//  EventXMLReader.m
//  dreaMote
//
//  Created by Moritz Venn on 31.12.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "EventXMLReader.h"

#import "../../Objects/Neutrino/Event.h"

@implementation NeutrinoEventXMLReader

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
	[super dealloc];
}

- (void)sendErroneousObject
{
	NSObject<EventProtocol> *fakeObject = [[NeutrinoEvent alloc] init];
	fakeObject.title = NSLocalizedString(@"Error retrieving Data", @"");
	[self.target performSelectorOnMainThread: self.addObject withObject: fakeObject waitUntilDone: NO];
	[fakeObject release];
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
- (void)parseFull
{
	NSArray *resultNodes = NULL;
	NSUInteger parsedEventsCounter = 0;
	
	resultNodes = [_parser nodesForXPath:@"/epglist/prog" error:nil];
	
	for (CXMLElement *resultElement in resultNodes) {
		if(++parsedEventsCounter >= MAX_EVENTS)
			break;
		
		// A prog in the xml represents an event, so create an instance of it.
		NSObject<EventProtocol> *newEvent = [[NeutrinoEvent alloc] initWithNode:(CXMLNode *)resultElement];

		[self.target performSelectorOnMainThread: self.addObject withObject: newEvent waitUntilDone: NO];
		[newEvent release];
	}
}

@end
