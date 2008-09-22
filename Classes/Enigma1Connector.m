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

#import "ServiceXMLReader.h"
#import "EventXMLReader.h"
#import "TimerXMLReader.h"
#import "VolumeXMLReader.h"
#import "MovieXMLReader.h"

#define VOLFACTOR (100/63)

@interface Enigma1Connector()
+ (NSString *)urlencode:(NSString *)toencode;
@end

@implementation Enigma1Connector

@synthesize baseAddress;

- (id)initWithAddress:(NSString *) address
{
	if(self = [super init])
	{
		baseAddress = [address copy];
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

+ (NSString *)urlencode:(NSString *)toencode
{
	return [(NSString *) CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)toencode, NULL, (CFStringRef)@"()<>@,.;:\"/[]?=\\& ", kCFStringEncodingUTF8) autorelease];
}

// TODO: can someone verify if this works (especially for movies)?
- (BOOL)zapTo:(Service *) service
{
	// Generate URI
	NSString *myURI = [NSString stringWithFormat:@"%@/cgi-bin/zapTo?mode=zap&path=%@", self.baseAddress, [Enigma1Connector urlencode: service.sref]];

	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

	// Create URL Object and download it
	[NSString stringWithContentsOfURL: [NSURL URLWithString: myURI] encoding: NSUTF8StringEncoding error: nil];

	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

	return YES; // The Enigma1-WebIf doesn't give us any useful result anyways
}

- (void)fetchServices:(id)target action:(SEL)action
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	NSString *myURI = [NSString stringWithFormat:@"%@/xml/services?mode=0&submode=4", self.baseAddress];

	NSError *parseError = nil;

	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

	ServiceXMLReader *streamReader = [ServiceXMLReader initWithTarget: target action: action];
	[streamReader parseXMLFileAtURL:[NSURL URLWithString:myURI] parseError:&parseError];
	[streamReader release];

	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	
	[pool release];
}

- (void)fetchEPG:(id)target action:(SEL)action service:(Service *)service
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	NSString *myURI = [NSString stringWithFormat:@"%@/xml/serviceepg?ref=%@", self.baseAddress, service.sref];

	NSError *parseError = nil;

	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

	EventXMLReader *streamReader = [EventXMLReader initWithTarget: target action: action];
	[streamReader parseXMLFileAtURL:[NSURL URLWithString:myURI] parseError:&parseError];
	[streamReader release];

	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	
	[pool release];
}

- (void)fetchTimers:(id)target action:(SEL)action
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	NSString *myURI = [NSString stringWithFormat:@"%@/xml/timers", self.baseAddress];
	
	NSError *parseError = nil;
	
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	
	TimerXMLReader *streamReader = [TimerXMLReader initWithTarget: target action: action];
	[streamReader parseXMLFileAtURL:[NSURL URLWithString:myURI] parseError:&parseError];
	[streamReader release];
	
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

	[pool release];
}

- (void)fetchMovielist:(id)target action:(SEL)action
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	NSString *myURI = [NSString stringWithFormat:@"%@/xml/services?mode=3&submode=4", self.baseAddress];
	
	NSError *parseError = nil;
	
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	
	MovieXMLReader *streamReader = [MovieXMLReader initWithTarget: target action: action];
	[streamReader parseXMLFileAtURL:[NSURL URLWithString:myURI] parseError:&parseError];
	[streamReader release];
	
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

	[pool release];
}

- (void)sendPowerstate: (NSString *) newState
{
	// Generate URI
	NSString *myURI = [NSString stringWithFormat:@"%@/cgi-bin/admin?command=%@", self.baseAddress, newState];

	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

	// Create URL Object and download it
	[NSString stringWithContentsOfURL: [NSURL URLWithString: myURI] encoding: NSUTF8StringEncoding error: nil];

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
	/*
	 * /cgi-bin/audio
	 * 0 -> 100%
	 * 63 -> 0% == Mute
	 */
	// Generate URI
	NSString *myURI = [NSString stringWithFormat:@"%@/cgi-bin/audio", self.baseAddress];

	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	
	// Create URL Object and download it
	NSString *myString = [NSString stringWithContentsOfURL: [NSURL URLWithString: myURI] encoding: NSUTF8StringEncoding error: nil];
	
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

		// Convert Volume to expected Format
		volume = VOLFACTOR * (63 - [[myString substringWithRange: firstRange] integerValue]);
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
	NSString *myURI = [NSString stringWithFormat:@"%@/cgi-bin/audio?mute=xy", self.baseAddress];

	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

	// Create URL Object and download it
	NSString *myString = [NSString stringWithContentsOfURL: [NSURL URLWithString: myURI] encoding: NSUTF8StringEncoding error: nil];

	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

	NSRange myRange = [myString rangeOfString: @"mute: 1"];
	if(myRange.length)
		return YES;

	return NO;
}

- (BOOL)setVolume:(NSInteger) newVolume
{
	// Generate URI
	NSString *myURI = [NSString stringWithFormat:@"%@/cgi-bin/audio?volume=%d", self.baseAddress, newVolume/VOLFACTOR];

	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

	// Create URL Object and download it
	NSString *myString = [NSString stringWithContentsOfURL: [NSURL URLWithString: myURI] encoding: NSUTF8StringEncoding error: nil];

	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

	NSRange myRange = [myString rangeOfString: @"Volume set."];
	if(myRange.length)
		return YES;

	return NO;
}

- (BOOL)addTimer:(Timer *) newTimer
{
	// We hack around a little here - assuming statePaused equals a disabled timer in enigma2 we hide this flag in afterEvent as there is no other way of setting it
	// TODO: find out if the assumption is true :-)
	NSInteger afterEvent = [newTimer getEnigmaAfterEvent];
	if(newTimer.disabled)
		afterEvent |= statePaused;

	// Generate URI
	NSString *myURI = [NSString stringWithFormat: @"%@/addTimerEvent?timer=regular&ref=%@&start=%d&duration=%d&descr=%@&after_event=%d&action=%@", baseAddress, newTimer.service.sref, (int)[newTimer.begin timeIntervalSince1970], (int)([newTimer.end timeIntervalSince1970] - [newTimer.begin timeIntervalSince1970]), [Enigma1Connector urlencode: newTimer.title], afterEvent , newTimer.justplay ? @"zap" : @"record"];

	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

	// Create URL Object and download it
	NSString *myString = [NSString stringWithContentsOfURL: [NSURL URLWithString: myURI] encoding: NSUTF8StringEncoding error: nil];

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
	NSString *myURI = [NSString stringWithFormat: @"%@/deleteTimerEvent?ref=%@&start=%d&force=yes", baseAddress, oldTimer.service.sref, (int)[oldTimer.begin timeIntervalSince1970]];

	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

	// Create URL Object and download it
	NSString *myString = [NSString stringWithContentsOfURL: [NSURL URLWithString: myURI] encoding: NSUTF8StringEncoding error: nil];

	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

	NSRange myRange = [myString rangeOfString: @"Timer event deleted successfully."];
	if(myRange.length)
		return YES;

	return NO;
}

- (BOOL)sendButton:(NSInteger) type
{
	// Generate URI
	NSString *myURI = [NSString stringWithFormat: @"%@/cgi-bin/rc?%d", baseAddress, type];

	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

	// Create URL Object and download it
	[NSString stringWithContentsOfURL: [NSURL URLWithString: myURI] encoding: NSUTF8StringEncoding error: nil];

	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

	return YES; // The Enigma1-WebIf doesn't give any useful result
}

@end
