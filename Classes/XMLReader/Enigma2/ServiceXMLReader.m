//
//  ServiceXMLReader.m
//  dreaMote
//
//  Created by Moritz Venn on 31.12.08.
//  Copyright 2008-2010 Moritz Venn. All rights reserved.
//

#import "ServiceXMLReader.h"

#import "../../Objects/Enigma2/Service.h"
#import "../../Objects/Generic/Service.h"

#import "CXMLElement.h"

@implementation Enigma2ServiceXMLReader

/* initialize */
- (id)initWithDelegate:(NSObject<ServiceSourceDelegate> *)delegate
{
	if((self = [super init]))
	{
		_delegate = [delegate retain];
	}
	return self;
}

/* dealloc */
- (void)dealloc
{
	[_delegate release];
	[super dealloc];
}

/* send fake object */
- (void)sendErroneousObject
{
	NSObject<ServiceProtocol> *fakeService = [[GenericService alloc] init];
	fakeService.sname = NSLocalizedString(@"Error retrieving Data", @"");
	[_delegate performSelectorOnMainThread: @selector(addService:)
								withObject: fakeService
							 waitUntilDone: NO];
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
	const NSArray *resultNodes = [_parser nodesForXPath:@"/e2servicelist/e2service" error:nil];
	
	for(CXMLElement *resultElement in resultNodes)
	{
		// An e2service in the xml represents a service, so create an instance of it.
		NSObject<ServiceProtocol> *newService = [[Enigma2Service alloc] initWithNode: (CXMLNode *)resultElement];
		
		[_delegate performSelectorOnMainThread: @selector(addService:)
									withObject: newService
								 waitUntilDone: NO];
		[newService release];
	}
}

@end
