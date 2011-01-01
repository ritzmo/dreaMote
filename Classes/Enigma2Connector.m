//
//  Enigma2Connector.m
//  dreaMote
//
//  Created by Moritz Venn on 08.03.08.
//  Copyright 2008-2011 Moritz Venn. All rights reserved.
//

#import "Enigma2Connector.h"

#import "Objects/EventProtocol.h"
#import "Objects/MovieProtocol.h"
#import "Objects/ServiceProtocol.h"
#import "Objects/TimerProtocol.h"

#import "XMLReader/Enigma2/EventXMLReader.h"
#import "XMLReader/Enigma2/CurrentXMLReader.h"
#import "XMLReader/Enigma2/MovieXMLReader.h"
#import "XMLReader/Enigma2/ServiceXMLReader.h"
#import "XMLReader/Enigma2/SignalXMLReader.h"
#import "XMLReader/Enigma2/TimerXMLReader.h"
#import "XMLReader/Enigma2/VolumeXMLReader.h"

#import "EnigmaRCEmulatorController.h"
#import "SimpleRCEmulatorController.h"

#import "Constants.h"

enum powerStates {
	kShutdownState = 1,
	kRebootState = 2,
	kRestartGUIState = 3,
};

enum enigma2MessageTypes {
	kEnigma2MessageTypeYesNo = 0,
	kEnigma2MessageTypeInfo = 1,
	kEnigma2MessageTypeMessage = 2,
	kEnigma2MessageTypeAttention = 3,
	kEnigma2MessageTypeMax = 4
};

@interface NSURLRequest(DummyInterface)
+ (void)setAllowsAnyHTTPSCertificate:(BOOL)allow forHost:(NSString*)host;
@end

@implementation Enigma2Connector

- (const BOOL const)hasFeature: (enum connectorFeatures)feature
{
	return 
		(feature != kFeaturesMessageCaption);
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
			_baseAddress = [NSURL URLWithString: address];
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
			
			_baseAddress = [NSURL URLWithString: remoteAddress];
		}
		[NSURLRequest setAllowsAnyHTTPSCertificate:YES forHost:[_baseAddress host]];
		[_baseAddress retain];
	}
	return self;
}

- (void)dealloc
{
	[_baseAddress release];

	[super dealloc];
}

+ (NSObject <RemoteConnector>*)newWithAddress:(NSString *) address andUsername: (NSString *)inUsername andPassword: (NSString *)inPassword andPort: (NSInteger)inPort useSSL: (BOOL)ssl
{
	return (NSObject <RemoteConnector>*)[[Enigma2Connector alloc] initWithAddress: address andUsername: inUsername andPassword: inPassword andPort: inPort useSSL: (BOOL)ssl];
}

- (BOOL)isReachable
{
	// Generate URI
	NSURL *myURI = [NSURL URLWithString:@"/web/about" relativeToURL:_baseAddress];

	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

	NSHTTPURLResponse *response;
	NSURLRequest *request = [NSURLRequest requestWithURL: myURI
											 cachePolicy: NSURLRequestReloadIgnoringCacheData timeoutInterval: 5];
	[NSURLConnection sendSynchronousRequest: request
										 returningResponse: &response error: nil];

	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

	return ([response statusCode] == 200);
}

- (Result *)simpleXmlResultToResult:(NSString *) xml
{
	NSError *error = nil;
	const NSArray *resultNodes = nil;
	Result *result = [Result createResult];
	CXMLDocument *dom = [[CXMLDocument alloc] initWithXMLString:xml options:0 error:&error];
	
	result.result = NO;

	if(error != nil)
	{
		result.resulttext = [error localizedDescription];
		[dom release];
		return result;
	}
	
	resultNodes = [dom nodesForXPath:@"/e2simplexmlresult/e2state" error:nil];
	for(CXMLElement *currentChild in resultNodes)
	{
		if([[currentChild stringValue] isEqualToString: @"True"])
		{
			result.result = YES;
		}
		break;
	}
	
	resultNodes = [dom nodesForXPath:@"/e2simplexmlresult/e2statetext" error:nil];
	for(CXMLElement *currentChild in resultNodes)
	{
		result.resulttext = [currentChild stringValue];
		break;
	}

	[dom release];
	return result;
}

- (Result *)zapInternal:(NSString *) sref
{
	Result *result = [Result createResult];
	
	// Generate URI
	NSURL *myURI = [NSURL URLWithString:[NSString stringWithFormat:@"/web/zap?sRef=%@", [sref stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding]] relativeToURL:_baseAddress];

	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

	// Create URL Object and download it
	NSHTTPURLResponse *response;
	NSURLRequest *request = [NSURLRequest requestWithURL: myURI
											 cachePolicy: NSURLRequestReloadIgnoringCacheData timeoutInterval: 5];
	[NSURLConnection sendSynchronousRequest: request
										 returningResponse: &response error: nil];

	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

	result.result = ([response statusCode] == 200);
	result.resulttext = [NSHTTPURLResponse localizedStringForStatusCode: [response statusCode]];
	return result;
}

- (Result *)zapTo:(NSObject<ServiceProtocol> *) service
{
	return [self zapInternal: service.sref];
}

- (Result *)playMovie:(NSObject<MovieProtocol> *) movie
{
	return [self zapInternal: movie.sref];
}

- (CXMLDocument *)fetchBouquets:(NSObject<ServiceSourceDelegate> *)delegate isRadio:(BOOL)isRadio
{
	NSString *sref = nil;
	if(isRadio)
		sref = @"sRef=1:7:2:0:0:0:0:0:0:0:(type%20==%202)FROM%20BOUQUET%20%22bouquets.radio%22%20ORDER%20BY%20bouquet";
	else
		sref = @"";
	NSURL *myURI = [NSURL URLWithString: [NSString stringWithFormat: @"/web/getservices?%@", sref] relativeToURL: _baseAddress];

	const BaseXMLReader *streamReader = [[Enigma2ServiceXMLReader alloc] initWithDelegate: delegate];
	CXMLDocument *doc = [streamReader parseXMLFileAtURL: myURI parseError: nil];
	[streamReader autorelease];
	return doc;
}

- (CXMLDocument *)fetchServices:(NSObject<ServiceSourceDelegate> *)delegate bouquet:(NSObject<ServiceProtocol> *)bouquet isRadio:(BOOL)isRadio
{
	NSString *sref = nil;
	if(!bouquet) // single bouquet mode
	{
		if(isRadio)
			sref =  @"1:7:2:0:0:0:0:0:0:0:FROM%20BOUQUET%20%22userbouquet.favourites.radio%22%20ORDER%20BY%20bouquet";
		else
			sref =  @"1:7:1:0:0:0:0:0:0:0:FROM%20BOUQUET%20%22userbouquet.favourites.tv%22%20ORDER%20BY%20bouquet";
	}
	else
		sref = [bouquet.sref stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding];
	NSURL *myURI = [NSURL URLWithString: [NSString stringWithFormat:@"/web/getservices?sRef=%@", sref] relativeToURL:_baseAddress];

	const BaseXMLReader *streamReader = [[Enigma2ServiceXMLReader alloc] initWithDelegate: delegate];
	CXMLDocument *doc = [streamReader parseXMLFileAtURL: myURI parseError: nil];
	[streamReader autorelease];
	return doc;
}

- (CXMLDocument *)fetchEPG:(NSObject<EventSourceDelegate> *)delegate service:(NSObject<ServiceProtocol> *)service
{
	NSURL *myURI = [NSURL URLWithString: [NSString stringWithFormat:@"/web/epgservice?sRef=%@", [service.sref stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding]] relativeToURL: _baseAddress];

	const BaseXMLReader *streamReader = [[Enigma2EventXMLReader alloc] initWithDelegate: delegate];
	CXMLDocument *doc = [streamReader parseXMLFileAtURL: myURI parseError: nil];
	[streamReader autorelease];
	return doc;
}

- (CXMLDocument *)fetchTimers:(NSObject<TimerSourceDelegate> *)delegate
{
	NSURL *myURI = [NSURL URLWithString: @"/web/timerlist" relativeToURL: _baseAddress];

	const BaseXMLReader *streamReader = [[Enigma2TimerXMLReader alloc] initWithDelegate: delegate];
	CXMLDocument *doc = [streamReader parseXMLFileAtURL: myURI parseError: nil];
	[streamReader autorelease];
	return doc;
}

- (CXMLDocument *)fetchMovielist:(NSObject<MovieSourceDelegate> *)delegate
{
	NSURL *myURI = [NSURL URLWithString: @"/web/movielist" relativeToURL: _baseAddress];

	const BaseXMLReader *streamReader = [[Enigma2MovieXMLReader alloc] initWithDelegate: delegate];
	CXMLDocument *doc = [streamReader parseXMLFileAtURL: myURI parseError: nil];
	[streamReader autorelease];
	return doc;
}

- (void)sendPowerstate: (NSInteger) newState
{
	// Generate URI
	NSURL *myURI = [NSURL URLWithString: [NSString stringWithFormat:@"/web/powerstate?newstate=%d", newState] relativeToURL: _baseAddress];

	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

	// Create URL Object and download it
	NSURLResponse *response;
	NSURLRequest *request = [NSURLRequest requestWithURL: myURI
											 cachePolicy: NSURLRequestReloadIgnoringCacheData timeoutInterval: 5];
	[NSURLConnection sendSynchronousRequest: request
										 returningResponse: &response error: nil];

	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

- (void)shutdown
{
	[self sendPowerstate: kShutdownState];
}

- (void)standby
{
	// NOTE: we send remote control command button power here as we want to toggle standby
	[self sendButton: kButtonCodePower];
}

- (void)reboot
{
	[self sendPowerstate: kRebootState];
}

- (void)restart
{
	[self sendPowerstate: kRestartGUIState];
}

- (void)getVolume: (NSObject<VolumeSourceDelegate> *)delegate
{
	NSURL *myURI = [NSURL URLWithString: @"/web/vol" relativeToURL: _baseAddress];

	const BaseXMLReader *streamReader = [[Enigma2VolumeXMLReader alloc] initWithDelegate: delegate];
	[streamReader parseXMLFileAtURL:myURI parseError: nil];
	[streamReader autorelease];
}

- (void)getSignal: (NSObject<SignalSourceDelegate> *)delegate
{
	NSURL *myURI = [NSURL URLWithString: @"/web/signal" relativeToURL: _baseAddress];
	
	const BaseXMLReader *streamReader = [[Enigma2SignalXMLReader alloc] initWithDelegate: delegate];
	[streamReader parseXMLFileAtURL:myURI parseError: nil];
	[streamReader autorelease];
}

- (BOOL)toggleMuted
{
	// Generate URI
	NSURL *myURI = [NSURL URLWithString: @"/web/vol?set=mute" relativeToURL: _baseAddress];

	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

	// Create URL Object and download it
	NSURLResponse *response;
	NSURLRequest *request = [NSURLRequest requestWithURL: myURI
											 cachePolicy: NSURLRequestReloadIgnoringCacheData timeoutInterval: 5];
	NSData *data = [NSURLConnection sendSynchronousRequest: request
										 returningResponse: &response error: nil];
	
	const NSString *myString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

	const NSRange myRange = [myString rangeOfString: @"<e2ismuted>True</e2ismuted>"];
	[myString release];
	return (myRange.length > 0);
}

- (Result *)setVolume:(NSInteger) newVolume
{
	// Generate URI
	NSURL *myURI = [NSURL URLWithString: [NSString stringWithFormat:@"/web/vol?set=set%d", newVolume] relativeToURL: _baseAddress];

	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

	// Create URL Object and download it
	NSURLResponse *response;
	NSURLRequest *request = [NSURLRequest requestWithURL: myURI
											 cachePolicy: NSURLRequestReloadIgnoringCacheData timeoutInterval: 5];
	NSData *data = [NSURLConnection sendSynchronousRequest: request
										 returningResponse: &response error: nil];
	
	NSString *myString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

	Result *result = [self simpleXmlResultToResult: myString];
	[myString release];
	return result;
}

- (Result *)addTimer:(NSObject<TimerProtocol> *) newTimer
{
	// Generate URI
	NSURL *myURI = [NSURL URLWithString: [NSString stringWithFormat: @"/web/timeradd?sRef=%@&begin=%d&end=%d&name=%@&description=%@&eit=%@&disabled=%d&justplay=%d&afterevent=%d&repeated=%d", [newTimer.service.sref stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding], (int)[newTimer.begin timeIntervalSince1970], (int)[newTimer.end timeIntervalSince1970], [newTimer.title stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding], [newTimer.tdescription stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding], newTimer.eit, newTimer.disabled ? 1 : 0, newTimer.justplay ? 1 : 0, newTimer.afterevent, newTimer.repeated] relativeToURL: _baseAddress];

	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

	// Create URL Object and download it
	NSURLResponse *response;
	NSURLRequest *request = [NSURLRequest requestWithURL: myURI
											 cachePolicy: NSURLRequestReloadIgnoringCacheData timeoutInterval: 5];
	NSData *data = [NSURLConnection sendSynchronousRequest: request
										 returningResponse: &response error: nil];
	
	NSString *myString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

	Result *result = [self simpleXmlResultToResult: myString];
	[myString release];
	return result;
}

- (Result *)editTimer:(NSObject<TimerProtocol> *) oldTimer: (NSObject<TimerProtocol> *) newTimer
{
	// Generate URI
	NSURL *myURI = [NSURL URLWithString: [NSString stringWithFormat: @"/web/timerchange?sRef=%@&begin=%d&end=%d&name=%@&description=%@&eit=%@&disabled=%d&justplay=%d&afterevent=%d&repeated=%d&channelOld=%@&beginOld=%d&endOld=%d&deleteOldOnSave=1", [newTimer.service.sref stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding], (int)[newTimer.begin timeIntervalSince1970], (int)[newTimer.end timeIntervalSince1970], [newTimer.title stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding], [newTimer.tdescription stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding], newTimer.eit, newTimer.disabled ? 1 : 0, newTimer.justplay ? 1 : 0, newTimer.afterevent, newTimer.repeated, [oldTimer.service.sref stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding], (int)[oldTimer.begin timeIntervalSince1970], (int)[oldTimer.end timeIntervalSince1970]] relativeToURL: _baseAddress];

	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

	// Create URL Object and download it
	NSURLResponse *response;
	NSURLRequest *request = [NSURLRequest requestWithURL: myURI
											 cachePolicy: NSURLRequestReloadIgnoringCacheData timeoutInterval: 5];
	NSData *data = [NSURLConnection sendSynchronousRequest: request
										 returningResponse: &response error: nil];
	
	NSString *myString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

	Result *result = [self simpleXmlResultToResult: myString];
	[myString release];
	return result;
}

- (Result *)delTimer:(NSObject<TimerProtocol> *) oldTimer
{
	// Generate URI
	NSURL *myURI = [NSURL URLWithString: [NSString stringWithFormat: @"/web/timerdelete?sRef=%@&begin=%d&end=%d", [oldTimer.service.sref stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding], (int)[oldTimer.begin timeIntervalSince1970], (int)[oldTimer.end timeIntervalSince1970]] relativeToURL: _baseAddress];

	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

	// Create URL Object and download it
	NSURLResponse *response;
	NSURLRequest *request = [NSURLRequest requestWithURL: myURI
											 cachePolicy: NSURLRequestReloadIgnoringCacheData timeoutInterval: 5];
	NSData *data = [NSURLConnection sendSynchronousRequest: request
										 returningResponse: &response error: nil];
	
	NSString *myString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

	Result *result = [self simpleXmlResultToResult: myString];
	[myString release];
	return result;
}

- (Result *)sendButton:(NSInteger) type
{
	// Generate URI
	NSURL *myURI = [NSURL URLWithString: [NSString stringWithFormat: @"/web/remotecontrol?command=%d", type] relativeToURL: _baseAddress];

	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

	// Create URL Object and download it
	NSURLResponse *response;
	NSURLRequest *request = [NSURLRequest requestWithURL: myURI
											 cachePolicy: NSURLRequestReloadIgnoringCacheData timeoutInterval: 5];
	NSData *data = [NSURLConnection sendSynchronousRequest: request
										 returningResponse: &response error: nil];
	
	NSString *myString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

	Result *result = [self simpleXmlResultToResult: myString];
	[myString release];
	return result;
}

- (Result *)sendMessage:(NSString *)message: (NSString *)caption: (NSInteger)type: (NSInteger)timeout
{
	// Generate URI
	NSURL *myURI = [NSURL URLWithString: [NSString stringWithFormat: @"/web/message?text=%@&type=%d&timeout=%d", [message  stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding], type, timeout] relativeToURL: _baseAddress];

	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

	// Create URL Object and download it
	NSURLResponse *response;
	NSURLRequest *request = [NSURLRequest requestWithURL: myURI
											 cachePolicy: NSURLRequestReloadIgnoringCacheData timeoutInterval: 5];
	NSData *data = [NSURLConnection sendSynchronousRequest: request
										 returningResponse: &response error: nil];

	NSString *myString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

	Result *result = [self simpleXmlResultToResult: myString];
	[myString release];
	return result;
}

- (const NSUInteger const)getMaxMessageType
{
	return kEnigma2MessageTypeMax;
}

- (NSString *)getMessageTitle: (NSUInteger)type
{
	switch(type)
	{
		case kEnigma2MessageTypeAttention:
			return NSLocalizedString(@"Attention", @"");
		case kEnigma2MessageTypeInfo:
			return NSLocalizedString(@"Info", @"");
		case kEnigma2MessageTypeMessage:
			return NSLocalizedString(@"Message", @"");
		case kEnigma2MessageTypeYesNo:
			return NSLocalizedString(@"Yes/No", @"");
		default:
			return @"???";
	}
}

- (NSData *)getScreenshot: (enum screenshotType)type
{
	NSString *appendType = nil;
	switch(type)
	{
		case kScreenshotTypeOSD:
			appendType = @"&o=&n=";
			break;
		case kScreenshotTypeVideo:
			appendType = @"&v=";
			break;
		case kScreenshotTypeBoth:
		default:
			appendType = @"";
			break;
	}

	// Generate URI
	NSURL *myURI = [NSURL URLWithString: [NSString stringWithFormat: @"/grab?format=jpg%@", appendType] relativeToURL: _baseAddress];

	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

	// Create URL Object and download it
	NSURLResponse *response;
	NSURLRequest *request = [NSURLRequest requestWithURL: myURI
											 cachePolicy: NSURLRequestReloadIgnoringCacheData timeoutInterval: 5];
	NSData *data = [NSURLConnection sendSynchronousRequest: request
										 returningResponse: &response error: nil];

	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

	return data;
}

- (Result *)delMovie:(NSObject<MovieProtocol> *) movie
{
	// Generate URI
	NSURL *myURI = [NSURL URLWithString:[NSString stringWithFormat:@"/web/moviedelete?sRef=%@", [movie.sref stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding]] relativeToURL:_baseAddress];

	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	
	// Create URL Object and download it
	NSHTTPURLResponse *response;
	NSURLRequest *request = [NSURLRequest requestWithURL: myURI
											 cachePolicy: NSURLRequestReloadIgnoringCacheData timeoutInterval: 5];
	NSData *data = [NSURLConnection sendSynchronousRequest: request
											returningResponse: &response error: nil];
	
	NSString *myString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

	Result *result = [self simpleXmlResultToResult: myString];
	[myString release];
	return result;
}

- (CXMLDocument *)searchEPG: (NSObject<EventSourceDelegate> *)delegate title:(NSString *)title
{
	// TODO: iso8859-1 is currently hardcoded, we might want to fix that
	NSURL *myURI = [NSURL URLWithString: [NSString stringWithFormat:@"/web/epgsearch?search=%@", [title stringByAddingPercentEscapesUsingEncoding: NSISOLatin1StringEncoding]] relativeToURL: _baseAddress];

	const BaseXMLReader *streamReader = [[Enigma2EventXMLReader alloc] initWithDelegate: delegate];
	CXMLDocument *doc = [streamReader parseXMLFileAtURL: myURI parseError: nil];
	[streamReader autorelease];
	return doc;
}

- (CXMLDocument *)searchEPGSimilar: (NSObject<EventSourceDelegate> *)delegate event:(NSObject<EventProtocol> *)event
{
	NSURL *myURI = [NSURL URLWithString: [NSString stringWithFormat:@"/web/epgsimilar?sRef=%@&eventid=%@", [event.service.sref stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding], event.eit] relativeToURL: _baseAddress];
	
	const BaseXMLReader *streamReader = [[Enigma2EventXMLReader alloc] initWithDelegate: delegate];
	CXMLDocument *doc = [streamReader parseXMLFileAtURL: myURI parseError: nil];
	[streamReader autorelease];
	return doc;
}

- (CXMLDocument *)getCurrent: (NSObject<EventSourceDelegate,ServiceSourceDelegate> *)delegate
{
	NSURL *myURI = [NSURL URLWithString: @"/web/getcurrent" relativeToURL: _baseAddress];
	
	const BaseXMLReader *streamReader = [[Enigma2CurrentXMLReader alloc] initWithDelegate: delegate];
	CXMLDocument *doc = [streamReader parseXMLFileAtURL: myURI parseError: nil];
	[streamReader autorelease];
	return doc;
}

- (Result *)instantRecord
{
	// Generate URI
	// TODO: we only allow infinite instant records for now
	NSURL *myURI = [NSURL URLWithString:@"/web/recordnow?recordnow=infinite" relativeToURL:_baseAddress];

	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

	// Create URL Object and download it
	NSHTTPURLResponse *response;
	NSURLRequest *request = [NSURLRequest requestWithURL: myURI
											cachePolicy: NSURLRequestReloadIgnoringCacheData timeoutInterval: 5];
	NSData *data = [NSURLConnection sendSynchronousRequest: request
						returningResponse: &response error: nil];

	NSString *myString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

	Result *result = [self simpleXmlResultToResult: myString];
	[myString release];
	return result;
}

- (void)openRCEmulator: (UINavigationController *)navigationController
{
	const BOOL useSimpleRemote = [[NSUserDefaults standardUserDefaults] boolForKey: kPrefersSimpleRemote];
	UIViewController *targetViewController = nil;
	if(useSimpleRemote)
		targetViewController = [[SimpleRCEmulatorController alloc] init];
	else
		targetViewController = [[EnigmaRCEmulatorController alloc] init];
	[navigationController pushViewController:targetViewController animated:YES];
	[targetViewController release];
}

- (void)freeCaches
{
	// NOTE: We don't use any caches
}

@end
