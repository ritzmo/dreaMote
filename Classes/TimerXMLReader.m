// Header

#import "TimerXMLReader.h"
#import "RemoteConnector.h" // XXX: we need e1 timer enums

static NSUInteger parsedTimersCounter;

@implementation TimerXMLReader

@synthesize currentTimerObject = _currentTimerObject;

// Timers are 'heavy'
#define MAX_TIMERS 100

+ (TimerXMLReader*)initWithTarget:(id)target action:(SEL)action
{
	TimerXMLReader *xmlReader = [[TimerXMLReader alloc] init];
	xmlReader.target = target;
	xmlReader.addObject = action;

	return xmlReader;
}

- (void)parserDidStartDocument:(NSXMLParser *)parser
{
	parsedTimersCounter = 0;
}

/*
 Enigma2 Example:
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

 Enigma1 Example:
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
- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
	if (qName) {
		elementName = qName;
	}

	// If the number of parsed timers is greater than MAX_ELEMENTS, abort the parse.
	// Otherwise the application runs very slowly on the device.
	if (parsedTimersCounter >= MAX_TIMERS) {
		[parser abortParsing];
	}
	
	if ([elementName isEqualToString:@"e2timer"] || [elementName isEqualToString:@"timer"]) {
		
		parsedTimersCounter++;
		
		// An e2timer in the xml represents a timer, so create an instance of it.
		self.currentTimerObject = [[Timer alloc] init];

		// XXX: be aware of the fact the send fully parsed timers

		return;
	}

	if (
		/* Enigma 2 */
		[elementName isEqualToString:@"e2servicereference"]	// Service Reference
		|| [elementName isEqualToString:@"e2servicename"]	// Service Name
		|| [elementName isEqualToString:@"e2eit"]			// Event Eit
		|| [elementName isEqualToString:@"e2name"]			// Timer Name
		|| [elementName isEqualToString:@"e2disabled"]		// Timer xy
		|| [elementName isEqualToString:@"e2justplay"]		// Timer type (kinda)
		|| [elementName isEqualToString:@"e2repeated"]		// Timer type (still kinda)
		|| [elementName isEqualToString:@"e2afterevent"]	// AfterEvent Action
		|| [elementName isEqualToString:@"e2timebegin"]		// Timer begin
		|| [elementName isEqualToString:@"e2timeend"]		// Timer end
		|| [elementName isEqualToString:@"e2description"]	// Timer description
		|| [elementName isEqualToString:@"e2state"]			// Timer state
		/* || [elementName isEqualToString:@"e2descriptionextended"]	// Timer extended description */
		/* Enigma 1 */
		|| [elementName isEqualToString:@"reference"]		// Service Reference
        || [elementName isEqualToString:@"name"]			// Service Name
		|| [elementName isEqualToString:@"description"]		// Timer Name
		|| [elementName isEqualToString:@"start"]			// Timer begin
		|| [elementName isEqualToString:@"duration"]		// Timer duration (no end in e1)
		|| [elementName isEqualToString:@"typedata"]		// Timer type, status, etc

		) {
		// Create a mutable string to hold the contents of this element.
		// The contents are collected in parser:foundCharacters:.
		self.contentOfCurrentProperty = [NSMutableString string];

	} else {
		// The element isn't one that we care about, so set the property that holds the 
		// character content of the current element to nil. That way, in the parser:foundCharacters:
		// callback, the string that the parser reports will be ignored.
		self.contentOfCurrentProperty = nil;
	}
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{	 
	if (qName) {
		elementName = qName;
	}

	if ([elementName isEqualToString:@"e2servicereference"] || [elementName isEqualToString:@"reference"]) {
		[[self currentTimerObject] setSref: [self contentOfCurrentProperty]];
	} else if ([elementName isEqualToString:@"e2servicename"] || [elementName isEqualToString:@"name"]) {
		// XXX: this relies on sref being set before, we might wanna fix this someday
		[[self currentTimerObject] setServiceFromSname: [self contentOfCurrentProperty]];
	} else if ([elementName isEqualToString:@"e2eit"]) {
		[[self currentTimerObject] setEit: [self contentOfCurrentProperty]];
	} else if ([elementName isEqualToString:@"e2timebegin"] || [elementName isEqualToString:@"start"]) {
		[[self currentTimerObject] setBeginFromString: [self contentOfCurrentProperty]];
	} else if ([elementName isEqualToString:@"e2timeend"]) {
		[[self currentTimerObject] setEndFromString: [self contentOfCurrentProperty]];
	} else if ([elementName isEqualToString:@"duration"]) {
		 // XXX: this relies on start being set before, darn that sucks :-)
		[[self currentTimerObject] setEndFromDurationString: [self contentOfCurrentProperty]];
	} else if ([elementName isEqualToString:@"e2name"] || [elementName isEqualToString:@"description"]) {
		[[self currentTimerObject] setTitle: [self contentOfCurrentProperty]];
	} else if ([elementName isEqualToString:@"e2description"]) {
		[[self currentTimerObject] setTdescription: [self contentOfCurrentProperty]];
	} else if ([elementName isEqualToString:@"e2justplay"]) {
		[[self currentTimerObject] setJustplayFromString: [self contentOfCurrentProperty]];
	} else if ([elementName isEqualToString:@"e2repeated"]) {
		[[self currentTimerObject] setRepeatedFromString: [self contentOfCurrentProperty]];
	} else if ([elementName isEqualToString:@"e2disabled"]) {
		[[self currentTimerObject] setDisabledFromString: [self contentOfCurrentProperty]];
	} else if ([elementName isEqualToString:@"e2state"]) {
		[[self currentTimerObject] setStateFromString: [self contentOfCurrentProperty]];
	} else if ([elementName isEqualToString:@"typedata"]) {
		// TODO: see if we can extract more information
		NSInteger typeData = [[self contentOfCurrentProperty] integerValue];

		// We translate to Enigma2 States here
		if(typeData & stateRunning)
			[[self currentTimerObject] setState: kTimerStateRunning];
		else if(typeData & stateFinished)
			[[self currentTimerObject] setState: kTimerStateFinished];
		else // stateWaiting or unknown
			[[self currentTimerObject] setState: kTimerStateWaiting];

		if(typeData & doShutdown)
			[[self currentTimerObject] setAfterevent: kAfterEventStandby];
		else if(typeData & doGoSleep)
			[[self currentTimerObject] setAfterevent: kAfterEventDeepstandby];
		else
			[[self currentTimerObject] setAfterevent: kAfterEventNothing];

		if(typeData & SwitchTimerEntry)
			[[self currentTimerObject] setJustplay: YES];
		else // We assume RecTimerEntry here
			[[self currentTimerObject] setJustplay: NO];

	} else if([elementName isEqualToString:@"e2timer"] || [elementName isEqualToString:@"timer"]) {
		[self.target performSelectorOnMainThread:self.addObject withObject:self.currentTimerObject waitUntilDone:NO];
	}
	self.contentOfCurrentProperty = nil;
}

@end
