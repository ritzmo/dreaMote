//
//  SleepTimerXMLReader.m
//  dreaMote
//
//  Created by Moritz Venn on 02.06.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import "SleepTimerXMLReader.h"

#import "Constants.h"
#import "../../Objects/Generic/SleepTimer.h"

static const char *kEnigma2SleepTimerElement = "e2sleeptimer";
static const NSUInteger kEnigma2SleepTimerElementLength = 13;
static const char *kEnigma2EnabledElement = "e2enabled";
static const NSUInteger kEnigma2EnabledElementLength = 10;
static const char *kEnigma2MinutesElement = "e2minutes";
static const NSUInteger kEnigma2MinutesElementLength = 10;
static const char *kEnigma2ActionElement = "e2action";
static const NSUInteger kEnigma2ActionElementLength = 9;
static const char *kEnigma2TextElement = "e2text";
static const NSUInteger kEnigma2TextElementLength = 7;

@interface Enigma2SleepTimerXMLReader()
@property (nonatomic, strong) SleepTimer *sleepTimer;
@end

@implementation Enigma2SleepTimerXMLReader

@synthesize sleepTimer;

/* initialize */
- (id)initWithDelegate:(NSObject<SleepTimerSourceDelegate> *)delegate
{
	if((self = [super init]))
	{
		_delegate = delegate;
	}
	return self;
}

/* send fake object */
- (void)sendErroneousObject
{
	SleepTimer *fake = [[SleepTimer alloc] init];
	fake.valid = NO;
	fake.text = NSLocalizedString(@"Error retrieving Data", @"");
	[_delegate performSelectorOnMainThread:@selector(addSleepTimer:)
								withObject:fake
							 waitUntilDone:NO];
}

/*
 Example:
 <?xml version="1.0" encoding="UTF-8"?> 
 <e2sleeptimer> 
  <e2enabled>False</e2enabled> 
  <e2minutes>45</e2minutes> 
  <e2action>shutdown</e2action> 
  <e2text>Sleeptimer is disabled</e2text>	
 </e2sleeptimer> 
*/
- (void)elementFound:(const xmlChar *)localname prefix:(const xmlChar *)prefix uri:(const xmlChar *)URI namespaceCount:(int)namespaceCount namespaces:(const xmlChar **)namespaces attributeCount:(int)attributeCount defaultAttributeCount:(int)defaultAttributeCount attributes:(xmlSAX2Attributes *)attributes
{
	if(!strncmp((const char *)localname, kEnigma2SleepTimerElement, kEnigma2SleepTimerElementLength))
	{
		self.sleepTimer = [[SleepTimer alloc] init];
	}
	else if(	!strncmp((const char *)localname, kEnigma2EnabledElement, kEnigma2EnabledElementLength)
			||	!strncmp((const char *)localname, kEnigma2MinutesElement, kEnigma2MinutesElementLength)
			||	!strncmp((const char *)localname, kEnigma2ActionElement, kEnigma2ActionElementLength)
			||	!strncmp((const char *)localname, kEnigma2TextElement, kEnigma2TextElementLength)
		)
	{
		currentString = [[NSMutableString alloc] init];
	}
}

- (void)endElement:(const xmlChar *)localname prefix:(const xmlChar *)prefix uri:(const xmlChar *)URI
{
	if(!strncmp((const char *)localname, kEnigma2SleepTimerElement, kEnigma2SleepTimerElementLength))
	{
		[_delegate performSelectorOnMainThread:@selector(addSleepTimer:)
									withObject:sleepTimer
								 waitUntilDone:NO];
	}
	else if(!strncmp((const char *)localname, kEnigma2EnabledElement, kEnigma2EnabledElementLength))
	{
		sleepTimer.enabled = [currentString boolValue];
	}
	else if(!strncmp((const char *)localname, kEnigma2MinutesElement, kEnigma2MinutesElementLength))
	{
		sleepTimer.time = [currentString integerValue];
	}
	else if(!strncmp((const char *)localname, kEnigma2ActionElement, kEnigma2ActionElementLength))
	{
		if([currentString isEqualToString:@"shutdown"])
			sleepTimer.action = sleeptimerShutdown;
		else
			sleepTimer.action = sleeptimerStandby;
	}
	else if(!strncmp((const char *)localname, kEnigma2TextElement, kEnigma2TextElementLength))
	{
		sleepTimer.text = currentString;
	}

	// this either does nothing or releases the string that was in use
	self.currentString = nil;
}

@end
