//
//  TimerXMLReader.h
//  Untitled
//
//  Created by Moritz Venn on 11.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "TimerXMLReader.h"

#import "Timer.h"

@implementation TimerXMLReader

// Timers are 'heavy'
#define MAX_TIMERS 100

+ (TimerXMLReader*)initWithTarget:(id)target action:(SEL)action
{
	TimerXMLReader *xmlReader = [[TimerXMLReader alloc] init];
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
	Timer *fakeObject = [[Timer alloc] init];
	fakeObject.title = NSLocalizedString(@"Error retrieving Data", @"");
	fakeObject.state = 0;
	fakeObject.valid = NO;
	[self.target performSelectorOnMainThread: self.addObject withObject: fakeObject waitUntilDone: NO];
	[fakeObject release];
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
- (void)parseAllEnigma2
{
	NSArray *resultNodes = NULL;
	CXMLNode *currentChild = NULL;
	NSUInteger parsedTimersCounter = 0;
	
	resultNodes = [_parser nodesForXPath:@"/e2timerlist/e2timer" error:nil];
	
	for(CXMLElement *resultElement in resultNodes)
	{
		if(++parsedTimersCounter >= MAX_TIMERS)
			break;
		
		// An e2timer in the xml represents a timer, so create an instance of it.
		Timer *newTimer = [[Timer alloc] init];
		
		for(NSUInteger counter = 0; counter < [resultElement childCount]; ++counter)
		{
			currentChild = (CXMLNode *)[resultElement childAtIndex: counter];
			NSString *elementName = [currentChild name];
			if([elementName isEqualToString:@"e2servicereference"]) {
				newTimer.sref = [currentChild stringValue];
				continue;
			}
			else if([elementName isEqualToString:@"e2servicename"]) {
				newTimer.sname = [currentChild stringValue];
				continue;
			}
			else if([elementName isEqualToString:@"e2eit"]) {
				newTimer.eit = [currentChild stringValue];
				continue;
			}
			else if([elementName isEqualToString:@"e2timebegin"]) {
				[newTimer setBeginFromString: [currentChild stringValue]];
				continue;
			}
			else if ([elementName isEqualToString:@"e2timeend"]) {
				[newTimer setEndFromString: [currentChild stringValue]];
				continue;
			}
			else if ([elementName isEqualToString:@"e2name"]) {
				newTimer.title = [currentChild stringValue];
				continue;
			}
			else if ([elementName isEqualToString:@"e2description"]) {
				newTimer.tdescription = [currentChild stringValue];
				continue;
			}
			else if ([elementName isEqualToString:@"e2justplay"]) {
				newTimer.justplay = [[currentChild stringValue] isEqualToString: @"1"];
				continue;
			}
			else if ([elementName isEqualToString:@"e2repeated"]) {
				newTimer.repeated = [[currentChild stringValue] integerValue];
				continue;
			}
			else if ([elementName isEqualToString:@"e2disabled"]) {
				newTimer.disabled = [[currentChild stringValue] isEqualToString: @"1"];
				continue;
			}
			else if ([elementName isEqualToString:@"e2state"]) {
				newTimer.state = [[currentChild stringValue] integerValue];
				continue;
			}
			else if ([elementName isEqualToString:@"e2afterevent"]) {
				newTimer.afterevent = [[currentChild stringValue] integerValue];
				continue;
			}
		}
		
		[self.target performSelectorOnMainThread: self.addObject withObject: newTimer waitUntilDone: NO];
		[newTimer release];
	}
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
- (void)parseAllEnigma1
{
	NSArray *resultNodes = NULL;
	CXMLNode *currentChild = NULL;
	NSUInteger parsedTimersCounter = 0;
	
	resultNodes = [_parser nodesForXPath:@"/timers/timer" error:nil];
	
	for(CXMLElement *resultElement in resultNodes)
	{
		if(++parsedTimersCounter >= MAX_TIMERS)
			break;
		
		// A timer in the xml represents a timer, so create an instance of it.
		Timer *newTimer = [[Timer alloc] init];
		
		for(NSUInteger counter = 0; counter < [resultElement childCount]; ++counter)
		{
			currentChild = (CXMLNode *)[resultElement childAtIndex: counter];
			NSString *elementName = [currentChild name];
			if ([elementName isEqualToString:@"reference"]) {
				newTimer.sref = [currentChild stringValue];
				continue;
			}
			else if ([elementName isEqualToString:@"name"]) {
				// We have to un-escape some characters here...
				newTimer.sname = [[currentChild stringValue] stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding];
				continue;
			}
			else if ([elementName isEqualToString:@"start"]) {
				[newTimer setBeginFromString: [currentChild stringValue]];
				continue;
			}
			else if ([elementName isEqualToString:@"duration"]) {
				[newTimer setEndFromDurationString: [currentChild stringValue]];
				continue;
			}
			else if ([elementName isEqualToString:@"description"]) {
				// We have to un-escape some characters here...
				newTimer.title = [[currentChild stringValue] stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding];
				continue;
			}
			else if ([elementName isEqualToString:@"typedata"]) {
				NSInteger typeData = [[currentChild stringValue] integerValue];
				
				// We translate to Enigma2 States here
				if(typeData & stateRunning)
					newTimer.state = kTimerStateRunning;
				else if(typeData & stateFinished)
					newTimer.state = kTimerStateFinished;
				else // stateWaiting or unknown
					newTimer.state =  kTimerStateWaiting;
				
				if(typeData & doShutdown)
					newTimer.afterevent = kAfterEventStandby;
				else if(typeData & doGoSleep)
					newTimer.afterevent = kAfterEventDeepstandby;
				else
					newTimer.afterevent = kAfterEventNothing;
				
				if(typeData & SwitchTimerEntry)
					newTimer.justplay = YES;
				else // We assume RecTimerEntry here
					newTimer.justplay = NO;
				continue;
			}
		}
		
		[self.target performSelectorOnMainThread: self.addObject withObject: newTimer waitUntilDone: NO];
		[newTimer release];
	}
}

- (void)parseAllNeutrino
{
}

@end
