//
//  CurrentXMLReader.m
//  dreaMote
//
//  Created by Moritz Venn on 26.10.09.
//  Copyright 2009-2011 Moritz Venn. All rights reserved.
//

#import "CurrentXMLReader.h"

#import "../../Objects/Generic/Event.h"
#import "../../Objects/Generic/Service.h"

@implementation EnigmaCurrentXMLReader

/* initialize */
- (id)initWithDelegate:(NSObject<EventSourceDelegate,ServiceSourceDelegate> *)delegate
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
	NSObject<ServiceProtocol> *fakeObject = [[GenericService alloc] init];
	fakeObject.sname = NSLocalizedString(@"Error retrieving Data", @"");
	[_delegate performSelectorOnMainThread: @selector(addService:)
								withObject: fakeObject
								waitUntilDone: NO];
	[fakeObject release];
}

- (NSObject<EventProtocol> *)parseEvent: (NSArray *)resultNodes
{
	for(CXMLElement *resultElement in resultNodes)
	{
		NSObject<EventProtocol> *newEvent = [[GenericEvent alloc] init];
		NSArray *childNodes = [resultElement nodesForXPath:@"description" error:nil];
		CXMLDocument *childElement;
		for(childElement in childNodes)
		{
			newEvent.title = [childElement stringValue];
			break;
		}

		// Workaround unknown now/next
		if(newEvent.title == nil)
		{
			[newEvent release];
			return nil;
		}

		childNodes = [resultElement nodesForXPath:@"start" error:nil];
		for(childElement in childNodes)
		{
			NSDate *begin = [NSDate dateWithTimeIntervalSince1970: [[childElement stringValue] doubleValue]];
			newEvent.begin = begin;
			break;
		}

		childNodes = [resultElement nodesForXPath:@"duration" error:nil];
		for(childElement in childNodes)
		{
			NSString *rawDurationString = [childElement stringValue];
			NSRange range;
			range.location = 1;
			range.length = [rawDurationString length] - 2;
			rawDurationString = [rawDurationString substringWithRange: range];
			newEvent.end = [[newEvent.begin addTimeInterval: [rawDurationString doubleValue] * 60.0] retain];
			break;
		}

		childNodes = [resultElement nodesForXPath:@"details" error:nil];
		for(childElement in childNodes)
		{
			newEvent.edescription = [childElement stringValue];
			break;
		}
		
		[_delegate performSelectorOnMainThread: @selector(addEvent:)
									withObject: newEvent
									waitUntilDone: NO];
		[newEvent autorelease];
		return newEvent;
	}
	return nil;
}

/*
 Example:
 */
- (void)parseFull
{
	const NSObject<EventProtocol> *current_event = [self parseEvent: [_parser nodesForXPath:@"/currentservicedata/current_event" error:nil]];
	const NSArray *resultNodes = [_parser nodesForXPath:@"/currentservicedata/service" error:nil];

	for(CXMLElement *resultElement in resultNodes)
	{
		NSObject<ServiceProtocol> *newService = [[GenericService alloc] init];
		NSArray *childNodes = [resultElement nodesForXPath:@"name" error:nil];
		CXMLElement *childElement = nil;
		for(childElement in childNodes)
		{
			newService.sname = [childElement stringValue];
			break;
		}

		if(newService.sname == nil || [newService.sname isEqualToString:@""])
		{
			// NOTE: fall back to current event title because it looks weird for
			// recordings otherwise, but if we are playing a recording back
			// we won't be able to distinguish between standby and running...
			if(current_event && current_event.title != nil && ![current_event.title isEqualToString:@""])
			{
				newService.sname = current_event.title;
			}
			else {
				newService.sname = NSLocalizedString(@"Nothing playing.", @"");
			}
		}
		else
		{
			childNodes = [resultElement nodesForXPath:@"reference" error:nil];
			for(childElement in childNodes)
			{
				newService.sref = [childElement stringValue];
				break;
			}
		}

		[_delegate performSelectorOnMainThread: @selector(addService:)
									withObject: newService
									waitUntilDone: NO];
		[newService release];
		break;
	}

	[self parseEvent: [_parser nodesForXPath:@"/currentservicedata/next_event" error:nil]];
}

@end
