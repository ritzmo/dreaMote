//
//  Enigma1Connector.m
//  dreaMote
//
//  Created by Moritz Venn on 08.03.08.
//  Copyright 2008-2011 Moritz Venn. All rights reserved.
//

#import "Enigma1Connector.h"

#import "Objects/Enigma/Service.h"
#import "Objects/Generic/Service.h"
#import "Objects/Generic/Volume.h"
#import "Objects/TimerProtocol.h"
#import "Objects/MovieProtocol.h"

#import "SynchronousRequestReader.h"
#import "ServiceSourceDelegate.h"
#import "VolumeSourceDelegate.h"
#import "XMLReader/Enigma/EventXMLReader.h"
#import "XMLReader/Enigma/CurrentXMLReader.h"
#import "XMLReader/Enigma/MovieXMLReader.h"
#import "XMLReader/Enigma/SignalXMLReader.h"
#import "XMLReader/Enigma/TimerXMLReader.h"

#import "EnigmaRCEmulatorController.h"
#import "SimpleRCEmulatorController.h"

#import "NSString+URLEncode.h"

// Services are 'lightweight'
#define MAX_SERVICES 2048

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
		(feature == kFeaturesBouquets) ||
		(feature == kFeaturesGUIRestart) ||
		(feature == kFeaturesRecordInfo) ||
		(feature == kFeaturesMessageCaption) ||
		(feature == kFeaturesMessageTimeout) ||
		(feature == kFeaturesMessageType) ||
		(feature == kFeaturesScreenshot) ||
		(feature == kFeaturesTimerAfterEvent) ||
		(feature == kFeaturesConstantTimerId) ||
		(feature == kFeaturesRecordDelete) ||
		(feature == kFeaturesInstantRecord) ||
		(feature == kFeaturesSatFinder) ||
		(feature == kFeaturesSimpleRepeated) ||
		(feature == kFeaturesCurrent);
}

- (const NSUInteger const)getMaxVolume
{
	return 63;
}

+ (NSObject <RemoteConnector>*)newWithAddress:(NSString *) address andUsername: (NSString *)inUsername andPassword: (NSString *)inPassword andPort: (NSInteger)inPort useSSL: (BOOL)ssl
{
	return (NSObject <RemoteConnector>*)[[Enigma1Connector alloc] initWithAddress: address andUsername: inUsername andPassword: inPassword andPort: inPort useSSL: (BOOL)ssl];
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
			if([inUsername isEqualToString: @""])
				remoteAddress = [NSString stringWithFormat: @"%@%@", scheme, address];
			else
				remoteAddress = [NSString stringWithFormat: @"%@%@:%@@%@", scheme, inUsername,
								inPassword, address];
			if(inPort > 0)
				remoteAddress = [remoteAddress stringByAppendingFormat: @":%d", inPort];

			_baseAddress = [[NSURL alloc] initWithString:remoteAddress];
		}
	}
	return self;
}

- (void)dealloc
{
	[_baseAddress release];
	[_cachedBouquetsXML release];

	[super dealloc];
}

- (void)freeCaches
{
	[_cachedBouquetsXML release];
	_cachedBouquetsXML = nil;
}

- (BOOL)isReachable
{
	// Generate URI
	NSURL *myURI = [NSURL URLWithString:@"/xml/boxstatus"  relativeToURL:_baseAddress];

	NSHTTPURLResponse *response;
	[SynchronousRequestReader sendSynchronousRequest:myURI
								   returningResponse:&response
											   error:nil];

	return ([response statusCode] == 200);
}

- (UIViewController *)newRCEmulator
{
	return [[EnigmaRCEmulatorController alloc] init];
}

- (void)indicateError:(NSObject<DataSourceDelegate> *)delegate error:(NSError *)error
{
	// check if delegate wants to be informated about errors
	SEL errorParsing = @selector(dataSourceDelegate:errorParsingDocument:error:);
	NSMethodSignature *sig = [delegate methodSignatureForSelector:errorParsing];
	if(delegate && [delegate respondsToSelector:errorParsing] && sig)
	{
		NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:sig];
		[invocation retainArguments];
		[invocation setTarget:delegate];
		[invocation setSelector:errorParsing];
		[invocation setArgument:&error atIndex:4];
		[invocation performSelectorOnMainThread:@selector(invoke) withObject:NULL
								  waitUntilDone:NO];
	}
}

- (void)indicateSuccess:(NSObject<DataSourceDelegate> *)delegate
{
	// check if delegate wants to be informated about parsing end
	SEL finishedParsing = @selector(dataSourceDelegate:finishedParsingDocument:);
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
- (NSError *)refreshBouquetsXMLCache
{
	NSURL *myURI = [NSURL URLWithString: @"/xml/services?mode=0&submode=4" relativeToURL: _baseAddress];
	NSError *returnValue = nil;

	const BaseXMLReader *streamReader = [[BaseXMLReader alloc] init];
	_cachedBouquetsXML = [[streamReader parseXMLFileAtURL: myURI parseError: &returnValue] retain];
	[streamReader release];
	return returnValue;
}

- (CXMLDocument *)fetchBouquets:(NSObject<ServiceSourceDelegate> *)delegate isRadio:(BOOL)isRadio
{
	if(isRadio)
	{
		[NSException raise:@"ExcUnsupportedFunction" format:@""];
		return nil;
	}

	if(!_cachedBouquetsXML || [_cachedBouquetsXML retainCount] == 1)
	{
		[_cachedBouquetsXML release];
		NSError *error = [self refreshBouquetsXMLCache];
		if(error)
		{
			NSObject<ServiceProtocol> *fakeService = [[GenericService alloc] init];
			fakeService.sname = NSLocalizedString(@"Error retrieving Data", @"");
			[delegate performSelectorOnMainThread: @selector(addService:)
										withObject: fakeService
									 waitUntilDone: NO];
			[fakeService release];

			[self indicateError:delegate error:error];
			return nil;
		}
	}

	NSArray *resultNodes = nil;
	NSUInteger parsedServicesCounter = 0;

	resultNodes = [_cachedBouquetsXML nodesForXPath:@"/bouquets/bouquet" error:nil];

	for(CXMLElement *resultElement in resultNodes)
	{
		if(++parsedServicesCounter >= MAX_SERVICES)
			break;

		// A service in the xml represents a service, so create an instance of it.
		NSObject<ServiceProtocol> *newService = [[EnigmaService alloc] initWithNode: (CXMLNode *)resultElement];

		[delegate performSelectorOnMainThread: @selector(addService:)
								   withObject: newService
								waitUntilDone: NO];
		[newService release];
	}

	[self indicateSuccess:delegate];
	return nil;
}

- (CXMLDocument *)fetchServices:(NSObject<ServiceSourceDelegate> *)delegate bouquet:(NSObject<ServiceProtocol> *)bouquet isRadio:(BOOL)isRadio
{
	if(isRadio)
	{
		[NSException raise:@"ExcUnsupportedFunction" format:@""];
		return nil;
	}

	// split view on ipad
	if(!bouquet)
	{
		[self indicateSuccess:delegate];
		return nil;
	}

	NSArray *resultNodes = nil;
	NSUInteger parsedServicesCounter = 0;

	resultNodes = [bouquet nodesForXPath: @"service" error: nil];
	if(!resultNodes || ![resultNodes count])
	{
		if(!_cachedBouquetsXML || [_cachedBouquetsXML retainCount] == 1)
		{
			[_cachedBouquetsXML release];
			NSError *error = [self refreshBouquetsXMLCache];
			if(error)
			{
				NSObject<ServiceProtocol> *fakeService = [[GenericService alloc] init];
				fakeService.sname = NSLocalizedString(@"Error retrieving Data", @"");
				[delegate performSelectorOnMainThread: @selector(addService:)
											withObject: fakeService
										 waitUntilDone: NO];
				[fakeService release];

				[self indicateError:delegate error:error];
				return nil;
			}
		}

		resultNodes = [_cachedBouquetsXML nodesForXPath:
						[NSString stringWithFormat: @"/bouquets/bouquet[reference=\"%@\"]/service", bouquet.sref]
						error:nil];
	}

	for(CXMLElement *resultElement in resultNodes)
	{
		if(++parsedServicesCounter >= MAX_SERVICES)
			break;

		// A service in the xml represents a service, so create an instance of it.
		NSObject<ServiceProtocol> *newService = [[EnigmaService alloc] initWithNode: (CXMLNode *)resultElement];

		[delegate performSelectorOnMainThread: @selector(addService:)
								   withObject: newService
								waitUntilDone: NO];
		[newService release];
	}

	[self indicateSuccess:delegate];
	return nil;
}

- (CXMLDocument *)fetchEPG: (NSObject<EventSourceDelegate> *)delegate service:(NSObject<ServiceProtocol> *)service
{
	NSURL *myURI = [NSURL URLWithString: [NSString stringWithFormat:@"/xml/serviceepg?ref=%@", [service.sref urlencode]] relativeToURL: _baseAddress];

	NSError *parseError = nil;

	const BaseXMLReader *streamReader = [[EnigmaEventXMLReader alloc] initWithDelegate: delegate];
	CXMLDocument *doc = [streamReader parseXMLFileAtURL: myURI parseError: &parseError];
	[streamReader autorelease];
	return doc;
}

#pragma mark Timer

- (CXMLDocument *)fetchTimers: (NSObject<TimerSourceDelegate> *)delegate
{
	NSURL *myURI = [NSURL URLWithString: @"/xml/timers" relativeToURL: _baseAddress];

	NSError *parseError = nil;

	const BaseXMLReader *streamReader = [[EnigmaTimerXMLReader alloc] initWithDelegate: delegate];
	CXMLDocument *doc = [streamReader parseXMLFileAtURL: myURI parseError: &parseError];
	[streamReader autorelease];
	return doc;
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
	[myString release];
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
			else {
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

	// Generate URI
	NSURL *myURI = [NSURL URLWithString: [NSString stringWithFormat: @"/deleteTimerEvent?ref=%@&start=%d&force=yes", [oldTimer.service.sref urlencode], (int)[oldTimer.begin timeIntervalSince1970]] relativeToURL: _baseAddress];

	NSData *data = [SynchronousRequestReader sendSynchronousRequest:myURI
												  returningResponse:nil
															  error:nil];

	NSString *myString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

	const NSRange myRange = [myString rangeOfString: @"Timer event deleted successfully."];
	result.result = (myRange.length > 0);
	result.resulttext = myString;
	[myString release];
	return result;
}

#pragma mark Recordings

- (Result *)playMovie:(NSObject<MovieProtocol> *) movie
{
	return [self zapInternal: movie.sref];
}

- (CXMLDocument *)fetchMovielist: (NSObject<MovieSourceDelegate> *)delegate withLocation:(NSString *)location
{
	if(location != nil)
	{
		[NSException raise:@"ExcUnsupportedFunction" format:@""];
		return nil;
	}

	NSURL *myURI = [NSURL URLWithString: @"/xml/services?mode=3&submode=4" relativeToURL: _baseAddress];

	NSError *parseError = nil;

	const BaseXMLReader *streamReader = [[EnigmaMovieXMLReader alloc] initWithDelegate: delegate];
	CXMLDocument *doc = [streamReader parseXMLFileAtURL: myURI parseError: &parseError];
	[streamReader autorelease];
	return doc;
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

	result.result = ([response statusCode] == 500);
	result.resulttext = [NSHTTPURLResponse localizedStringForStatusCode: [response statusCode]];
	return result;
}

#pragma mark Control

- (CXMLDocument *)getCurrent: (NSObject<EventSourceDelegate,ServiceSourceDelegate> *)delegate
{
	NSURL *myURI = [NSURL URLWithString: @"/xml/currentservicedata" relativeToURL: _baseAddress];

	const BaseXMLReader *streamReader = [[EnigmaCurrentXMLReader alloc] initWithDelegate: delegate];
	CXMLDocument *doc = [streamReader parseXMLFileAtURL: myURI parseError: nil];
	[streamReader autorelease];
	return doc;
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

	[myString release];

	[delegate performSelectorOnMainThread: @selector(addVolume:)
							   withObject: volumeObject
							waitUntilDone: NO];
	[volumeObject release];
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
	[myString release];
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
	[myString release];
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
	[streamReader autorelease];
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
	[myString release];
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
		NSURL *myURI = [NSURL URLWithString: @"/cgi-bin/osdshot" relativeToURL: _baseAddress];

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
		[myString release];
		if(!myRange.length)
			return nil;

		// Generate URI
		myURI = [NSURL URLWithString: @"/root/tmp/screenshot.jpg" relativeToURL: _baseAddress];

		data = [SynchronousRequestReader sendSynchronousRequest:myURI
											  returningResponse:nil
														  error:nil];

		return data;
	}

	return nil;
}

#pragma mark Unsupported

- (CXMLDocument *)searchEPG: (NSObject<EventSourceDelegate> *)delegate title:(NSString *)title
{
	[NSException raise:@"ExcUnsupportedFunction" format:@""];
	return nil;
}

- (CXMLDocument *)searchEPGSimilar: (NSObject<EventSourceDelegate> *)delegate event:(NSObject<EventProtocol> *)event
{
	[NSException raise:@"ExcUnsupportedFunction" format:@""];
	return nil;
}

- (CXMLDocument *)fetchPlaylist:(NSObject <FileSourceDelegate>*)delegate
{
	[NSException raise:@"ExcUnsupportedFunction" format:@""];
	return nil;
}

- (CXMLDocument *)fetchFiles:(NSObject <FileSourceDelegate>*)delegate path:(NSString *)path
{
	[NSException raise:@"ExcUnsupportedFunction" format:@""];
	return nil;
}

- (Result *)addTrack:(NSObject<FileProtocol> *) track startPlayback:(BOOL)play
{
	[NSException raise:@"ExcUnsupportedFunction" format:@""];
	return nil;
}

- (Result *)removeTrack:(NSObject<FileProtocol> *) track
{
	[NSException raise:@"ExcUnsupportedFunction" format:@""];
	return nil;
}

- (Result *)playTrack:(NSObject<FileProtocol> *) track
{
	[NSException raise:@"ExcUnsupportedFunction" format:@""];
	return nil;
}

- (Result *)mediaplayerCommand:(NSString *)command
{
	[NSException raise:@"ExcUnsupportedFunction" format:@""];
	return nil;
}

- (CXMLDocument *)fetchLocationlist: (NSObject<LocationSourceDelegate> *)delegate;
{
	[NSException raise:@"ExcUnsupportedFunction" format:@""];
	return nil;
}

- (CXMLDocument *)getAbout: (NSObject<AboutSourceDelegate> *)delegate
{
	[NSException raise:@"ExcUnsupportedFunction" format:@""];
	return nil;
}

- (CXMLDocument *)getMetadata: (NSObject<MetadataSourceDelegate> *)delegate
{
	[NSException raise:@"ExcUnsupportedFunction" format:@""];
	return nil;
}

- (NSData *)getFile: (NSString *)fullpath;
{
	[NSException raise:@"ExcUnsupportedFunction" format:@""];
	return nil;
}

- (CXMLDocument *)getNow:(NSObject<NowSourceDelegate> *)delegate bouquet:(NSObject<ServiceProtocol> *)bouquet isRadio:(BOOL)isRadio
{
	[NSException raise:@"ExcUnsupportedFunction" format:@""];
	return nil;
}

- (CXMLDocument *)getNext:(NSObject<NextSourceDelegate> *)delegate bouquet:(NSObject<ServiceProtocol> *)bouquet isRadio:(BOOL)isRadio
{
	[NSException raise:@"ExcUnsupportedFunction" format:@""];
	return nil;
}

- (NSURL *)getStreamURLForMovie:(NSObject<MovieProtocol> *)movie
{
	[NSException raise:@"ExcUnsupportedFunction" format:@""];
	return nil;
}

- (NSURL *)getStreamURLForService:(NSObject<ServiceProtocol> *)service
{
	[NSException raise:@"ExcUnsupportedFunction" format:@""];
	return nil;
}

@end
