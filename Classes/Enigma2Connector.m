//
//  Enigma2Connector.m
//  Untitled
//
//  Created by Moritz Venn on 08.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "Enigma2Connector.h"

#import "Service.h"
#import "Timer.h"
#import "Event.h"
#import "Volume.h"

#import "ServiceXMLReader.h"
#import "EventXMLReader.h"
#import "TimerXMLReader.h"
#import "VolumeXMLReader.h"

@implementation Enigma2Connector

@synthesize baseAddress;

- (id)initWithAddress:(NSString *) address
{
	baseAddress = [address copy];
	return self;
}

+ (id <RemoteConnector>*)createClassWithAddress:(NSString *) address
{
	return (id <RemoteConnector>*)[[Enigma2Connector alloc] initWithAddress: address];
}

- (BOOL)zapTo:(Service *) service
{
	// Generate URI
	NSString *myURI = [NSString stringWithFormat:@"%@/web/zap?sRef=%@", self.baseAddress, [service getServiceReference]];
	
	// Create URL Object and download it
	NSString *myString = [NSString stringWithContentsOfURL: [NSURL URLWithString: myURI] encoding: NSUTF8StringEncoding error: nil];
	
	// Compare to expected result
	return [myString isEqualToString: @"	<rootElement></rootElement>"];
}

- (void)fetchServices:(id)target action:(SEL)action
{
	NSString *myURI = [NSString stringWithFormat:@"%@/web/getservices?sRef=%@", self.baseAddress, @"1:7:1:0:0:0:0:0:0:0:FROM%20BOUQUET%20%22userbouquet.favourites.tv%22%20ORDER%20BY%20bouquet"];

	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	NSError *parseError = nil;

	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

	ServiceXMLReader *streamReader = [ServiceXMLReader initWithTarget: target action: action];
	[streamReader parseXMLFileAtURL:[NSURL URLWithString:myURI] parseError:&parseError];
	[streamReader release];
	[pool release];

	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

- (void)fetchEPG:(id)target action:(SEL)action service:(Service *)service
{
	NSString *myURI = [NSString stringWithFormat:@"%@/web/epgservice?sRef=%@", self.baseAddress, [service getServiceReference]];

	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	NSError *parseError = nil;

	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

	EventXMLReader *streamReader = [EventXMLReader initWithTarget: target action: action];
	[streamReader parseXMLFileAtURL:[NSURL URLWithString:myURI] parseError:&parseError];
	[streamReader release];
	[pool release];

	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

- (void)fetchTimers:(id)target action:(SEL)action
{
	NSString *myURI = [NSString stringWithFormat:@"%@/web/timerlist", self.baseAddress];

	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	NSError *parseError = nil;
	
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	
	TimerXMLReader *streamReader = [TimerXMLReader initWithTarget: target action: action];
	[streamReader parseXMLFileAtURL:[NSURL URLWithString:myURI] parseError:&parseError];
	[streamReader release];
	[pool release];
	
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

- (void)sendPowerstate: (int) newState
{
	// Generate URI
	NSString *myURI = [NSString stringWithFormat:@"%@/web/powerstate?newstate=%d", self.baseAddress, newState];
	
	// Create URL Object and download it
	[NSString stringWithContentsOfURL: [NSURL URLWithString: myURI] encoding: NSUTF8StringEncoding error: nil];
}

- (void)shutdown
{
	[self sendPowerstate: 1];
}

- (void)standby
{
	// XXX: we send remote control command 116 here as we want to toggle standby

	// Generate URI
	NSString *myURI = [NSString stringWithFormat:@"%@/web/remotecontrol?command=116", self.baseAddress];
	
	// Create URL Object and download it
	[NSString stringWithContentsOfURL: [NSURL URLWithString: myURI] encoding: NSUTF8StringEncoding error: nil];
}

- (void)reboot
{
	[self sendPowerstate: 2];
}

- (void)restart
{
	[self sendPowerstate: 3];
}

- (void)getVolume:(id)target action:(SEL)action
{
	NSString *myURI = [NSString stringWithFormat:@"%@/web/vol", self.baseAddress];

	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	NSError *parseError = nil;
	
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

	VolumeXMLReader *streamReader = [VolumeXMLReader initWithTarget: target action: action];
	[streamReader parseXMLFileAtURL:[NSURL URLWithString:myURI] parseError:&parseError];
	[streamReader release];
	[pool release];

	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

- (BOOL)toggleMuted
{
	// Generate URI
	NSString *myURI = [NSString stringWithFormat:@"%@/web/vol?set=mute", self.baseAddress];

	// Create URL Object and download it
	NSString *myString = [NSString stringWithContentsOfURL: [NSURL URLWithString: myURI] encoding: NSUTF8StringEncoding error: nil];

	NSRange myRange = [myString rangeOfString: @"<e2ismuted>True</e2ismuted>"];
	if(myRange.length)
		return YES;

	return NO;
}

- (void)setVolume:(int) newVolume
{
	// Generate URI
	NSString *myURI = [NSString stringWithFormat:@"%@/web/vol?set=set%d", self.baseAddress, newVolume];
	
	// Create URL Object and download it
	[NSString stringWithContentsOfURL: [NSURL URLWithString: myURI] encoding: NSUTF8StringEncoding error: nil];
}

+ (NSString *)urlencode:(NSString *)toencode
{
	return [(NSString *) CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)toencode, NULL, (CFStringRef)@"()<>@,.;:\"/[]?=\\& ", kCFStringEncodingUTF8) autorelease];
}

- (void)addTimer:(Timer *) newTimer
{
	// Generate URI
	NSString *myURI = [NSString stringWithFormat: @"%@/web/timeradd?sRef=%@&begin=%d&end=%d&name=%@&description=%@&eit=%@&disabled=%d&justplay=%d&afterevent=%d", baseAddress, [[newTimer service] sref], (int)[[newTimer begin] timeIntervalSince1970], (int)[[newTimer end] timeIntervalSince1970], [Enigma2Connector urlencode: [newTimer title]], [Enigma2Connector urlencode: [newTimer tdescription]], [newTimer eit], [newTimer disabled], [newTimer justplay], 0/*[newTimer afterEvent]*/];

	// Create URL Object and download it
	[NSString stringWithContentsOfURL: [NSURL URLWithString: myURI] encoding: NSUTF8StringEncoding error: nil];
}

- (void)editTimer:(Timer *) oldTimer: (Timer *) newTimer
{
	// Generate URI
	NSString *myURI = [NSString stringWithFormat: @"%@/web/timerchange?sRef=%@&begin=%d&end=%d&name=%@&description=%@&eit=%@&disabled=%d&justplay=%d&afterevent=%d&channelOld=%@&beginOld=%d&endOld=%d&deleteOldOnSave=1", baseAddress, [[newTimer service] sref], (int)[[newTimer begin] timeIntervalSince1970], (int)[[newTimer end] timeIntervalSince1970], [Enigma2Connector urlencode: [newTimer title]], [Enigma2Connector urlencode: [newTimer tdescription]], [newTimer eit], [newTimer disabled], [newTimer justplay], 0/*[newTimer afterEvent]*/, [[oldTimer service] sref], (int)[[oldTimer begin] timeIntervalSince1970], (int)[[oldTimer end] timeIntervalSince1970]];

	// Create URL Object and download it
	[NSString stringWithContentsOfURL: [NSURL URLWithString: myURI] encoding: NSUTF8StringEncoding error: nil];
}

- (void)delTimer:(Timer *) oldTimer
{
	// Generate URI
	NSString *myURI = [NSString stringWithFormat: @"%@/web/timerdelete?sRef=%@&begin=%d&end=%d", baseAddress, [[oldTimer service] sref], (int)[[oldTimer begin] timeIntervalSince1970], (int)[[oldTimer end] timeIntervalSince1970]];

	// Create URL Object and download it
	[NSString stringWithContentsOfURL: [NSURL URLWithString: myURI] encoding: NSUTF8StringEncoding error: nil];
}

@end
