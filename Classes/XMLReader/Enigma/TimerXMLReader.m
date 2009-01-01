//
//  TimerXMLReader.h
//  dreaMote
//
//  Created by Moritz Venn on 31.12.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "TimerXMLReader.h"

#import "../../Objects/Enigma/Timer.h"

@implementation EnigmaTimerXMLReader

// Timers are 'heavy'
#define MAX_TIMERS 100

- (void)dealloc
{
	[super dealloc];
}

- (void)sendErroneousObject
{
	EnigmaTimer *fakeObject = [[EnigmaTimer alloc] init];
	fakeObject.title = NSLocalizedString(@"Error retrieving Data", @"");
	fakeObject.state = 0;
	fakeObject.valid = NO;
	[_target performSelectorOnMainThread: _addObject withObject: fakeObject waitUntilDone: NO];
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
	NSUInteger parsedTimersCounter = 0;
	
	resultNodes = [_parser nodesForXPath:@"/timers/timer" error:nil];
	
	for(CXMLElement *resultElement in resultNodes)
	{
		if(++parsedTimersCounter >= MAX_TIMERS)
			break;
		
		// A timer in the xml represents a timer, so create an instance of it.
		EnigmaTimer *newTimer = [[EnigmaTimer alloc] initWithNode: (CXMLNode *)resultElement];

		[_target performSelectorOnMainThread: _addObject withObject: newTimer waitUntilDone: NO];
		[newTimer release];
	}
}

@end
