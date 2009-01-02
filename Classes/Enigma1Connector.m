//
//  Enigma1Connector.m
//  Untitled
//
//  Created by Moritz Venn on 08.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "Enigma1Connector.h"

#import "Objects/Enigma/Service.h"
#import "Objects/Generic/Timer.h"
#import "Objects/Generic/Volume.h"

#import "XMLReader/Enigma/EventXMLReader.h"
#import "XMLReader/Enigma/TimerXMLReader.h"
#import "XMLReader/Enigma/MovieXMLReader.h"

// Services are 'lightweight'
#define MAX_SERVICES 2048

@implementation Enigma1Connector

@synthesize baseAddress;

- (const BOOL)hasFeature: (enum connectorFeatures)feature
{
	return
		(feature == kFeaturesGUIRestart) ||
		(feature == kFeaturesRecordInfo) ||
		(feature == kFeaturesMessageCaption) ||
		(feature == kFeaturesMessageTimeout) ||
		(feature == kFeaturesScreenshot) ||
		(feature == kFeaturesTimerAfterEvent) ||
		(feature == kFeaturesFullRemote);
}

- (NSInteger)getMaxVolume
{
	return 63;
}

- (id)initWithAddress:(NSString *) address
{
	if(self = [super init])
	{
		self.baseAddress = [NSURL URLWithString: address];
	}
	return self;
}

- (void)dealloc
{
	[baseAddress release];
	[cachedBouquetsXML release];

	[super dealloc];
}

+ (NSObject <RemoteConnector>*)createClassWithAddress:(NSString *) address
{
	return (NSObject <RemoteConnector>*)[[Enigma1Connector alloc] initWithAddress: address];
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

- (BOOL)zapTo:(NSObject<ServiceProtocol> *) service
{
	// Generate URI
	NSURL *myURI = [NSURL URLWithString: [NSString stringWithFormat:@"/cgi-bin/zapTo?mode=zap&path=%@", [service.sref stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding]] relativeToURL: baseAddress];

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
	NSArray *resultNodes = NULL;
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
	NSURL *myURI = [NSURL URLWithString: [NSString stringWithFormat:@"/xml/serviceepg?ref=%@", service.sref] relativeToURL: baseAddress];

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
	// Generate URI
	NSURL *myURI = [NSURL URLWithString: [NSString stringWithFormat: @"/addTimerEvent?timer=regular&ref=%@&start=%d&duration=%d&descr=%@&after_event=%d&action=%@", newTimer.service.sref, (int)[newTimer.begin timeIntervalSince1970], (int)([newTimer.end timeIntervalSince1970] - [newTimer.begin timeIntervalSince1970]), [newTimer.title stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding], [newTimer getEnigmaAfterEvent] , newTimer.justplay ? @"zap" : @"record"] relativeToURL: baseAddress];

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
	// This is the easiest way I found in enigma sources as changeTimerEvent does not accept start & duration ;-)
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
	NSURL *myURI = [NSURL URLWithString: [NSString stringWithFormat: @"/deleteTimerEvent?ref=%@&start=%d&force=yes", oldTimer.service.sref, (int)[oldTimer.begin timeIntervalSince1970]] relativeToURL: baseAddress];

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
	// Generate URI
	NSURL *myURI = [NSURL URLWithString: [NSString stringWithFormat: @"/cgi-bin/xmessage?body=%@&caption=%@&timeout=%d", [message  stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding], [caption  stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding], timeout] relativeToURL: baseAddress];

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

- (void)freeCaches
{
	[cachedBouquetsXML release];
	cachedBouquetsXML = nil;
}

@end
