//
//  ServiceXMLReader.m
//  Untitled
//
//  Created by Moritz Venn on 23.10.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "ServiceXMLReader.h"

#import "Service.h"

static NSUInteger parsedServicesCounter;

@implementation NeutrinoServiceXMLReader

@synthesize currentServiceObject = _currentServiceObject;

// Services are 'lightweight'
#define MAX_SERVICES 2048

+ (NeutrinoServiceXMLReader*)initWithTarget:(id)target action:(SEL)action
{
	NeutrinoServiceXMLReader *xmlReader = [[NeutrinoServiceXMLReader alloc] init];
	xmlReader.target = target;
	xmlReader.addObject = action;

	return xmlReader;
}

- (void)dealloc
{
	[_currentServiceObject release];
	[super dealloc];
}

- (void)parserDidStartDocument:(NSXMLParser *)parser
{
	parsedServicesCounter = 0;
}

/*
 Example:
 <?xml version="1.0" encoding="UTF-8"?>
 <zapit>
  <Bouquet type="0" bouquet_id="0000" name="Hauptsender" hidden="0" locked="0">
   <channel serviceID="d175" name="ProSieben" tsid="2718" onid="f001"/>
  </Bouquet>
 </zapit>
*/
- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
	if (qName)
	{
		elementName = qName;
	}

	if ([elementName isEqualToString:@"channel"])
	{
		// If the number of parsed services is greater than MAX_ELEMENTS, abort the parse.
		// Otherwise the application runs very slowly on the device.
		if(++parsedServicesCounter >= MAX_SERVICES)
		{
			self.currentServiceObject = nil;
			self.contentOfCurrentProperty = nil;

			[parser abortParsing];
		}
		else
		{
			// A channel in the xml represents a service, so create an instance of it.
			Service *newService = [[Service alloc] init];
			newService.sname = [attributeDict valueForKey:@"name"];
			newService.sref = [attributeDict valueForKey:@"serviceID"];
			[self.target performSelectorOnMainThread: self.addObject withObject: newService waitUntilDone: NO];
			[newService release];
		}
	}
}

@end
