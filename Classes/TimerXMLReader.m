// Header

#import "TimerXMLReader.h"

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
	
	if ([elementName isEqualToString:@"e2timer"]) {
		
		parsedTimersCounter++;
		
		// An e2timer in the xml represents a timer, so create an instance of it.
		self.currentTimerObject = [[Timer alloc] init];

		// XXX: be aware of the fact the send fully parsed timers

		return;
	}

	if ([elementName isEqualToString:@"e2servicereference"]) {
		// Create a mutable string to hold the contents of the 'e2servicereference' element.
		// The contents are collected in parser:foundCharacters:.
		self.contentOfCurrentProperty = [NSMutableString string];

	} else if ([elementName isEqualToString:@"e2servicename"]) {
		// Create a mutable string to hold the contents of the 'e2servicename' element.
		// The contents are collected in parser:foundCharacters:.
		self.contentOfCurrentProperty = [NSMutableString string];

	} else if ([elementName isEqualToString:@"e2eit"]) {
		// Create a mutable string to hold the contents of the 'e2eit' element.
		// The contents are collected in parser:foundCharacters:.
		self.contentOfCurrentProperty = [NSMutableString string];

	} else if ([elementName isEqualToString:@"e2name"]) {
		// Create a mutable string to hold the contents of the 'e2name' element.
		// The contents are collected in parser:foundCharacters:.
		self.contentOfCurrentProperty = [NSMutableString string];

	} else if ([elementName isEqualToString:@"e2disabled"]) {
		// Create a mutable string to hold the contents of the 'e2disabled' element.
		// The contents are collected in parser:foundCharacters:.
		self.contentOfCurrentProperty = [NSMutableString string];

	} else if ([elementName isEqualToString:@"e2justplay"]) {
		// Create a mutable string to hold the contents of the 'e2justplay' element.
		// The contents are collected in parser:foundCharacters:.
		self.contentOfCurrentProperty = [NSMutableString string];
		
	} else if ([elementName isEqualToString:@"e2repeated"]) {
		// Create a mutable string to hold the contents of the 'e2repeated' element.
		// The contents are collected in parser:foundCharacters:.
		self.contentOfCurrentProperty = [NSMutableString string];
		
	}/* else if ([elementName isEqualToString:@"e2afterevent"]) {
		// Create a mutable string to hold the contents of the 'e2afterevent' element.
		// The contents are collected in parser:foundCharacters:.
		self.contentOfCurrentProperty = [NSMutableString string];
		
	}*/ else if ([elementName isEqualToString:@"e2timebegin"]) {
		// Create a mutable string to hold the contents of the 'e2timebegin' element.
		// The contents are collected in parser:foundCharacters:.
		self.contentOfCurrentProperty = [NSMutableString string];
		
	} else if ([elementName isEqualToString:@"e2timeend"]) {
		// Create a mutable string to hold the contents of the 'e2timeend' element.
		// The contents are collected in parser:foundCharacters:.
		self.contentOfCurrentProperty = [NSMutableString string];
		
	} else if ([elementName isEqualToString:@"e2description"]) {
		// Create a mutable string to hold the contents of the 'e2description' element.
		// The contents are collected in parser:foundCharacters:.
		self.contentOfCurrentProperty = [NSMutableString string];

	} else if ([elementName isEqualToString:@"e2state"]) {
		// Create a mutable string to hold the contents of the 'e2state' element.
		// The contents are collected in parser:foundCharacters:.
		self.contentOfCurrentProperty = [NSMutableString string];
		
	}/* else if ([elementName isEqualToString:@"e2descriptionextended"]) {
		// Create a mutable string to hold the contents of the 'e2descriptionextended' element.
		// The contents are collected in parser:foundCharacters:.
		self.contentOfCurrentProperty = [NSMutableString string];

	}*/ else {
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

	if ([elementName isEqualToString:@"e2servicereference"]) {
		[[self currentTimerObject] setSref: [self contentOfCurrentProperty]];
	} else if ([elementName isEqualToString:@"e2servicename"]) {
		// XXX: this relies on sref being set before, we might wanna fix this someday
		[[self currentTimerObject] setServiceFromSname: [self contentOfCurrentProperty]];
	} else if ([elementName isEqualToString:@"e2eit"]) {
		[[self currentTimerObject] setEit: [self contentOfCurrentProperty]];
	} else if ([elementName isEqualToString:@"e2timebegin"]) {
		[[self currentTimerObject] setBeginFromString: [self contentOfCurrentProperty]];
	} else if ([elementName isEqualToString:@"e2timeend"]) {
		[[self currentTimerObject] setEndFromString: [self contentOfCurrentProperty]];
	} else if ([elementName isEqualToString:@"e2name"]) {
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
	} else if([elementName isEqualToString:@"e2timer"]) {
		[self.target performSelectorOnMainThread:self.addObject withObject:self.currentTimerObject waitUntilDone:NO];
	}
	self.contentOfCurrentProperty = nil;
}

@end
