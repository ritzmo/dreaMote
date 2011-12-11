//
//  AboutXMLReader.m
//  dreaMote
//
//  Created by Moritz Venn on 08.01.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import "AboutXMLReader.h"

#import <Objects/Generic/About.h>
#import <Objects/Generic/Harddisk.h>

static const char *kEnigma2About = "e2about";
static const NSUInteger kEnigma2AboutLength = 8;
static const char *kEnigma2EnigmaVersion = "e2enigmaversion";
static const NSUInteger kEnigma2EnigmaVersionLength = 16;
static const char *kEnigma2ImageVersion = "e2imageversion";
static const NSUInteger kEnigma2ImageVersionLength = 15;
static const char *kEnigma2Model = "e2model";
static const NSUInteger kEnigma2ModelLength = 8;
static const char *kEnigma2Hdd = "e2hddinfo";
static const NSUInteger kEnigma2HddLength = 10;
static const char *kEnigma2HddModel = "model";
static const NSUInteger kEnigma2HddModelLength = 6;
static const char *kEnigma2HddCapacity = "capacity";
static const NSUInteger kEnigma2HddCapacityLength = 9;
static const char *kEnigma2HddFree = "free";
static const NSUInteger kEnigma2HddFreeLength = 5;
static const char *kEnigma2Nims = "e2tunerinfo";
static const NSUInteger kEnigma2NimsLength = 12;
static const char *kEnigma2NimType = "type";
static const NSUInteger kEnigma2NimTypeLength = 5;

@interface Enigma2AboutXMLReader()
@property (nonatomic, strong) GenericAbout *about;
@property (nonatomic, strong) Harddisk *hdd;
@property (nonatomic, strong) NSMutableArray *currentList;
@end

@implementation Enigma2AboutXMLReader

@synthesize about, currentList, hdd;

/* initialize */
- (id)initWithDelegate:(NSObject<AboutSourceDelegate> *)delegate
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
	[(NSObject<AboutSourceDelegate> *)_delegate addAbout:nil];
	[super errorLoadingDocument:error];
}

/*
Example:
<?xml version="1.0" encoding="UTF-8"?> 
<e2about> 
 <e2enigmaversion>2010-12-21-experimental</e2enigmaversion>
 [...] 
</e2about> 
*/
- (void)elementFound:(const xmlChar *)localname prefix:(const xmlChar *)prefix uri:(const xmlChar *)URI namespaceCount:(int)namespaceCount namespaces:(const xmlChar **)namespaces attributeCount:(int)attributeCount defaultAttributeCount:(int)defaultAttributeCount attributes:(xmlSAX2Attributes *)attributes
{
	if(!strncmp((const char *)localname, kEnigma2About, kEnigma2AboutLength))
	{
		about = [[GenericAbout alloc] init];
	}
	else if(	!strncmp((const char *)localname, kEnigma2EnigmaVersion, kEnigma2EnigmaVersionLength)
			||	!strncmp((const char *)localname, kEnigma2ImageVersion, kEnigma2ImageVersionLength)
			||	!strncmp((const char *)localname, kEnigma2Model, kEnigma2ModelLength)
			||	!strncmp((const char *)localname, kEnigma2HddCapacity, kEnigma2HddCapacityLength)
			||	!strncmp((const char *)localname, kEnigma2HddFree, kEnigma2HddFreeLength)
			||	!strncmp((const char *)localname, kEnigma2HddModel, kEnigma2HddModelLength)
			||	!strncmp((const char *)localname, kEnigma2NimType, kEnigma2NimTypeLength)
			)
	{
		currentString = [[NSMutableString alloc] init];
	}
	else if(!strncmp((const char *)localname, kEnigma2Nims, kEnigma2NimsLength))
	{
		currentList = [[NSMutableArray alloc] initWithCapacity:4];
		about.tuners = currentList;
	}
	else if(!strncmp((const char *)localname, kEnigma2Hdd, kEnigma2HddLength))
	{
		if(!currentList)
		{
			currentList = [[NSMutableArray alloc] initWithCapacity:2];
			about.hdd = currentList;
		}
		hdd = [[Harddisk alloc] init];
	}
}

- (void)endElement:(const xmlChar *)localname prefix:(const xmlChar *)prefix uri:(const xmlChar *)URI
{
	if(!strncmp((const char *)localname, kEnigma2About, kEnigma2AboutLength))
	{
		[_delegate performSelectorOnMainThread:@selector(addAbout:)
									withObject:about
								 waitUntilDone:NO];
		about = nil;
		currentList = nil;
	}
	else if(!strncmp((const char *)localname, kEnigma2EnigmaVersion, kEnigma2EnigmaVersionLength))
	{
		about.version = currentString;
	}
	else if(!strncmp((const char *)localname, kEnigma2ImageVersion, kEnigma2ImageVersionLength))
	{
		about.imageVersion = currentString;
	}
	else if(!strncmp((const char *)localname, kEnigma2Model, kEnigma2ModelLength))
	{
		about.model = currentString;
	}
	else if(!strncmp((const char *)localname, kEnigma2Hdd, kEnigma2HddLength))
	{
		[currentList addObject:hdd];
	}
	else if(!strncmp((const char *)localname, kEnigma2HddCapacity, kEnigma2HddCapacityLength))
	{
		hdd.capacity = currentString;
	}
	else if(!strncmp((const char *)localname, kEnigma2HddFree, kEnigma2HddFreeLength))
	{
		hdd.free = currentString;
	}
	else if(!strncmp((const char *)localname, kEnigma2HddModel, kEnigma2HddModelLength))
	{
		hdd.model = currentString;
	}
	else if(!strncmp((const char *)localname, kEnigma2NimType, kEnigma2NimTypeLength))
	{
		[currentList addObject:currentString];
	}

	self.currentString = nil;
}

@end
