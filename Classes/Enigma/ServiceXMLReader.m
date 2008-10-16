//
//  ServiceXMLReader.m
//  Untitled
//
//  Created by Moritz Venn on 11.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "ServiceXMLReader.h"

static NSUInteger parsedServicesCounter;

@implementation ServiceXMLReader

@synthesize currentServiceObject = _currentServiceObject;

// Services are 'lightweight'
#define MAX_SERVICES 2048

+ (ServiceXMLReader*)initWithTarget:(id)target action:(SEL)action
{
	ServiceXMLReader *xmlReader = [[ServiceXMLReader alloc] init];
	xmlReader.target = target;
	xmlReader.addObject = action;

	return xmlReader;
}

- (void)parserDidStartDocument:(NSXMLParser *)parser
{
	parsedServicesCounter = 0;
}

/*
 Enigma2 Example:
 <?xml version="1.0" encoding="UTF-8"?>
 <e2servicelist>
  <e2service>
   <e2servicereference>1:0:1:335:9DD0:7E:820000:0:0:0:</e2servicereference>
   <e2servicename>M6 Suisse</e2servicename>
  </e2service>
 </e2servicelist>

 Enigma1 Example:
 <?xml version="1.0" encoding="UTF-8"?>
 <bouquets>
  <bouquet><reference>4097:7:0:33fc5:0:0:0:0:0:0:/var/tuxbox/config/enigma/userbouquet.33fc5.tv</reference><name>Favourites (TV)</name>
   <service><reference>1:0:1:6dca:44d:1:c00000:0:0:0:</reference><name>Das Erste</name><provider>ARD</provider><orbital_position>192</orbital_position></service>
  </bouquet>
 </bouquets>
*/
- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
	if (qName)
	{
		elementName = qName;
	}

	// If the number of parsed services is greater than MAX_ELEMENTS, abort the parse.
	// Otherwise the application runs very slowly on the device.
	if (parsedServicesCounter >= MAX_SERVICES)
	{
		self.currentServiceObject = nil;
		self.contentOfCurrentProperty = nil;

		[parser abortParsing];
	}
	
	if ([elementName isEqualToString:@"e2service"] || [elementName isEqualToString:@"service"])
	{
		parsedServicesCounter++;

		// An (e2)service in the xml represents a service, so create an instance of it.
		self.currentServiceObject = [[Service alloc] init];

		return;
	}
		
	if (
		/* Enigma 2 */
		[elementName isEqualToString:@"e2servicereference"] // Sref
		|| [elementName isEqualToString:@"e2servicename"]	// Sname
		/* Enigma 1 */
		|| [elementName isEqualToString:@"reference"]		// Sref
		|| [elementName isEqualToString:@"name"]			// Sname

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
		self.currentServiceObject.sref = self.contentOfCurrentProperty;
	} else if ([elementName isEqualToString:@"e2servicename"] || [elementName isEqualToString:@"name"]) {
		self.currentServiceObject.sname = self.contentOfCurrentProperty;
	} else if ([elementName isEqualToString:@"e2service"] || [elementName isEqualToString:@"service"]) {
		[self.target performSelectorOnMainThread: self.addObject withObject: self.currentServiceObject waitUntilDone: NO];
	}
	self.contentOfCurrentProperty = nil;
}

@end
