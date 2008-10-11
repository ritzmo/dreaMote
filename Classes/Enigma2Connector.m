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
#import "MovieXMLReader.h"

enum powerStates {
	kShutdownState = 1,
	kRebootState = 2,
	kRestartGUIState = 3,
};

@interface Enigma2Connector()
+ (NSString *)urlencode:(NSString *)toencode;
@end

@implementation Enigma2Connector

@synthesize baseAddress;

- (const BOOL)hasFeature: (enum connectorFeatures)feature
{
	return
		(feature == kFeaturesDisabledTimers) ||
		(feature == kFeaturesExtendedRecordInfo);
}

- (NSInteger)getMaxVolume
{
	return 100;
}

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
	return (id <RemoteConnector>*)[[Enigma2Connector alloc] initWithAddress: address];
}

+ (NSString *)urlencode:(NSString *)toencode
{
	return [(NSString *) CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)toencode, NULL, (CFStringRef)@"()<>@,.;:\"/[]?=\\& ", kCFStringEncodingUTF8) autorelease];
}

- (BOOL)isReachable
{
	// Generate URI
	NSString *myURI = [NSString stringWithFormat:@"%@/web/about", self.baseAddress];

	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

	NSError *error;
	NSURLResponse *response;
	NSURLRequest *request = [NSURLRequest requestWithURL: [NSURL URLWithString: myURI]
											 cachePolicy: NSURLRequestReloadIgnoringCacheData timeoutInterval: 5];
	NSData *data = [NSURLConnection sendSynchronousRequest: request
										 returningResponse: &response error: &error];

	NSString *myString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

	NSRange myRange = [myString rangeOfString: @"<e2about>"];
	if(myRange.length)
		return YES;
	
	return NO;
}

- (BOOL)zapTo:(Service *) service
{
	// Generate URI
	NSString *myURI = [NSString stringWithFormat:@"%@/web/zap?sRef=%@", self.baseAddress, [Enigma2Connector urlencode: service.sref]];

	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

	// Create URL Object and download it
	NSString *myString = [NSString stringWithContentsOfURL: [NSURL URLWithString: myURI] encoding: NSUTF8StringEncoding error: nil];

	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	
	// Compare to expected result
	return [myString isEqualToString: @"	<rootElement></rootElement>"];
}

- (void)fetchServices:(id)target action:(SEL)action
{
	NSString *myURI = [NSString stringWithFormat:@"%@/web/getservices?sRef=%@", self.baseAddress, @"1:7:1:0:0:0:0:0:0:0:FROM%20BOUQUET%20%22userbouquet.favourites.tv%22%20ORDER%20BY%20bouquet"];

	NSError *parseError = nil;

	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

	ServiceXMLReader *streamReader = [ServiceXMLReader initWithTarget: target action: action];
	[streamReader parseXMLFileAtURL:[NSURL URLWithString:myURI] parseError:&parseError];
	[streamReader release];

	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

- (void)fetchEPG:(id)target action:(SEL)action service:(Service *)service
{
	NSString *myURI = [NSString stringWithFormat:@"%@/web/epgservice?sRef=%@", self.baseAddress, service.sref];

	NSError *parseError = nil;

	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

	EventXMLReader *streamReader = [EventXMLReader initWithTarget: target action: action];
	[streamReader parseXMLFileAtURL:[NSURL URLWithString:myURI] parseError:&parseError];
	[streamReader release];

	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

- (void)fetchTimers:(id)target action:(SEL)action
{
	NSString *myURI = [NSString stringWithFormat:@"%@/web/timerlist", self.baseAddress];
	
	NSError *parseError = nil;
	
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	
	TimerXMLReader *streamReader = [TimerXMLReader initWithTarget: target action: action];
	[streamReader parseXMLFileAtURL:[NSURL URLWithString:myURI] parseError:&parseError];
	[streamReader release];
	
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

- (void)fetchMovielist:(id)target action:(SEL)action
{
	NSString *myURI = [NSString stringWithFormat:@"%@/web/movielist", self.baseAddress];
	
	NSError *parseError = nil;
	
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	
	MovieXMLReader *streamReader = [MovieXMLReader initWithTarget: target action: action];
	[streamReader parseXMLFileAtURL:[NSURL URLWithString:myURI] parseError:&parseError];
	[streamReader release];
	
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

- (void)sendPowerstate: (NSInteger) newState
{
	// Generate URI
	NSString *myURI = [NSString stringWithFormat:@"%@/web/powerstate?newstate=%d", self.baseAddress, newState];

	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

	// Create URL Object and download it
	[NSString stringWithContentsOfURL: [NSURL URLWithString: myURI] encoding: NSUTF8StringEncoding error: nil];

	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

- (void)shutdown
{
	[self sendPowerstate: kShutdownState];
}

- (void)standby
{
	// XXX: we send remote control command button power here as we want to toggle standby
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

- (void)getVolume:(id)target action:(SEL)action
{
	NSString *myURI = [NSString stringWithFormat:@"%@/web/vol", self.baseAddress];

	NSError *parseError = nil;
	
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

	VolumeXMLReader *streamReader = [VolumeXMLReader initWithTarget: target action: action];
	[streamReader parseXMLFileAtURL:[NSURL URLWithString:myURI] parseError:&parseError];
	[streamReader release];

	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

- (BOOL)toggleMuted
{
	// Generate URI
	NSString *myURI = [NSString stringWithFormat:@"%@/web/vol?set=mute", self.baseAddress];

	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

	// Create URL Object and download it
	NSString *myString = [NSString stringWithContentsOfURL: [NSURL URLWithString: myURI] encoding: NSUTF8StringEncoding error: nil];

	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

	NSRange myRange = [myString rangeOfString: @"<e2ismuted>True</e2ismuted>"];
	if(myRange.length)
		return YES;

	return NO;
}

- (BOOL)setVolume:(NSInteger) newVolume
{
	// Generate URI
	NSString *myURI = [NSString stringWithFormat:@"%@/web/vol?set=set%d", self.baseAddress, newVolume];

	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

	// Create URL Object and download it
	NSString *myString = [NSString stringWithContentsOfURL: [NSURL URLWithString: myURI] encoding: NSUTF8StringEncoding error: nil];

	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

	NSRange myRange = [myString rangeOfString: @"<e2result>True</e2result>"];
	if(myRange.length)
		return YES;
	
	return NO;
}

- (BOOL)addTimer:(Timer *) newTimer
{
	// Generate URI
	NSString *myURI = [NSString stringWithFormat: @"%@/web/timeradd?sRef=%@&begin=%d&end=%d&name=%@&description=%@&eit=%@&disabled=%d&justplay=%d&afterevent=%d", baseAddress, newTimer.service.sref, (int)[newTimer.begin timeIntervalSince1970], (int)[newTimer.end timeIntervalSince1970], [Enigma2Connector urlencode: newTimer.title], [Enigma2Connector urlencode: newTimer.tdescription], newTimer.eit, newTimer.disabled ? 1 : 0, newTimer.justplay ? 1 : 0, newTimer.afterevent];

	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

	// Create URL Object and download it
	NSString *myString = [NSString stringWithContentsOfURL: [NSURL URLWithString: myURI] encoding: NSUTF8StringEncoding error: nil];

	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

	NSRange myRange = [myString rangeOfString: @"<e2state>True</e2state>"];
	if(myRange.length)
		return YES;
	
	return NO;
}

- (BOOL)editTimer:(Timer *) oldTimer: (Timer *) newTimer
{
	// Generate URI
	NSString *myURI = [NSString stringWithFormat: @"%@/web/timerchange?sRef=%@&begin=%d&end=%d&name=%@&description=%@&eit=%@&disabled=%d&justplay=%d&afterevent=%d&channelOld=%@&beginOld=%d&endOld=%d&deleteOldOnSave=1", baseAddress, newTimer.service.sref, (int)[newTimer.begin timeIntervalSince1970], (int)[newTimer.end timeIntervalSince1970], [Enigma2Connector urlencode: newTimer.title], [Enigma2Connector urlencode: newTimer.tdescription], newTimer.eit, newTimer.disabled ? 1 : 0, newTimer.justplay ? 1 : 0, newTimer.afterevent, oldTimer.service.sref, (int)[oldTimer.begin timeIntervalSince1970], (int)[oldTimer.end timeIntervalSince1970]];

	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

	// Create URL Object and download it
	NSString *myString = [NSString stringWithContentsOfURL: [NSURL URLWithString: myURI] encoding: NSUTF8StringEncoding error: nil];

	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

	NSRange myRange = [myString rangeOfString: @"<e2state>True</e2state>"];
	if(myRange.length)
		return YES;
	
	return NO;
}

- (BOOL)delTimer:(Timer *) oldTimer
{
	// Generate URI
	NSString *myURI = [NSString stringWithFormat: @"%@/web/timerdelete?sRef=%@&begin=%d&end=%d", baseAddress, oldTimer.service.sref, (int)[oldTimer.begin timeIntervalSince1970], (int)[oldTimer.end timeIntervalSince1970]];

	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

	// Create URL Object and download it
	NSString *myString = [NSString stringWithContentsOfURL: [NSURL URLWithString: myURI] encoding: NSUTF8StringEncoding error: nil];

	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

	NSRange myRange = [myString rangeOfString: @"<e2state>True</e2state>"];
	if(myRange.length)
		return YES;
	
	return NO;
}

- (BOOL)sendButton:(NSInteger) type
{
	// Generate URI
	NSString *myURI = [NSString stringWithFormat: @"%@/web/remotecontrol?command=%d", baseAddress, type];

	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

	// Create URL Object and download it
	NSString *myString = [NSString stringWithContentsOfURL: [NSURL URLWithString: myURI] encoding: NSUTF8StringEncoding error: nil];

	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

	NSRange myRange = [myString rangeOfString: @"<e2result>True</e2result>"];
	if(myRange.length)
		return YES;
	
	return NO;
}

@end
