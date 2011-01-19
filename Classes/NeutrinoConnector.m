//
//  NeutrinoConnector.m
//  dreaMote
//
//  Created by Moritz Venn on 15.10.08.
//  Copyright 2008-2011 Moritz Venn. All rights reserved.
//

#import "NeutrinoConnector.h"

#import "CXMLElement.h"

#import "Objects/Neutrino/Bouquet.h"
#import "Objects/Generic/Service.h"
#import "Objects/Generic/Volume.h"
#import "Objects/Generic/Timer.h"

#import "SynchronousRequestReader.h"
#import "MovieSourceDelegate.h"
#import "ServiceSourceDelegate.h"
#import "SignalSourceDelegate.h"
#import "TimerSourceDelegate.h"
#import "VolumeSourceDelegate.h"
#import "XMLReader/BaseXMLReader.h"
#import "XMLReader/Neutrino/EventXMLReader.h"

#import "NeutrinoRCEmulatorController.h"
#import "SimpleRCEmulatorController.h"

#import "NSString+URLEncode.h"

enum neutrinoMessageTypes {
	kNeutrinoMessageTypeNormal = 0,
	kNeutrinoMessageTypeConfirmed = 1,
	kNeutrinoMessageTypeMax = 2,
};

@implementation NeutrinoConnector

- (const BOOL const)hasFeature: (enum connectorFeatures)feature
{
	// Screenshots do not work yet... :-/
	return
		(feature == kFeaturesBouquets) ||
		(feature == kFeaturesConstantTimerId) ||
		(feature == kFeaturesMessageType);
}

- (const NSUInteger const)getMaxVolume
{
	return 100;
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

+ (NSObject <RemoteConnector>*)newWithAddress:(NSString *) address andUsername: (NSString *)inUsername andPassword: (NSString *)inPassword andPort: (NSInteger)inPort useSSL: (BOOL)ssl
{
	return (NSObject <RemoteConnector>*)[[NeutrinoConnector alloc] initWithAddress: address andUsername: inUsername andPassword: inPassword andPort: inPort useSSL: (BOOL)ssl];
}

- (UIViewController *)newRCEmulator
{
	return [[NeutrinoRCEmulatorController alloc] init];
}

- (BOOL)isReachable
{
	// Generate URI
	NSURL *myURI = [NSURL URLWithString:@"/control/info"  relativeToURL:_baseAddress];

	NSHTTPURLResponse *response;
	[SynchronousRequestReader sendSynchronousRequest:myURI
								   returningResponse:&response
											   error:nil];

	return ([response statusCode] == 200);
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
		[invocation setArgument:&self atIndex:2];
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
		[invocation setArgument:&self atIndex:2];
		[invocation performSelectorOnMainThread:@selector(invoke) withObject:NULL
								  waitUntilDone:NO];
	}
}

#pragma mark Services

- (Result *)zapTo:(NSObject<ServiceProtocol> *) service
{
	Result *result = [Result createResult];

	// Generate URI
	NSURL *myURI = [NSURL URLWithString: [NSString stringWithFormat:@"/control/zapto?%@", [service.sref urlencode]] relativeToURL: _baseAddress];

	NSHTTPURLResponse *response;
	[SynchronousRequestReader sendSynchronousRequest:myURI
								   returningResponse:&response
											   error:nil];

	result.result = ([response statusCode] == 200);
	result.resulttext = [NSHTTPURLResponse localizedStringForStatusCode: [response statusCode]];
	return result;
}

/*
 Example:
 <?xml version="1.0" encoding="UTF-8"?>
 <zapit>
 <Bouquet type="0" bouquet_id="0000" name="Hauptsender" hidden="0" locked="0">
 <channel serviceID="d175" name="ProSieben" tsid="2718" onid="f001"/>
 </Bouquet>
 </zapit>
 */
- (NSError *)refreshBouquetsXMLCache
{
	NSURL *myURI = [NSURL URLWithString: @"/control/getbouquetsxml" relativeToURL: _baseAddress];
	NSError *returnValue = nil;

	const BaseXMLReader *streamReader = [[BaseXMLReader alloc] init];
	_cachedBouquetsXML = [[streamReader parseXMLFileAtURL: myURI parseError: &returnValue] retain];
	[streamReader release];
	return returnValue;
}

- (CXMLDocument *)fetchBouquets: (NSObject<ServiceSourceDelegate> *)delegate isRadio:(BOOL)isRadio
{
	if(isRadio)
	{
		[NSException raise:@"ExcUnsupportedFunction" format:@""];
		return nil;
	}

	NSArray *resultNodes = nil;

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

	resultNodes = [_cachedBouquetsXML nodesForXPath:@"/zapit/Bouquet" error:nil];

	for(CXMLElement *resultElement in resultNodes)
	{
		// A channel in the xml represents a service, so create an instance of it.
		NSObject<ServiceProtocol> *newService = [[NeutrinoBouquet alloc] initWithNode: resultElement];

		[delegate performSelectorOnMainThread: @selector(addService:)
								   withObject: newService
								waitUntilDone: NO];
		[newService release];
	}

	[self indicateSuccess:delegate];
	return nil;
}

- (CXMLDocument *)fetchServices: (NSObject<ServiceSourceDelegate> *)delegate bouquet:(NSObject<ServiceProtocol> *)bouquet isRadio:(BOOL)isRadio
{
	if(isRadio)
	{
		[NSException raise:@"ExcUnsupportedFunction" format:@""];
		return nil;
	}

	NSArray *resultNodes = nil;

	resultNodes = [bouquet nodesForXPath: @"channel" error: nil];
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
						[NSString stringWithFormat: @"/zapit/Bouquet[@name=\"%@\"]/channel", bouquet.sname]
						error:nil];
	}

	for(CXMLElement *resultElement in resultNodes)
	{
		// A channel in the xml represents a service, so create an instance of it.
		NSObject<ServiceProtocol> *newService = [[GenericService alloc] init];

		newService.sname = [[resultElement attributeForName: @"name"] stringValue];
		newService.sref = [NSString stringWithFormat: @"%@%@%@",
						   [[resultElement attributeForName: @"tsid"] stringValue],
						   [[resultElement attributeForName: @"onid"] stringValue],
						   [[resultElement attributeForName: @"serviceID"] stringValue]];

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
	// TODO: Maybe we should not hardcode "max"
	NSURL *myURI = [NSURL URLWithString: [NSString stringWithFormat:@"/control/epg?xml=true&channelid=%@&details=true&max=100", service.sref] relativeToURL: _baseAddress];

	const BaseXMLReader *streamReader = [[NeutrinoEventXMLReader alloc] initWithDelegate: delegate];
	CXMLDocument *doc = [streamReader parseXMLFileAtURL: myURI parseError: nil];
	[streamReader autorelease];
	return doc;
}

#pragma mark Timer

// TODO: reimplement this as streaming parser some day :-)
- (CXMLDocument *)fetchTimers: (NSObject<TimerSourceDelegate> *)delegate
{
	// Refresh Service Cache if empty, we need it later when resolving service references
	if(!_cachedBouquetsXML)
		[self refreshBouquetsXMLCache];

	// Generate URI
	NSURL *myURI = [NSURL URLWithString: @"/control/timer" relativeToURL: _baseAddress];

	NSHTTPURLResponse *response;
	NSError *error = nil;
	NSData *data = [SynchronousRequestReader sendSynchronousRequest:myURI
												  returningResponse:&response
															  error:&error];

	// Error occured, so send fake object
	if(error || !data)
	{
		NSObject<TimerProtocol> *fakeObject = [[GenericTimer alloc] init];
		fakeObject.title = NSLocalizedString(@"Error retrieving Data", @"");
		fakeObject.state = 0;
		fakeObject.valid = NO;
		[delegate performSelectorOnMainThread: @selector(addTimer:)
								   withObject: fakeObject
								waitUntilDone: NO];
		[fakeObject release];

		[self indicateError:delegate error:error];
		return nil;
	}

	// Parse
	const NSString *baseString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	const NSArray *timerStringList = [baseString componentsSeparatedByString: @"\n"];
	for(NSString *timerString in timerStringList)
	{
		// eventID eventType eventRepeat repcount announceTime alarmTime stopTime data
		NSArray *timerStringComponents = [timerString componentsSeparatedByString:@" "];

		if([timerStringComponents count] < 8) // NOTE: should not happen... but hopefully not our fault if it does...
			continue;

		NSObject<TimerProtocol> *timer = [[GenericTimer alloc] init];

		// Determine type, reject unhandled
		const NSInteger timerType = [[timerStringComponents objectAtIndex: 1] integerValue];
		if(timerType == neutrinoTimerTypeRecord)
			timer.justplay = NO;
		else if(timerType == neutrinoTimerTypeZapto)
			timer.justplay = YES;
		else
		{
			[timer release];
			timer = nil;
			continue;
		}

		timer.eit = [timerStringComponents objectAtIndex: 0]; // NOTE: actually wrong but we need it :-)
		timer.title = [NSString stringWithFormat: @"Timer %@", timer.eit];
		timer.repeated = [[timerStringComponents objectAtIndex: 2] integerValue]; // NOTE: as long as we don't offer to edit this via gui we can just keep the value and not change it to some common interpretation
		timer.repeatcount = [[timerStringComponents objectAtIndex: 3] integerValue];
		[timer setBeginFromString: [timerStringComponents objectAtIndex: 5]];
		[timer setEndFromString: [timerStringComponents objectAtIndex: 6]];

		// Eventually fetch Service from our Cache
		NSRange objRange;
		objRange.location = 7;
		objRange.length = [timerStringComponents count] - 7;
		NSString *sname = [[timerStringComponents subarrayWithRange: objRange] componentsJoinedByString: @" "];

		NSObject<ServiceProtocol> *service = [[GenericService alloc] init];
		service.sname = sname;
		const NSArray *resultNodes = [_cachedBouquetsXML nodesForXPath:
									[NSString stringWithFormat: @"/zapit/Bouquet/channel[@name=\"%@\"]", sname]
									error:nil];
		// XXX: do we really want this? we don't care about the sref :-)
		if([resultNodes count])
		{
			CXMLElement *resultElement = [resultNodes objectAtIndex: 0];
			service.sref = [NSString stringWithFormat: @"%@%@%@",
								[[resultElement attributeForName: @"tsid"] stringValue],
								[[resultElement attributeForName: @"onid"] stringValue],
								[[resultElement attributeForName: @"serviceID"] stringValue]];
		}
		else
		{
			// NOTE: we set a fake sref here as the service is valid enough for timers...
			service.sref = @"dc";
		}
		timer.service = service;
		[service release];

		// Determine state
		const NSDate *announce = [NSDate dateWithTimeIntervalSince1970:
									[[timerStringComponents objectAtIndex: 4] doubleValue]];
		if([announce timeIntervalSinceNow] > 0)
			timer.state = kTimerStateWaiting;
		else if([timer.begin timeIntervalSinceNow] > 0)
			timer.state = kTimerStatePrepared;
		else if([timer.end timeIntervalSinceNow] > 0)
			timer.state = kTimerStateRunning;
		else
			timer.state = kTimerStateFinished;

		[delegate performSelectorOnMainThread: @selector(addTimer:)
								   withObject: timer
								waitUntilDone: NO];
		[timer release];
	}
	[baseString release];

	[self indicateSuccess:delegate];
	return nil;
}

- (Result *)addTimer:(NSObject<TimerProtocol> *) newTimer
{
	Result *result = [Result createResult];

	// Generate URI
	// NOTE: Fails if I try to format the whole URL by one stringWithFormat... type will be wrong and sref can't be read so the program will crash
	NSMutableString *add = [NSMutableString stringWithCapacity: 100];
	[add appendFormat: @"/control/timer?action=new&alarm=%d&stop=%d&type=", (int)[newTimer.begin timeIntervalSince1970], (int)[newTimer.end timeIntervalSince1970]];
	[add appendFormat: @"%d", (newTimer.justplay) ? neutrinoTimerTypeZapto : neutrinoTimerTypeRecord];
	[add appendString: @"&channel_name="];
	[add appendString: [newTimer.service.sname urlencode]];
	[add replaceOccurrencesOfString:@"+" withString:@"%2B" options:0 range:NSMakeRange(0, [add length])];
	NSURL *myURI = [NSURL URLWithString: add relativeToURL: _baseAddress];

	NSHTTPURLResponse *response;
	[SynchronousRequestReader sendSynchronousRequest:myURI
								   returningResponse:&response
											   error:nil];

	// Sourcecode suggests that they always return ok, so we only do this simple check
	result.result = ([response statusCode] == 200);
	result.resulttext = [NSHTTPURLResponse localizedStringForStatusCode: [response statusCode]];
	return result;
}

- (Result *)editTimer:(NSObject<TimerProtocol> *) oldTimer: (NSObject<TimerProtocol> *) newTimer
{
	Result *result = [Result createResult];

	// Generate URI
	// NOTE: Fails if I try to format the whole URL by one stringWithFormat... type will be wrong and sref can't be read so the program will crash
	NSMutableString *add = [NSMutableString stringWithCapacity: 100];
	[add appendFormat: @"/control/timer?action=modify&id=%@&alarm=%d&stop=%d&format=", oldTimer.eit, (int)[newTimer.begin timeIntervalSince1970], (int)[newTimer.end timeIntervalSince1970]];
	[add appendFormat: @"%d", (newTimer.justplay) ? neutrinoTimerTypeZapto : neutrinoTimerTypeRecord];
	[add appendString: @"&channel_name="];
	[add appendString: [newTimer.service.sname urlencode]];
	[add appendString: @"&rep="];
	[add appendFormat: @"%d", newTimer.repeated];
	[add appendString: @"&repcount="];
	[add appendFormat: @"%d", newTimer.repeatcount];
	[add replaceOccurrencesOfString:@"+" withString:@"%2B" options:0 range:NSMakeRange(0, [add length])];
	NSURL *myURI = [NSURL URLWithString: add relativeToURL: _baseAddress];

	NSHTTPURLResponse *response;
	[SynchronousRequestReader sendSynchronousRequest:myURI
								   returningResponse:&response
											   error:nil];

	// Sourcecode suggests that they always return ok, so we only do this simple check
	result.result = ([response statusCode] == 200);
	result.resulttext = [NSHTTPURLResponse localizedStringForStatusCode: [response statusCode]];
	return result;
}

- (Result *)delTimer:(NSObject<TimerProtocol> *) oldTimer
{
	Result *result = [Result createResult];

	// Generate URI
	NSURL *myURI = [NSURL URLWithString: [NSString stringWithFormat: @"/control/timer?action=remove&id=%@", oldTimer.eit] relativeToURL: _baseAddress];

	NSHTTPURLResponse *response;
	[SynchronousRequestReader sendSynchronousRequest:myURI
								   returningResponse:&response
											   error:nil];

	// Sourcecode suggests that they always return ok, so we only do this simple check
	result.result = ([response statusCode] == 200);
	result.resulttext = [NSHTTPURLResponse localizedStringForStatusCode: [response statusCode]];
	return result;
}

#pragma mark Recordings

- (CXMLDocument *)fetchMovielist: (NSObject<MovieSourceDelegate> *)delegate withLocation: (NSString *)location
{
	// is this possible?
	return nil;
}

#pragma mark Control

- (void)sendPowerstate: (NSString *) newState
{
	// Generate URI
	NSURL *myURI = [NSURL URLWithString: [NSString stringWithFormat:@"/control/%@", newState] relativeToURL: _baseAddress];

	NSHTTPURLResponse *response;
	[SynchronousRequestReader sendSynchronousRequest:myURI
								   returningResponse:&response
											   error:nil];
}

- (void)shutdown
{
	[self sendPowerstate: @"shutdown"];
}

- (void)standby
{
	// Generate URI
	NSURL *myURI = [NSURL URLWithString: @"/control/standby" relativeToURL: _baseAddress];

	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

	NSHTTPURLResponse *response;
	NSData *data = [SynchronousRequestReader sendSynchronousRequest:myURI
												  returningResponse:&response
															  error:nil];

	NSString *myString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	const BOOL equalsOn = [myString isEqualToString: @"on"];
	[myString release];
	if(equalsOn)
		myString = @"standby?off";
	else
		myString = @"standby?on";

	[self sendPowerstate: myString];

	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

- (void)reboot
{
	[self sendPowerstate: @"reboot"];
}

- (void)restart
{
	// NOTE: not available
}

- (void)getVolume: (NSObject<VolumeSourceDelegate> *)delegate
{
	GenericVolume *volumeObject = [[GenericVolume alloc] init];

	// Generate URI (mute)
	NSURL *myURI = [NSURL URLWithString: @"/control/volume?status" relativeToURL: _baseAddress];

	NSHTTPURLResponse *response;
	NSData *data = [SynchronousRequestReader sendSynchronousRequest:myURI
												  returningResponse:&response
															  error:nil];
	
	NSString *myString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	if([myString isEqualToString: @"1"])
		volumeObject.ismuted = YES;
	else
		volumeObject.ismuted = NO;

	[myString release];

	// Generate URI (volume)
	myURI = [NSURL URLWithString: @"/control/volume" relativeToURL: _baseAddress];

	data = [SynchronousRequestReader sendSynchronousRequest:myURI
										  returningResponse:&response
													  error:nil];
	
	myString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	volumeObject.current = [myString integerValue];

	[myString release];

	[delegate performSelectorOnMainThread: @selector(addVolume:)
							   withObject: volumeObject
							waitUntilDone: NO];
	[volumeObject release];
}

- (BOOL)toggleMuted
{
	// Generate URI
	NSURL *myURI = [NSURL URLWithString: @"/control/volume?status" relativeToURL: _baseAddress];

	NSHTTPURLResponse *response;
	NSData *data = [SynchronousRequestReader sendSynchronousRequest:myURI
												  returningResponse:&response
															  error:nil];
	
	const NSString *myString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	const BOOL equalsRes = [myString isEqualToString: @"1"];
	[myString release];
	if(equalsRes)
		myString = @"unmute";
	else
		myString = @"mute";


	// Generate new URI
	myURI = [NSURL URLWithString: [NSString stringWithFormat: @"/control/volume?%@", myString] relativeToURL: _baseAddress];

	[SynchronousRequestReader sendSynchronousRequest:myURI
								   returningResponse:&response
											   error:nil];

	return !equalsRes;
}

- (Result *)setVolume:(NSInteger) newVolume
{
	Result *result = [Result createResult];

	// neutrino expect volume to be a multiple of 5
	const NSUInteger diff = newVolume % 5;
	// NOTE: to make this code easier we could just add/remove the diff but lets try it fair first :-)
	if(diff < 3)
		newVolume -= diff;
	else
		newVolume += diff;

	// Generate URI
	NSURL *myURI = [NSURL URLWithString: [NSString stringWithFormat: @"/control/volume?%d", newVolume] relativeToURL: _baseAddress];

	NSHTTPURLResponse *response;
	[SynchronousRequestReader sendSynchronousRequest:myURI
								   returningResponse:&response
											   error:nil];

	// Sourcecode suggests that they always return ok, so we only do this simple check
	result.result = ([response statusCode] == 200);
	result.resulttext = [NSHTTPURLResponse localizedStringForStatusCode: [response statusCode]];
	return result;
}

- (Result *)sendButton:(NSInteger) type
{
	Result *result = [Result createResult];

	// We fake some button codes (namely tv/radio) so we have to be able to set a custom uri
	NSURL *myURI = nil;

	// Translate ButtonCodes
	NSString *buttonCode = nil;
	switch(type)
	{
		case kButtonCode0: buttonCode = @"KEY_0"; break;
		case kButtonCode1: buttonCode = @"KEY_1"; break;
		case kButtonCode2: buttonCode = @"KEY_2"; break;
		case kButtonCode3: buttonCode = @"KEY_3"; break;
		case kButtonCode4: buttonCode = @"KEY_4"; break;
		case kButtonCode5: buttonCode = @"KEY_5"; break;
		case kButtonCode6: buttonCode = @"KEY_6"; break;
		case kButtonCode7: buttonCode = @"KEY_7"; break;
		case kButtonCode8: buttonCode = @"KEY_8"; break;
		case kButtonCode9: buttonCode = @"KEY_9"; break;
		case kButtonCodeMenu: buttonCode = @"KEY_SETUP"; break;
		case kButtonCodeLeft: buttonCode = @"KEY_LEFT"; break;
		case kButtonCodeRight: buttonCode = @"KEY_RIGHT"; break;
		case kButtonCodeUp: buttonCode = @"KEY_UP"; break;
		case kButtonCodeDown: buttonCode = @"KEY_DOWN"; break;
		case kButtonCodeLame: buttonCode = @"KEY_HOME"; break;
		case kButtonCodeRed: buttonCode = @"KEY_RED"; break;
		case kButtonCodeGreen: buttonCode = @"KEY_GREEN"; break;
		case kButtonCodeYellow: buttonCode = @"KEY_YELLOW"; break;
		case kButtonCodeBlue: buttonCode = @"KEY_BLUE"; break;
		case kButtonCodeVolUp: buttonCode = @"KEY_VOLUMEUP"; break;
		case kButtonCodeVolDown: buttonCode = @"KEY_VOLUMEDOWN"; break;
		case kButtonCodeMute: buttonCode = @"KEY_MUTE"; break;
		case kButtonCodeHelp: buttonCode = @"KEY_HELP"; break;
		case kButtonCodePower: buttonCode = @"KEY_POWER"; break;
		case kButtonCodeOK: buttonCode = @"KEY_OK"; break;
		case kButtonCodeTV:
			myURI = [NSURL URLWithString: @"/control/setmode?tv" relativeToURL: _baseAddress];
			break;
		case kButtonCodeRadio:
			myURI = [NSURL URLWithString: @"/control/setmode?radio" relativeToURL: _baseAddress];
			break;
		//case kButtonCode: buttonCode = @"KEY_"; break; // meant for copy&paste ;-)
		default:
			break;
	}

	if(myURI == nil)
	{
		if(buttonCode == nil)
		{
			result.result = NO;
			result.resulttext = NSLocalizedString(@"Unable to map button to keycode!", @"");
			return result;
		}

		// Generate URI
		myURI = [NSURL URLWithString: [NSString stringWithFormat: @"/control/rcem?%@", buttonCode] relativeToURL: _baseAddress];
	}

	NSHTTPURLResponse *response;
	[SynchronousRequestReader sendSynchronousRequest:myURI
								   returningResponse:&response
											   error:nil];

	result.result = ([response statusCode] == 200);
	result.resulttext = [NSHTTPURLResponse localizedStringForStatusCode: [response statusCode]];
	return result;
}

#pragma mark Messaging

- (Result *)sendMessage:(NSString *)message: (NSString *)caption: (NSInteger)type: (NSInteger)timeout
{
	Result *result = [Result createResult];

	// Generate URI
	NSURL *myURI = [NSURL URLWithString: [NSString stringWithFormat: @"/control/message?%@=%@", type == kNeutrinoMessageTypeConfirmed ? @"nmsg" : @"popup", [message urlencode]] relativeToURL: _baseAddress];

	NSHTTPURLResponse *response;
	[SynchronousRequestReader sendSynchronousRequest:myURI
								   returningResponse:&response
											   error:nil];

	result.result = ([response statusCode] == 200);
	result.resulttext = [NSHTTPURLResponse localizedStringForStatusCode: [response statusCode]];
	return result;
}

- (const NSUInteger const)getMaxMessageType
{
	return kNeutrinoMessageTypeMax;
}

- (NSString *)getMessageTitle: (NSUInteger)type
{
	switch(type)
	{
		case kNeutrinoMessageTypeNormal:
			return NSLocalizedString(@"Normal", @"");
		case kNeutrinoMessageTypeConfirmed:
			return NSLocalizedString(@"Confirmed", @"");
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
		NSURL *myURI = [NSURL URLWithString: @"/GLJ-snapBMP.htm" relativeToURL: _baseAddress];

		NSHTTPURLResponse *response;
		[SynchronousRequestReader sendSynchronousRequest:myURI
									   returningResponse:&response
												   error:nil];

		if([response statusCode] == 200)
		{
			// Generate URI
			myURI = [NSURL URLWithString: @"/control/exec?gljtool&fbsh_bmp" relativeToURL: _baseAddress];

			NSData *data = [SynchronousRequestReader sendSynchronousRequest:myURI
														  returningResponse:&response
																	  error:nil];

			return data;
		}

		// Generate URI
		myURI = [NSURL URLWithString: @"/control/exec?Y_Tools&fbshot&-r&-o&/tmp/dreaMote_Screenshot.bmp" relativeToURL: _baseAddress];

		[SynchronousRequestReader sendSynchronousRequest:myURI
									   returningResponse:&response
												   error:nil];

		// do we actually get a status != 200 back?
		// maybe check if data is not empty...
		if([response statusCode] != 200)
		{
			// Generate URI
			myURI = [NSURL URLWithString: @"/control/exec?Y_Tools&fbshot&-o&/tmp/dreaMote_Screenshot.bmp" relativeToURL: _baseAddress];

			[SynchronousRequestReader sendSynchronousRequest:myURI
										   returningResponse:&response
													   error:nil];
		}

		// Generate URI
		myURI = [NSURL URLWithString: @"/tmp/dreaMote_Screenshot.bmp" relativeToURL: _baseAddress];

		NSData *data = [SynchronousRequestReader sendSynchronousRequest:myURI
													  returningResponse:&response
																  error:nil];

		// Generate URI
		myURI = [NSURL URLWithString: @"/control/exec?Y_Tools&fbshot_clear" relativeToURL: _baseAddress];

		[SynchronousRequestReader sendSynchronousRequest:myURI
									   returningResponse:&response
												   error:nil];

		return data;
	}
	else// We actually generate a combined picture here
	{
		// We need to trigger a capture and individually fetch the picture
		// Generate URI
		NSURL *myURI = [NSURL URLWithString: @"/control/exec?Y_Tools&fbshot&fb&-q&/tmp/dreaMote_Screenshot.png" relativeToURL: _baseAddress];

		// Create URL Object and download it
		NSURLResponse *response;
		[SynchronousRequestReader sendSynchronousRequest:myURI
									   returningResponse:&response
												   error:nil];

		// XXX: check status?

		// Generate URI
		myURI = [NSURL URLWithString: @"/tmp/dreaMote_Screenshot.png" relativeToURL: _baseAddress];

		NSData *data = [SynchronousRequestReader sendSynchronousRequest:myURI
													  returningResponse:&response
																  error:nil];

		// Generate URI
		myURI = [NSURL URLWithString: @"/control/exec?Y_Tools&fbshot_clear" relativeToURL: _baseAddress];

		[SynchronousRequestReader sendSynchronousRequest:myURI
									   returningResponse:&response
												   error:nil];

		return data;
	}

	return nil;
}

#pragma mark Unsupported

- (Result *)delMovie:(NSObject<MovieProtocol> *) movie
{
	[NSException raise:@"ExcUnsupportedFunction" format:@""];
	return nil;
}

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

- (CXMLDocument *)getCurrent: (NSObject<EventSourceDelegate,ServiceSourceDelegate> *)delegate
{
	[NSException raise:@"ExcUnsupportedFunction" format:@""];
	return nil;
}

- (Result *)instantRecord
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

- (Result *)playMovie: (NSObject<MovieProtocol> *)movie
{
	[NSException raise:@"ExcUnsupportedFunction" format:@""];
	return nil;
}

- (CXMLDocument *)fetchLocationlist: (NSObject<LocationSourceDelegate> *)delegate;
{
	[NSException raise:@"ExcUnsupportedFunction" format:@""];
	return nil;
}

- (void)getSignal: (NSObject<SignalSourceDelegate> *)delegate
{
	[NSException raise:@"ExcUnsupportedFunction" format:@""];
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

@end
