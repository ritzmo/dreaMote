//
//  Enigma1Connector.m
//  Untitled
//
//  Created by Moritz Venn on 08.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "Enigma1Connector.h"

#import "Service.h"
#import "Timer.h"
#import "Event.h"
#import "Volume.h"

#import "Enigma/ServiceXMLReader.h"
#import "Enigma/EventXMLReader.h"
#import "Enigma/TimerXMLReader.h"
#import "Enigma/VolumeXMLReader.h"
#import "Enigma/MovieXMLReader.h"

@implementation Enigma1Connector

@synthesize baseAddress;

- (const BOOL)hasFeature: (enum connectorFeatures)feature
{
	return (feature == kFeaturesGUIRestart);
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

	[super dealloc];
}

+ (id <RemoteConnector>*)createClassWithAddress:(NSString *) address
{
	return (id <RemoteConnector>*)[[Enigma1Connector alloc] initWithAddress: address];
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

- (BOOL)zapTo:(Service *) service
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

- (void)fetchServices:(id)target action:(SEL)action
{
	NSURL *myURI = [NSURL URLWithString: @"/xml/services?mode=0&submode=4" relativeToURL: baseAddress];

	NSError *parseError = nil;

	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

	ServiceXMLReader *streamReader = [ServiceXMLReader initWithTarget: target action: action];
	[streamReader parseXMLFileAtURL: myURI parseError: &parseError];
	[streamReader release];

	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

- (void)fetchEPG:(id)target action:(SEL)action service:(Service *)service
{
	NSURL *myURI = [NSURL URLWithString: [NSString stringWithFormat:@"/xml/serviceepg?ref=%@", service.sref] relativeToURL: baseAddress];

	NSError *parseError = nil;

	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

	EnigmaEventXMLReader *streamReader = [EnigmaEventXMLReader initWithTarget: target action: action];
	[streamReader parseXMLFileAtURL: myURI parseError: &parseError];
	[streamReader release];

	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

- (void)fetchTimers:(id)target action:(SEL)action
{
	NSURL *myURI = [NSURL URLWithString: @"/xml/timers" relativeToURL: baseAddress];
	
	NSError *parseError = nil;
	
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	
	TimerXMLReader *streamReader = [TimerXMLReader initWithTarget: target action: action];
	[streamReader parseXMLFileAtURL: myURI parseError: &parseError];
	[streamReader release];
	
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

- (void)fetchMovielist:(id)target action:(SEL)action
{
	NSURL *myURI = [NSURL URLWithString: @"/xml/services?mode=3&submode=4" relativeToURL: baseAddress];
	
	NSError *parseError = nil;
	
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	
	MovieXMLReader *streamReader = [MovieXMLReader initWithTarget: target action: action];
	[streamReader parseXMLFileAtURL: myURI parseError: &parseError];
	[streamReader release];
	
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
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

	[target performSelectorOnMainThread:action withObject:volumeObject waitUntilDone:NO];
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
	if(myRange.length)
		return YES;

	return NO;
}

- (BOOL)addTimer:(Timer *) newTimer
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
	if(myRange.length)
		return YES;
	
	return NO;
}

- (BOOL)editTimer:(Timer *) oldTimer: (Timer *) newTimer
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

- (BOOL)delTimer:(Timer *) oldTimer
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

@end
