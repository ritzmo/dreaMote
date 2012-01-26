//
//  TimerXMLReader.h
//  dreaMote
//
//  Created by Moritz Venn on 31.12.08.
//  Copyright 2008-2012 Moritz Venn. All rights reserved.
//

#import "TimerXMLReader.h"

#import <Constants.h>
#import <Objects/Generic/Service.h>
#import <Objects/Generic/Timer.h>

#import "NSObject+Queue.h"

static const char *kEnigma2TimerElement = "e2timer";
static const NSUInteger kEnigma2TimerElementLength = 8;
static const char *kEnigma2TimerEventId = "e2eit";
static const NSUInteger kEnigma2TimerEventIdLength = 6;
static const char *kEnigma2TimerName = "e2name";
static const NSUInteger kEnigma2TimerNameLength = 7;
static const char *kEnigma2TimerDisabled = "e2disabled";
static const NSUInteger kEnigma2TimerDisabledLength = 11;
static const char *kEnigma2TimerBegin = "e2timebegin";
static const NSUInteger kEnigma2TimerBeginLength = 12;
static const char *kEnigma2TimerEnd = "e2timeend";
static const NSUInteger kEnigma2TimerEndLength = 10;
static const char *kEnigma2TimerJustplay = "e2justplay";
static const NSUInteger kEnigma2TimerJustplayLength = 11;
static const char *kEnigma2TimerAfterEvent = "e2afterevent";
static const NSUInteger kEnigma2TimerAfterEventLength = 13;
static const char *kEnigma2TimerState = "e2state";
static const NSUInteger kEnigma2TimerStateLength = 8;
static const char *kEnigma2TimerRepeated = "e2repeated";
static const NSUInteger kEnigma2TimerRepeatedLength = 11;
static const char *kEnigma2TimerVpsEnabled = "e2vpsplugin_enabled";
static const NSUInteger kEnigma2TimerVpsEnabledLength = 20;
static const char *kEnigma2TimerVpsOverwrite = "e2vpsplugin_overwrite";
static const NSUInteger kEnigma2TimerVpsOverwriteLength = 22;
static const char *kEnigma2TimerVpsTime = "e2vpsplugin_time";
static const NSUInteger kEnigma2TimerVpsTimeLength = 17;

@interface Enigma2TimerXMLReader()
@property (nonatomic,strong) NSObject<TimerProtocol> *currentTimer;
@end

@implementation Enigma2TimerXMLReader

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
 <e2timerlist>
  <e2timer>
   <e2servicereference>1:0:1:445C:453:1:C00000:0:0:0:</e2servicereference>
   <e2servicename>SAT.1</e2servicename>
   <e2eit>48286</e2eit>
   <e2name>Numb3rs - Die Logik des Verbrechens</e2name>
   <e2description>Numb3rs - Die Logik des Verbrechens</e2description>
   <e2descriptionextended>N/A</e2descriptionextended>
   <e2disabled>0</e2disabled>
   <e2timebegin>1205093400</e2timebegin>
   <e2timeend>1205097600</e2timeend>
   <e2duration>4200</e2duration>
   <e2startprepare>1205093380</e2startprepare>
   <e2justplay>0</e2justplay>
   <e2afterevent>0</e2afterevent>
   <e2logentries></e2logentries>
   <e2filename></e2filename>
   <e2backoff>0</e2backoff>
   <e2nextactivation></e2nextactivation>
   <e2firsttryprepare>True</e2firsttryprepare>
   <e2state>0</e2state>
   <e2repeated>0</e2repeated>
   <e2dontsave>0</e2dontsave>
   <e2cancled>False</e2cancled>
   <e2color>000000</e2color>
   <e2toggledisabled>1</e2toggledisabled>
   <e2toggledisabledimg>off</e2toggledisabledimg>
  </e2timer>
 </e2timerlist>
*/
- (void)elementFound:(const xmlChar *)localname prefix:(const xmlChar *)prefix uri:(const xmlChar *)URI namespaceCount:(int)namespaceCount namespaces:(const xmlChar **)namespaces attributeCount:(int)attributeCount defaultAttributeCount:(int)defaultAttributeCount attributes:(xmlSAX2Attributes *)attributes
{
	if(!strncmp((const char *)localname, kEnigma2TimerElement, kEnigma2TimerElementLength))
	{
		GenericService *service = [[GenericService alloc] init];
		self.currentTimer = [[GenericTimer alloc] init];
		currentTimer.service = service;
	}
	else if(	!strncmp((const char *)localname, kEnigma2Servicereference, kEnigma2ServicereferenceLength)
			||	!strncmp((const char *)localname, kEnigma2Servicename, kEnigma2ServicenameLength)
			||	!strncmp((const char *)localname, kEnigma2TimerEventId, kEnigma2TimerEventIdLength)
			||	!strncmp((const char *)localname, kEnigma2TimerName, kEnigma2TimerNameLength)
			||	!strncmp((const char *)localname, kEnigma2Description, kEnigma2DescriptionLength)
#if 0
			||	!strncmp((const char *)localname, kEnigma2DescriptionExtended, kEnigma2DescriptionExtendedLength)
#endif
			||	!strncmp((const char *)localname, kEnigma2TimerDisabled, kEnigma2TimerDisabledLength)
			||	!strncmp((const char *)localname, kEnigma2TimerBegin, kEnigma2TimerBeginLength)
			||	!strncmp((const char *)localname, kEnigma2TimerEnd, kEnigma2TimerEndLength)
			||	!strncmp((const char *)localname, kEnigma2TimerJustplay, kEnigma2TimerJustplayLength)
			||	!strncmp((const char *)localname, kEnigma2TimerAfterEvent, kEnigma2TimerAfterEventLength)
			||	!strncmp((const char *)localname, kEnigma2TimerState, kEnigma2TimerStateLength)
			||	!strncmp((const char *)localname, kEnigma2TimerRepeated, kEnigma2TimerRepeatedLength)
			||	!strncmp((const char *)localname, kEnigma2Location, kEnigma2LocationLength)
			||	!strncmp((const char *)localname, kEnigma2Tags, kEnigma2TagsLength)
			||	!strncmp((const char *)localname, kEnigma2TimerVpsEnabled, kEnigma2TimerVpsEnabledLength)
			||	!strncmp((const char *)localname, kEnigma2TimerVpsOverwrite, kEnigma2TimerVpsOverwriteLength)
			||	!strncmp((const char *)localname, kEnigma2TimerVpsTime, kEnigma2TimerVpsTimeLength)
		)
	{
		currentString = [[NSMutableString alloc] init];
	}
}

- (void)endElement:(const xmlChar *)localname prefix:(const xmlChar *)prefix uri:(const xmlChar *)URI
{
	if(!strncmp((const char *)localname, kEnigma2TimerElement, kEnigma2TimerElementLength))
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
	else if(!strncmp((const char *)localname, kEnigma2Servicereference, kEnigma2ServicereferenceLength))
	{
		currentTimer.service.sref = currentString;
	}
	else if(!strncmp((const char *)localname, kEnigma2Servicename, kEnigma2ServicenameLength))
	{
		currentTimer.service.sname = currentString;
	}
	else if(!strncmp((const char *)localname, kEnigma2TimerEventId, kEnigma2TimerEventIdLength))
	{
		currentTimer.eit = currentString;
	}
	else if(!strncmp((const char *)localname, kEnigma2TimerName, kEnigma2TimerNameLength))
	{
		currentTimer.title = currentString;
	}
	else if(!strncmp((const char *)localname, kEnigma2Description, kEnigma2DescriptionLength))
	{
		currentTimer.tdescription = currentString;
	}
#if 0
	else if(!strncmp((const char *)localname, kEnigma2DescriptionExtended, kEnigma2DescriptionExtendedLength))
	{
		currentTimer.edescription = currentString;
	}
#endif
	else if(!strncmp((const char *)localname, kEnigma2TimerDisabled, kEnigma2TimerDisabledLength))
	{
		currentTimer.disabled = [currentString isEqualToString:@"1"];
	}
	else if(!strncmp((const char *)localname, kEnigma2TimerBegin, kEnigma2TimerBeginLength))
	{
		currentTimer.begin = [NSDate dateWithTimeIntervalSince1970: [currentString doubleValue]];
	}
	else if(!strncmp((const char *)localname, kEnigma2TimerEnd, kEnigma2TimerEndLength))
	{
		currentTimer.end = [NSDate dateWithTimeIntervalSince1970: [currentString doubleValue]];
	}
	else if(!strncmp((const char *)localname, kEnigma2TimerJustplay, kEnigma2TimerJustplayLength))
	{
		currentTimer.justplay = [currentString isEqualToString:@"1"];
	}
	else if(!strncmp((const char *)localname, kEnigma2TimerAfterEvent, kEnigma2TimerAfterEventLength))
	{
		currentTimer.afterevent = [currentString integerValue];
	}
	else if(!strncmp((const char *)localname, kEnigma2TimerState, kEnigma2TimerStateLength))
	{
		currentTimer.state = [currentString integerValue];
	}
	else if(!strncmp((const char *)localname, kEnigma2TimerRepeated, kEnigma2TimerRepeatedLength))
	{
		currentTimer.repeated = [currentString integerValue];
	}
	else if(!strncmp((const char *)localname, kEnigma2Location, kEnigma2LocationLength))
	{
		if(![currentString isEqualToString:@"None"])
			currentTimer.location = currentString;
	}
	else if(!strncmp((const char *)localname, kEnigma2Tags, kEnigma2TagsLength))
	{
		[currentTimer setTagsFromString:currentString];
	}
	else if(!strncmp((const char *)localname, kEnigma2TimerVpsEnabled, kEnigma2TimerVpsEnabledLength))
	{
		if([currentString isEqualToString:@"True"])
			currentTimer.vpsplugin_enabled = YES;
	}
	else if(!strncmp((const char *)localname, kEnigma2TimerVpsOverwrite, kEnigma2TimerVpsOverwriteLength))
	{
		if([currentString isEqualToString:@"True"])
			currentTimer.vpsplugin_overwrite = YES;
	}
	else if(!strncmp((const char *)localname, kEnigma2TimerVpsTime, kEnigma2TimerVpsTimeLength))
	{
		NSTimeInterval time = [currentString doubleValue];
		if(time <= 0)
			time = -1;
		currentTimer.vpsplugin_time = time;
	}

	// this either does nothing or releases the string that was in use
	self.currentString = nil;
}

@end
