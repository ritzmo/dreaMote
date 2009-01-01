//
//  ServiceXMLReader.m
//  dreaMote
//
//  Created by Moritz Venn on 31.12.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "ServiceXMLReader.h"

#import "../../Objects/Enigma2/Service.h"
#import "../../Objects/Generic/Service.h"

#import "CXMLElement.h"

@implementation Enigma2ServiceXMLReader

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
 <e2servicelist>
  <e2service>
   <e2servicereference>1:0:1:335:9DD0:7E:820000:0:0:0:</e2servicereference>
   <e2servicename>M6 Suisse</e2servicename>
  </e2service>
 </e2servicelist>
*/
- (void)parseFull
{
	NSArray *resultNodes = NULL;
	NSUInteger parsedServicesCounter = 0;
	
	resultNodes = [_parser nodesForXPath:@"/e2servicelist/e2service" error:nil];
	
	for(CXMLElement *resultElement in resultNodes)
	{
		if(++parsedServicesCounter >= MAX_SERVICES)
			break;
		
		// An e2service in the xml represents a service, so create an instance of it.
		Enigma2Service *newService = [[Enigma2Service alloc] initWithNode: (CXMLNode *)resultElement];
		
		[_target performSelectorOnMainThread: _addObject withObject: newService waitUntilDone: NO];
		[newService release];
	}
}

@end
