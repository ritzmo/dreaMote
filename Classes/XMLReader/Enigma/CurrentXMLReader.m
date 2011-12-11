//
//  CurrentXMLReader.m
//  dreaMote
//
//  Created by Moritz Venn on 26.10.09.
//  Copyright 2009-2011 Moritz Venn. All rights reserved.
//

#import "CurrentXMLReader.h"

#import <Constants.h>

#import <Objects/Generic/Event.h>
#import <Objects/Generic/Service.h>

#import <XMLReader/Enigma/EventXMLReader.h>

static const char *kEnigmaServiceElement = "service";
static NSUInteger kEnigmaServiceElementLength = 8;
static const char *kEnigmaCurrentEvent = "current_event";
static NSUInteger kEnigmaCurrentEventLength = 14;
static const char *kEnigmaNextEvent = "next_event";
static NSUInteger kEnigmaNextEventLength = 11;

typedef enum
{
	CONTEXT_UNK,
	CONTEXT_SERVICE,
	CONTEXT_EVENT
} currentContext_t;

@interface SaxXmlReader()
- (void)charactersFound:(const xmlChar *)characters length:(int)length;
@end

@interface EnigmaEventXMLReader()
@property (nonatomic, strong) NSObject<EventProtocol> *currentEvent;
@end

@interface EnigmaCurrentXMLReader()
@property (nonatomic, assign) currentContext_t context;
@property (nonatomic, strong) GenericService *currentService;
@property (nonatomic, strong) EnigmaEventXMLReader *ereader;
@end

@implementation EnigmaCurrentXMLReader

@synthesize context, currentService, ereader;

/* initialize */
- (id)initWithDelegate:(NSObject<EventSourceDelegate,ServiceSourceDelegate> *)delegate
{
	if((self = [super init]))
	{
		_delegate = delegate;
	}
	return self;
}

/* send fake object */
- (void)errorLoadingDocument:(NSError *)error
{
	NSObject<ServiceProtocol> *fakeObject = [[GenericService alloc] init];
	fakeObject.sname = NSLocalizedString(@"Error retrieving Data", @"");
	[(NSObject<ServiceSourceDelegate> *)_delegate addService:fakeObject];
	[super errorLoadingDocument:error];
}

- (BOOL)parseXMLFileAtURL:(NSURL *)URL parseError:(NSError **)error
{
	ereader = [[EnigmaEventXMLReader alloc] initWithDelegate:nil];
	const BOOL retVal = [super parseXMLFileAtURL:URL parseError:error];
	ereader = nil;
	return retVal;
}

/*
 Example:
 */
- (void)elementFound:(const xmlChar *)localname prefix:(const xmlChar *)prefix uri:(const xmlChar *)URI namespaceCount:(int)namespaceCount namespaces:(const xmlChar **)namespaces attributeCount:(int)attributeCount defaultAttributeCount:(int)defaultAttributeCount attributes:(xmlSAX2Attributes *)attributes
{
	if(context == CONTEXT_SERVICE)
	{
		if(		!strncmp((const char *)localname, kEnigmaName, kEnigmaNameLength)
		   ||	!strncmp((const char *)localname, kEnigmaReference, kEnigmaReferenceLength))
		{
			currentString = [[NSMutableString alloc] init];
		}
	}
	else if(context == CONTEXT_EVENT)
	{
		[ereader elementFound:localname prefix:prefix uri:URI namespaceCount:namespaceCount namespaces:namespaces attributeCount:attributeCount defaultAttributeCount:defaultAttributeCount attributes:attributes];
	}
	else if(!strncmp((const char *)localname, kEnigmaServiceElement, kEnigmaServiceElementLength))
	{
		context = CONTEXT_SERVICE;
		currentService = [[GenericService alloc] init];
	}
	else if(	!strncmp((const char *)localname, kEnigmaCurrentEvent, kEnigmaCurrentEventLength)
			||	!strncmp((const char *)localname, kEnigmaNextEvent, kEnigmaNextEventLength))
	{
		context = CONTEXT_EVENT;
	}
}

- (void)endElement:(const xmlChar *)localname prefix:(const xmlChar *)prefix uri:(const xmlChar *)URI
{
	if(context == CONTEXT_SERVICE)
	{
		if(!strncmp((const char *)localname, kEnigmaServiceElement, kEnigmaServiceElementLength))
		{
			context = CONTEXT_UNK;
		}
		else if(!strncmp((const char *)localname, kEnigmaName, kEnigmaNameLength))
		{
			currentService.sname = currentString;
		}
		else if(!strncmp((const char *)localname, kEnigmaReference, kEnigmaReferenceLength))
		{
			currentService.sref = currentString;
		}
	}
	else if(context == CONTEXT_EVENT)
	{
		if(!strncmp((const char *)localname, kEnigmaCurrentEvent, kEnigmaCurrentEventLength))
		{
			NSObject<EventProtocol> *currentEvent = ereader.currentEvent;
			if(!currentEvent.title || [currentEvent.title isEqualToString:@""])
				currentEvent = nil;

			if(currentService.sname == nil || [currentService.sname isEqualToString:@""])
			{
				// NOTE: fall back to current event title because it looks weird for
				// recordings otherwise, but if we are playing a recording back
				// we won't be able to distinguish between standby and running...
				if(currentEvent)
				{
					currentService.sname = currentEvent.title;
				}
				else
				{
					currentService.sname = NSLocalizedString(@"Nothing playing.", @"");
				}
			}

			context = CONTEXT_UNK;
			[_delegate performSelectorOnMainThread:@selector(addService:)
										withObject:currentService
									 waitUntilDone:NO];

			if(currentEvent)
				[_delegate performSelectorOnMainThread:@selector(addEvent:)
											withObject:currentEvent
										 waitUntilDone:NO];
		}
		if(!strncmp((const char *)localname, kEnigmaNextEvent, kEnigmaNextEventLength))
		{
			NSObject<EventProtocol> *currentEvent = ereader.currentEvent;
			if(!currentEvent.title || [currentEvent.title isEqualToString:@""])
				return;

			context = CONTEXT_UNK;
			[_delegate performSelectorOnMainThread:@selector(addEvent:)
										withObject:currentEvent
									 waitUntilDone:NO];
		}
		else
		{
			[ereader endElement:localname prefix:prefix uri:URI];
		}
	}
	currentString = nil;
}

- (void)charactersFound:(const xmlChar *)characters length:(int)length
{
	[ereader charactersFound:characters length:length];
	[super charactersFound:characters length:length];
}

@end
