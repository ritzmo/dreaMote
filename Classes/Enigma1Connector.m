//
//  Enigma1Connector.m
//  dreaMote
//
//  Created by Moritz Venn on 08.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "Enigma1Connector.h"

#import "Objects/Enigma/Service.h"
#import "Objects/Generic/Volume.h"
#import "Objects/TimerProtocol.h"
#import "Objects/MovieProtocol.h"

#import "XMLReader/Enigma/EventXMLReader.h"
#import "XMLReader/Enigma/TimerXMLReader.h"
#import "XMLReader/Enigma/MovieXMLReader.h"

#import "EnigmaRCEmulatorController.h"

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

- (const BOOL)hasFeature: (enum connectorFeatures)feature
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
		(feature == kFeaturesInstantRecord);
}

- (NSInteger)getMaxVolume
{
	return 63;
}

- (id)initWithAddress: (NSString *)address andUsername: (NSString *)inUsername andPassword: (NSString *)inPassword andPort: (NSInteger)inPort
{
	if(self = [super init])
	{
		// Protect from unexpected input and assume a full URL if address starts with http
		if([address rangeOfString: @"http"].location == 0)
		{
			baseAddress = [NSURL URLWithString: address];
		}
		else
		{
			NSString *remoteAddress = nil;
			if([inUsername isEqualToString: @""])
				remoteAddress = [NSString stringWithFormat: @"http://%@", address];
			else
				remoteAddress = [NSString stringWithFormat: @"http://%@:%@@%@", inUsername,
								inPassword, address];
			if(inPort > 0)
				remoteAddress = [remoteAddress stringByAppendingFormat: @":%d", inPort];
		
			baseAddress = [NSURL URLWithString: remoteAddress];
		}
		[baseAddress retain];
	}
	return self;
}

- (void)dealloc
{
	[baseAddress release];
	[cachedBouquetsXML release];

	[super dealloc];
}

+ (NSObject <RemoteConnector>*)createClassWithAddress:(NSString *) address andUsername: (NSString *)inUsername andPassword: (NSString *)inPassword andPort: (NSInteger)inPort
{
	return (NSObject <RemoteConnector>*)[[Enigma1Connector alloc] initWithAddress: address andUsername: inUsername andPassword: inPassword andPort: inPort];
}

- (BOOL)isReachable
{
	// Generate URI
	NSURL *myURI = [NSURL URLWithString:@"/xml/boxstatus"  relativeToURL:baseAddress];
	
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

	NSHTTPURLResponse *response;
	NSURLRequest *request = [NSURLRequest requestWithURL: myURI
											 cachePolicy: NSURLRequestReloadIgnoringCacheData timeoutInterval: 5];
	[NSURLConnection sendSynchronousRequest: request
										 returningResponse: &response error: nil];

	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

	return ([response statusCode] == 200);
}

- (BOOL)zapInternal: (NSString *)sref
{
	// Generate URI
	NSURL *myURI = [NSURL URLWithString: [NSString stringWithFormat:@"/cgi-bin/zapTo?mode=zap&path=%@", [sref stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding]] relativeToURL: baseAddress];
	
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	
	// Create URL Object and download it
	NSHTTPURLResponse *response;
	NSURLRequest *request = [NSURLRequest requestWithURL: myURI
											 cachePolicy: NSURLRequestReloadIgnoringCacheData timeoutInterval: 5];
	[NSURLConnection sendSynchronousRequest: request
						  returningResponse: &response error: nil];
	
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	
	return ([response statusCode] == 204);
}

- (BOOL)zapTo:(NSObject<ServiceProtocol> *) service
{
	return [self zapInternal: service.sref];
}

- (BOOL)playMovie:(NSObject<MovieProtocol> *) movie
{
	return [self zapInternal: movie.sref];
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
- (void)refreshBouquetsXMLCache
{
	NSURL *myURI = [NSURL URLWithString: @"/xml/services?mode=0&submode=4" relativeToURL: baseAddress];

	BaseXMLReader *streamReader = [[BaseXMLReader alloc] initWithTarget: nil action: nil];
	cachedBouquetsXML = [[streamReader parseXMLFileAtURL: myURI parseError: nil] retain];
	[streamReader release];
}

- (CXMLDocument *)fetchBouquets:(id)target action:(SEL)action
{
	if(!cachedBouquetsXML || [cachedBouquetsXML retainCount] == 1)
	{
			[cachedBouquetsXML release];
			[self refreshBouquetsXMLCache];
	}

	NSArray *resultNodes = NULL;
	NSUInteger parsedServicesCounter = 0;

	resultNodes = [cachedBouquetsXML nodesForXPath:@"/bouquets/bouquet" error:nil];

	for(CXMLElement *resultElement in resultNodes)
	{
		if(++parsedServicesCounter >= MAX_SERVICES)
			break;

		// A service in the xml represents a service, so create an instance of it.
		NSObject<ServiceProtocol> *newService = [[EnigmaService alloc] initWithNode: (CXMLNode *)resultElement];

		[target performSelectorOnMainThread: action withObject: newService waitUntilDone: NO];
		[newService release];
	}

	// I don't assume we really need this but for the sake of it... :-)
	return cachedBouquetsXML;
}

- (CXMLDocument *)fetchServices:(id)target action:(SEL)action bouquet:(NSObject<ServiceProtocol> *)bouquet
{
	NSArray *resultNodes = nil;
	NSUInteger parsedServicesCounter = 0;

	resultNodes = [bouquet nodesForXPath: @"service" error: nil];
	if(!resultNodes || ![resultNodes count])
	{
		if(!cachedBouquetsXML || [cachedBouquetsXML retainCount] == 1)
		{
			[cachedBouquetsXML release];
			[self refreshBouquetsXMLCache];
		}

		resultNodes = [cachedBouquetsXML nodesForXPath:
						[NSString stringWithFormat: @"/bouquets/bouquet[reference=\"%@\"]/service", bouquet.sref]
						error:nil];
	}
	
	for(CXMLElement *resultElement in resultNodes)
	{
		if(++parsedServicesCounter >= MAX_SERVICES)
			break;

		// A service in the xml represents a service, so create an instance of it.
		NSObject<ServiceProtocol> *newService = [[EnigmaService alloc] initWithNode: (CXMLNode *)resultElement];

		[target performSelectorOnMainThread: action withObject: newService waitUntilDone: NO];
		[newService release];
	}

	// I don't assume we really need this but for the sake of it... :-)
	return cachedBouquetsXML;
}

- (CXMLDocument *)fetchEPG:(id)target action:(SEL)action service:(NSObject<ServiceProtocol> *)service
{
	NSURL *myURI = [NSURL URLWithString: [NSString stringWithFormat:@"/xml/serviceepg?ref=%@", [service.sref stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding]] relativeToURL: baseAddress];

	NSError *parseError = nil;

	BaseXMLReader *streamReader = [[EnigmaEventXMLReader alloc] initWithTarget: target action: action];
	CXMLDocument *doc = [streamReader parseXMLFileAtURL: myURI parseError: &parseError];
	[streamReader autorelease];
	return doc;
}

- (CXMLDocument *)fetchTimers:(id)target action:(SEL)action
{
	NSURL *myURI = [NSURL URLWithString: @"/xml/timers" relativeToURL: baseAddress];
	
	NSError *parseError = nil;

	BaseXMLReader *streamReader = [[EnigmaTimerXMLReader alloc] initWithTarget: target action: action];
	CXMLDocument *doc = [streamReader parseXMLFileAtURL: myURI parseError: &parseError];
	[streamReader autorelease];
	return doc;
}

- (CXMLDocument *)fetchMovielist:(id)target action:(SEL)action
{
	NSURL *myURI = [NSURL URLWithString: @"/xml/services?mode=3&submode=4" relativeToURL: baseAddress];
	
	NSError *parseError = nil;

	BaseXMLReader *streamReader = [[EnigmaMovieXMLReader alloc] initWithTarget: target action: action];
	CXMLDocument *doc = [streamReader parseXMLFileAtURL: myURI parseError: &parseError];
	[streamReader autorelease];
	return doc;
}

- (void)sendPowerstate: (NSString *) newState
{
	// Generate URI
	NSURL *myURI = [NSURL URLWithString: [NSString stringWithFormat:@"/cgi-bin/admin?command=%@", newState] relativeToURL: baseAddress];

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
	[self sendPowerstate: @"shutdown"];
}

- (void)standby
{
	// XXX: we send remote control command button power here as we want to toggle standby
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

- (void)getVolume:(id)target action:(SEL)action
{
	// Generate URI
	NSURL *myURI = [NSURL URLWithString: @"/cgi-bin/audio" relativeToURL: baseAddress];

	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	
	// Create URL Object and download it
	NSURLResponse *response;
	NSURLRequest *request = [NSURLRequest requestWithURL: myURI
											 cachePolicy: NSURLRequestReloadIgnoringCacheData timeoutInterval: 5];
	NSData *data = [NSURLConnection sendSynchronousRequest: request
										 returningResponse: &response error: nil];
	
	NSString *myString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

	Volume *volumeObject = [[Volume alloc] init];
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

	[target performSelectorOnMainThread:action withObject:volumeObject waitUntilDone:NO];
	[volumeObject release];
}

- (BOOL)toggleMuted
{
	// Generate URI
	NSURL *myURI = [NSURL URLWithString: @"/cgi-bin/audio?mute=xy" relativeToURL: baseAddress];

	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

	// Create URL Object and download it
	NSURLResponse *response;
	NSURLRequest *request = [NSURLRequest requestWithURL: myURI
											 cachePolicy: NSURLRequestReloadIgnoringCacheData timeoutInterval: 5];
	NSData *data = [NSURLConnection sendSynchronousRequest: request
										 returningResponse: &response error: nil];
	
	NSString *myString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

	NSRange myRange = [myString rangeOfString: @"mute: 1"];
	[myString release];
	if(myRange.length)
		return YES;

	return NO;
}

- (BOOL)setVolume:(NSInteger) newVolume
{
	// Generate URI
	NSURL *myURI = [NSURL URLWithString: [NSString stringWithFormat:@"/cgi-bin/audio?volume=%d", 63 - newVolume] relativeToURL: baseAddress];

	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

	// Create URL Object and download it
	NSURLResponse *response;
	NSURLRequest *request = [NSURLRequest requestWithURL: myURI
											 cachePolicy: NSURLRequestReloadIgnoringCacheData timeoutInterval: 5];
	NSData *data = [NSURLConnection sendSynchronousRequest: request
										 returningResponse: &response error: nil];
	
	NSString *myString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

	NSRange myRange = [myString rangeOfString: @"Volume set."];
	[myString release];
	if(myRange.length)
		return YES;

	return NO;
}

- (BOOL)addTimer:(NSObject<TimerProtocol> *) newTimer
{
	NSInteger afterEvent = 0;
	if(newTimer.afterevent == kAfterEventStandby)
		afterEvent = doGoSleep;
	else if(newTimer.afterevent == kAfterEventDeepstandby)
		afterEvent = doShutdown;
	else // newTimer.afterevent == kAfterEventNothing or unhandled
		afterEvent = 0;

	// Generate URI
	NSURL *myURI = [NSURL URLWithString: [NSString stringWithFormat: @"/addTimerEvent?timer=regular&ref=%@&start=%d&duration=%d&descr=%@&after_event=%d&action=%@", [newTimer.service.sref stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding], (int)[newTimer.begin timeIntervalSince1970], (int)([newTimer.end timeIntervalSince1970] - [newTimer.begin timeIntervalSince1970]), [newTimer.title stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding], afterEvent, newTimer.justplay ? @"zap" : @"record"] relativeToURL: baseAddress];

	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

	// Create URL Object and download it
	NSURLResponse *response;
	NSURLRequest *request = [NSURLRequest requestWithURL: myURI
											 cachePolicy: NSURLRequestReloadIgnoringCacheData timeoutInterval: 5];
	NSData *data = [NSURLConnection sendSynchronousRequest: request
										 returningResponse: &response error: nil];
	
	NSString *myString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

	NSRange myRange = [myString rangeOfString: @"Timer event was created successfully."];
	[myString release];
	if(myRange.length)
		return YES;
	
	return NO;
}

- (BOOL)editTimer:(NSObject<TimerProtocol> *) oldTimer: (NSObject<TimerProtocol> *) newTimer
{
	// This is the only way I found in enigma sources as changeTimerEvent does not allow us e.g. to change the service
	if([self delTimer: oldTimer])
	{
		if([self addTimer: newTimer])
			return YES;

		// XXX: We might run into serious problems if this fails too :-)
		[self addTimer: oldTimer]; // We failed to add the new timer, try to add the old one again
	}
	return NO;
}

- (BOOL)delTimer:(NSObject<TimerProtocol> *) oldTimer
{
	// Generate URI
	NSURL *myURI = [NSURL URLWithString: [NSString stringWithFormat: @"/deleteTimerEvent?ref=%@&start=%d&force=yes", [oldTimer.service.sref stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding], (int)[oldTimer.begin timeIntervalSince1970]] relativeToURL: baseAddress];

	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

	// Create URL Object and download it
	NSURLResponse *response;
	NSURLRequest *request = [NSURLRequest requestWithURL: myURI
											 cachePolicy: NSURLRequestReloadIgnoringCacheData timeoutInterval: 5];
	NSData *data = [NSURLConnection sendSynchronousRequest: request
										 returningResponse: &response error: nil];
	
	NSString *myString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

	NSRange myRange = [myString rangeOfString: @"Timer event deleted successfully."];
	[myString release];
	if(myRange.length)
		return YES;

	return NO;
}

- (BOOL)sendButton:(NSInteger) type
{
	// Fix some Buttoncodes
	switch(type)
	{
		case kButtonCodeLame:
			type = 1;
			break;
		case kButtonCodeMenu:
			type = 141;
			break;
		case kButtonCodeTV:
			type = 385;
			break;
		case kButtonCodeRadio:
			type = 377;
			break;
		case kButtonCodeText:
			type = 66;
			break;
		default:
			break;
	}

	// Generate URI
	NSURL *myURI = [NSURL URLWithString: [NSString stringWithFormat: @"/cgi-bin/rc?%d", type] relativeToURL: baseAddress];

	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

	// Create URL Object and download it
	NSHTTPURLResponse *response;
	NSURLRequest *request = [NSURLRequest requestWithURL: myURI
											 cachePolicy: NSURLRequestReloadIgnoringCacheData timeoutInterval: 5];
	[NSURLConnection sendSynchronousRequest: request
										 returningResponse: &response error: nil];

	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

	return ([response statusCode] == 204);
}

- (BOOL)sendMessage:(NSString *)message: (NSString *)caption: (NSInteger)type: (NSInteger)timeout
{
	NSInteger translatedType = -1;
	switch(type)
	{
		case kEnigma1MessageTypeInfo:
			translatedType = 16;
		case kEnigma1MessageTypeWarning:
			translatedType = 32;
		case kEnigma1MessageTypeQuestion:
			translatedType = 64;
		case kEnigma1MessageTypeError:
			translatedType = 128;
		default:
			translatedType = -1;
	}

	// Generate URI
	NSURL *myURI = [NSURL URLWithString: [NSString stringWithFormat: @"/cgi-bin/xmessage?body=%@&caption=%@&timeout=%d&icon=%d", [message  stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding], [caption  stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding], timeout, translatedType] relativeToURL: baseAddress];

	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

	// Create URL Object and download it
	NSURLResponse *response;
	NSURLRequest *request = [NSURLRequest requestWithURL: myURI
											 cachePolicy: NSURLRequestReloadIgnoringCacheData timeoutInterval: 5];
	NSData *data = [NSURLConnection sendSynchronousRequest: request
										 returningResponse: &response error: nil];

	NSString *myString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

	NSRange myRange = [myString rangeOfString: @"+ok"];
	[myString release];
	if(myRange.length)
		return YES;

	return NO;
}

- (NSInteger)getMaxMessageType
{
	return kEnigma1MessageTypeMax;
}

- (NSString *)getMessageTitle: (NSInteger)type
{
	switch(type)
	{
		case kEnigma1MessageTypeInfo:
			return NSLocalizedString(@"Info", @"");
		case kEnigma1MessageTypeWarning:
			return NSLocalizedString(@"Warning", @"");
		case kEnigma1MessageTypeQuestion:
			return NSLocalizedString(@"Question", @"");
		case kEnigma1MessageTypeError:
			return NSLocalizedString(@"Error", @"");
		default:
			return @"???";
	}
}

- (NSData *)getScreenshot: (enum screenshotType)type
{
	if(type == kScreenshotTypeOSD)
	{
		// Generate URI
		NSURL *myURI = [NSURL URLWithString: @"/cgi-bin/osdshot" relativeToURL: baseAddress];

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
	else// We actually generate a combined picture here
	{
		// We need to trigger a capture and individually fetch the picture
		// Generate URI
		NSURL *myURI = [NSURL URLWithString: @"/body?mode=controlScreenShot" relativeToURL: baseAddress];
		
		[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
		
		// Create URL Object and download it
		NSURLResponse *response;
		NSURLRequest *request = [NSURLRequest requestWithURL: myURI
											cachePolicy: NSURLRequestReloadIgnoringCacheData timeoutInterval: 5];
		NSData *data = [NSURLConnection sendSynchronousRequest: request
											returningResponse: &response error: nil];
		
		[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
		
		NSString *myString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

		NSRange myRange = [myString rangeOfString: @"/root/tmp/screenshot.jpg"];
		[myString release];
		if(!myRange.length)
			return nil;
		
		// Generate URI
		myURI = [NSURL URLWithString: @"/root/tmp/screenshot.jpg" relativeToURL: baseAddress];

		[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

		// Create URL Object and download it
		request = [NSURLRequest requestWithURL: myURI
											cachePolicy: NSURLRequestReloadIgnoringCacheData timeoutInterval: 5];
		data = [NSURLConnection sendSynchronousRequest: request
											returningResponse: &response error: nil];

		[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

		return data;
	}

	return nil;
}

- (BOOL)delMovie:(NSObject<MovieProtocol> *) movie
{
	// Generate URI
	NSURL *myURI = [NSURL URLWithString:[NSString stringWithFormat:@"/cgi-bin/deleteMovie?ref=%@", [movie.sref stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding]] relativeToURL:baseAddress];

	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

	// Create URL Object and download it
	NSHTTPURLResponse *response;
	NSURLRequest *request = [NSURLRequest requestWithURL: myURI
											 cachePolicy: NSURLRequestReloadIgnoringCacheData timeoutInterval: 5];
	[NSURLConnection sendSynchronousRequest: request
										returningResponse: &response error: nil];

	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

	return ([response statusCode] == 204);
}

- (CXMLDocument *)searchEPG:(id)target action:(SEL)action title:(NSString *)title
{
	[NSException raise:@"ExcUnsupportedFunction" format:nil];
	return nil;
}

- (BOOL)instantRecord
{
	// Generate URI
	NSURL *myURI = [NSURL URLWithString:@"/cgi-bin/videocontrol?command=record" relativeToURL:baseAddress];

	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

	// Create URL Object and download it
	NSHTTPURLResponse *response;
	NSURLRequest *request = [NSURLRequest requestWithURL: myURI
											 cachePolicy: NSURLRequestReloadIgnoringCacheData timeoutInterval: 5];
	[NSURLConnection sendSynchronousRequest: request
						  returningResponse: &response error: nil];

	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

	return ([response statusCode] == 500);
}

- (void)openRCEmulator: (UINavigationController *)navigationController
{
	UIViewController *targetViewController = [[EnigmaRCEmulatorController alloc] init];
	[navigationController pushViewController:targetViewController animated:YES];
	[targetViewController release];
}

- (void)freeCaches
{
	[cachedBouquetsXML release];
	cachedBouquetsXML = nil;
}

@end
