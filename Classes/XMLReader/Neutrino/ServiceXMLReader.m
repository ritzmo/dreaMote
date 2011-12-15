//
//  ServiceXMLReader.m
//  dreaMote
//
//  Created by Moritz Venn on 13.03.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import "ServiceXMLReader.h"

#import <Constants.h>
#import <Objects/Generic/Service.h>

#import "NSObject+Queue.h"

static const char *kNeutrinoServiceElement = "channel";
static const NSUInteger kNeutrinoServiceElementLength = 8;
static const char *kNeutrinoServicereference = "id";
static const NSUInteger kNeutrinoServicereferenceLength = 3;
static const char *kNeutrinoServicename = "name";
static const NSUInteger kNeutrinoServicenameLength = 5;
static const char *kNeutrinoServicelogo = "logo";
static const NSUInteger kNeutrinoServicelogoLength = 5;

@interface NeutrinoServiceXMLReader()
@property (nonatomic, strong) NSObject<ServiceProtocol> *currentService;
@end

@implementation NeutrinoServiceXMLReader

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
- (void)errorLoadingDocument:(NSError *)error
{
	NSObject<ServiceProtocol> *fakeService = [[GenericService alloc] init];
	fakeService.sname = NSLocalizedString(@"Error retrieving Data", @"");
	[(NSObject<ServiceSourceDelegate> *)_delegate addService:fakeService];
	[super errorLoadingDocument:error];
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

/*
 Example:
 <?xml version="1.0" encoding="iso-8859-1"?>
 <bouquetlist>
 <bouquet>
 <bnumber>6</bnumber>
 </bouquet>
 <channel>
 <number>32</number>
 <id>20085000a</id>
 <name><![CDATA[Sky Cinema]]></name>
 </channel>
 </bouquetlist>
	OR
 <channellist>
 <channel>
 <number>1</number>
 <bouquet>0</bouquet>
 <id>b24403f300012b5c</id>
 <short_id>3f300012b5c</short_id>
 <name>Das Erste HD</name>
 <logo>/share/tuxbox/neutrino/icons/logo/3f300012b5c.jpg</logo>
 </channel>
 </channellist>
*/
- (void)elementFound:(const xmlChar *)localname prefix:(const xmlChar *)prefix uri:(const xmlChar *)URI namespaceCount:(int)namespaceCount namespaces:(const xmlChar **)namespaces attributeCount:(int)attributeCount defaultAttributeCount:(int)defaultAttributeCount attributes:(xmlSAX2Attributes *)attributes
{
	if(!strncmp((const char *)localname, kNeutrinoServiceElement, kNeutrinoServiceElementLength))
	{
		self.currentService = [[GenericService alloc] init];
	}
	else if(	!strncmp((const char *)localname, kNeutrinoServicereference, kNeutrinoServicereferenceLength)
			||	!strncmp((const char *)localname, kNeutrinoServicename, kNeutrinoServicenameLength)
			||	!strncmp((const char *)localname, kNeutrinoServicelogo, kNeutrinoServicelogoLength)
		)
	{
		currentString = [[NSMutableString alloc] init];
	}
}

- (void)endElement:(const xmlChar *)localname prefix:(const xmlChar *)prefix uri:(const xmlChar *)URI
{
	if(!strncmp((const char *)localname, kNeutrinoServiceElement, kNeutrinoServiceElementLength))
	{
		if(self.currentItems)
		{
			[self.currentItems addObject:currentService];
			if(self.currentItems.count >= kBatchDispatchItemsCount)
			{
				NSArray *dispatchArray = [self.currentItems copy];
				[self.currentItems removeAllObjects];
				[[_delegate queueOnMainThread] addServices:dispatchArray];
			}
		}
		else
			[_delegate performSelectorOnMainThread:@selector(addService:)
										withObject:currentService
									 waitUntilDone:NO];
	}
	else if(!strncmp((const char *)localname, kNeutrinoServicereference, kNeutrinoServicereferenceLength))
	{
		currentService.sref = currentString;
	}
	else if(!strncmp((const char *)localname, kNeutrinoServicename, kNeutrinoServicenameLength))
	{
			currentService.sname = currentString;
	}
	else if(!strncmp((const char *)localname, kNeutrinoServicelogo, kNeutrinoServicelogoLength))
	{
		currentService.piconName = currentString;
	}

	// this either does nothing or releases the string that was in use
	self.currentString = nil;
}

@end
