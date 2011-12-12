//
//  Enigma1Connector.m
//  dreaMote
//
//  Created by Moritz Venn on 08.03.08.
//  Copyright 2008-2011 Moritz Venn. All rights reserved.
//

#import "Enigma1Connector.h"

#import <Constants.h>

#import <Objects/Enigma/Service.h>
#import <Objects/Enigma/Timer.h>
#import <Objects/Generic/Movie.h>
#import <Objects/Generic/Service.h>
#import <Objects/Generic/Volume.h>
#import <Objects/TimerProtocol.h>
#import <Objects/MovieProtocol.h>

#import <SynchronousRequestReader.h>
#import <Delegates/ServiceSourceDelegate.h>
#import <Delegates/VolumeSourceDelegate.h>
#import <XMLReader/Enigma/EventXMLReader.h>
#import <XMLReader/Enigma/CurrentXMLReader.h>
#import <XMLReader/Enigma/MovieXMLReader.h>
#import <XMLReader/Enigma/SignalXMLReader.h>
#import <XMLReader/Enigma/TimerXMLReader.h>

#import <ViewController/EnigmaRCEmulatorController.h>

#import <Categories/NSString+URLEncode.h>

// Services are 'lightweight'
#define MAX_SERVICES 2048

/*! @brief Virtual Service Reference for 'All TV Services'. */
static NSString *enigmaAllServices = @"ALL_SERVICES_ENIGMA";
/*! @brief Virtual Service Reference for 'All Radio Services'. */
static NSString *enigmaAllRadioServices = @"ALL_RADIO_SERVICES_ENIGMA";

enum enigma1MessageTypes {
	kEnigma1MessageTypeInfo = 0,
	kEnigma1MessageTypeWarning = 1,
	kEnigma1MessageTypeQuestion = 2,
	kEnigma1MessageTypeError = 3,
	kEnigma1MessageTypeMax = 4
};

@implementation Enigma1Connector

- (const BOOL const)hasFeature: (enum connectorFeatures)feature
{
	return
		(feature == kFeaturesRadioMode) ||
		(feature == kFeaturesBouquets) ||
		//(feature == kFeaturesProviderList) ||
		(feature == kFeaturesStreaming) ||
		(feature == kFeaturesGUIRestart) ||
		(feature == kFeaturesRecordInfo) ||
		(feature == kFeaturesMessageCaption) ||
		(feature == kFeaturesMessageTimeout) ||
		(feature == kFeaturesMessageType) ||
		(feature == kFeaturesScreenshot) ||
		(feature == kFeaturesCombinedScreenshot) ||
		(feature == kFeaturesTimerAfterEvent) ||
		(feature == kFeaturesConstantTimerId) ||
		(feature == kFeaturesRecordDelete) ||
		(feature == kFeaturesInstantRecord) ||
		(feature == kFeaturesSatFinder) ||
		(feature == kFeaturesTimerRepeated) ||
		(feature == kFeaturesSimpleRepeated) ||
		(feature == kFeaturesCurrent) ||
		(feature == kFeaturesTimerTitle) ||
		(feature == kFeaturesTimerCleanup);
}

- (const NSUInteger const)getMaxVolume
{
	return 63;
}

- (id)initWithAddress: (NSString *)address andUsername: (NSString *)inUsername andPassword: (NSString *)inPassword andPort: (NSInteger)inPort useSSL: (BOOL)ssl
{
	if((self = [super init]))
	{
		// Protect from unexpected input and assume a full URL if address starts with http
		if([address rangeOfString: @"http"].location == 0)
		{
			_baseAddress = [[NSURL alloc] initWithString:address];
		}
		else
		{
			NSString *remoteAddress = nil;
			const NSString *scheme = ssl ? @"https://" : @"http://";
			remoteAddress = [NSString stringWithFormat: @"%@%@", scheme, address];
			if(inPort > 0)
				remoteAddress = [remoteAddress stringByAppendingFormat: @":%d", inPort];

			_baseAddress = [[NSURL alloc] initWithString:remoteAddress];
		}
		_bouquetsCacheLock = [[NSLock alloc] init];
	}
	return self;
}

+ (NSObject <RemoteConnector>*)newWithConnection:(const NSDictionary *)connection
{
	NSString *address = [connection objectForKey: kRemoteHost];
	NSString *username = [[connection objectForKey: kUsername] urlencode];
	NSString *password = [[connection objectForKey: kPassword] urlencode];
	const NSInteger port = [[connection objectForKey: kPort] integerValue];
	const BOOL ssl = [[connection objectForKey: kSSL] boolValue];

	return [[Enigma1Connector alloc] initWithAddress:address andUsername:username andPassword:password andPort:port useSSL:ssl];
}

+ (NSArray *)knownDefaultConnections
{
	NSNumber *connector = [NSNumber numberWithInteger:kEnigma1Connector];
	return [NSArray arrayWithObjects:
				[NSDictionary dictionaryWithObjectsAndKeys:
					@"dreambox", kRemoteHost,
					@"root", kUsername,
					@"dreambox", kPassword,
					@"NO", kSSL,
					connector, kConnector,
					nil],
				[NSDictionary dictionaryWithObjectsAndKeys:
					@"dm7020", kRemoteHost,
					@"root", kUsername,
					@"dreambox", kPassword,
					@"NO", kSSL,
					connector, kConnector,
					nil],
				[NSDictionary dictionaryWithObjectsAndKeys:
					@"dm600", kRemoteHost,
					@"root", kUsername,
					@"dreambox", kPassword,
					@"NO", kSSL,
					connector, kConnector,
					nil],
				[NSDictionary dictionaryWithObjectsAndKeys:
					@"dm500", kRemoteHost,
					@"root", kUsername,
					@"dreambox", kPassword,
					@"NO", kSSL,
					connector, kConnector,
					nil],
			nil];
}

+ (NSArray *)matchNetServices:(NSArray *)netServices
{
	// XXX: implement this?
	return nil;
}

- (void)freeCaches
{
	[_bouquetsCacheLock lock];

	xmlFreeDoc(_cachedBouquetsDoc);
	_cachedBouquetsDoc = NULL;

	[_bouquetsCacheLock unlock];
}

- (BOOL)isReachable:(NSError **)error
{
	// Generate URI
	NSURL *myURI = [NSURL URLWithString:@"/xml/boxstatus"  relativeToURL:_baseAddress];

	NSHTTPURLResponse *response;
	[SynchronousRequestReader sendSynchronousRequest:myURI
								   returningResponse:&response
											   error:error];

	if([response statusCode] == 200)
	{
		return YES;
	}
	else
	{
		// no connection error but unexpected status, generate error
		if(error != nil && *error == nil)
		{
			*error = [NSError errorWithDomain:@"myDomain"
										 code:99
									 userInfo:[NSDictionary dictionaryWithObject:[NSString stringWithFormat:NSLocalizedString(@"Connection to remote host failed with status code %d.", @""), [response statusCode]] forKey:NSLocalizedDescriptionKey]];
		}
		return NO;
	}
}

- (UIViewController *)newRCEmulator
{
	return [[EnigmaRCEmulatorController alloc] init];
}

- (void)indicateError:(NSObject<DataSourceDelegate> *)delegate error:(__unsafe_unretained NSError *)error
{
	// check if delegate wants to be informated about errors
	SEL errorParsing = @selector(dataSourceDelegate:errorParsingDocument:);
	NSMethodSignature *sig = [delegate methodSignatureForSelector:errorParsing];
	if(delegate && [delegate respondsToSelector:errorParsing] && sig)
	{
		NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:sig];
		[invocation retainArguments];
		[invocation setTarget:delegate];
		[invocation setSelector:errorParsing];
		[invocation setArgument:&error atIndex:3];
		[invocation performSelectorOnMainThread:@selector(invoke) withObject:NULL
								  waitUntilDone:NO];
	}
}

- (void)indicateSuccess:(NSObject<DataSourceDelegate> *)delegate
{
	// check if delegate wants to be informated about parsing end
	SEL finishedParsing = @selector(dataSourceDelegateFinishedParsingDocument:);
	NSMethodSignature *sig = [delegate methodSignatureForSelector:finishedParsing];
	if(delegate && [delegate respondsToSelector:finishedParsing] && sig)
	{
		NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:sig];
		[invocation retainArguments];
		[invocation setTarget:delegate];
		[invocation setSelector:finishedParsing];
		[invocation performSelectorOnMainThread:@selector(invoke) withObject:NULL
								  waitUntilDone:NO];
	}
}

# pragma mark Services

- (Result *)zapInternal: (NSString *)sref
{
	Result *result = [Result createResult];

	// Generate URI
	NSURL *myURI = [NSURL URLWithString: [NSString stringWithFormat:@"/cgi-bin/zapTo?mode=zap&path=%@", [sref urlencode]] relativeToURL: _baseAddress];

	NSHTTPURLResponse *response;
	[SynchronousRequestReader sendSynchronousRequest:myURI
								   returningResponse:&response
											   error:nil];

	result.result = ([response statusCode] == 204);
	result.resulttext = [NSHTTPURLResponse localizedStringForStatusCode: [response statusCode]];
	return result;
}

- (Result *)zapTo:(NSObject<ServiceProtocol> *) service
{
	return [self zapInternal: service.sref];
}

/*
 Example:
 <?xml version="1.0" encoding="UTF-8"?>
 <bouquets>
 <bouquet><reference>4097:7:0:33fc5:0:0:0:0:0:0:/var/tuxbox/config/enigma/userbouquet.33fc5.tv</reference><name>Favourites (TV)</name>
 <service><reference>1:0:1:6dca:44d:1:c00000:0:0:0:</reference><name>Das Erste</name><provider>ARD</provider><orbital_position>192</orbital_position></service>
 </bouquet>
 </bouquets>
 */
- (NSError *)maybeRefreshBouquetsXMLCache:(cacheType)requestedCacheType
{
	NSError *error = nil;
	@synchronized(self)
	{
		if(_cachedBouquetsDoc == NULL || _cacheType != requestedCacheType)
		{
			NSInteger mode = 0;
			if(requestedCacheType & CACHE_TYPE_RADIO)
				mode = 1;
			NSInteger submode = 4;
			if(requestedCacheType & CACHE_MASK_PROVIDER)
				submode = 3;
			else if(requestedCacheType & CACHE_MASK_ALL)
				submode = 5;
			_cacheType = requestedCacheType;

			NSURL *myURI = [NSURL URLWithString:[NSString stringWithFormat:@"/xml/services?mode=%d&submode=%d", mode, submode] relativeToURL:_baseAddress];
			NSHTTPURLResponse *response;
			NSData *data = [SynchronousRequestReader sendSynchronousRequest:myURI
														  returningResponse:&response
																	  error:&error];

			xmlFreeDoc(_cachedBouquetsDoc); // free possible old document
			if(error)
				_cachedBouquetsDoc = NULL;
			else
			{
				_cachedBouquetsDoc = xmlReadMemory([data bytes], [data length], "", NULL, XML_PARSE_RECOVER | XML_PARSE_NOENT);
				if(_cachedBouquetsDoc == NULL)
				{
					NSString *errorText = nil;
					xmlErrorPtr theLastErrorPtr = xmlGetLastError();
					if(theLastErrorPtr)
						errorText = [NSString stringWithUTF8String:theLastErrorPtr->message];
					else
						errorText = NSLocalizedString(@"Unknown parsing error occured.", @"Data parsing failed for unknown reason.");
					error = [NSError errorWithDomain:@"myDomain"
												code:101
											userInfo:[NSDictionary dictionaryWithObject:errorText forKey:NSLocalizedDescriptionKey]];
				}
			}
		}
	}
	return error;
}

- (BaseXMLReader *)fetchBouquetsOrProvider:(NSObject<ServiceSourceDelegate> *)delegate cacheType:(cacheType)requestedCacheType
{
	[_bouquetsCacheLock lock];
	xmlFreeDoc(_cachedBouquetsDoc); _cachedBouquetsDoc = NULL; // TODO: bouquets always force a reload
	NSError *error = [self maybeRefreshBouquetsXMLCache:requestedCacheType];
	if(error)
	{
		NSObject<ServiceProtocol> *fakeService = [[GenericService alloc] init];
		fakeService.sname = NSLocalizedString(@"Error retrieving Data", @"");
		[delegate performSelectorOnMainThread: @selector(addService:)
								   withObject: fakeService
								waitUntilDone: NO];

		[self indicateError:delegate error:error];
		[_bouquetsCacheLock unlock];
		return nil;
	}

	xmlXPathContextPtr xpathCtx = NULL;
	xmlXPathObjectPtr xpathObj = NULL;
	const BOOL isProvider = (requestedCacheType & CACHE_MASK_PROVIDER);
	do
	{
		xmlNodeSetPtr nodes;

		xpathCtx = xmlXPathNewContext(_cachedBouquetsDoc);
		if(!xpathCtx) break;

		// get state
		xpathObj = xmlXPathEvalExpression((xmlChar *)(isProvider ? "/providers/provider" : "/bouquets/bouquet"), xpathCtx);
		if(!xpathObj) break;

		nodes = xpathObj->nodesetval;
		if(!nodes) break;

		for(NSInteger i = 0; i < nodes->nodeNr; ++i)
		{
			xmlNodePtr cur = nodes->nodeTab[i];
			EnigmaService *newService = [[EnigmaService alloc] init];
			newService.isBouquet = !isProvider;

			for(xmlNodePtr child = cur->children; child; child = child->next)
			{
				if(!strncmp((const char *)child->name, kEnigmaName, kEnigmaNameLength))
				{
					xmlChar *stringVal = xmlNodeListGetString(_cachedBouquetsDoc, child->children, 1);
					newService.sname = [NSString stringWithCString:(const char *)stringVal encoding:NSUTF8StringEncoding];
					xmlFree(stringVal);
				}
				else if(!strncmp((const char *)child->name, kEnigmaReference, kEnigmaReferenceLength))
				{
					xmlChar *stringVal = xmlNodeListGetString(_cachedBouquetsDoc, child->children, 1);
					newService.sref = [NSString stringWithCString:(const char *)stringVal encoding:NSUTF8StringEncoding];
					xmlFree(stringVal);
				}
			}

			[delegate performSelectorOnMainThread:@selector(addService:) withObject:newService waitUntilDone:NO];
		}
	} while(0);
	xmlXPathFreeObject(xpathObj);
	xmlXPathFreeContext(xpathCtx);

	[self indicateSuccess:delegate];
	[_bouquetsCacheLock unlock];
	return nil;
}

- (BaseXMLReader *)fetchBouquets:(NSObject<ServiceSourceDelegate> *)delegate isRadio:(BOOL)isRadio
{
	return [self fetchBouquetsOrProvider:delegate cacheType:CACHE_MASK_BOUQUET|(isRadio ? CACHE_TYPE_RADIO : CACHE_TYPE_TV)];
}

- (BaseXMLReader *)fetchProviders:(NSObject<ServiceSourceDelegate> *)delegate isRadio:(BOOL)isRadio
{
	return [self fetchBouquetsOrProvider:delegate cacheType:CACHE_MASK_PROVIDER|(isRadio ? CACHE_TYPE_RADIO : CACHE_TYPE_TV)];
}

- (NSObject<ServiceProtocol> *)allServicesBouquet:(BOOL)isRadio
{
	GenericService *service = [[GenericService alloc] init];
	service.sname = NSLocalizedString(@"All Services", @"Name of 'All Services'-Bouquet");
	if(isRadio)
		service.sref = enigmaAllRadioServices;
	else
		service.sref = enigmaAllServices;
	return service;
}

- (BaseXMLReader *)fetchServices:(NSObject<ServiceSourceDelegate> *)delegate bouquet:(NSObject<ServiceProtocol> *)bouquet isRadio:(BOOL)isRadio
{
	// split view on ipad
	if(!bouquet)
	{
		[self indicateSuccess:delegate];
		return nil;
	}

	[_bouquetsCacheLock lock];

	// Gather information on the needed cache type
	cacheType thisType = (isRadio ? CACHE_TYPE_RADIO : CACHE_TYPE_TV);
	NSString *sref = bouquet.sref;
	if(sref == enigmaAllServices || sref == enigmaAllRadioServices)
	{
		thisType |= CACHE_MASK_ALL;
	}
	else if([bouquet isKindOfClass:[EnigmaService class]])
	{
		thisType |= (((EnigmaService *)bouquet).isBouquet) ? CACHE_MASK_BOUQUET : CACHE_MASK_PROVIDER;
	}

	// if cache type is wrong, try to load cache and abort on failure
	if(_cacheType != thisType)
	{
#if IS_DEBUG()
		NSLog(@"[Enigma1Connector] Cached document has type %d but expecting type %d, reloading.", _cacheType, thisType);
#endif
		NSError *error = [self maybeRefreshBouquetsXMLCache:thisType];
		if(error)
		{
			NSObject<ServiceProtocol> *fakeService = [[GenericService alloc] init];
			fakeService.sname = NSLocalizedString(@"Error retrieving Data", @"");
			[delegate performSelectorOnMainThread: @selector(addService:)
									   withObject: fakeService
									waitUntilDone: NO];

			[self indicateError:delegate error:error];
			[_bouquetsCacheLock unlock];
			return nil;
		}
	}
#if IS_DEBUG()
	else
		NSLog(@"[Enigma1Connector] Cached document has correct type.");
#endif

	NSString *xpath = nil;
	if(thisType & CACHE_MASK_BOUQUET)
		xpath = [NSString stringWithFormat: @"/bouquets/bouquet[reference=\"%@\"]/service", bouquet.sref];
	else if(thisType & CACHE_MASK_PROVIDER)
		xpath = [NSString stringWithFormat: @"/providers/provider[reference=\"%@\"]/service", bouquet.sref];
	else if(thisType & CACHE_MASK_ALL)
		xpath = @"/*/*/service";
	else
	{
		NSLog(@"[Enigma1Connector] Incomplete mask - doing our best!");
		xpath = [NSString stringWithFormat: @"/*/*[reference=\"%@\"]/service", bouquet.sref];
	}

	xmlXPathContextPtr xpathCtx = NULL;
	xmlXPathObjectPtr xpathObj = NULL;
	do
	{
		xmlNodeSetPtr nodes;

		xpathCtx = xmlXPathNewContext(_cachedBouquetsDoc);
		if(!xpathCtx) break;

		// get state
		xpathObj = xmlXPathEvalExpression((xmlChar *)[xpath cStringUsingEncoding:NSUTF8StringEncoding], xpathCtx);
		if(!xpathObj) break;

		nodes = xpathObj->nodesetval;
		if(!nodes) break;

		for(NSInteger i = 0; i < nodes->nodeNr; ++i)
		{
			xmlNodePtr cur = nodes->nodeTab[i];
			GenericService *newService = [[GenericService alloc] init];

			for(xmlNodePtr child = cur->children; child; child = child->next)
			{
				if(!strncmp((const char *)child->name, kEnigmaName, kEnigmaNameLength))
				{
					xmlChar *stringVal = xmlNodeListGetString(_cachedBouquetsDoc, child->children, 1);
					newService.sname = [NSString stringWithCString:(const char *)stringVal encoding:NSUTF8StringEncoding];
					xmlFree(stringVal);
				}
				else if(!strncmp((const char *)child->name, kEnigmaReference, kEnigmaReferenceLength))
				{
					xmlChar *stringVal = xmlNodeListGetString(_cachedBouquetsDoc, child->children, 1);
					newService.sref = [NSString stringWithCString:(const char *)stringVal encoding:NSUTF8StringEncoding];
					xmlFree(stringVal);
				}
			}

			[delegate performSelectorOnMainThread:@selector(addService:) withObject:newService waitUntilDone:NO];
		}
	} while(0);
	xmlXPathFreeObject(xpathObj);
	xmlXPathFreeContext(xpathCtx);

	[self indicateSuccess:delegate];
	[_bouquetsCacheLock unlock];
	return nil;
}

- (BaseXMLReader *)fetchEPG: (NSObject<EventSourceDelegate> *)delegate service:(NSObject<ServiceProtocol> *)service
{
	NSURL *myURI = [NSURL URLWithString: [NSString stringWithFormat:@"/xml/serviceepg?ref=%@", [service.sref urlencode]] relativeToURL: _baseAddress];

	NSError *parseError = nil;

	BaseXMLReader *streamReader = [[EnigmaEventXMLReader alloc] initWithDelegate:delegate];
	[streamReader parseXMLFileAtURL:myURI parseError:&parseError];
	return streamReader;
}

- (NSURL *)getStreamURLForService:(NSObject<ServiceProtocol> *)service
{
	// handle services which are actually recordings
	if([service.sref rangeOfString:@"/hdd/movie/"].location != NSNotFound)
	{
		NSObject<MovieProtocol> *movie = [[GenericMovie alloc] init];
		movie.sref = service.sref;
		NSURL *myURI = [self getStreamURLForMovie:movie];
		return myURI;
	}

	// XXX: we first zap on the receiver and subsequently retrieve the new streaming url, any way to optimize this?
	Result *result = [self zapTo:service];
	if(result.result)
	{
		[NSThread sleepForTimeInterval:1]; // sleep for one second to have a little time for tuning
		NSURL *myURI = [NSURL URLWithString:@"/video.m3u" relativeToURL:_baseAddress];

		NSHTTPURLResponse *response;
		NSError *error = nil;
		NSData *data = [SynchronousRequestReader sendSynchronousRequest:myURI
													  returningResponse:&response
																  error:&error];

		NSString *myString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
		myURI = [NSURL URLWithString:myString];
		return myURI;
	}
	return nil;
}

#pragma mark Timer

- (BaseXMLReader *)fetchTimers: (NSObject<TimerSourceDelegate> *)delegate
{
	NSURL *myURI = [NSURL URLWithString: @"/xml/timers" relativeToURL: _baseAddress];

	NSError *parseError = nil;

	BaseXMLReader *streamReader = [[EnigmaTimerXMLReader alloc] initWithDelegate:delegate];
	[streamReader parseXMLFileAtURL:myURI parseError:&parseError];
	return streamReader;
}

- (Result *)addTimer:(NSObject<TimerProtocol> *) newTimer
{
	const NSUInteger repeated = newTimer.repeated;
	Result *result = [Result createResult];
	NSUInteger afterEvent = 0;
	NSURL *myURI = nil;

	switch(newTimer.afterevent)
	{
		case kAfterEventStandby:
			afterEvent = doGoSleep;
			break;
		case kAfterEventDeepstandby:
			afterEvent = doShutdown;
			break;
		case kAfterEventNothing:
		default:
			afterEvent = 0;
	}

	if(repeated == 0)
	{
		// Generate non-repeated URI
		myURI = [NSURL URLWithString: [NSString stringWithFormat: @"/addTimerEvent?timer=regular&ref=%@&start=%d&duration=%d&descr=%@&after_event=%d&action=%@", [newTimer.service.sref urlencode], (int)[newTimer.begin timeIntervalSince1970], (int)([newTimer.end timeIntervalSince1970] - [newTimer.begin timeIntervalSince1970]), [newTimer.title urlencode], afterEvent, newTimer.justplay ? @"zap" : @"record"] relativeToURL: _baseAddress];
	}
	else
	{
		// XXX: we theoretically could "inject" our weekday flags into the type but
		// lets try to avoid more ugly hacks than this code already has :-)

		// Generate repeated URI
		myURI = [NSURL URLWithString: [NSString stringWithFormat: @"/addTimerEvent?timer=repeating&ref=%@&start=%d&duration=%d&descr=%@&after_event=%d&action=%@&mo=%@&tu=%@&we=%@&th=%@&fr=%@&sa=%@&su=%@", [newTimer.service.sref urlencode], (int)[newTimer.begin timeIntervalSince1970], (int)([newTimer.end timeIntervalSince1970] - [newTimer.begin timeIntervalSince1970]), [newTimer.title urlencode], afterEvent, newTimer.justplay ? @"zap" : @"record", (repeated & weekdayMon) > 0 ? @"on" : @"off", (repeated & weekdayTue) > 0 ? @"on" : @"off", (repeated & weekdayWed) > 0 ? @"on" : @"off", (repeated & weekdayThu) > 0 ? @"on" : @"off", (repeated & weekdayFri) > 0 ? @"on" : @"off", (repeated & weekdaySat) > 0 ? @"on" : @"off", (repeated & weekdaySun) > 0 ? @"on" : @"off"] relativeToURL: _baseAddress];
	}

	NSData *data = [SynchronousRequestReader sendSynchronousRequest:myURI
												  returningResponse:nil
															  error:nil];

	NSString *myString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

	const NSRange myRange = [myString rangeOfString: @"Timer event was created successfully."];
	result.result = (myRange.length > 0);
	result.resulttext = myString;
	return result;
}

- (Result *)editTimer:(NSObject<TimerProtocol> *) oldTimer: (NSObject<TimerProtocol> *) newTimer
{
	// This is the only way I found in enigma sources as changeTimerEvent does not allow us e.g. to change the service
	Result *result = [self delTimer: oldTimer];

	// removing original timer succeeded
	if(result.result)
	{
		result = [self addTimer: newTimer];
		// failed to add new one, try to recover from failure
		if(result.result == NO)
		{
			Result *result2 = [self addTimer: oldTimer];
			// old timer re-added
			if(result2.result)
			{
				result.result = NO;
				result.resulttext = [NSString stringWithFormat: NSLocalizedString(@"Could not add new timer (%@)!", @""), result.resulttext];
			}
			// could not re-add old timer
			else
			{
				result.result = NO;
				result.resulttext = [NSString stringWithFormat: NSLocalizedString(@"Could not add new timer and failed to retain original one! (%@)", @""), result2.resulttext];
			}
		}

		return result;
	}

	result.result = NO;
	result.resulttext = [NSString stringWithFormat: NSLocalizedString(@"Could not remove base timer (%@)!", @""), result.resulttext];
	return result;
}

- (Result *)delTimer:(NSObject<TimerProtocol> *) oldTimer
{
	Result *result = [Result createResult];
	NSString *append = nil;
	if([oldTimer respondsToSelector:@selector(typedata)])
		append = [NSString stringWithFormat:@"&type=%d", ((EnigmaTimer *)oldTimer).typedata];
	else
		append = @"";

	// Generate URI
	NSURL *myURI = [NSURL URLWithString: [NSString stringWithFormat: @"/deleteTimerEvent?ref=%@&start=%d&force=yes%@", [oldTimer.service.sref urlencode], (int)[oldTimer.begin timeIntervalSince1970], append] relativeToURL: _baseAddress];

	NSData *data = [SynchronousRequestReader sendSynchronousRequest:myURI
												  returningResponse:nil
															  error:nil];

	NSString *myString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

	const NSRange myRange = [myString rangeOfString: @"Timer event deleted successfully."];
	result.result = (myRange.length > 0);
	result.resulttext = myString;
	return result;
}

- (Result *)cleanupTimers:(const NSArray *)timers
{
	Result *result = [Result createResult];
	NSURL *myURI = [NSURL URLWithString:@"/cleanupTimerList" relativeToURL:_baseAddress];

	NSHTTPURLResponse *response;
	[SynchronousRequestReader sendSynchronousRequest:myURI
								   returningResponse:&response
											   error:nil];

	result.result = ([response statusCode] == 204);
	result.resulttext = [NSHTTPURLResponse localizedStringForStatusCode:[response statusCode]];
	return result;
}

#pragma mark Recordings

- (Result *)playMovie:(NSObject<MovieProtocol> *) movie
{
	return [self zapInternal: movie.sref];
}

- (BaseXMLReader *)fetchMovielist: (NSObject<MovieSourceDelegate> *)delegate withLocation:(NSString *)location
{
	if(location != nil)
	{
#if IS_DEBUG()
		[NSException raise:@"ExcUnsupportedFunction" format:@""];
#endif
		return nil;
	}

	NSURL *myURI = [NSURL URLWithString: @"/xml/services?mode=3&submode=4" relativeToURL: _baseAddress];

	NSError *parseError = nil;

	BaseXMLReader *streamReader = [[EnigmaMovieXMLReader alloc] initWithDelegate:delegate];
	[streamReader parseXMLFileAtURL:myURI parseError:&parseError];
	return streamReader;
}

- (Result *)delMovie:(NSObject<MovieProtocol> *) movie
{
	Result *result = [Result createResult];

	// Generate URI
	NSURL *myURI = [NSURL URLWithString:[NSString stringWithFormat:@"/cgi-bin/deleteMovie?ref=%@", [movie.sref urlencode]] relativeToURL:_baseAddress];

	NSHTTPURLResponse *response;
	[SynchronousRequestReader sendSynchronousRequest:myURI
								   returningResponse:&response
											   error:nil];

	result.result = ([response statusCode] == 204);
	result.resulttext = [NSHTTPURLResponse localizedStringForStatusCode: [response statusCode]];
	return result;
}

- (Result *)instantRecord
{
	Result *result = [Result createResult];

	// Generate URI
	NSURL *myURI = [NSURL URLWithString:@"/cgi-bin/videocontrol?command=record" relativeToURL:_baseAddress];

	NSHTTPURLResponse *response;
	[SynchronousRequestReader sendSynchronousRequest:myURI
								   returningResponse:&response
											   error:nil];

	result.result = ([response statusCode] == 204);
	result.resulttext = [NSHTTPURLResponse localizedStringForStatusCode: [response statusCode]];
	return result;
}

- (NSURL *)getStreamURLForMovie:(NSObject<MovieProtocol> *)movie
{
	NSURL *myURI = [NSURL URLWithString:[NSString stringWithFormat:@"/movie.m3u?ref=%@", [movie.sref urlencode]] relativeToURL:_baseAddress];

	NSHTTPURLResponse *response;
	NSError *error = nil;
	NSData *data = [SynchronousRequestReader sendSynchronousRequest:myURI
												  returningResponse:&response
															  error:&error];

	NSString *myString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	myURI = [NSURL URLWithString:myString];
	return myURI;
}

#pragma mark Control

- (BaseXMLReader *)getCurrent: (NSObject<EventSourceDelegate,ServiceSourceDelegate> *)delegate
{
	NSURL *myURI = [NSURL URLWithString: @"/xml/currentservicedata" relativeToURL: _baseAddress];

	BaseXMLReader *streamReader = [[EnigmaCurrentXMLReader alloc] initWithDelegate:delegate];
	[streamReader parseXMLFileAtURL:myURI parseError:nil];
	return streamReader;
}

- (void)sendPowerstate: (NSString *) newState
{
	// Generate URI
	NSURL *myURI = [NSURL URLWithString: [NSString stringWithFormat:@"/cgi-bin/admin?command=%@", newState] relativeToURL: _baseAddress];

	[SynchronousRequestReader sendSynchronousRequest:myURI
								   returningResponse:nil
											   error:nil];
}

- (void)shutdown
{
	[self sendPowerstate: @"shutdown"];
}

- (void)standby
{
	// NOTE: we send remote control command button power here as we want to toggle standby
	[self sendButton: kButtonCodePower];
}

- (void)reboot
{
	[self sendPowerstate: @"reboot"];
}

- (void)restart
{
	[self sendPowerstate: @"restart"];
}

- (void)getVolume: (NSObject<VolumeSourceDelegate> *)delegate
{
	// Generate URI
	NSURL *myURI = [NSURL URLWithString: @"/cgi-bin/audio" relativeToURL: _baseAddress];

	NSData *data = [SynchronousRequestReader sendSynchronousRequest:myURI
												  returningResponse:nil
															  error:nil];

	const NSString *myString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

	GenericVolume *volumeObject = [[GenericVolume alloc] init];
	NSInteger volume = -1;

	NSRange firstRange = [myString rangeOfString: @"volume: "];
	NSRange secondRange;
	if(firstRange.length)
	{
		secondRange = [myString rangeOfString: @"<br>"];
		firstRange.location = firstRange.length;
		firstRange.length = secondRange.location - firstRange.location;

		// Invert volume range we get to ease usage
		volume = 63 - [[myString substringWithRange: firstRange] integerValue];
	}
	volumeObject.current = volume;

	firstRange = [myString rangeOfString: @"mute: "];
	if(firstRange.length)
	{
		firstRange.location = firstRange.length;
		firstRange.length = 1;

		volumeObject.ismuted = [[myString substringWithRange: firstRange] isEqualToString: @"1"];
	}
	else
		volumeObject.ismuted = NO;


	[delegate performSelectorOnMainThread: @selector(addVolume:)
							   withObject: volumeObject
							waitUntilDone: NO];
}

- (BOOL)toggleMuted
{
	// Generate URI
	NSURL *myURI = [NSURL URLWithString: @"/cgi-bin/audio?mute=xy" relativeToURL: _baseAddress];

	NSData *data = [SynchronousRequestReader sendSynchronousRequest:myURI
												  returningResponse:nil
															  error:nil];

	const NSString *myString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

	const NSRange myRange = [myString rangeOfString: @"mute: 1"];
	return (myRange.length > 0);
}

- (Result *)setVolume:(NSInteger) newVolume
{
	Result *result = [Result createResult];

	// Generate URI
	NSURL *myURI = [NSURL URLWithString: [NSString stringWithFormat:@"/cgi-bin/audio?volume=%d", 63 - newVolume] relativeToURL: _baseAddress];

	NSData *data = [SynchronousRequestReader sendSynchronousRequest:myURI
												  returningResponse:nil
															  error:nil];

	NSString *myString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

	const NSRange myRange = [myString rangeOfString: @"Volume set."];
	result.result = (myRange.length > 0);
	result.resulttext = myString;
	return result;
}

- (Result *)sendButton:(NSInteger) type
{
	Result *result = [Result createResult];

	// Fix some Buttoncodes
	switch(type)
	{
		case kButtonCodeLame: type = 1; break;
		case kButtonCodeMenu: type = 141; break;
		case kButtonCodeTV: type = 385; break;
		case kButtonCodeRadio: type = 377; break;
		case kButtonCodeText: type = 66; break;
		default: break;
	}

	// Generate URI
	NSURL *myURI = [NSURL URLWithString: [NSString stringWithFormat: @"/cgi-bin/rc?%d", type] relativeToURL: _baseAddress];

	NSHTTPURLResponse *response;
	[SynchronousRequestReader sendSynchronousRequest:myURI
								   returningResponse:&response
											  error:nil];

	result.result = ([response statusCode] == 204);
	result.resulttext = [NSHTTPURLResponse localizedStringForStatusCode: [response statusCode]];
	return result;
}

#pragma mark Signal

- (void)getSignal: (NSObject<SignalSourceDelegate> *)delegate
{
	NSURL *myURI = [NSURL URLWithString: @"/xml/streaminfo" relativeToURL: _baseAddress];

	NSError *parseError = nil;

	const BaseXMLReader *streamReader = [[EnigmaSignalXMLReader alloc] initWithDelegate: delegate];
	[streamReader parseXMLFileAtURL: myURI parseError: &parseError];
}

#pragma mark Messaging

- (Result *)sendMessage:(NSString *)message: (NSString *)caption: (NSInteger)type: (NSInteger)timeout
{
	Result *result = [Result createResult];

	NSInteger translatedType = -1;
	switch(type)
	{
		case kEnigma1MessageTypeInfo:
			translatedType = 16;
			break;
		case kEnigma1MessageTypeWarning:
			translatedType = 32;
			break;
		case kEnigma1MessageTypeQuestion:
			translatedType = 64;
			break;
		case kEnigma1MessageTypeError:
			translatedType = 128;
			break;
		default:
			translatedType = -1;
	}

	// Generate URI
	NSURL *myURI = [NSURL URLWithString: [NSString stringWithFormat: @"/cgi-bin/xmessage?body=%@&caption=%@&timeout=%d&icon=%d", [message  urlencode], [caption  urlencode], timeout, translatedType] relativeToURL: _baseAddress];

	NSData *data = [SynchronousRequestReader sendSynchronousRequest:myURI
												  returningResponse:nil
															  error:nil];

	NSString *myString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

	const NSRange myRange = [myString rangeOfString: @"+ok"];
	result.result = (myRange.length > 0);
	result.resulttext = myString;
	return result;
}

- (const NSUInteger const)getMaxMessageType
{
	return kEnigma1MessageTypeMax;
}

- (NSString *)getMessageTitle: (NSUInteger)type
{
	switch(type)
	{
		case kEnigma1MessageTypeInfo:
			return NSLocalizedString(@"Info", @"Message type");
		case kEnigma1MessageTypeWarning:
			return NSLocalizedString(@"Warning", @"Message type");
		case kEnigma1MessageTypeQuestion:
			return NSLocalizedString(@"Question", @"Message type");
		case kEnigma1MessageTypeError:
			return NSLocalizedString(@"Error", @"Message type");
		default:
			return @"???";
	}
}

#pragma mark Screenshots

- (NSData *)getScreenshot: (enum screenshotType)type
{
	if(type == kScreenshotTypeOSD)
	{
		// Generate URI
		NSURL *myURI = [NSURL URLWithString: @"/cgi-bin/osdshot?display=yes" relativeToURL: _baseAddress];

		NSData *data = [SynchronousRequestReader sendSynchronousRequest:myURI
													  returningResponse:nil
																  error:nil];

		return data;
	}
	else// We actually generate a combined picture here
	{
		// We need to trigger a capture and individually fetch the picture
		// Generate URI
		NSURL *myURI = [NSURL URLWithString: @"/body?mode=controlScreenShot" relativeToURL: _baseAddress];

		NSData *data = [SynchronousRequestReader sendSynchronousRequest:myURI
													  returningResponse:nil
																  error:nil];

		const NSString *myString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
		const NSRange myRange = [myString rangeOfString: @"/root/tmp/screenshot.jpg"];
		const NSRange myRangeBmp = [myString rangeOfString: @"/root/tmp/screenshot.bmp"];

		// Generate URI
		if(myRange.length)
			myURI = [NSURL URLWithString: @"/root/tmp/screenshot.jpg" relativeToURL: _baseAddress];
		else if(myRangeBmp.length)
			myURI = [NSURL URLWithString: @"/root/tmp/screenshot.bmp" relativeToURL: _baseAddress];
		else
			return nil;

		data = [SynchronousRequestReader sendSynchronousRequest:myURI
											  returningResponse:nil
														  error:nil];

		return data;
	}

	return nil;
}

#pragma mark Unsupported

- (BaseXMLReader *)fetchLocationlist: (NSObject<LocationSourceDelegate> *)delegate;
{
#if IS_DEBUG()
	[NSException raise:@"ExcUnsupportedFunction" format:@""];
#endif
	return nil;
}

@end
