//
//  ServiceXMLReader.m
//  Untitled
//
//  Created by Moritz Venn on 11.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "ServiceXMLReader.h"

#import "../../Objects/Generic/Service.h"

#import "CXMLElement.h"

@implementation Enigma2ServiceXMLReader

// Services are 'lightweight'
#define MAX_SERVICES 2048

+ (Enigma2ServiceXMLReader*)initWithTarget:(id)target action:(SEL)action
{
	Enigma2ServiceXMLReader *xmlReader = [[Enigma2ServiceXMLReader alloc] init];
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
- (void)parseFull
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

@end
