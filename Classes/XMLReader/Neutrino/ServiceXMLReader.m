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

@implementation NeutrinoServiceXMLReader

// Services are 'lightweight'
#define MAX_SERVICES 2048

+ (NeutrinoServiceXMLReader*)initWithTarget:(id)target action:(SEL)action
{
	NeutrinoServiceXMLReader *xmlReader = [[NeutrinoServiceXMLReader alloc] init];
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
 <zapit>
 <Bouquet type="0" bouquet_id="0000" name="Hauptsender" hidden="0" locked="0">
 <channel serviceID="d175" name="ProSieben" tsid="2718" onid="f001"/>
 </Bouquet>
 </zapit>
 */
- (void)parseFull
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
