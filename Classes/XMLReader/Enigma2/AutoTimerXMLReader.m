//
//  AutoTimerXMLReader.m
//  dreaMote
//
//  Created by Moritz Venn on 17.03.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import "AutoTimerXMLReader.h"

#import "Constants.h"

static const char *kEnigma2ATElement = "timer";
static const NSUInteger kEnigma2ATElementLength = 6;
static const char *kEnigma2ATName = "name";
static const NSUInteger kEnigma2ATNameLength = 5;
static const char *kEnigma2ATMatch = "match";
static const NSUInteger kEnigma2ATMatchLength = 6;
static const char *kEnigma2ATEnabled = "enabled";
static const NSUInteger kEnigma2ATEnabledLength = 8;
static const char *kEnigma2ATId = "id";
static const NSUInteger kEnigma2ATIdLength = 3;
static const char *kEnigma2ATFrom = "from";
static const NSUInteger kEnigma2ATFromLength = 5;
static const char *kEnigma2ATTo = "to";
static const NSUInteger kEnigma2ATToLength = 3;
static const char *kEnigma2ATOffset = "offset";
static const NSUInteger kEnigma2ATOffsetLength = 7;
static const char *kEnigma2ATEncoding = "encoding";
static const NSUInteger kEnigma2ATEncodingLength = 9;
static const char *kEnigma2ATSearchType = "searchType";
static const NSUInteger kEnigma2ATSearchTypeLength = 11;
static const char *kEnigma2ATSearchCase = "searchCase";
static const NSUInteger kEnigma2ATSearchCaseLength = 11;
static const char *kEnigma2ATOverrideAlternatives = "overrideAlternatives";
static const NSUInteger kEnigma2ATOverrideAlternativesLength = 21;
static const char *kEnigma2ATInclude = "include";
static const NSUInteger kEnigma2ATIncludeLength = 8;
static const char *kEnigma2ATExclude = "exclude";
static const NSUInteger kEnigma2ATExcludeLength = 8;
static const char *kEnigma2ATMaxduration = "maxduration";
static const NSUInteger kEnigma2ATMaxdurationLength = 12;
static const char *kEnigma2ATLocation = "location";
static const NSUInteger kEnigma2ATLocationLength = 9;
static const char *kEnigma2ATCounter = "counter";
static const NSUInteger kEnigma2ATCounterLength = 8;
static const char *kEnigma2ATCounterFormat = "counterFormat";
static const NSUInteger kEnigma2ATCounterFormatLength = 14;
static const char *kEnigma2ATLeft = "left";
static const NSUInteger kEnigma2ATLeftLength = 5;
static const char *kEnigma2ATJustplay = "justplay";
static const NSUInteger kEnigma2ATJustplayLength = 9;
static const char *kEnigma2ATAfter = "after";
static const NSUInteger kEnigma2ATAfterLength = 6;
static const char *kEnigma2ATBefore = "before";
static const NSUInteger kEnigma2ATBeforeLength = 7;
static const char *kEnigma2ATLastBegin = "lastBegin";
static const NSUInteger kEnigma2ATLastBeginLength = 10;
static const char *kEnigma2ATLastActivation = "lastActivation";
static const NSUInteger kEnigma2ATLastActivationLength = 15;
static const char *kEnigma2ATAvoidDuplicateDescription = "avoidDuplicateDescription";
static const NSUInteger kEnigma2ATAvoidDuplicateDescriptionLength = 26;
static const char *kEnigma2ATAfterevent = "afterevent";
static const NSUInteger kEnigma2ATAftereventLength = 11;

@interface Enigma2AutoTimerXMLReader()
@property (nonatomic, retain) AutoTimer *currentAT;
@end

@implementation Enigma2AutoTimerXMLReader

@synthesize currentAT;

/* initialize */
- (id)initWithDelegate:(NSObject<AutoTimerSourceDelegate> *)delegate
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
	[currentAT release];

	[super dealloc];
}

/* send fake object */
- (void)sendErroneousObject
{
	AutoTimer *fakeObject = [[AutoTimer alloc] init];
	//fakeObject.title = NSLocalizedString(@"Error retrieving Data", @"");

	[_delegate performSelectorOnMainThread:@selector(addAutoTimer:)
								withObject:fakeObject
							 waitUntilDone:NO];
	[fakeObject release];
}

/*
 Example:
 <?xml version="1.0" ?> 
 <autotimer version="5"> 
 <timer name="Mad Men" match="Mad Men" enabled="no" id="11" from="20:00" to="23:15" offset="5" encoding="ISO8859-15" searchType="exact" searchCase="sensitive" overrideAlternatives="1"> 
 <e2service> 
 <e2servicereference>1:134:1:0:0:0:0:0:0:0:FROM BOUQUET "alternatives.__fox___serie.tv" ORDER BY bouquet</e2servicereference> 
 <e2servicename>Fox Serie</e2servicename> 
 </e2service> 
 <include where="dayofweek">0</include> 
 </timer>
 </autotimer>
*/
- (void)elementFound:(const xmlChar *)localname prefix:(const xmlChar *)prefix uri:(const xmlChar *)URI namespaceCount:(int)namespaceCount namespaces:(const xmlChar **)namespaces attributeCount:(int)attributeCount defaultAttributeCount:(int)defaultAttributeCount attributes:(xmlSAX2Attributes *)attributes
{
	if(!strncmp((const char *)localname, kEnigma2ATElement, kEnigma2ATElementLength))
	{
		self.currentAT = [[[AutoTimer alloc] init] autorelease];
		// read attributes
	}
	else if(	!strncmp((const char *)localname, kEnigma2ATInclude, kEnigma2ATIncludeLength)
			||	!strncmp((const char *)localname, kEnigma2ATExclude, kEnigma2ATExcludeLength))
	{
		// required: where (keep in instance variable)
		currentString = [[NSMutableString alloc] init];
	}
	else if(!strncmp((const char *)localname, kEnigma2ATAfterevent, kEnigma2ATAftereventLength))
	{
		// optional: from/to as attribute (ignore in first version, just like gui on stb)
		currentString = [[NSMutableString alloc] init];
	}
	else if(!strncmp((const char *)localname, kEnigma2Servicename, kEnigma2ServicenameLength))
	{
		// create new service
		currentString = [[NSMutableString alloc] init];
	}
	else if(!strncmp((const char *)localname, kEnigma2Servicereference, kEnigma2ServicereferenceLength))
	{
		// make sure (local) service exists
		currentString = [[NSMutableString alloc] init];
	}
	else if(!strncmp((const char *)localname, kEnigma2Tags, kEnigma2TagsLength))
	{
		currentString = [[NSMutableString alloc] init];
	}
}

- (void)endElement:(const xmlChar *)localname prefix:(const xmlChar *)prefix uri:(const xmlChar *)URI
{
	if(!strncmp((const char *)localname, kEnigma2ATElement, kEnigma2ATElementLength))
	{
		// guarding this allows us to ignore timers under some circumstances
		if(currentAT)
			[_delegate performSelectorOnMainThread:@selector(addAutoTimer:)
										withObject:currentAT
									 waitUntilDone:NO];
		self.currentAT = nil;
	}
	else if(!strncmp((const char *)localname, kEnigma2ATInclude, kEnigma2ATIncludeLength))
	{
		// append to includes
	}
	else if(!strncmp((const char *)localname, kEnigma2ATExclude, kEnigma2ATExcludeLength))
	{
		// append to exclude
	}
	else if(!strncmp((const char *)localname, kEnigma2ATAfterevent, kEnigma2ATAftereventLength))
	{
		// optional: from/to as attribute
		currentString = [[NSMutableString alloc] init];
	}
	else if(!strncmp((const char *)localname, kEnigma2Servicename, kEnigma2ServicenameLength))
	{
		//currentService.sname = currentString;
	}
	else if(!strncmp((const char *)localname, kEnigma2Servicereference, kEnigma2ServicereferenceLength))
	{
		//currentService.sref = currentString;
		//TODO: determine type based on sref and append to service/bouquet
	}
	else if(!strncmp((const char *)localname, kEnigma2Tags, kEnigma2TagsLength))
	{
		// copy [GenericMovie setTagsFromString:]
	}

	// this either does nothing or releases the string that was in use
	self.currentString = nil;
}

@end