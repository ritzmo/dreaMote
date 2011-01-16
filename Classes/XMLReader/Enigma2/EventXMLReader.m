//
//  EventXMLReader.m
//  dreaMote
//
//  Created by Moritz Venn on 31.12.08.
//  Copyright 2008-2011 Moritz Venn. All rights reserved.
//

#import "EventXMLReader.h"

#import "../../Objects/Generic/Event.h"
#import "../../Objects/Generic/Service.h"

static const char *kEnigma2EventElement = "e2event";
static const NSUInteger kEnigma2EventElementLength = 8;
static const char *kEnigma2EventExtendedDescription = "e2eventdescriptionextended";
static const NSUInteger kEnigma2EventExtendedDescriptionLength = 27;
static const char *kEnigma2EventDescription = "e2eventdescription";
static const NSUInteger kEnigma2EventDescriptionLength = 19;
static const char *kEnigma2EventTitle = "e2eventtitle";
static const NSUInteger kEnigma2EventTitleLength = 13;
static const char *kEnigma2EventLegacyTitle = "e2eventname";
static const NSUInteger kEnigma2EventLegacyTitleLength = 12;
static const char *kEnigma2EventDuration = "e2eventduration";
static const NSUInteger kEnigma2EventDurationLength = 16;
static const char *kEnigma2EventBegin = "e2eventstart";
static const NSUInteger kEnigma2EventBeginLength = 13;
static const char *kEnigma2EventEventId = "e2eventid";
static const NSUInteger kEnigma2EventEventIdLength = 9;
static const char *kEnigma2EventSref = "e2eventservicereference";
static const NSUInteger kEnigma2EventSrefLength = 24;
static const char *kEnigma2EventSname = "e2eventservicename";
static const NSUInteger kEnigma2EventSnameLength = 19;

@interface Enigma2EventXMLReader()
@property (nonatomic, retain) NSObject<EventProtocol> *currentEvent;
@end

@implementation Enigma2EventXMLReader

@synthesize currentEvent = _currentEvent;

/* initialize */
- (id)initWithDelegate:(NSObject<EventSourceDelegate> *)delegate
{
	if((self = [super init]))
	{
		_delegate = [delegate retain];
		_delegateSelector = @selector(addEvent:);
		_getServices = YES; // needed for similar search, we should fix that ;)
	}
	return self;
}

/* initialize */
- (id)initWithNowDelegate:(NSObject<NowSourceDelegate> *)delegate
{
	if((self = [super init]))
	{
		_delegate = [delegate retain];
		_delegateSelector = @selector(addNowEvent:);
		_getServices = YES;
	}
	return self;
}

/* initialize */
- (id)initWithNextDelegate:(NSObject<NextSourceDelegate> *)delegate
{
	if((self = [super init]))
	{
		_delegate = [delegate retain];
		_delegateSelector = @selector(addNextEvent:);
		_getServices = NO;
	}
	return self;
}

/* dealloc */
- (void)dealloc
{
	[_currentEvent release];
	[_delegate release];

	[super dealloc];
}

/* send fake object */
- (void)sendErroneousObject
{
	NSObject<EventProtocol> *fakeObject = [[GenericEvent alloc] init];
	fakeObject.title = NSLocalizedString(@"Error retrieving Data", @"");
	[_delegate performSelectorOnMainThread: _delegateSelector
								withObject: fakeObject
							 waitUntilDone: NO];
	[fakeObject release];
}

/* send terminating object */
- (void)sendTerminatingObject
{
	[_delegate performSelectorOnMainThread: _delegateSelector
								withObject: nil
							 waitUntilDone: NO];
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
- (void)elementFound:(const xmlChar *)localname prefix:(const xmlChar *)prefix uri:(const xmlChar *)URI namespaceCount:(int)namespaceCount namespaces:(const xmlChar **)namespaces attributeCount:(int)attributeCount defaultAttributeCount:(int)defaultAttributeCount attributes:(xmlSAX2Attributes *)attributes
{
	if(!strncmp((const char *)localname, kEnigma2EventElement, kEnigma2EventElementLength))
	{
		self.currentEvent = [[[GenericEvent alloc] init] autorelease];
		if(_getServices)
		{
			GenericService *service = [[GenericService alloc] init];
			self.currentEvent.service = service;
			[service release];
		}
	}
	else if(	!strncmp((const char *)localname, kEnigma2EventExtendedDescription, kEnigma2EventExtendedDescriptionLength)
			||	!strncmp((const char *)localname, kEnigma2EventDescription, kEnigma2EventDescriptionLength)
			||	!strncmp((const char *)localname, kEnigma2EventTitle, kEnigma2EventTitleLength)
			||	!strncmp((const char *)localname, kEnigma2EventLegacyTitle, kEnigma2EventLegacyTitleLength)
			||	!strncmp((const char *)localname, kEnigma2EventDuration, kEnigma2EventDurationLength)
			||	!strncmp((const char *)localname, kEnigma2EventBegin, kEnigma2EventBeginLength)
			||	!strncmp((const char *)localname, kEnigma2EventEventId, kEnigma2EventEventIdLength)
			||	(_getServices && (
					!strncmp((const char *)localname, kEnigma2EventSref, kEnigma2EventSrefLength)
				||	!strncmp((const char *)localname, kEnigma2EventSname, kEnigma2EventSnameLength)
			)	)
		)
	{
		currentString = [[NSMutableString alloc] init];
	}
}

- (void)endElement:(const xmlChar *)localname prefix:(const xmlChar *)prefix uri:(const xmlChar *)URI
{
	if([currentString isEqualToString:@"None"])
	{
		self.currentString = nil;
		return;
	}

	if(!strncmp((const char *)localname, kEnigma2EventElement, kEnigma2EventElementLength))
	{
		[_delegate performSelectorOnMainThread: _delegateSelector
									withObject: self.currentEvent
								 waitUntilDone: NO];
	}
	else if(!strncmp((const char *)localname, kEnigma2EventExtendedDescription, kEnigma2EventExtendedDescriptionLength))
	{
		_currentEvent.edescription = currentString;
	}
	else if(!strncmp((const char *)localname, kEnigma2EventDescription, kEnigma2EventDescriptionLength))
	{
		_currentEvent.sdescription = currentString;
	}
	else if(	!strncmp((const char *)localname, kEnigma2EventTitle, kEnigma2EventTitleLength)
			||	!strncmp((const char *)localname, kEnigma2EventLegacyTitle, kEnigma2EventLegacyTitleLength)
		)
	{
		_currentEvent.title = currentString;
	}
	else if(!strncmp((const char *)localname, kEnigma2EventDuration, kEnigma2EventDurationLength))
	{
		[_currentEvent setEndFromDurationString:currentString];
	}
	else if(!strncmp((const char *)localname, kEnigma2EventBegin, kEnigma2EventBeginLength))
	{
		[_currentEvent setBeginFromString:currentString];
	}
	else if(!strncmp((const char *)localname, kEnigma2EventEventId, kEnigma2EventEventIdLength))
	{
		_currentEvent.eit = currentString;
	}
	else if(_getServices)
	{
		if(!strncmp((const char *)localname, kEnigma2EventSref, kEnigma2EventSrefLength))
		{
			// if service begins with 1:64: this is a marker
			if([[currentString substringToIndex: 5] isEqualToString: @"1:64:"])
			{
				// ignore value to mark service invalid
				_currentEvent.service.sref = nil;
			}
			else
			{
				_currentEvent.service.sref = currentString;
			}
		}
		else if(!strncmp((const char *)localname, kEnigma2EventSname, kEnigma2EventSnameLength))
		{
			_currentEvent.service.sname = currentString;
		}
	}

	// this either does nothing or releases the string that was in use
	self.currentString = nil;
}

@end