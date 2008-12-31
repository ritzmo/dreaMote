//
//  ServiceXMLReader.m
//  Untitled
//
//  Created by Moritz Venn on 11.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "ServiceXMLReader.h"

#import "Service.h"

#import "CXMLElement.h"

@implementation ServiceXMLReader

// Services are 'lightweight'
#define MAX_SERVICES 2048

+ (ServiceXMLReader*)initWithTarget:(id)target action:(SEL)action
{
	ServiceXMLReader *xmlReader = [[ServiceXMLReader alloc] init];
	xmlReader.target = target;
	xmlReader.addObject = action;

	return xmlReader;
}

- (void)sendErroneousObject
{
	Service *fakeService = [[Service alloc] init];
	fakeService.sname = NSLocalizedString(@"Error retrieving Data", @"");
	[self.target performSelectorOnMainThread: self.addObject withObject: fakeService waitUntilDone: NO];
	[fakeService release];
}

/*
 Example:
 <?xml version="1.0" encoding="UTF-8"?>
 <e2servicelist>
  <e2service>
   <e2servicereference>1:0:1:335:9DD0:7E:820000:0:0:0:</e2servicereference>
   <e2servicename>M6 Suisse</e2servicename>
  </e2service>
 </e2servicelist>
*/
- (void)parseAllEnigma2
{
	NSArray *resultNodes = NULL;
	CXMLNode *currentChild = NULL;
	NSUInteger parsedServicesCounter = 0;
	
	resultNodes = [_parser nodesForXPath:@"/e2servicelist/e2service" error:nil];
	
	for(CXMLElement *resultElement in resultNodes)
	{
		if(++parsedServicesCounter >= MAX_SERVICES)
			break;
		
		// An e2service in the xml represents a service, so create an instance of it.
		Service *newService = [[Service alloc] init];
		
		for(NSUInteger counter = 0; counter < [resultElement childCount]; ++counter)
		{
			currentChild = (CXMLNode *)[resultElement childAtIndex: counter];
			NSString *elementName = [currentChild name];
			if([elementName isEqualToString:@"e2servicereference"])
			{
				newService.sref = [currentChild stringValue];
				continue;
			}
			else if([elementName isEqualToString:@"e2servicename"])
			{
				newService.sname = [currentChild stringValue];
				continue;
			}
		}
		
		[self.target performSelectorOnMainThread: self.addObject withObject: newService waitUntilDone: NO];
		[newService release];
	}
}

/*
 Example:
 <?xml version="1.0" encoding="UTF-8"?>
 <bouquets>
  <bouquet><reference>4097:7:0:33fc5:0:0:0:0:0:0:/var/tuxbox/config/enigma/userbouquet.33fc5.tv</reference><name>Favourites (TV)</name>
   <service><reference>1:0:1:6dca:44d:1:c00000:0:0:0:</reference><name>Das Erste</name><provider>ARD</provider><orbital_position>192</orbital_position></service>
  </bouquet>
 </bouquets>
*/
- (void)parseAllEnigma1
{
	NSArray *resultNodes = NULL;
	CXMLNode *currentChild = NULL;
	NSUInteger parsedServicesCounter = 0;
	
	resultNodes = [_parser nodesForXPath:@"/bouquets/bouquet/service" error:nil];
	
	for(CXMLElement *resultElement in resultNodes)
	{
		if(++parsedServicesCounter >= MAX_SERVICES)
			break;
		
		// A service in the xml represents a service, so create an instance of it.
		Service *newService = [[Service alloc] init];
		
		for(NSUInteger counter = 0; counter < [resultElement childCount]; ++counter)
		{
			currentChild = (CXMLNode *)[resultElement childAtIndex: counter];
			NSString *elementName = [currentChild name];
			if([elementName isEqualToString:@"reference"])
			{
				newService.sref = [currentChild stringValue];
				continue;
			}
			else if([elementName isEqualToString:@"name"])
			{
				newService.sname = [currentChild stringValue];
				continue;
			}
		}
		
		[self.target performSelectorOnMainThread: self.addObject withObject: newService waitUntilDone: NO];
		[newService release];
	}
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
- (void)parseAllNeutrino
{
	NSArray *resultNodes = NULL;
	NSUInteger parsedServicesCounter = 0;
	
	resultNodes = [_parser nodesForXPath:@"/zapit/Bouquet/channel" error:nil];
	
	for(CXMLElement *resultElement in resultNodes)
	{
		if(++parsedServicesCounter >= MAX_SERVICES)
			break;
		
		// A channel in the xml represents a service, so create an instance of it.
		Service *newService = [[Service alloc] init];

		newService.sname = [[resultElement attributeForName: @"name"] stringValue];
		newService.sref = [NSString stringWithFormat: @"%@%@%@",
							[[resultElement attributeForName: @"tsid"] stringValue],
							[[resultElement attributeForName: @"onid"] stringValue],
							[[resultElement attributeForName: @"serviceID"] stringValue]];
		
		[self.target performSelectorOnMainThread: self.addObject withObject: newService waitUntilDone: NO];
		[newService release];
	}
}

@end
