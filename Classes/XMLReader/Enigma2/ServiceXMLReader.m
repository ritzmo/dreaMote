//
//  ServiceXMLReader.m
//  dreaMote
//
//  Created by Moritz Venn on 31.12.08.
//  Copyright 2008-2011 Moritz Venn. All rights reserved.
//

#import "ServiceXMLReader.h"

#import "NSObject+Queue.h"

#import "Constants.h"
#import <Objects/Generic/Service.h>

@interface Enigma2ServiceXMLReader()
@property (nonatomic, strong) NSObject<ServiceProtocol> *currentService;
@end

@implementation Enigma2ServiceXMLReader

@synthesize currentService;

/* initialize */
- (id)initWithDelegate:(NSObject<ServiceSourceDelegate> *)delegate
{
	if((self = [super init]))
	{
		_delegate = delegate;
		if([delegate respondsToSelector:@selector(addServices:)])
			self.currentItems = [NSMutableArray arrayWithCapacity:kBatchDispatchItemsCount];
	}
	return self;
}

/* send fake object */
- (void)sendErroneousObject
{
	NSObject<ServiceProtocol> *fakeService = [[GenericService alloc] init];
	fakeService.sname = NSLocalizedString(@"Error retrieving Data", @"");
	[_delegate performSelectorOnMainThread:@selector(addService:)
								withObject:fakeService
							 waitUntilDone:NO];
}

- (void)finishedParsingDocument
{
	if(self.currentItems.count)
	{
		[(NSObject<ServiceSourceDelegate> *)_delegate addServices:self.currentItems];
		[self.currentItems removeAllObjects];
	}
	[super finishedParsingDocument];
}

- (void)maybeDispatch:(NSObject<ServiceProtocol> *)service
{
	[self.currentItems addObject:service];
	if(self.currentItems.count >= kBatchDispatchItemsCount)
	{
		[(NSObject<ServiceSourceDelegate> *)_delegate addServices:self.currentItems];
		[self.currentItems removeAllObjects];
	}
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
- (void)elementFound:(const xmlChar *)localname prefix:(const xmlChar *)prefix uri:(const xmlChar *)URI namespaceCount:(int)namespaceCount namespaces:(const xmlChar **)namespaces attributeCount:(int)attributeCount defaultAttributeCount:(int)defaultAttributeCount attributes:(xmlSAX2Attributes *)attributes
{
	if(!strncmp((const char *)localname, kEnigma2ServiceElement, kEnigma2ServiceElementLength))
	{
		self.currentService = [[GenericService alloc] init];
	}
	else if(	!strncmp((const char *)localname, kEnigma2Servicereference, kEnigma2ServicereferenceLength)
			||	!strncmp((const char *)localname, kEnigma2Servicename, kEnigma2ServicenameLength)
		)
	{
		currentString = [[NSMutableString alloc] init];
	}
}

- (void)endElement:(const xmlChar *)localname prefix:(const xmlChar *)prefix uri:(const xmlChar *)URI
{
	if(!strncmp((const char *)localname, kEnigma2ServiceElement, kEnigma2ServiceElementLength))
	{
		if(self.currentItems)
		{
			[[self queueOnMainThread] maybeDispatch:currentService];
		}
		else
		{
			[[_delegate queueOnMainThread] addService:currentService];
		}
		currentService = nil;
	}
	else if(!strncmp((const char *)localname, kEnigma2Servicereference, kEnigma2ServicereferenceLength))
	{
		currentService.sref = currentString;
		// if service begins with 1:64: this is a marker and thus invalid
		if([currentString hasPrefix:@"1:64:"])
			[currentService setValid:NO];
	}
	else if(!strncmp((const char *)localname, kEnigma2Servicename, kEnigma2ServicenameLength))
	{
			currentService.sname = currentString;
	}

	// this either does nothing or releases the string that was in use
	self.currentString = nil;
}

@end
