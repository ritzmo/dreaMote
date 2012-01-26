//
//  EventXMLReader.m
//  dreaMote
//
//  Created by Moritz Venn on 31.12.08.
//  Copyright 2008-2012 Moritz Venn. All rights reserved.
//

#import "EventXMLReader.h"

#import <Constants.h>
#import <Objects/Generic/Event.h>

#import "NSObject+Queue.h"

static const char *kEnigmaEventElement = "event";
static const NSUInteger kEnigmaEventElementLength = 6;
static const char *kEnigmaEventExtendedDescription = "details";
static const NSUInteger kEnigmaEventExtendedDescriptionLength = 8;

@interface EnigmaEventXMLReader()
@property (nonatomic, strong) NSObject<EventProtocol> *currentEvent;
@end

@implementation EnigmaEventXMLReader

@synthesize currentEvent;

/* initialize */
- (id)initWithDelegate:(NSObject<EventSourceDelegate> *)delegate
{
	if((self = [super init]))
	{
		_delegate = delegate;
		if([delegate respondsToSelector:@selector(addEvents:)])
			self.currentItems = [NSMutableArray arrayWithCapacity:kBatchDispatchItemsCount];
	}
	return self;
}

/* send fake object */
- (void)errorLoadingDocument:(NSError *)error
{
	NSObject<EventProtocol> *fakeObject = [[GenericEvent alloc] init];
	fakeObject.title = NSLocalizedString(@"Error retrieving Data", @"");
	[(NSObject<EventSourceDelegate> *)_delegate addEvent:fakeObject];
	[super errorLoadingDocument:error];
}

- (void)finishedParsingDocument
{
	if(self.currentItems.count)
	{
		[(NSObject<EventSourceDelegate> *)_delegate addEvents:self.currentItems];
		[self.currentItems removeAllObjects];
	}
	[super finishedParsingDocument];
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
		self.currentEvent = [[GenericEvent alloc] init];
	}
	else if(	!strncmp((const char *)localname, kEnigmaEventExtendedDescription, kEnigmaEventExtendedDescriptionLength)
			||	!strncmp((const char *)localname, kEnigmaDescription, kEnigmaDescriptionLength)
			||	!strncmp((const char *)localname, kEnigmaDuration, kEnigmaDurationLength)
			||	!strncmp((const char *)localname, kEnigmaBegin, kEnigmaBeginLength)
		)
	{
		currentString = [[NSMutableString alloc] init];
	}
}

- (void)endElement:(const xmlChar *)localname prefix:(const xmlChar *)prefix uri:(const xmlChar *)URI
{
	if(!strncmp((const char *)localname, kEnigmaEventElement, kEnigmaEventElementLength))
	{
		if(self.currentItems)
		{
			[self.currentItems addObject:currentEvent];
			if(self.currentItems.count > kBatchDispatchItemsCount)
			{
				NSArray *dispatchArray = [self.currentItems copy];
				[self.currentItems removeAllObjects];
				[[_delegate queueOnMainThread] addEvents:dispatchArray];
			}
		}
		else
			[_delegate performSelectorOnMainThread:@selector(addEvent:)
										withObject:currentEvent
									 waitUntilDone:NO];
	}
	else if(!strncmp((const char *)localname, kEnigmaEventExtendedDescription, kEnigmaEventExtendedDescriptionLength))
	{
		currentEvent.edescription = currentString;
	}
	else if(!strncmp((const char *)localname, kEnigmaDescription, kEnigmaDescriptionLength))
	{
		currentEvent.title = currentString;
	}
	else if(!strncmp((const char *)localname, kEnigmaDuration, kEnigmaDurationLength))
	{
		[currentEvent setEndFromDurationString:currentString];
	}
	else if(!strncmp((const char *)localname, kEnigmaBegin, kEnigmaBeginLength))
	{
		[currentEvent setBeginFromString:currentString];
	}

	// this either does nothing or releases the string that was in use
	self.currentString = nil;
}
@end
