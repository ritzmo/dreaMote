//
//  LocationXMLReader.m
//  dreaMote
//
//  Created by Moritz Venn on 01.01.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import "LocationXMLReader.h"

#import <Constants.h>
#import <Objects/Generic/Location.h>

#import "NSObject+Queue.h"

@implementation Enigma2LocationXMLReader

/* initialize */
- (id)initWithDelegate:(NSObject<LocationSourceDelegate> *)delegate
{
	if((self = [super init]))
	{
		_delegate = delegate;
		if([_delegate respondsToSelector:@selector(addLocation:)])
			self.currentItems = [NSMutableArray arrayWithCapacity:kBatchDispatchItemsCount];
	}
	return self;
}

/* send fake object */
- (void)errorLoadingDocument:(NSError *)error
{
	NSObject<LocationProtocol> *fakeObject = [[GenericLocation alloc] init];
	fakeObject.fullpath = NSLocalizedString(@"Error retrieving Data", @"");
	fakeObject.valid = NO;
	[(NSObject<LocationSourceDelegate> *)_delegate addLocation:fakeObject];
	[super errorLoadingDocument:error];
}

- (void)finishedParsingDocument
{
	if(self.currentItems.count)
	{
		[(NSObject<LocationSourceDelegate> *)_delegate addLocations:self.currentItems];
		[self.currentItems removeAllObjects];
	}
	[super finishedParsingDocument];
}

/*
Example:
<?xml version="1.0" encoding="UTF-8"?> 
<e2locations> 
 <e2location>/hdd/movie/</e2location> 
</e2locations> 
*/
- (void)elementFound:(const xmlChar *)localname prefix:(const xmlChar *)prefix uri:(const xmlChar *)URI namespaceCount:(int)namespaceCount namespaces:(const xmlChar **)namespaces attributeCount:(int)attributeCount defaultAttributeCount:(int)defaultAttributeCount attributes:(xmlSAX2Attributes *)attributes
{
	if(		!strncmp((const char *)localname, kEnigma2Location, kEnigma2LocationLength)
	   ||	!strncmp((const char *)localname, kEnigma2SimpleXmlItem, kEnigma2SimpleXmlItemLength))
	{
		currentString = [[NSMutableString alloc] init];
	}
}

- (void)endElement:(const xmlChar *)localname prefix:(const xmlChar *)prefix uri:(const xmlChar *)URI
{
	if(		!strncmp((const char *)localname, kEnigma2Location, kEnigma2LocationLength)
	   ||	!strncmp((const char *)localname, kEnigma2SimpleXmlItem, kEnigma2SimpleXmlItemLength))
	{
		GenericLocation *newLocation = [[GenericLocation alloc] init];
		newLocation.fullpath = currentString;
		newLocation.valid = YES;
		if(self.currentItems)
		{
			[self.currentItems addObject:newLocation];
			if(self.currentItems.count >= kBatchDispatchItemsCount)
			{
				NSArray *dispatchArray = [self.currentItems copy];
				[self.currentItems removeAllObjects];
				[[_delegate queueOnMainThread] addLocations:dispatchArray];
			}
		}
		else
			[[_delegate queueOnMainThread] addLocation:newLocation];
	}
	currentString = nil;
}

@end
