//
//  ServiceXMLReader.m
//  dreaMote
//
//  Created by Moritz Venn on 31.12.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "ServiceXMLReader.h"

#import "../../Objects/Generic/Service.h"

#import "CXMLElement.h"

@implementation EnigmaServiceXMLReader

// Services are 'lightweight'
#define MAX_SERVICES 2048

- (void)sendErroneousObject
{
	Service *fakeService = [[Service alloc] init];
	fakeService.sname = NSLocalizedString(@"Error retrieving Data", @"");
	[_target performSelectorOnMainThread: _addObject withObject: fakeService waitUntilDone: NO];
	[fakeService release];
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
- (void)parseFull
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
		
		[_target performSelectorOnMainThread: _addObject withObject: newService waitUntilDone: NO];
		[newService release];
	}
}

@end
