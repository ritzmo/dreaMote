//
//  EventXMLReader.m
//  dreaMote
//
//  Created by Moritz Venn on 31.12.08.
//  Copyright 2008-2011 Moritz Venn. All rights reserved.
//

#import "EventXMLReader.h"

#import "../../Objects/Generic/Event.h"

static const char *kEnigmaEventElement = "event";
static const NSUInteger kEnigmaEventElementLength = 6;
static const char *kEnigmaEventExtendedDescription = "details";
static const NSUInteger kEnigmaEventExtendedDescriptionLength = 8;
static const char *kEnigmaEventTitle = "description";
static const NSUInteger kEnigmaEventTitleLength = 12;
static const char *kEnigmaEventDuration = "duration";
static const NSUInteger kEnigmaEventDurationLength = 9;
static const char *kEnigmaEventBegin = "start";
static const NSUInteger kEnigmaEventBeginLength = 6;

@interface EnigmaEventXMLReader()
@property (nonatomic, retain) NSObject<EventProtocol> *currentEvent;
@end

@implementation EnigmaEventXMLReader

@synthesize currentEvent;

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
	[currentEvent release];

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

- (void)sendTerminatingObject
{
	[_delegate performSelectorOnMainThread: @selector(addEvent:)
								withObject: nil
							 waitUntilDone: NO];
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
- (void)elementFound:(const xmlChar *)localname prefix:(const xmlChar *)prefix uri:(const xmlChar *)URI namespaceCount:(int)namespaceCount namespaces:(const xmlChar **)namespaces attributeCount:(int)attributeCount defaultAttributeCount:(int)defaultAttributeCount attributes:(xmlSAX2Attributes *)attributes
{
	if(!strncmp((const char *)localname, kEnigmaEventElement, kEnigmaEventElementLength))
	{
		self.currentEvent = [[[GenericEvent alloc] init] autorelease];
	}
	else if(	!strncmp((const char *)localname, kEnigmaEventExtendedDescription, kEnigmaEventExtendedDescriptionLength)
			||	!strncmp((const char *)localname, kEnigmaEventTitle, kEnigmaEventTitleLength)
			||	!strncmp((const char *)localname, kEnigmaEventDuration, kEnigmaEventDurationLength)
			||	!strncmp((const char *)localname, kEnigmaEventBegin, kEnigmaEventBeginLength)
		)
	{
		currentString = [[NSMutableString alloc] init];
	}
}

- (void)endElement:(const xmlChar *)localname prefix:(const xmlChar *)prefix uri:(const xmlChar *)URI
{
	if(!strncmp((const char *)localname, kEnigmaEventElement, kEnigmaEventElementLength))
	{
		[_delegate performSelectorOnMainThread: @selector(addEvent:)
									withObject: currentEvent
								 waitUntilDone: NO];
	}
	else if(!strncmp((const char *)localname, kEnigmaEventExtendedDescription, kEnigmaEventExtendedDescriptionLength))
	{
		currentEvent.edescription = currentString;
	}
	else if(!strncmp((const char *)localname, kEnigmaEventTitle, kEnigmaEventTitleLength))
	{
		currentEvent.title = currentString;
	}
	else if(!strncmp((const char *)localname, kEnigmaEventDuration, kEnigmaEventDurationLength))
	{
		[currentEvent setEndFromDurationString:currentString];
	}
	else if(!strncmp((const char *)localname, kEnigmaEventBegin, kEnigmaEventBeginLength))
	{
		[currentEvent setBeginFromString:currentString];
	}

	// this either does nothing or releases the string that was in use
	self.currentString = nil;
}
@end
