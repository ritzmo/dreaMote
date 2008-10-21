//
//  NeutrinoConnector.m
//  Untitled
//
//  Created by Moritz Venn on 15.10.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#ifdef ENABLE_NEUTRINO_CONNECTOR

#import "NeutrinoConnector.h"

#import "Service.h"
#import "Timer.h"
#import "Event.h"
#import "Volume.h"

#import "Neutrino/EventXMLReader.h"

@implementation NeutrinoConnector

@synthesize baseAddress;

- (const BOOL)hasFeature: (enum connectorFeatures)feature
{
	return NO;
}

- (NSInteger)getMaxVolume
{
	return 100;
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
	return (id <RemoteConnector>*)[[NeutrinoConnector alloc] initWithAddress: address];
}

- (BOOL)isReachable
{
	// Generate URI
	NSURL *myURI = [NSURL URLWithString:@"/control/info"  relativeToURL:baseAddress];

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
	NSURL *myURI = [NSURL URLWithString: [NSString stringWithFormat:@"/control/zapto?%@", [service.sref stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding]] relativeToURL: baseAddress];

	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

	// Create URL Object and download it
	NSHTTPURLResponse *response;
	NSURLRequest *request = [NSURLRequest requestWithURL: myURI
											 cachePolicy: NSURLRequestReloadIgnoringCacheData timeoutInterval: 5];
	[NSURLConnection sendSynchronousRequest: request
										 returningResponse: &response error: nil];

	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

	// TODO: is the status code correct?
	return ([response statusCode] == 200);
}

- (void)fetchServices:(id)target action:(SEL)action
{
	// Generate URI
	NSURL *myURI = [NSURL URLWithString: @"/control/channellist" relativeToURL: baseAddress];
	
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	
	// Create URL Object and download it
	NSURLResponse *response;
	NSURLRequest *request = [NSURLRequest requestWithURL: myURI
											 cachePolicy: NSURLRequestReloadIgnoringCacheData timeoutInterval: 5];
	NSData *data = [NSURLConnection sendSynchronousRequest: request
										 returningResponse: &response error: nil];
	
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	
	// Parse
	NSArray *serviceStringList = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] componentsSeparatedByString: @"\n"];
	for(NSString *serviceString in serviceStringList)
	{
		// channel_id channelname
		NSRange range = [serviceString rangeOfString: @" "];
		if(range.length)
		{
			Service *service = [[Service alloc] init];

			// Cut until first " "
			range.length = range.location;
			range.location = 0;
			service.sref = [serviceString substringWithRange: range];
			
			// Cut from first " "
			range.location = range.length + 1;
			range.length = [serviceString length] - range.location;
			
			service.sname = [serviceString substringWithRange: range];

			[target performSelectorOnMainThread:action withObject:service waitUntilDone:NO];
			[service release];
		}
	}
}

- (void)fetchEPG:(id)target action:(SEL)action service:(Service *)service
{
	// XXX: Maybe we should not hardcode "max"
	NSURL *myURI = [NSURL URLWithString: [NSString stringWithFormat:@"/control/epg?xml=true&channelid=%@&details=true&max=100", service.sref] relativeToURL: baseAddress];
	
	NSError *parseError = nil;
	
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	
	NeutrinoEventXMLReader *streamReader = [NeutrinoEventXMLReader initWithTarget: target action: action];
	[streamReader parseXMLFileAtURL:myURI parseError:&parseError];
	[streamReader release];
	
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

- (void)fetchTimers:(id)target action:(SEL)action
{
	// Generate URI
	NSURL *myURI = [NSURL URLWithString: @"/control/timer?format=id" relativeToURL: baseAddress];

	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

	// Create URL Object and download it
	NSURLResponse *response;
	NSURLRequest *request = [NSURLRequest requestWithURL: myURI
											 cachePolicy: NSURLRequestReloadIgnoringCacheData timeoutInterval: 5];
	NSData *data = [NSURLConnection sendSynchronousRequest: request
						  returningResponse: &response error: nil];

	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

	// Parse
	NSArray *timerStringList = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] componentsSeparatedByString: @"\n"];
	for(NSString *timerString in timerStringList)
	{
		// eventID eventType eventRepeat repcount announceTime alarmTime stopTime data
		NSArray *timerStringComponents = [timerString componentsSeparatedByString:@" "];

		if([timerStringComponents count] < 8) // XXX: should not happen...
			continue;

		Timer *timer = [[Timer alloc] init];
		
		// Determine type, reject unhandled
		NSInteger timerType = [[timerStringComponents objectAtIndex: 1] integerValue];
		if(timerType == neutrinoTimerTypeRecord)
			timer.justplay = NO;
		else if(timerType == neutrinoTimerTypeZapto)
			timer.justplay = YES;
		else
		{
			[timer release];
			continue;
		}

		timer.eit = [timerStringComponents objectAtIndex: 0]; // XXX: actually wrong but we need it :-)
		timer.repeated = [[timerStringComponents objectAtIndex: 2] integerValue]; // XXX: as long as we don't offer to edit this via gui we can just keep the value and not change it to some common interpretation
		timer.repeatcount = [[timerStringComponents objectAtIndex: 3] integerValue];
		// XXX: is it ok to ignore announce time?
		[timer setBeginFromString: [timerStringComponents objectAtIndex: 5]];
		[timer setEndFromString: [timerStringComponents objectAtIndex: 6]];

		Service *service = [[Service alloc] init];
		service.sref = [timerStringComponents objectAtIndex: 7];
		service.sname = @"???"; // XXX: should be resolved
		timer.service = service;
		[service release];

		[target performSelectorOnMainThread:action withObject:timer waitUntilDone:NO];
		[timer release];
	}
}

- (void)fetchMovielist:(id)target action:(SEL)action
{
	// XXX: is this actually possible?
}

- (void)sendPowerstate: (NSString *) newState
{
	// Generate URI
	NSURL *myURI = [NSURL URLWithString: [NSString stringWithFormat:@"/control/%@", newState] relativeToURL: baseAddress];

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
	// Generate URI
	NSURL *myURI = [NSURL URLWithString: @"/control/standby" relativeToURL: baseAddress];
	
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

	// Create URL Object and download it
	NSURLResponse *response;
	NSURLRequest *request = [NSURLRequest requestWithURL: myURI
											 cachePolicy: NSURLRequestReloadIgnoringCacheData timeoutInterval: 5];
	NSData *data = [NSURLConnection sendSynchronousRequest: request
										 returningResponse: &response error: nil];

	NSString *myString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	if([myString isEqualToString: @"on"])
		myString = @"standby?off";
	else
		myString = @"standby?on";

	// XXX: sendPowerstate will toggle it back and on/off/on/off might look odd... remove?
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

	[self sendPowerstate: myString];
}

- (void)reboot
{
	[self sendPowerstate: @"reboot"];
}

- (void)restart
{
	// XXX: not available
}

- (void)getVolume:(id)target action:(SEL)action
{
	Volume *volumeObject = [[Volume alloc] init];

	// Generate URI (mute)
	NSURL *myURI = [NSURL URLWithString: @"/control/volume?status" relativeToURL: baseAddress];
	
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	
	// Create URL Object and download it
	NSURLResponse *response;
	NSURLRequest *request = [NSURLRequest requestWithURL: myURI
											 cachePolicy: NSURLRequestReloadIgnoringCacheData timeoutInterval: 5];
	NSData *data = [NSURLConnection sendSynchronousRequest: request
										 returningResponse: &response error: nil];
	
	NSString *myString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	if([myString isEqualToString: @"1"])
		volumeObject.ismuted = YES;
	else
		volumeObject.ismuted = NO;

	// Generate URI (volume)
	myURI = [NSURL URLWithString: @"/control/volume" relativeToURL: baseAddress];
	
	// Create URL Object and download it
	request = [NSURLRequest requestWithURL: myURI
							   cachePolicy: NSURLRequestReloadIgnoringCacheData timeoutInterval: 5];
	data = [NSURLConnection sendSynchronousRequest: request
						  returningResponse: &response error: nil];
	
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

	myString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	volumeObject.current = [myString integerValue];

	[target performSelectorOnMainThread:action withObject:volumeObject waitUntilDone:NO];
	[volumeObject release];
}

- (BOOL)toggleMuted
{
	// Generate URI
	NSURL *myURI = [NSURL URLWithString: @"/control/volume?status" relativeToURL: baseAddress];
	
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	
	// Create URL Object and download it
	NSURLResponse *response;
	NSURLRequest *request = [NSURLRequest requestWithURL: myURI
											 cachePolicy: NSURLRequestReloadIgnoringCacheData timeoutInterval: 5];
	NSData *data = [NSURLConnection sendSynchronousRequest: request
										 returningResponse: &response error: nil];

	NSString *myString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	if([myString isEqualToString: @"1"])
		myString = @"unmute";
	else
		myString = @"mute";

	// Generate new URI
	myURI = [NSURL URLWithString: [NSString stringWithFormat: @"/control/volume?%@", myString] relativeToURL: baseAddress];

	// Create URL Object and download it
	request = [NSURLRequest requestWithURL: myURI
											 cachePolicy: NSURLRequestReloadIgnoringCacheData timeoutInterval: 5];
	[NSURLConnection sendSynchronousRequest: request
										 returningResponse: &response error: nil];

	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

	return ([myString isEqualToString: @"mute"]);
}

- (BOOL)setVolume:(NSInteger) newVolume
{
	// neutrino expect volume to be a multiple of 5
	// TODO: find out if 0 is allowed
	NSInteger diff = newVolume % 5;
	// XXX: to make this code easier we could just add/remove the diff but lets try it fair first :-)
	if(diff < 3)
		newVolume -= diff;
	else
		newVolume += diff;

	// Generate URI
	NSURL *myURI = [NSURL URLWithString: [NSString stringWithFormat: @"/control/volume?%d", newVolume] relativeToURL: baseAddress];
	
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	
	// Create URL Object and download it
	NSHTTPURLResponse *response;
	NSURLRequest *request = [NSURLRequest requestWithURL: myURI
											 cachePolicy: NSURLRequestReloadIgnoringCacheData timeoutInterval: 5];
	[NSURLConnection sendSynchronousRequest: request
						  returningResponse: &response error: nil];
	
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	
	// Sourcecode suggests that they always return ok, so we only do this simple check
	return ([response statusCode] == 200);
}

- (BOOL)addTimer:(Timer *) newTimer
{
	// Generate URI
	NSURL *myURI = [NSURL URLWithString: [NSString stringWithFormat: @"/control/timer?action=new&alarm=%d&stop=%d&type=%d&channel_id=%@", (NSTimeInterval)[newTimer.begin timeIntervalSince1970], (NSTimeInterval)[newTimer.end timeIntervalSince1970], (newTimer.justplay) ? neutrinoTimerTypeZapto : neutrinoTimerTypeRecord, newTimer.service.sref] relativeToURL: baseAddress];
	
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	
	// Create URL Object and download it
	NSHTTPURLResponse *response;
	NSURLRequest *request = [NSURLRequest requestWithURL: myURI
											 cachePolicy: NSURLRequestReloadIgnoringCacheData timeoutInterval: 5];
	[NSURLConnection sendSynchronousRequest: request
						  returningResponse: &response error: nil];
	
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	
	// Sourcecode suggests that they always return ok, so we only do this simple check
	return ([response statusCode] == 200);
}

- (BOOL)editTimer:(Timer *) oldTimer: (Timer *) newTimer
{
	// Generate URI
	NSURL *myURI = [NSURL URLWithString: [NSString stringWithFormat: @"/control/timer?action=new&id=%@&alarm=%d&stop=%d&type=%d&channel_id=%@&rep=%d&repcount=%d", oldTimer.eit, (NSTimeInterval)[newTimer.begin timeIntervalSince1970], (NSTimeInterval)[newTimer.end timeIntervalSince1970], (newTimer.justplay) ? neutrinoTimerTypeZapto : neutrinoTimerTypeRecord, newTimer.service.sref, newTimer.repeated, newTimer.repeatcount] relativeToURL: baseAddress];
	
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	
	// Create URL Object and download it
	NSHTTPURLResponse *response;
	NSURLRequest *request = [NSURLRequest requestWithURL: myURI
											 cachePolicy: NSURLRequestReloadIgnoringCacheData timeoutInterval: 5];
	[NSURLConnection sendSynchronousRequest: request
						  returningResponse: &response error: nil];
	
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	
	// Sourcecode suggests that they always return ok, so we only do this simple check
	return ([response statusCode] == 200);
}

- (BOOL)delTimer:(Timer *) oldTimer
{
	// Generate URI
	NSURL *myURI = [NSURL URLWithString: [NSString stringWithFormat: @"/control/timer?action=remove&id=%@", oldTimer.eit] relativeToURL: baseAddress];

	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

	// Create URL Object and download it
	NSHTTPURLResponse *response;
	NSURLRequest *request = [NSURLRequest requestWithURL: myURI
											 cachePolicy: NSURLRequestReloadIgnoringCacheData timeoutInterval: 5];
	[NSURLConnection sendSynchronousRequest: request
										 returningResponse: &response error: nil];
	
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

	// Sourcecode suggests that they always return ok, so we only do this simple check
	return ([response statusCode] == 200);
}

- (BOOL)sendButton:(NSInteger) type
{
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
		//case kButtonCode: buttonCode = @"KEY_HOME"; break; // XXX: unimpl?
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
		//case kButtonCode: buttonCode = @"KEY_"; break; // meant for copy&paste ;-)
		default:
			break;
	}

	if(buttonCode == nil)
		return NO;

	// Generate URI
	NSURL *myURI = [NSURL URLWithString: [NSString stringWithFormat: @"/control/rcem?%@", buttonCode] relativeToURL: baseAddress];

	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

	// Create URL Object and download it
	NSHTTPURLResponse *response;
	NSURLRequest *request = [NSURLRequest requestWithURL: myURI
											 cachePolicy: NSURLRequestReloadIgnoringCacheData timeoutInterval: 5];
	[NSURLConnection sendSynchronousRequest: request
										 returningResponse: &response error: nil];

	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

	// XXX: is this status code correct?
	return ([response statusCode] == 200);
}

- (BOOL)sendMessage:(NSString *)message: (NSString *)caption: (NSInteger)type: (NSInteger)timeout
{
	// Generate URI
	// XXX: there's also nmsg - whats the difference?!
	NSURL *myURI = [NSURL URLWithString: [NSString stringWithFormat: @"/control/message?popup=%@", message] relativeToURL: baseAddress];

	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

	// Create URL Object and download it
	NSHTTPURLResponse *response;
	NSURLRequest *request = [NSURLRequest requestWithURL: myURI
											 cachePolicy: NSURLRequestReloadIgnoringCacheData timeoutInterval: 5];
	[NSURLConnection sendSynchronousRequest: request
										 returningResponse: &response error: nil];

	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

	// XXX: is this status code correct?
	return ([response statusCode] == 200);
}

@end

#endif