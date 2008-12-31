//
//  TimerXMLReader.h
//  Untitled
//
//  Created by Moritz Venn on 11.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "TimerXMLReader.h"

#import "../../Objects/Generic/Timer.h"

@implementation EnigmaTimerXMLReader

// Timers are 'heavy'
#define MAX_TIMERS 100

+ (EnigmaTimerXMLReader*)initWithTarget:(id)target action:(SEL)action
{
	EnigmaTimerXMLReader *xmlReader = [[EnigmaTimerXMLReader alloc] init];
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
- (void)parseFull
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

@end
