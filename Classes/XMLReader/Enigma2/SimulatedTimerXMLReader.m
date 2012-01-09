//
//  SimulatedTimerXMLReader.h
//  dreaMote
//
//  Created by Moritz Venn on 09.01.12.
//  Copyright 2012 Moritz Venn. All rights reserved.
//

#import "SimulatedTimerXMLReader.h"

#import <Constants.h>
#import <Objects/Generic/Service.h>
#import <Objects/Generic/SimulatedTimer.h>

#import "NSObject+Queue.h"

static const char *kEnigma2TimerElement = "e2simulatedtimer";
static const NSUInteger kEnigma2TimerElementLength = 17;
static const char *kEnigma2TimerName = "e2name";
static const NSUInteger kEnigma2TimerNameLength = 7;
static const char *kEnigma2TimerBegin = "e2timebegin";
static const NSUInteger kEnigma2TimerBeginLength = 12;
static const char *kEnigma2TimerEnd = "e2timeend";
static const NSUInteger kEnigma2TimerEndLength = 10;
static const char *kEnigma2AutoTimerName = "e2autotimername";
static const NSUInteger kEnigma2AutoTimerNameLength = 16;

@interface Enigma2SimulatedTimerXMLReader()
@property (nonatomic,strong) SimulatedTimer *currentTimer;
@end

@implementation Enigma2SimulatedTimerXMLReader

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
 <e2autotimersimulate api_version="1.2">
  <e2simulatedtimer>
   <e2servicereference>1:0:1:132F:3EF:1:C00000:0:0:0:</e2servicereference>
   <e2servicename>ORF1 HD</e2servicename>
   <e2name>CSI NY</e2name>
   <e2timebegin>1326136320</e2timebegin>
   <e2timeend>1326139920</e2timeend>
   <e2autotimername>CSI:NY</e2autotimername>
  </e2simulatedtimer>
 </e2autotimersimulate>
*/
- (void)elementFound:(const xmlChar *)localname prefix:(const xmlChar *)prefix uri:(const xmlChar *)URI namespaceCount:(int)namespaceCount namespaces:(const xmlChar **)namespaces attributeCount:(int)attributeCount defaultAttributeCount:(int)defaultAttributeCount attributes:(xmlSAX2Attributes *)attributes
{
	if(!strncmp((const char *)localname, kEnigma2TimerElement, kEnigma2TimerElementLength))
	{
		GenericService *service = [[GenericService alloc] init];
		self.currentTimer = [[SimulatedTimer alloc] init];
		currentTimer.service = service;
	}
	else if(	!strncmp((const char *)localname, kEnigma2Servicereference, kEnigma2ServicereferenceLength)
			||	!strncmp((const char *)localname, kEnigma2Servicename, kEnigma2ServicenameLength)
			||	!strncmp((const char *)localname, kEnigma2TimerName, kEnigma2TimerNameLength)
			||	!strncmp((const char *)localname, kEnigma2TimerBegin, kEnigma2TimerBeginLength)
			||	!strncmp((const char *)localname, kEnigma2TimerEnd, kEnigma2TimerEndLength)
			||	!strncmp((const char *)localname, kEnigma2AutoTimerName, kEnigma2AutoTimerNameLength)
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
	else if(!strncmp((const char *)localname, kEnigma2TimerName, kEnigma2TimerNameLength))
	{
		currentTimer.title = currentString;
	}
	else if(!strncmp((const char *)localname, kEnigma2TimerBegin, kEnigma2TimerBeginLength))
	{
		currentTimer.begin = [NSDate dateWithTimeIntervalSince1970:[currentString doubleValue]];
	}
	else if(!strncmp((const char *)localname, kEnigma2TimerEnd, kEnigma2TimerEndLength))
	{
		currentTimer.end = [NSDate dateWithTimeIntervalSince1970:[currentString doubleValue]];
	}
	else if(!strncmp((const char *)localname, kEnigma2AutoTimerName, kEnigma2AutoTimerNameLength))
	{
		currentTimer.autotimerName = currentString;
	}

	// this either does nothing or releases the string that was in use
	self.currentString = nil;
}

@end
