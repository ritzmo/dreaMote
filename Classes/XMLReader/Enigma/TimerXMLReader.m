//
//  TimerXMLReader.h
//  dreaMote
//
//  Created by Moritz Venn on 31.12.08.
//  Copyright 2008-2011 Moritz Venn. All rights reserved.
//

#import "TimerXMLReader.h"

#import <Constants.h>

#import <Objects/Enigma/Timer.h>
#import <Objects/Generic/Service.h>

#import "NSObject+Queue.h"

static const char *kEnigmaTimerElement = "timer";
static NSUInteger kEnigmaTimerElementLength = 6;
static const char *kEnigmaTimerTypedata = "typedata";
static NSUInteger kEnigmaTimerTypedataLength = 9;

@interface EnigmaTimerXMLReader()
@property (nonatomic, strong) EnigmaTimer *currentTimer;
@end

@implementation EnigmaTimerXMLReader

@synthesize currentTimer;

/* initialize */
- (id)initWithDelegate:(NSObject<TimerSourceDelegate> *)delegate
{
	if((self = [super init]))
	{
		_delegate = delegate;
		if([delegate respondsToSelector:@selector(addTimers:)])
			self.currentItems = [NSMutableArray arrayWithCapacity:kBatchDispatchItemsCount];
	}
	return self;
}

/* send fake object */
- (void)errorLoadingDocument:(NSError *)error
{
	NSObject<TimerProtocol> *fakeObject = [[GenericTimer alloc] init];
	fakeObject.title = NSLocalizedString(@"Error retrieving Data", @"");
	fakeObject.state = 0;
	fakeObject.valid = NO;
	[(NSObject<TimerSourceDelegate> *)_delegate addTimer:fakeObject];
	[super errorLoadingDocument:error];
}

- (void)finishedParsingDocument
{
	if(self.currentItems.count)
	{
		[(NSObject<TimerSourceDelegate> *)_delegate addTimers:self.currentItems];
		[self.currentItems removeAllObjects];
	}
	[super finishedParsingDocument];
}

/*
 Example:
 <?xml version="1.0" encoding="UTF-8"?>
 <timers>
  <timer>
   <type>SINGLE</type>
   <days></days>
   <action>DVR</action>
   <postaction></postaction>
   <status>FINISHED</status>
   <typedata>268</typedata>
   <service>
    <reference>1:0:1:6dca:44d:1:c00000:0:0:0:</reference>
    <name>Das Erste</name>
   </service>
   <event>
    <date>19.12.2007</date>
    <time>20:15</time>
    <start>1198091700</start>
    <duration>5400</duration>
    <description>Krauses Fest - Fernsehfilm Deutschland 2007 - Der FilmMittwoch im Ersten</description>
   </event>
  </timer>
 </timers>
*/
- (void)elementFound:(const xmlChar *)localname prefix:(const xmlChar *)prefix uri:(const xmlChar *)URI namespaceCount:(int)namespaceCount namespaces:(const xmlChar **)namespaces attributeCount:(int)attributeCount defaultAttributeCount:(int)defaultAttributeCount attributes:(xmlSAX2Attributes *)attributes
{
	if(!strncmp((const char *)localname, kEnigmaTimerElement, kEnigmaTimerElementLength))
	{
		GenericService *service = [[GenericService alloc] init];
		self.currentTimer = [[EnigmaTimer alloc] init];
		currentTimer.service = service;
	}
	else if(	!strncmp((const char *)localname, kEnigmaReference, kEnigmaReferenceLength)
			||	!strncmp((const char *)localname, kEnigmaName, kEnigmaNameLength)
			||	!strncmp((const char *)localname, kEnigmaBegin, kEnigmaBeginLength)
			||	!strncmp((const char *)localname, kEnigmaDuration, kEnigmaDurationLength)
			||	!strncmp((const char *)localname, kEnigmaDescription, kEnigmaDescriptionLength)
			||	!strncmp((const char *)localname, kEnigmaTimerTypedata, kEnigmaTimerTypedataLength))
	{
		currentString = [[NSMutableString alloc] init];
	}
}

- (void)endElement:(const xmlChar *)localname prefix:(const xmlChar *)prefix uri:(const xmlChar *)URI
{
	if(!strncmp((const char *)localname, kEnigmaTimerElement, kEnigmaTimerElementLength))
	{
		if(self.currentItems)
		{
			[self.currentItems addObject:currentTimer];
			if(self.currentItems.count >= kBatchDispatchItemsCount)
			{
				NSArray *dispatchArray = [self.currentItems copy];
				[self.currentItems removeAllObjects];
				[[_delegate queueOnMainThread] addTimers:dispatchArray];
			}
		}
		else
		{
			[(NSObject<TimerSourceDelegate> *)[_delegate queueOnMainThread] addTimer:currentTimer];
		}
	}
	else if(!strncmp((const char *)localname, kEnigmaReference, kEnigmaReferenceLength))
	{
		currentTimer.service.sref = currentString;
	}
	else if(!strncmp((const char *)localname, kEnigmaName, kEnigmaNameLength))
	{
		currentTimer.service.sname = currentString;
	}
	else if(!strncmp((const char *)localname, kEnigmaBegin, kEnigmaBeginLength))
	{
		[currentTimer setBeginFromString:currentString];
	}
	else if(!strncmp((const char *)localname, kEnigmaDuration, kEnigmaDurationLength))
	{
		[currentTimer setEndFromDurationString:currentString];
	}
	else if(!strncmp((const char *)localname, kEnigmaDescription, kEnigmaDescriptionLength))
	{
		currentTimer.title = currentString;
	}
	else if(!strncmp((const char *)localname, kEnigmaTimerTypedata, kEnigmaTimerTypedataLength))
	{
		currentTimer.typedata = [currentString integerValue];
	}
	currentString = nil;
}

@end
