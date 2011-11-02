//
//  CurrentXMLReader.m
//  dreaMote
//
//  Created by Moritz Venn on 26.10.09.
//  Copyright 2009-2011 Moritz Venn. All rights reserved.
//

#import "CurrentXMLReader.h"

#import "../../Objects/Enigma2/Event.h"
#import "../../Objects/Enigma2/Service.h"
#import "../../Objects/Generic/Service.h"

@implementation Enigma2CurrentXMLReader

/* initialize */
- (id)initWithDelegate:(NSObject<EventSourceDelegate,ServiceSourceDelegate> *)delegate
{
	if((self = [super init]))
	{
		_delegate = delegate;
	}
	return self;
}

/* send fake object */
- (void)sendErroneousObject
{
	NSObject<ServiceProtocol> *fakeObject = [[GenericService alloc] init];
	fakeObject.sname = NSLocalizedString(@"Error retrieving Data", @"");
	[_delegate performSelectorOnMainThread: @selector(addService:)
								withObject: fakeObject
								waitUntilDone: NO];
}

/*
 Example:
*/
- (void)parseFull
{
	NSArray *resultNodes = [document nodesForXPath:@"/e2currentserviceinformation/e2service" error:nil];
	CXMLElement *resultElement = nil;

	for(resultElement in resultNodes)
	{
		// An e2service in the xml represents a service, so create an instance of it.
		NSObject<ServiceProtocol> *newService = [[Enigma2Service alloc] initWithNode: (CXMLNode *)resultElement];

		// *grml*
		if(newService.sname == nil || [newService.sname isEqualToString:@""])
		{
			newService = [[GenericService alloc] init];
			newService.sname = NSLocalizedString(@"Nothing playing.", @"");
		}

		[_delegate performSelectorOnMainThread: @selector(addService:)
									withObject: newService
								 waitUntilDone: NO];
	}

	resultNodes = [document nodesForXPath:@"/e2currentserviceinformation/e2eventlist/e2event" error:nil];
	for(resultElement in resultNodes)
	{
		// An e2event in the xml represents an event, so create an instance of it.
		NSObject<EventProtocol> *newEvent = [[Enigma2Event alloc] initWithNode: (CXMLNode *)resultElement];

		// Workaround unknown now/next
		NSString *title = newEvent.title;
		if(title == nil || [title isEqualToString:@""])
		{
			continue;
		}

		[_delegate performSelectorOnMainThread: @selector(addEvent:)
									withObject: newEvent
								 waitUntilDone: NO];
	}
}

@end
