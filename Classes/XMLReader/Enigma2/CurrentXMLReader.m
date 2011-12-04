//
//  CurrentXMLReader.m
//  dreaMote
//
//  Created by Moritz Venn on 26.10.09.
//  Copyright 2009-2011 Moritz Venn. All rights reserved.
//

#import "CurrentXMLReader.h"

#import <Constants.h>

#import <XMLReader/Enigma2/ServiceXMLReader.h>
#import <XMLReader/Enigma2/EventXMLReader.h>

#import <Objects/Generic/Service.h>

@interface Enigma2CurrentXMLReader()
@property (nonatomic, strong) Enigma2ServiceXMLReader *sreader;
@property (nonatomic, strong) Enigma2EventXMLReader *ereader;
@end

@interface Enigma2ServiceXMLReader()
- (void)charactersFound:(const xmlChar *)characters length:(int)length;
@property (nonatomic, strong) NSObject<ServiceProtocol> *currentService;
@end

@interface Enigma2EventXMLReader()
- (void)charactersFound:(const xmlChar *)characters length:(int)length;
@property (nonatomic, strong) NSObject<EventProtocol> *currentEvent;
@end

@implementation Enigma2CurrentXMLReader

@synthesize sreader, ereader;

/* initialize */
- (id)initWithDelegate:(NSObject<EventSourceDelegate,ServiceSourceDelegate> *)delegate
{
	if((self = [super init]))
	{
		_delegate = delegate;
		sreader = [[Enigma2ServiceXMLReader alloc] initWithDelegate:nil];
		ereader = [[Enigma2EventXMLReader alloc] initWithDelegate:nil];
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
- (void)elementFound:(const xmlChar *)localname prefix:(const xmlChar *)prefix uri:(const xmlChar *)URI namespaceCount:(int)namespaceCount namespaces:(const xmlChar **)namespaces attributeCount:(int)attributeCount defaultAttributeCount:(int)defaultAttributeCount attributes:(xmlSAX2Attributes *)attributes
{
	[sreader elementFound:localname prefix:prefix uri:URI namespaceCount:namespaceCount namespaces:namespaces attributeCount:attributeCount defaultAttributeCount:defaultAttributeCount attributes:attributes];
	[ereader elementFound:localname prefix:prefix uri:URI namespaceCount:namespaceCount namespaces:namespaces attributeCount:attributeCount defaultAttributeCount:defaultAttributeCount attributes:attributes];
}

- (void)endElement:(const xmlChar *)localname prefix:(const xmlChar *)prefix uri:(const xmlChar *)URI
{
	if(!strncmp((const char *)localname, kEnigma2ServiceElement, kEnigma2ServiceElementLength))
	{
		NSObject<ServiceProtocol> *newService = sreader.currentService;
		if(newService.sname == nil || [newService.sname isEqualToString:@""])
		{
			newService = [[GenericService alloc] init];
			newService.sname = NSLocalizedString(@"Nothing playing.", @"");
		}

		[_delegate performSelectorOnMainThread:@selector(addService:)
									withObject:newService
								 waitUntilDone:NO];
	}
	else if(!strncmp((const char *)localname, kEnigma2EventElement, kEnigma2EventElementLength))
	{
		NSObject<EventProtocol> *newEvent = ereader.currentEvent;
		NSString *title = newEvent.title;
		if(title == nil || [title isEqualToString:@""])
			return; // don't push event

		[_delegate performSelectorOnMainThread:@selector(addEvent:)
									withObject:newEvent
								 waitUntilDone:NO];
	}
	else
	{
		[sreader endElement:localname prefix:prefix uri:URI];
		[ereader endElement:localname prefix:prefix uri:URI];
	}
}

- (void)charactersFound:(const xmlChar *)characters length:(int)length
{
	[sreader charactersFound:characters length:length];
	[ereader charactersFound:characters length:length];
}

@end
