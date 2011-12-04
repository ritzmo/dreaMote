//
//  VolumeXMLReader.m
//  dreaMote
//
//  Created by Moritz Venn on 31.12.08.
//  Copyright 2008-2011 Moritz Venn. All rights reserved.
//

#import "VolumeXMLReader.h"

#import <Constants.h>

#import <Objects/Generic/Volume.h>

static const char *kEnigma2Volume = "e2volume";
static const NSUInteger kEnigma2VolumeLength = 9;
static const char *kEnigma2Result = "e2result";
static const NSUInteger kEnigma2ResultLength = 9;
static const char *kEnigma2Resulttext = "e2resulttext";
static const NSUInteger kEnigma2ResulttextLength = 13;
static const char *kEnigma2Current = "e2current";
static const NSUInteger kEnigma2CurrentLength = 10;
static const char *kEnigma2Ismuted = "e2ismuted";
static const NSUInteger kEnigma2IsmutedLength = 10;

@interface Enigma2VolumeXMLReader()
@property (nonatomic, strong) GenericVolume *volume;
@end

@implementation Enigma2VolumeXMLReader

@synthesize volume;

/* initialize */
- (id)initWithDelegate:(NSObject<VolumeSourceDelegate> *)delegate
{
	if((self = [super init]))
	{
		_delegate = delegate;
	}
	return self;
}

/*
 Example:
 <?xml version="1.0" encoding="UTF-8"?>
 <e2volume>
 <e2result>True</e2result>
 <e2resulttext>state</e2resulttext>
 <e2current>5</e2current>
 <e2ismuted>False</e2ismuted>	
 </e2volume>
*/
- (void)elementFound:(const xmlChar *)localname prefix:(const xmlChar *)prefix uri:(const xmlChar *)URI namespaceCount:(int)namespaceCount namespaces:(const xmlChar **)namespaces attributeCount:(int)attributeCount defaultAttributeCount:(int)defaultAttributeCount attributes:(xmlSAX2Attributes *)attributes
{
	if(!strncmp((const char *)localname, kEnigma2Volume, kEnigma2VolumeLength))
	{
		volume = [[GenericVolume alloc] init];
	}
	else if(!strncmp((const char *)localname, kEnigma2Result, kEnigma2ResultLength)
		||	!strncmp((const char *)localname, kEnigma2Resulttext, kEnigma2ResulttextLength)
		||	!strncmp((const char *)localname, kEnigma2Current, kEnigma2CurrentLength)
		||	!strncmp((const char *)localname, kEnigma2Ismuted, kEnigma2IsmutedLength)
	   )
	{
		currentString = [[NSMutableString alloc] init];
	}
}

- (void)endElement:(const xmlChar *)localname prefix:(const xmlChar *)prefix uri:(const xmlChar *)URI
{
	if(!strncmp((const char *)localname, kEnigma2Volume, kEnigma2VolumeLength))
	{
		[_delegate performSelectorOnMainThread:@selector(addVolume:)
									withObject:volume
								 waitUntilDone:NO];
	}
	else if(!strncmp((const char *)localname, kEnigma2Result, kEnigma2ResultLength))
	{
		volume.result = [currentString boolValue];
	}
	else if(!strncmp((const char *)localname, kEnigma2Resulttext, kEnigma2ResulttextLength))
	{
		volume.resulttext = currentString;
	}
	else if(!strncmp((const char *)localname, kEnigma2Current, kEnigma2CurrentLength))
	{
		volume.current = [currentString integerValue];
	}
	else if(!strncmp((const char *)localname, kEnigma2Ismuted, kEnigma2IsmutedLength))
	{
		volume.ismuted = [currentString boolValue];
	}

	self.currentString = nil;
}

@end
