//
//  NeutrinoConnector.m
//  Untitled
//
//  Created by Moritz Venn on 15.10.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "NeutrinoConnector.h"

#import "Objects/Generic/Service.h"
#import "Objects/Generic/Timer.h"
#import "Objects/Generic/Volume.h"

#import "XMLReader/Neutrino/ServiceXMLReader.h"
#import "XMLReader/Neutrino/EventXMLReader.h"

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
		serviceCache = [[NSMutableDictionary dictionaryWithCapacity: 50] retain];
	}
	return self;
}

- (void)dealloc
{
	[baseAddress release];
	[serviceCache release];
	[serviceTarget release];

	[super dealloc];
}

+ (NSObject <RemoteConnector>*)createClassWithAddress:(NSString *) address
{
	return (NSObject <RemoteConnector>*)[[NeutrinoConnector alloc] initWithAddress: address];
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

- (void)addService:(Service *)newService
{
	if(newService != nil && newService.valid)
		[serviceCache setObject: newService forKey: newService.sname];

	[serviceTarget performSelectorOnMainThread:serviceSelector withObject:newService waitUntilDone:NO];
}

- (BaseXMLReader *)fetchServices:(id)target action:(SEL)action
{
	[serviceCache removeAllObjects];
	if(serviceTarget != target)
	{
		[serviceTarget release];
		serviceTarget = [target retain];
	}
	serviceSelector = action;

	NSURL *myURI = [NSURL URLWithString: @"/control/getbouquetsxml" relativeToURL: baseAddress];

	NSError *parseError = nil;

	BaseXMLReader *streamReader = [[NeutrinoServiceXMLReader initWithTarget: self action: @selector(addService:)] autorelease];
	[streamReader parseXMLFileAtURL: myURI parseError: &parseError];
	return streamReader;
}

- (BaseXMLReader *)fetchEPG:(id)target action:(SEL)action service:(Service *)service
{
	// XXX: Maybe we should not hardcode "max"
	NSURL *myURI = [NSURL URLWithString: [NSString stringWithFormat:@"/control/epg?xml=true&channelid=%@&details=true&max=100", service.sref] relativeToURL: baseAddress];
	
	NSError *parseError = nil;

	BaseXMLReader *streamReader = [[NeutrinoEventXMLReader initWithTarget: target action: action] autorelease];
	[streamReader parseXMLFileAtURL: myURI parseError: &parseError];
	return streamReader;
}

// TODO: reimplement this as streaming parser some day :-)
- (BaseXMLReader *)fetchTimers:(id)target action:(SEL)action
{
	// Refresh Service Cache if empty, we need it later when resolving service references
	if([serviceCache count] == 0)
		[self fetchServices:nil action:nil];

	// Generate URI
	NSURL *myURI = [NSURL URLWithString: @"/control/timer" relativeToURL: baseAddress];

	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

	// Create URL Object and download it
	NSURLResponse *response;
	NSError *error;
	NSURLRequest *request = [NSURLRequest requestWithURL: myURI
											 cachePolicy: NSURLRequestReloadIgnoringCacheData timeoutInterval: 5];
	NSData *data = [NSURLConnection sendSynchronousRequest: request
						  returningResponse: &response error: &error];

	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

	// Error occured, so send fake object
	if(error || !data)
	{
		NSObject<TimerProtocol> *fakeObject = [[Timer alloc] init];
		fakeObject.title = NSLocalizedString(@"Error retrieving Data", @"");
		fakeObject.state = 0;
		fakeObject.valid = NO;
		[target performSelectorOnMainThread: action withObject: fakeObject waitUntilDone: NO];
		[fakeObject release];

		return nil;
	}

	// Parse
	NSArray *timerStringList = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] componentsSeparatedByString: @"\n"];
	for(NSString *timerString in timerStringList)
	{
		// eventID eventType eventRepeat repcount announceTime alarmTime stopTime data
		NSArray *timerStringComponents = [timerString componentsSeparatedByString:@" "];

		if([timerStringComponents count] < 8) // XXX: should not happen...
			continue;

		NSObject<TimerProtocol> *timer = [[Timer alloc] init];
		
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
		timer.title = [NSString stringWithFormat: @"Timer %@", timer.eit];
		timer.repeated = [[timerStringComponents objectAtIndex: 2] integerValue]; // XXX: as long as we don't offer to edit this via gui we can just keep the value and not change it to some common interpretation
		timer.repeatcount = [[timerStringComponents objectAtIndex: 3] integerValue];
		[timer setBeginFromString: [timerStringComponents objectAtIndex: 5]];
		[timer setEndFromString: [timerStringComponents objectAtIndex: 6]];

		// Eventually fetch Service from our Cache
		NSRange objRange;
		objRange.location = 7;
		objRange.length = [timerStringComponents count] - 7;
		NSString *sname = [[timerStringComponents subarrayWithRange: objRange] componentsJoinedByString: @" "];
		Service *service = [serviceCache objectForKey: sname];
		if(service != nil)
			timer.service = service;
		else
		{
			// XXX: we set a fake sref here as the service is valid enough for timers...
			service = [[Service alloc] init];
			service.sref = @"dc";
			service.sname = sname;
			timer.service = service;
			[service release];
		}

		// Determine state
		NSDate *announce = [NSDate dateWithTimeIntervalSince1970:
									[[timerStringComponents objectAtIndex: 4] doubleValue]];
		if([announce timeIntervalSinceNow] > 0)
			timer.state = kTimerStateWaiting;
		else if([timer.begin timeIntervalSinceNow] > 0)
			timer.state = kTimerStatePrepared;
		else if([timer.end timeIntervalSinceNow] > 0)
			timer.state = kTimerStateRunning;
		else
			timer.state = kTimerStateFinished;

		[target performSelectorOnMainThread:action withObject:timer waitUntilDone:NO];
		[timer release];
	}

	return nil;
}

- (BaseXMLReader *)fetchMovielist:(id)target action:(SEL)action
{
	// XXX: is this actually possible?
	return nil;
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
	BOOL equalsOn = [myString isEqualToString: @"on"];
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

	[myString release];

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

	[myString release];

	[target performSelectorOnMainThread:action withObject:volumeObject waitUntilDone:NO];
	[volumeObject release];
}

- (BOOL)toggleMuted
{
	BOOL equalsRes = NO;
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
	equalsRes = [myString isEqualToString: @"1"];
	[myString release];
	if(equalsRes)
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

	equalsRes = [myString isEqualToString: @"mute"];
	[myString release];
	return equalsRes;
}

- (BOOL)setVolume:(NSInteger) newVolume
{
	// neutrino expect volume to be a multiple of 5
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

- (BOOL)addTimer:(NSObject<TimerProtocol> *) newTimer
{
	// Generate URI
	// XXX: Fails if I try to format the whole URL by one stringWithFormat... type will be wrong and sref can't be read so the program will crash
	NSString *add = [NSString stringWithFormat: @"/control/timer?action=new&alarm=%d&stop=%d&type=", (int)[newTimer.begin timeIntervalSince1970], (int)[newTimer.end timeIntervalSince1970]];
	add = [add stringByAppendingFormat: @"%d", (newTimer.justplay) ? neutrinoTimerTypeZapto : neutrinoTimerTypeRecord];
	add = [add stringByAppendingString: @"&channel_name="];
	add = [add stringByAppendingString: [newTimer.service.sname stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding]];
	NSURL *myURI = [NSURL URLWithString: add relativeToURL: baseAddress];
	
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

- (BOOL)editTimer:(NSObject<TimerProtocol> *) oldTimer: (NSObject<TimerProtocol> *) newTimer
{
	// Generate URI
	// XXX: Fails if I try to format the whole URL by one stringWithFormat... type will be wrong and sref can't be read so the program will crash
	NSString *add = [NSString stringWithFormat: @"/control/timer?action=modify&id=%@&alarm=%d&stop=%d&format=", oldTimer.eit, (int)[newTimer.begin timeIntervalSince1970], (int)[newTimer.end timeIntervalSince1970]];
	add = [add stringByAppendingFormat: @"%d", (newTimer.justplay) ? neutrinoTimerTypeZapto : neutrinoTimerTypeRecord];
	add = [add stringByAppendingString: @"&channel_name="];
	add = [add stringByAppendingString: [newTimer.service.sname stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding]];
	add = [add stringByAppendingString: @"&rep="];
	add = [add stringByAppendingFormat: @"%d", newTimer.repeated];
	add = [add stringByAppendingString: @"&repcount="];
	add = [add stringByAppendingFormat: @"%d", newTimer.repeatcount];
	NSURL *myURI = [NSURL URLWithString: add relativeToURL: baseAddress];

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

- (BOOL)delTimer:(NSObject<TimerProtocol> *) oldTimer
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
			myURI = [NSURL URLWithString: @"/control/setmode?tv" relativeToURL: baseAddress];
			break;
		case kButtonCodeRadio:
			myURI = [NSURL URLWithString: @"/control/setmode?radio" relativeToURL: baseAddress];
			break;
		//case kButtonCode: buttonCode = @"KEY_"; break; // meant for copy&paste ;-)
		default:
			break;
	}

	if(myURI == nil)
	{
		if(buttonCode == nil)
			return NO;

		// Generate URI
		myURI = [NSURL URLWithString: [NSString stringWithFormat: @"/control/rcem?%@", buttonCode] relativeToURL: baseAddress];
	}

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
	// we open a popup which means the window will close automatically
	// nmsg (a window which must be closed be the user) is also available
	NSURL *myURI = [NSURL URLWithString: [NSString stringWithFormat: @"/control/message?popup=%@", [message stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding]] relativeToURL: baseAddress];

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

- (NSData *)getScreenshot: (enum screenshotType)type
{
	// XXX: not supported, some extracts from yweb source:
	// do_snapshot:
	///control/exec?Y_Tools&fbshot&fb&-q&/tmp/dreaMote_Screenshot.png
	// do_dboxshot:
	///control/exec?Y_Tools&fbshot&-r&-o&/tmp/dreaMote_Screenshot.bmp
	// if response(-r) != 200 then s/-r//g
	//after:
	//control/exec?Y_Tools&fbshot_clear
	return nil;
}

- (void)freeCaches
{
	[serviceCache removeAllObjects];
	[serviceTarget release];
	serviceTarget = nil;
}

@end
