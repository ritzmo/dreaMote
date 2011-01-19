//
//  ServiceXMLReader.m
//  dreaMote
//
//  Created by Moritz Venn on 31.12.08.
//  Copyright 2008-2011 Moritz Venn. All rights reserved.
//

#import "ServiceXMLReader.h"

#import "Constants.h"
#import "../../Objects/Generic/Service.h"

static const char *kEnigma2ServiceElement = "e2service";
static const NSUInteger kEnigma2ServiceElementLength = 10;

@interface Enigma2ServiceXMLReader()
@property (nonatomic, retain) NSObject<ServiceProtocol> *currentService;
@end

@implementation Enigma2ServiceXMLReader

@synthesize currentService;

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
	[currentService release];

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
- (void)elementFound:(const xmlChar *)localname prefix:(const xmlChar *)prefix uri:(const xmlChar *)URI namespaceCount:(int)namespaceCount namespaces:(const xmlChar **)namespaces attributeCount:(int)attributeCount defaultAttributeCount:(int)defaultAttributeCount attributes:(xmlSAX2Attributes *)attributes
{
	if(!strncmp((const char *)localname, kEnigma2ServiceElement, kEnigma2ServiceElementLength))
	{
		self.currentService = [[[GenericService alloc] init] autorelease];
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
		[_delegate performSelectorOnMainThread: @selector(addService:)
									withObject: currentService
								 waitUntilDone: NO];
	}
	else if(!strncmp((const char *)localname, kEnigma2Servicereference, kEnigma2ServicereferenceLength))
	{
		// if service begins with 1:64: this is a marker
		if(![[currentString substringToIndex: 5] isEqualToString: @"1:64:"])
			currentService.sref = currentString;
	}
	else if(!strncmp((const char *)localname, kEnigma2Servicename, kEnigma2ServicenameLength))
	{
			currentService.sname = currentString;
	}

	// this either does nothing or releases the string that was in use
	self.currentString = nil;
}

@end
