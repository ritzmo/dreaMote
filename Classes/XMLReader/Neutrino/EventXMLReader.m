//
//  EventXMLReader.m
//  dreaMote
//
//  Created by Moritz Venn on 31.12.08.
//  Copyright 2008-2011 Moritz Venn. All rights reserved.
//

#import "EventXMLReader.h"

#import <Objects/Generic/Event.h>
#import <Objects/Generic/Service.h>
#import <Delegates/ServiceSourceDelegate.h>

static const char *kNeutrinoEventElement = "prog";
static const NSUInteger kNeutrinoEventElementLength = 5;
static const char *kNeutrinoEventExtendedDescription = "info2";
static const NSUInteger kNeutrinoEventExtendedDescriptionLength = 6;
static const char *kNeutrinoEventDescription = "info1";
static const NSUInteger kNeutrinoEventDescriptionLength = 6;
static const char *kNeutrinoEventTitle = "description";
static const NSUInteger kNeutrinoEventTitleLength = 12;
static const char *kNeutrinoEventEnd = "stop_sec";
static const NSUInteger kNeutrinoEventEndLength = 9;
static const char *kNeutrinoEventBegin = "start_sec";
static const NSUInteger kNeutrinoEventBeginLength = 10;
static const char *kNeutrinoEventId = "eventid";
static const NSUInteger kNeutrinoEventIdLength = 8;
// service
static const char *kNeutrinoChannelId = "channel_id";
static const NSUInteger kNeutrinoChannelIdLength = 11;
static const char *kNeutrinoChannelName = "channel_name";
static const NSUInteger kNeutrinoChannelNameLength = 13;

@interface NeutrinoEventXMLReader()
@property (nonatomic, strong) NSObject<EventProtocol> *currentEvent;
@property (nonatomic, strong) NSObject<ServiceProtocol> *currentService;
@end

@implementation NeutrinoEventXMLReader

@synthesize currentEvent, currentService;

/* initialize */
- (id)initWithDelegate:(NSObject<EventSourceDelegate> *)delegate
{
	if((self = [super init]))
	{
		_delegate = delegate;
	}
	return self;
}

/* initialize */
- (id)initWithDelegate:(NSObject<EventSourceDelegate> *)delegate andGetCurrent:(BOOL)getCurrent
{
	if((self = [super init]))
	{
		_delegate = delegate;
		if(getCurrent && [delegate respondsToSelector:@selector(addService:)])
		{
			_getCurrent = [NSDate date];
		}
	}
	return self;
}

- (CXMLDocument *)parseXMLFileAtURL: (NSURL *)URL parseError: (NSError **)error
{
	_currentCounter = 2;
	return [super parseXMLFileAtURL:URL parseError:error];
}

/* send fake object */
- (void)errorLoadingDocument:(NSError *)error
{
	if(_getCurrent)
	{
		NSObject<ServiceProtocol> *fakeObject = [[GenericService alloc] init];
		fakeObject.sname = NSLocalizedString(@"Error retrieving Data", @"");
		[(NSObject<ServiceSourceDelegate> *)_delegate addService:fakeObject];
	}
	else
	{
		NSObject<EventProtocol> *fakeObject = [[GenericEvent alloc] init];
		fakeObject.title = NSLocalizedString(@"Error retrieving Data", @"");
		[(NSObject<EventSourceDelegate> *)_delegate addEvent:fakeObject];
	}
	[super errorLoadingDocument:error];
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
- (void)elementFound:(const xmlChar *)localname prefix:(const xmlChar *)prefix uri:(const xmlChar *)URI namespaceCount:(int)namespaceCount namespaces:(const xmlChar **)namespaces attributeCount:(int)attributeCount defaultAttributeCount:(int)defaultAttributeCount attributes:(xmlSAX2Attributes *)attributes
{
	if(!strncmp((const char *)localname, kNeutrinoEventElement, kNeutrinoEventElementLength))
	{
		self.currentEvent = [[GenericEvent alloc] init];
	}
	else if(	!strncmp((const char *)localname, kNeutrinoEventExtendedDescription, kNeutrinoEventExtendedDescriptionLength)
			||	!strncmp((const char *)localname, kNeutrinoEventTitle, kNeutrinoEventTitleLength)
			||	!strncmp((const char *)localname, kNeutrinoEventEnd, kNeutrinoEventEndLength)
			||	!strncmp((const char *)localname, kNeutrinoEventBegin, kNeutrinoEventBeginLength)
			||	!strncmp((const char *)localname, kNeutrinoEventDescription, kNeutrinoEventDescriptionLength)
			||	!strncmp((const char *)localname, kNeutrinoEventId, kNeutrinoEventIdLength)
			)
	{
		currentString = [[NSMutableString alloc] init];
	}
	else if(_getCurrent)
	{
		if(!strncmp((const char *)localname, kNeutrinoChannelId, kNeutrinoChannelIdLength))
		{
			self.currentService = [[GenericService alloc] init];
			currentString = [[NSMutableString alloc] init];
		}
		else if(!strncmp((const char *)localname, kNeutrinoChannelName, kNeutrinoChannelNameLength))
		{
			currentString = [[NSMutableString alloc] init];
		}
	}
}

- (void)endElement:(const xmlChar *)localname prefix:(const xmlChar *)prefix uri:(const xmlChar *)URI
{
	if(!strncmp((const char *)localname, kNeutrinoEventElement, kNeutrinoEventElementLength))
	{
		if(_getCurrent)
		{
			// already have the two events we were looking for
			if(!_currentCounter)
				return;

			// event ends in the future, decrement counter
			if([_getCurrent timeIntervalSinceDate:currentEvent.end] < 0)
			{
				--_currentCounter;
			}
			// evend ended in the past, ignore
			else
			{
				return;
			}
		}
		[_delegate performSelectorOnMainThread: @selector(addEvent:)
									withObject: currentEvent
								 waitUntilDone: NO];
	}
	else if(!strncmp((const char *)localname, kNeutrinoEventExtendedDescription, kNeutrinoEventExtendedDescriptionLength))
	{
		currentEvent.edescription = currentString;
	}
	else if(!strncmp((const char *)localname, kNeutrinoEventTitle, kNeutrinoEventTitleLength))
	{
		currentEvent.title = currentString;
	}
	else if(!strncmp((const char *)localname, kNeutrinoEventEnd, kNeutrinoEventEndLength))
	{
		[currentEvent setEnd:[NSDate dateWithTimeIntervalSince1970:[currentString doubleValue]]];
	}
	else if(!strncmp((const char *)localname, kNeutrinoEventBegin, kNeutrinoEventBeginLength))
	{
		[currentEvent setBeginFromString:currentString];
	}
	else if(!strncmp((const char *)localname, kNeutrinoEventDescription, kNeutrinoEventDescriptionLength))
	{
		currentEvent.sdescription = currentString;
	}
	else if(!strncmp((const char *)localname, kNeutrinoEventId, kNeutrinoEventIdLength))
	{
		currentEvent.eit = currentString;
	}
	else if(_getCurrent)
	{
		if(!strncmp((const char *)localname, kNeutrinoChannelId, kNeutrinoChannelIdLength))
		{
			currentService.sref = currentString;
		}
		else if(!strncmp((const char *)localname, kNeutrinoChannelName, kNeutrinoChannelNameLength))
		{
			currentService.sname = currentString;
			[_delegate performSelectorOnMainThread:@selector(addService:)
										withObject:currentService
									 waitUntilDone:NO];
			self.currentService = nil;
		}
	}

	// this either does nothing or releases the string that was in use
	self.currentString = nil;
}

@end
