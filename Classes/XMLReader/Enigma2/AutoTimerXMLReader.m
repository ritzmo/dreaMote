//
//  AutoTimerXMLReader.m
//  dreaMote
//
//  Created by Moritz Venn on 17.03.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import "AutoTimerXMLReader.h"

#import "Constants.h"

static const char *kEnigma2ATBaseElement = "autotimer";
static const NSUInteger kEnigma2ATBaseElementLength = 10;
static const char *kEnigma2ATVersion = "version";
static const NSUInteger kEnigma2ATVersionLength = 8;
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
#if 0
static const char *kEnigma2ATCounter = "counter";
static const NSUInteger kEnigma2ATCounterLength = 8;
static const char *kEnigma2ATCounterFormat = "counterFormat";
static const NSUInteger kEnigma2ATCounterFormatLength = 14;
static const char *kEnigma2ATLeft = "left";
static const NSUInteger kEnigma2ATLeftLength = 5;
static const char *kEnigma2ATLastBegin = "lastBegin";
static const NSUInteger kEnigma2ATLastBeginLength = 10;
static const char *kEnigma2ATLastActivation = "lastActivation";
static const NSUInteger kEnigma2ATLastActivationLength = 15;
#endif
static const char *kEnigma2ATJustplay = "justplay";
static const NSUInteger kEnigma2ATJustplayLength = 9;
static const char *kEnigma2ATSetEndtime = "setEndtime";
static const NSUInteger kEnigma2ATSetEndtimeLength = 11;
static const char *kEnigma2ATAfter = "after";
static const NSUInteger kEnigma2ATAfterLength = 6;
static const char *kEnigma2ATBefore = "before";
static const NSUInteger kEnigma2ATBeforeLength = 7;
static const char *kEnigma2ATAvoidDuplicateDescription = "avoidDuplicateDescription";
static const NSUInteger kEnigma2ATAvoidDuplicateDescriptionLength = 26;
static const char *kEnigma2ATSearchForDuplicateDescription = "searchForDuplicateDescription";
static const NSUInteger kEnigma2ATSearchForDuplicateDescriptionLength = 30;
static const char *kEnigma2ATAfterevent = "afterevent";
static const NSUInteger kEnigma2ATAftereventLength = 11;
static const char *kEnigma2ATWhere = "where";
static const NSUInteger kEnigma2ATWhereLength = 6;
static const char *kEnigma2ATVpsEnabled = "vps_enabled";
static const NSUInteger kEnigma2ATVpsEnabledLength = 12;
static const char *kEnigma2ATVpsOverwrite = "vps_overwrite";
static const NSUInteger kEnigma2ATVpsOverwriteLength = 14;

@interface Enigma2AutoTimerXMLReader()
@property (nonatomic, strong) AutoTimer *currentAT;
@property (nonatomic, strong) NSObject<ServiceProtocol> *currentService;
@end

@implementation Enigma2AutoTimerXMLReader

@synthesize currentAT, currentService;

/* initialize */
- (id)initWithDelegate:(NSObject<AutoTimerSourceDelegate> *)delegate
{
	if((self = [super init]))
	{
		_delegate = delegate;
		gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
	}
	return self;
}

/* send fake object */
- (void)errorLoadingDocument:(NSError *)error
{
	AutoTimer *fakeObject = [[AutoTimer alloc] init];
	fakeObject.name = NSLocalizedString(@"Error retrieving Data", @"");
	[(NSObject<AutoTimerSourceDelegate> *)_delegate addAutoTimer:fakeObject];
	[super errorLoadingDocument:error];
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
		self.currentAT = [[AutoTimer alloc] init];
		autoTimerWhere = autoTimerWhereInvalid;

		NSInteger i = 0;
		for(; i < attributeCount; ++i)
		{
			const NSInteger valueLength = (int)(attributes[i].end - attributes[i].value);
			NSString *value = [[NSString alloc] initWithBytes:(const void *)attributes[i].value
                                                       length:valueLength
                                                     encoding:NSUTF8StringEncoding];
            if(!strncmp((const char*)attributes[i].localname, kEnigma2ATName, kEnigma2ATNameLength))
			{
				currentAT.name = value;
			}
			else if(!strncmp((const char*)attributes[i].localname, kEnigma2ATMatch, kEnigma2ATMatchLength))
			{
				currentAT.match = value;
			}
			else if(!strncmp((const char*)attributes[i].localname, kEnigma2ATEnabled, kEnigma2ATEnabledLength))
			{
				currentAT.enabled = [value isEqualToString:@"yes"];
			}
			else if(!strncmp((const char*)attributes[i].localname, kEnigma2ATId, kEnigma2ATIdLength))
			{
				currentAT.idno = [value integerValue];
			}
			else if(!strncmp((const char*)attributes[i].localname, kEnigma2ATFrom, kEnigma2ATFromLength))
			{
				NSDateComponents *components = [gregorian components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit) fromDate:[NSDate date]];

				const NSArray *comps = [value componentsSeparatedByString:@":"];
				if([comps count] != 2)
				{
#if IS_DEBUG()
					[NSException raise:NSInternalInconsistencyException format:@"invalid 'from' received"];
#endif
					self.currentAT = nil;
				}
				else
				{
					[components setHour:[[comps objectAtIndex:0] integerValue]];
					[components setMinute:[[comps objectAtIndex:1] integerValue]];

					currentAT.from = [gregorian dateFromComponents:components];
				}
			}
			else if(!strncmp((const char*)attributes[i].localname, kEnigma2ATTo, kEnigma2ATToLength))
			{
				NSDateComponents *components = [gregorian components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit) fromDate:[NSDate date]];

				const NSArray *comps = [value componentsSeparatedByString:@":"];
				if([comps count] != 2)
				{
#if IS_DEBUG()
					[NSException raise:NSInternalInconsistencyException format:@"invalid 'to' received"];
#endif
					self.currentAT = nil;
				}
				else
				{
					[components setHour:[[comps objectAtIndex:0] integerValue]];
					[components setMinute:[[comps objectAtIndex:1] integerValue]];

					currentAT.to = [gregorian dateFromComponents:components];
				}
			}
			else if(!strncmp((const char*)attributes[i].localname, kEnigma2ATOffset, kEnigma2ATOffsetLength))
			{
				NSRange comma = [value rangeOfString:@","];
				if(comma.location == NSNotFound)
				{
					NSInteger offset = [value integerValue];
					currentAT.offsetBefore = offset;
					currentAT.offsetAfter = offset;
				}
				else
				{
					currentAT.offsetBefore = [[value substringToIndex:comma.location] integerValue];
					currentAT.offsetAfter = [[value substringFromIndex:comma.location + 1] integerValue];
				}
			}
			else if(!strncmp((const char*)attributes[i].localname, kEnigma2ATEncoding, kEnigma2ATEncodingLength))
			{
				currentAT.encoding = value;
			}
			else if(!strncmp((const char*)attributes[i].localname, kEnigma2ATSearchCase, kEnigma2ATSearchCaseLength))
			{
				currentAT.searchCase = [value isEqualToString:@"sensitive"] ? CASE_SENSITIVE : CASE_INSENSITIVE;
			}
			else if(!strncmp((const char*)attributes[i].localname, kEnigma2ATSearchType, kEnigma2ATSearchTypeLength))
			{
				if([value isEqualToString:@"exact"])
					currentAT.searchType = SEARCH_TYPE_EXACT;
				else if([value isEqualToString:@"description"])
					currentAT.searchType = SEARCH_TYPE_DESCRIPTION;
				else // should not be needed, but just to be sure...
					currentAT.searchType = SEARCH_TYPE_PARTIAL;
			}
			else if(!strncmp((const char*)attributes[i].localname, kEnigma2ATOverrideAlternatives, kEnigma2ATOverrideAlternativesLength))
			{
				currentAT.overrideAlternatives = [value isEqualToString:@"1"];
			}
			else if(!strncmp((const char*)attributes[i].localname, kEnigma2ATAvoidDuplicateDescription, kEnigma2ATAvoidDuplicateDescriptionLength))
			{
				currentAT.avoidDuplicateDescription = [value integerValue];
			}
			else if(!strncmp((const char*)attributes[i].localname, kEnigma2ATSearchForDuplicateDescription, kEnigma2ATSearchForDuplicateDescriptionLength))
			{
				currentAT.searchForDuplicateDescription = [value integerValue];
			}
			else if(!strncmp((const char*)attributes[i].localname, kEnigma2ATAfter, kEnigma2ATAfterLength))
			{
				currentAT.after = [NSDate dateWithTimeIntervalSince1970:[value doubleValue]];
			}
			else if(!strncmp((const char*)attributes[i].localname, kEnigma2ATBefore, kEnigma2ATBeforeLength))
			{
				currentAT.before = [NSDate dateWithTimeIntervalSince1970:[value doubleValue]];
			}
			else if(!strncmp((const char*)attributes[i].localname, kEnigma2ATMaxduration, kEnigma2ATMaxdurationLength))
			{
				currentAT.maxduration = [value integerValue];
			}
			else if(!strncmp((const char*)attributes[i].localname, kEnigma2ATLocation, kEnigma2ATLocationLength))
			{
				currentAT.location = value;
			}
#if 0
			else if(!strncmp((const char*)attributes[i].localname, kEnigma2ATLastBegin, kEnigma2ATLastBeginLength))
			{
				//
			}
			else if(!strncmp((const char*)attributes[i].localname, kEnigma2ATLastActivation, kEnigma2ATLastActivationLength))
			{
				//
			}
			else if(!strncmp((const char*)attributes[i].localname, kEnigma2ATCounter, kEnigma2ATCounterLength))
			{
				//
			}
			else if(!strncmp((const char*)attributes[i].localname, kEnigma2ATCounterFormat, kEnigma2ATCounterFormatLength))
			{
				//
			}
			else if(!strncmp((const char*)attributes[i].localname, kEnigma2ATLeft, kEnigma2ATLeftLength))
			{
				//
			}
#endif
			else if(!strncmp((const char*)attributes[i].localname, kEnigma2ATJustplay, kEnigma2ATJustplayLength))
			{
				currentAT.justplay = [value isEqualToString:@"1"];
			}
			else if(!strncmp((const char*)attributes[i].localname, kEnigma2ATSetEndtime, kEnigma2ATSetEndtimeLength))
			{
				currentAT.setEndtime = [value isEqualToString:@"1"];
			}
			else if(!strncmp((const char*)attributes[i].localname, kEnigma2ATVpsEnabled, kEnigma2ATVpsEnabledLength))
			{
				currentAT.vps_enabled = [value isEqualToString:@"yes"];
			}
			else if(!strncmp((const char*)attributes[i].localname, kEnigma2ATVpsOverwrite, kEnigma2ATVpsOverwriteLength))
			{
				currentAT.vps_overwrite = [value isEqualToString:@"yes"];
			}
		}
	}
	else if(	!strncmp((const char *)localname, kEnigma2ATInclude, kEnigma2ATIncludeLength)
			||	!strncmp((const char *)localname, kEnigma2ATExclude, kEnigma2ATExcludeLength))
	{
		NSInteger i = 0;
		for(; i < attributeCount; ++i)
		{
			const NSInteger valueLength = (int)(attributes[i].end - attributes[i].value);
			const NSString *value = [[NSString alloc] initWithBytes:(const void *)attributes[i].value
															 length:valueLength
														   encoding:NSUTF8StringEncoding];
			if(!strncmp((const char*)attributes[i].localname, kEnigma2ATWhere, kEnigma2ATWhereLength))
			{
				if([value isEqualToString:@"title"])
				{
					autoTimerWhere = autoTimerWhereTitle;
				}
				else if([value isEqualToString:@"shortdescription"])
				{
					autoTimerWhere = autoTimerWhereShortdescription;
				}
				else if([value isEqualToString:@"description"])
				{
					autoTimerWhere = autoTimerWhereDescription;
				}
				else if([value isEqualToString:@"dayofweek"])
				{
					autoTimerWhere = autoTimerWhereDayOfWeek;
				}
			}

		}

		if(autoTimerWhere != autoTimerWhereInvalid)
			currentString = [[NSMutableString alloc] init];
	}
	else if(!strncmp((const char *)localname, kEnigma2ATAfterevent, kEnigma2ATAftereventLength))
	{
		// optional: from/to as attribute (ignore in first version, just like gui on stb)
		currentString = [[NSMutableString alloc] init];
	}
	else if(!strncmp((const char *)localname, kEnigma2Servicename, kEnigma2ServicenameLength))
	{
		currentString = [[NSMutableString alloc] init];
	}
	else if(!strncmp((const char *)localname, kEnigma2Servicereference, kEnigma2ServicereferenceLength))
	{
		// create new service
		if(currentService)
			self.currentService = nil;

		currentService = [[GenericService alloc] init];
		currentString = [[NSMutableString alloc] init];
	}
	else if(!strncmp((const char *)localname, kEnigma2Tags, kEnigma2TagsLength))
	{
		currentString = [[NSMutableString alloc] init];
	}
	else if(!strncmp((const char *)localname, kEnigma2ATBaseElement, kEnigma2ATBaseElementLength))
	{
		NSInteger i = 0;
		for(; i < attributeCount; ++i)
		{
			const NSInteger valueLength = (int)(attributes[i].end - attributes[i].value);
			NSString *value = [[NSString alloc] initWithBytes:(const void *)attributes[i].value
                                                       length:valueLength
                                                     encoding:NSUTF8StringEncoding];
			if(!strncmp((const char*)attributes[i].localname, kEnigma2ATVersion, kEnigma2ATVersionLength))
			{
				NSInteger intValue = [value integerValue];
				if(intValue <= 0)
				{
#if IS_DEBUG()
					NSLog(@"AutoTimer supposedly invalid version '%@', ignoring!", value);
#endif
					continue;
				}
				NSNumber *version = [NSNumber numberWithInteger:intValue];
				[_delegate performSelectorOnMainThread:@selector(gotAutoTimerVersion:) withObject:version waitUntilDone:NO];
			}
		}
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
		[currentAT addInclude:currentString where:autoTimerWhere];

		autoTimerWhere = autoTimerWhereInvalid;
	}
	else if(!strncmp((const char *)localname, kEnigma2ATExclude, kEnigma2ATExcludeLength))
	{
		[currentAT addExclude:currentString where:autoTimerWhere];

		autoTimerWhere = autoTimerWhereInvalid;
	}
	else if(!strncmp((const char *)localname, kEnigma2ATAfterevent, kEnigma2ATAftereventLength))
	{
		if([currentString isEqualToString:@"none"])
		{
			currentAT.afterEventAction = kAfterEventNothing;
		}
		else if([currentString isEqualToString:@"standby"])
		{
			currentAT.afterEventAction = kAfterEventStandby;
		}
		else if([currentString isEqualToString:@"shutdown"])
		{
			currentAT.afterEventAction = kAfterEventDeepstandby;
		}
		else if([currentString isEqualToString:@"auto"])
		{
			currentAT.afterEventAction = kAfterEventAuto;
		}
	}
	else if(!strncmp((const char *)localname, kEnigma2Servicename, kEnigma2ServicenameLength))
	{
		currentService.sname = currentString;
		const NSArray *comps = [currentService.sref componentsSeparatedByString:@":"];
		const NSString *type = [comps objectAtIndex:1];
		if([type isEqualToString:@"7"]) // check if this is sane…
			[currentAT.bouquets addObject:currentService];
		else
			[currentAT.services addObject:currentService];

		self.currentService = nil;
	}
	else if(!strncmp((const char *)localname, kEnigma2Servicereference, kEnigma2ServicereferenceLength))
	{
		currentService.sref = currentString;
	}
	else if(!strncmp((const char *)localname, kEnigma2Tags, kEnigma2TagsLength))
	{
		currentAT.tags = [currentString componentsSeparatedByString:@" "];
	}

	// this either does nothing or releases the string that was in use
	self.currentString = nil;
}

@end