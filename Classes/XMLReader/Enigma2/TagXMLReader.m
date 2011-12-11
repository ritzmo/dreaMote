//
//  TagXMLReader.m
//  dreaMote
//
//  Created by Moritz Venn on 20.11.11.
//  Copyright (c) 2011 Moritz Venn. All rights reserved.
//

#import "TagXMLReader.h"

#import <Constants.h>
#import <Objects/Generic/Tag.h>

static const char *kEnigma2Tag = "e2tag";
static const NSInteger kEnigma2TagLength = 6;

@implementation Enigma2TagXMLReader

/* initialize */
- (id)initWithDelegate:(NSObject<TagSourceDelegate> *)delegate
{
	if((self = [super init]))
	{
		_delegate = delegate;
	}
	return self;
}

/* send fake object */
- (void)errorLoadingDocument:(NSError *)error
{
	Tag *fakeObject = [[Tag alloc] init];
	fakeObject.tag = NSLocalizedString(@"Error retrieving Data", @"");
	fakeObject.valid = NO;
	[(NSObject<TagSourceDelegate> *)_delegate addTag:fakeObject];
	[super errorLoadingDocument:error];
}

/*
 Example:
 <?xml version="1.0" encoding="UTF-8"?>
 <e2tags>
 <e2tag>Krimi</e2tag>
 </e2tags>
 */
- (void)elementFound:(const xmlChar *)localname prefix:(const xmlChar *)prefix uri:(const xmlChar *)URI namespaceCount:(int)namespaceCount namespaces:(const xmlChar **)namespaces attributeCount:(int)attributeCount defaultAttributeCount:(int)defaultAttributeCount attributes:(xmlSAX2Attributes *)attributes
{
	if(		!strncmp((const char *)localname, kEnigma2Tag, kEnigma2TagLength)
	   ||	!strncmp((const char *)localname, kEnigma2SimpleXmlItem, kEnigma2SimpleXmlItemLength))
	{
		currentString = [[NSMutableString alloc] init];
	}
}

- (void)endElement:(const xmlChar *)localname prefix:(const xmlChar *)prefix uri:(const xmlChar *)URI
{
	if(		!strncmp((const char *)localname, kEnigma2Tag, kEnigma2TagLength)
	   ||	!strncmp((const char *)localname, kEnigma2SimpleXmlItem, kEnigma2SimpleXmlItemLength))
	{
		Tag *newTag = [[Tag alloc] init];
		newTag.tag = currentString;
		newTag.valid = YES;
		[_delegate performSelectorOnMainThread:@selector(addTag:)
									withObject:newTag
								 waitUntilDone:NO];
	}
	currentString = nil;
}

@end
