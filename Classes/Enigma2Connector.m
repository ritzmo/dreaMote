//
//  Enigma2Connector.m
//  dreaMote
//
//  Created by Moritz Venn on 08.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "Enigma2Connector.h"

#import "Objects/EventProtocol.h"
#import "Objects/MovieProtocol.h"
#import "Objects/ServiceProtocol.h"
#import "Objects/TimerProtocol.h"

#import "XMLReader/Enigma2/ServiceXMLReader.h"
#import "XMLReader/Enigma2/EventXMLReader.h"
#import "XMLReader/Enigma2/TimerXMLReader.h"
#import "XMLReader/Enigma2/VolumeXMLReader.h"
#import "XMLReader/Enigma2/MovieXMLReader.h"
#import "XMLReader/Enigma2/SignalXMLReader.h"

#import "EnigmaRCEmulatorController.h"

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

@implementation Enigma2Connector

- (const BOOL)hasFeature: (enum connectorFeatures)feature
{
	return 
		(feature != kFeaturesMessageCaption);
}

- (NSInteger)getMaxVolume
{
	return 100;
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

	[super dealloc];
}

+ (NSObject <RemoteConnector>*)createClassWithAddress:(NSString *) address andUsername: (NSString *)inUsername andPassword: (NSString *)inPassword andPort: (NSInteger)inPort
{
	return (NSObject <RemoteConnector>*)[[Enigma2Connector alloc] initWithAddress: address andUsername: inUsername andPassword: inPassword andPort: inPort];
}

- (BOOL)isReachable
{
	// Generate URI
	NSURL *myURI = [NSURL URLWithString:@"/web/about" relativeToURL:baseAddress];

	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

	NSHTTPURLResponse *response;
	NSURLRequest *request = [NSURLRequest requestWithURL: myURI
											 cachePolicy: NSURLRequestReloadIgnoringCacheData timeoutInterval: 5];
	[NSURLConnection sendSynchronousRequest: request
										 returningResponse: &response error: nil];

	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

	return ([response statusCode] == 200);
}

- (BOOL)zapInternal:(NSString *) sref
{
	// Generate URI
	NSURL *myURI = [NSURL URLWithString:[NSString stringWithFormat:@"/web/zap?sRef=%@", [sref stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding]] relativeToURL:baseAddress];

	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

	// Create URL Object and download it
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
	return [self zapInternal: service.sref];
}

- (BOOL)playMovie:(NSObject<MovieProtocol> *) movie
{
	return [self zapInternal: movie.sref];
}

- (CXMLDocument *)fetchBouquets:(id)target action:(SEL)action
{
	NSURL *myURI = [NSURL URLWithString: @"/web/getservices" relativeToURL: baseAddress];

	BaseXMLReader *streamReader = [[Enigma2ServiceXMLReader alloc] initWithTarget: target action: action];
	CXMLDocument *doc = [streamReader parseXMLFileAtURL: myURI parseError: nil];
	[streamReader autorelease];
	return doc;
}

- (CXMLDocument *)fetchServices:(id)target action:(SEL)action bouquet:(NSObject<ServiceProtocol> *)bouquet;
{
	NSString *sref = nil;
	if(!bouquet) // single bouquet mode
		sref =  @"1:7:1:0:0:0:0:0:0:0:FROM%20BOUQUET%20%22userbouquet.favourites.tv%22%20ORDER%20BY%20bouquet";
	else
		sref = [bouquet.sref stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding];
	NSURL *myURI = [NSURL URLWithString: [NSString stringWithFormat:@"/web/getservices?sRef=%@", sref] relativeToURL:baseAddress];

	BaseXMLReader *streamReader = [[Enigma2ServiceXMLReader alloc] initWithTarget: target action: action];
	CXMLDocument *doc = [streamReader parseXMLFileAtURL: myURI parseError: nil];
	[streamReader autorelease];
	return doc;
}

- (CXMLDocument *)fetchEPG:(id)target action:(SEL)action service:(NSObject<ServiceProtocol> *)service
{
	NSURL *myURI = [NSURL URLWithString: [NSString stringWithFormat:@"/web/epgservice?sRef=%@", [service.sref stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding]] relativeToURL: baseAddress];

	BaseXMLReader *streamReader = [[Enigma2EventXMLReader alloc] initWithTarget: target action: action];
	CXMLDocument *doc = [streamReader parseXMLFileAtURL: myURI parseError: nil];
	[streamReader autorelease];
	return doc;
}

- (CXMLDocument *)fetchTimers:(id)target action:(SEL)action
{
	NSURL *myURI = [NSURL URLWithString: @"/web/timerlist" relativeToURL: baseAddress];

	BaseXMLReader *streamReader = [[Enigma2TimerXMLReader alloc] initWithTarget: target action: action];
	CXMLDocument *doc = [streamReader parseXMLFileAtURL: myURI parseError: nil];
	[streamReader autorelease];
	return doc;
}

- (CXMLDocument *)fetchMovielist:(id)target action:(SEL)action
{
	NSURL *myURI = [NSURL URLWithString: @"/web/movielist" relativeToURL: baseAddress];

	BaseXMLReader *streamReader = [[Enigma2MovieXMLReader alloc] initWithTarget: target action: action];
	CXMLDocument *doc = [streamReader parseXMLFileAtURL: myURI parseError: nil];
	[streamReader autorelease];
	return doc;
}

- (void)sendPowerstate: (NSInteger) newState
{
	// Generate URI
	NSURL *myURI = [NSURL URLWithString: [NSString stringWithFormat:@"/web/powerstate?newstate=%d", newState] relativeToURL: baseAddress];

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
	NSURL *myURI = [NSURL URLWithString: @"/web/vol" relativeToURL: baseAddress];

	Enigma2VolumeXMLReader *streamReader = [[Enigma2VolumeXMLReader alloc] initWithTarget: target action: action];
	[streamReader parseXMLFileAtURL:myURI parseError: nil];
	[streamReader autorelease];
}

- (void)getSignal:(id)target action:(SEL)action
{
	NSURL *myURI = [NSURL URLWithString: @"/web/signal" relativeToURL: baseAddress];
	
	Enigma2SignalXMLReader *streamReader = [[Enigma2SignalXMLReader alloc] initWithTarget: target action: action];
	[streamReader parseXMLFileAtURL:myURI parseError: nil];
	[streamReader autorelease];
}

- (BOOL)toggleMuted
{
	// Generate URI
	NSURL *myURI = [NSURL URLWithString: @"/web/vol?set=mute" relativeToURL: baseAddress];

	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

	// Create URL Object and download it
	NSURLResponse *response;
	NSURLRequest *request = [NSURLRequest requestWithURL: myURI
											 cachePolicy: NSURLRequestReloadIgnoringCacheData timeoutInterval: 5];
	NSData *data = [NSURLConnection sendSynchronousRequest: request
										 returningResponse: &response error: nil];
	
	NSString *myString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

	NSRange myRange = [myString rangeOfString: @"<e2ismuted>True</e2ismuted>"];
	[myString release];
	if(myRange.length)
		return YES;

	return NO;
}

- (BOOL)setVolume:(NSInteger) newVolume
{
	// Generate URI
	NSURL *myURI = [NSURL URLWithString: [NSString stringWithFormat:@"/web/vol?set=set%d", newVolume] relativeToURL: baseAddress];

	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

	// Create URL Object and download it
	NSURLResponse *response;
	NSURLRequest *request = [NSURLRequest requestWithURL: myURI
											 cachePolicy: NSURLRequestReloadIgnoringCacheData timeoutInterval: 5];
	NSData *data = [NSURLConnection sendSynchronousRequest: request
										 returningResponse: &response error: nil];
	
	NSString *myString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

	NSRange myRange = [myString rangeOfString: @"<e2result>True</e2result>"];
	[myString release];
	if(myRange.length)
		return YES;
	
	return NO;
}

- (BOOL)addTimer:(NSObject<TimerProtocol> *) newTimer
{
	// Generate URI
	NSURL *myURI = [NSURL URLWithString: [NSString stringWithFormat: @"/web/timeradd?sRef=%@&begin=%d&end=%d&name=%@&description=%@&eit=%@&disabled=%d&justplay=%d&afterevent=%d", [newTimer.service.sref stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding], (int)[newTimer.begin timeIntervalSince1970], (int)[newTimer.end timeIntervalSince1970], [newTimer.title stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding], [newTimer.tdescription stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding], newTimer.eit, newTimer.disabled ? 1 : 0, newTimer.justplay ? 1 : 0, newTimer.afterevent] relativeToURL: baseAddress];

	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

	// Create URL Object and download it
	NSURLResponse *response;
	NSURLRequest *request = [NSURLRequest requestWithURL: myURI
											 cachePolicy: NSURLRequestReloadIgnoringCacheData timeoutInterval: 5];
	NSData *data = [NSURLConnection sendSynchronousRequest: request
										 returningResponse: &response error: nil];
	
	NSString *myString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

	NSRange myRange = [myString rangeOfString: @"<e2state>True</e2state>"];
	[myString release];
	if(myRange.length)
		return YES;
	
	return NO;
}

- (BOOL)editTimer:(NSObject<TimerProtocol> *) oldTimer: (NSObject<TimerProtocol> *) newTimer
{
	// Generate URI
	NSURL *myURI = [NSURL URLWithString: [NSString stringWithFormat: @"/web/timerchange?sRef=%@&begin=%d&end=%d&name=%@&description=%@&eit=%@&disabled=%d&justplay=%d&afterevent=%d&channelOld=%@&beginOld=%d&endOld=%d&deleteOldOnSave=1", [newTimer.service.sref stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding], (int)[newTimer.begin timeIntervalSince1970], (int)[newTimer.end timeIntervalSince1970], [newTimer.title stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding], [newTimer.tdescription stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding], newTimer.eit, newTimer.disabled ? 1 : 0, newTimer.justplay ? 1 : 0, newTimer.afterevent, oldTimer.service.sref, (int)[oldTimer.begin timeIntervalSince1970], (int)[oldTimer.end timeIntervalSince1970]] relativeToURL: baseAddress];

	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

	// Create URL Object and download it
	NSURLResponse *response;
	NSURLRequest *request = [NSURLRequest requestWithURL: myURI
											 cachePolicy: NSURLRequestReloadIgnoringCacheData timeoutInterval: 5];
	NSData *data = [NSURLConnection sendSynchronousRequest: request
										 returningResponse: &response error: nil];
	
	NSString *myString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

	NSRange myRange = [myString rangeOfString: @"<e2state>True</e2state>"];
	[myString release];
	if(myRange.length)
		return YES;
	
	return NO;
}

- (BOOL)delTimer:(NSObject<TimerProtocol> *) oldTimer
{
	// Generate URI
	NSURL *myURI = [NSURL URLWithString: [NSString stringWithFormat: @"/web/timerdelete?sRef=%@&begin=%d&end=%d", [oldTimer.service.sref stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding], (int)[oldTimer.begin timeIntervalSince1970], (int)[oldTimer.end timeIntervalSince1970]] relativeToURL: baseAddress];

	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

	// Create URL Object and download it
	NSURLResponse *response;
	NSURLRequest *request = [NSURLRequest requestWithURL: myURI
											 cachePolicy: NSURLRequestReloadIgnoringCacheData timeoutInterval: 5];
	NSData *data = [NSURLConnection sendSynchronousRequest: request
										 returningResponse: &response error: nil];
	
	NSString *myString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

	NSRange myRange = [myString rangeOfString: @"<e2state>True</e2state>"];
	[myString release];
	if(myRange.length)
		return YES;
	
	return NO;
}

- (BOOL)sendButton:(NSInteger) type
{
	// Generate URI
	NSURL *myURI = [NSURL URLWithString: [NSString stringWithFormat: @"/web/remotecontrol?command=%d", type] relativeToURL: baseAddress];

	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

	// Create URL Object and download it
	NSURLResponse *response;
	NSURLRequest *request = [NSURLRequest requestWithURL: myURI
											 cachePolicy: NSURLRequestReloadIgnoringCacheData timeoutInterval: 5];
	NSData *data = [NSURLConnection sendSynchronousRequest: request
										 returningResponse: &response error: nil];
	
	NSString *myString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

	NSRange myRange = [myString rangeOfString: @"<e2result>True</e2result>"];
	[myString release];
	if(myRange.length)
		return YES;
	
	return NO;
}

- (BOOL)sendMessage:(NSString *)message: (NSString *)caption: (NSInteger)type: (NSInteger)timeout
{
	// Generate URI
	NSURL *myURI = [NSURL URLWithString: [NSString stringWithFormat: @"/web/message?text=%@&type=%d&timeout=%d", [message  stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding], type, timeout] relativeToURL: baseAddress];

	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

	// Create URL Object and download it
	NSURLResponse *response;
	NSURLRequest *request = [NSURLRequest requestWithURL: myURI
											 cachePolicy: NSURLRequestReloadIgnoringCacheData timeoutInterval: 5];
	NSData *data = [NSURLConnection sendSynchronousRequest: request
										 returningResponse: &response error: nil];

	NSString *myString = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];

	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

	NSRange myRange = [myString rangeOfString: @"<e2result>True</e2result>"];
	if(myRange.length)
		return YES;
	myRange = [myString rangeOfString: @"<e2state>True</e2state>"];
	if(myRange.length)
		return YES;

	return NO;
}

- (NSInteger)getMaxMessageType
{
	return kEnigma2MessageTypeMax;
}

- (NSString *)getMessageTitle: (NSInteger)type
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
			appendType = @"&o";
			break;
		case kScreenshotTypeVideo:
			appendType = @"&v";
			break;
		case kScreenshotTypeBoth:
		default:
			appendType = @"";
			break;
	}

	// Generate URI
	NSURL *myURI = [NSURL URLWithString: [NSString stringWithFormat: @"/grab?format=jpg%@", appendType] relativeToURL: baseAddress];

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

- (BOOL)delMovie:(NSObject<MovieProtocol> *) movie
{
	// Generate URI
	NSURL *myURI = [NSURL URLWithString:[NSString stringWithFormat:@"/web/moviedelete?sRef=%@", [movie.sref stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding]] relativeToURL:baseAddress];
	
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	
	// Create URL Object and download it
	NSHTTPURLResponse *response;
	NSURLRequest *request = [NSURLRequest requestWithURL: myURI
											 cachePolicy: NSURLRequestReloadIgnoringCacheData timeoutInterval: 5];
	NSData *data = [NSURLConnection sendSynchronousRequest: request
											returningResponse: &response error: nil];
	
	NSString *myString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	
	NSRange myRange = [myString rangeOfString: @"<e2result>True</e2result>"];
	[myString release];
	if(myRange.length)
		return YES;
	
	return NO;
}

- (CXMLDocument *)searchEPG:(id)target action:(SEL)action title:(NSString *)title
{
	// XXX: iso8859-1 is currently hardcoded, we might want to fix that
	NSURL *myURI = [NSURL URLWithString: [NSString stringWithFormat:@"/web/epgsearch?search=%@", [title stringByAddingPercentEscapesUsingEncoding: NSISOLatin1StringEncoding]] relativeToURL: baseAddress];

	BaseXMLReader *streamReader = [[Enigma2EventXMLReader alloc] initWithTarget: target action: action];
	CXMLDocument *doc = [streamReader parseXMLFileAtURL: myURI parseError: nil];
	[streamReader autorelease];
	return doc;
}

- (CXMLDocument *)searchEPGSimilar:(id)target action:(SEL)action event:(NSObject<EventProtocol> *)event
{
	NSURL *myURI = [NSURL URLWithString: [NSString stringWithFormat:@"/web/epgsimilar?sRef=%@&eventid=%@", [event.service.sref stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding], event.eit] relativeToURL: baseAddress];
	
	BaseXMLReader *streamReader = [[Enigma2EventXMLReader alloc] initWithTarget: target action: action];
	CXMLDocument *doc = [streamReader parseXMLFileAtURL: myURI parseError: nil];
	[streamReader autorelease];
	return doc;
}

- (BOOL)instantRecord
{
	// Generate URI
	// XXX: we only allow infinite instant records for now
	NSURL *myURI = [NSURL URLWithString:@"/web/recordnow?recordnow=infinite" relativeToURL:baseAddress];

	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

	// Create URL Object and download it
	NSHTTPURLResponse *response;
	NSURLRequest *request = [NSURLRequest requestWithURL: myURI
											cachePolicy: NSURLRequestReloadIgnoringCacheData timeoutInterval: 5];
	NSData *data = [NSURLConnection sendSynchronousRequest: request
						returningResponse: &response error: nil];

	NSString *myString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

	NSRange myRange = [myString rangeOfString: @"<e2state>True</e2state>"];
	[myString release];
	if(myRange.length)
		return YES;

	return NO;
}

- (void)openRCEmulator: (UINavigationController *)navigationController
{
	UIViewController *targetViewController = [[EnigmaRCEmulatorController alloc] init];
	[navigationController pushViewController:targetViewController animated:YES];
	[targetViewController release];
}

- (void)freeCaches
{
	// XXX: We don't use any caches
}

@end
