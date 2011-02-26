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

#import "SynchronousRequestReader.h"
#import "XMLReader/Enigma2/AboutXMLReader.h"
#import "XMLReader/Enigma2/CurrentXMLReader.h"
#import "XMLReader/Enigma2/EventXMLReader.h"
#import "XMLReader/Enigma2/FileXMLReader.h"
#import "XMLReader/Enigma2/MetadataXMLReader.h"
#import "XMLReader/Enigma2/MovieXMLReader.h"
#import "XMLReader/Enigma2/LocationXMLReader.h"
#import "XMLReader/Enigma2/ServiceXMLReader.h"
#import "XMLReader/Enigma2/SignalXMLReader.h"
#import "XMLReader/Enigma2/TimerXMLReader.h"
#import "XMLReader/Enigma2/VolumeXMLReader.h"

#import "EnigmaRCEmulatorController.h"
#import "SimpleRCEmulatorController.h"

#import "NSString+URLEncode.h"

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

- (const BOOL const)hasFeature: (enum connectorFeatures)feature
{
	return
		(feature != kFeaturesMessageCaption) &&
		(feature != kFeaturesStreaming);
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
			_baseAddress = [[NSURL alloc] initWithString:address];
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

			_baseAddress = [[NSURL alloc] initWithString:remoteAddress];
		}
	}
	return self;
}

- (void)dealloc
{
	[_baseAddress release];

	[super dealloc];
}

- (void)freeCaches
{
	// NOTE: We don't use any caches
}

+ (NSObject <RemoteConnector>*)newWithAddress:(NSString *) address andUsername: (NSString *)inUsername andPassword: (NSString *)inPassword andPort: (NSInteger)inPort useSSL: (BOOL)ssl
{
	return (NSObject <RemoteConnector>*)[[Enigma2Connector alloc] initWithAddress: address andUsername: inUsername andPassword: inPassword andPort: inPort useSSL: (BOOL)ssl];
}

- (UIViewController *)newRCEmulator
{
	return [[EnigmaRCEmulatorController alloc] init];
}

- (BOOL)isReachable
{
	NSURL *myURI = [NSURL URLWithString:@"/web/about" relativeToURL:_baseAddress];

	NSHTTPURLResponse *response;
	[SynchronousRequestReader sendSynchronousRequest:myURI
								   returningResponse:&response
											   error:nil];

	return ([response statusCode] == 200);
}

- (Result *)getResultFromSimpleXmlWithRelativeString:(NSString *)relativeURL
{
	CXMLDocument *dom = nil;
	NSError *error = nil;
	NSURL *myURI = [[NSURL alloc] initWithString:relativeURL relativeToURL:_baseAddress];
	NSData *data = [SynchronousRequestReader sendSynchronousRequest:myURI
												  returningResponse:nil
															  error:&error];

	if(error == nil)
	{
		NSString *myString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
		dom = [[CXMLDocument alloc] initWithXMLString:myString options:0 error:&error];
		[myString release];
	}

	Result *result = [Result createResult];
	result.result = NO;
	if(error != nil)
	{
		result.resulttext = [error localizedDescription];
	}
	else
	{
		const NSArray *resultNodes = [dom nodesForXPath:@"/e2simplexmlresult/e2state" error:nil];
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
	}

	[myURI release];
	[dom release];
	return result;
}

#pragma mark Services

- (Result *)zapInternal:(NSString *) sref
{
	Result *result = [Result createResult];
	NSURL *myURI = [NSURL URLWithString:[NSString stringWithFormat:@"/web/zap?sRef=%@", [sref urlencode]] relativeToURL:_baseAddress];

	NSHTTPURLResponse *response;
	[SynchronousRequestReader sendSynchronousRequest:myURI
								   returningResponse:&response
											   error:nil];

	result.result = ([response statusCode] == 200);
	result.resulttext = [NSHTTPURLResponse localizedStringForStatusCode: [response statusCode]];
	return result;
}

- (Result *)zapTo:(NSObject<ServiceProtocol> *) service
{
	return [self zapInternal: service.sref];
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
		sref = [bouquet.sref urlencode];
	NSURL *myURI = [NSURL URLWithString: [NSString stringWithFormat:@"/web/getservices?sRef=%@", sref] relativeToURL:_baseAddress];

	const BaseXMLReader *streamReader = [[Enigma2ServiceXMLReader alloc] initWithDelegate: delegate];
	CXMLDocument *doc = [streamReader parseXMLFileAtURL: myURI parseError: nil];
	[streamReader autorelease];
	return doc;
}

- (CXMLDocument *)fetchEPG:(NSObject<EventSourceDelegate> *)delegate service:(NSObject<ServiceProtocol> *)service
{
	NSURL *myURI = [NSURL URLWithString: [NSString stringWithFormat:@"/web/epgservice?sRef=%@", [service.sref urlencode]] relativeToURL: _baseAddress];

	const BaseXMLReader *streamReader = [[Enigma2EventXMLReader alloc] initWithDelegateAndGetServices:delegate getServices:NO];
	CXMLDocument *doc = [streamReader parseXMLFileAtURL: myURI parseError: nil];
	[streamReader autorelease];
	return doc;
}

- (CXMLDocument *)searchEPG: (NSObject<EventSourceDelegate> *)delegate title:(NSString *)title
{
	// TODO: iso8859-1 is currently hardcoded, we might want to fix that
	NSURL *myURI = [NSURL URLWithString: [NSString stringWithFormat:@"/web/epgsearch?search=%@", [title urlencodeWithEncoding:NSISOLatin1StringEncoding]] relativeToURL: _baseAddress];

	const BaseXMLReader *streamReader = [[Enigma2EventXMLReader alloc] initWithDelegateAndGetServices:delegate getServices:YES];
	CXMLDocument *doc = [streamReader parseXMLFileAtURL: myURI parseError: nil];
	[streamReader autorelease];
	return doc;
}

- (CXMLDocument *)searchEPGSimilar: (NSObject<EventSourceDelegate> *)delegate event:(NSObject<EventProtocol> *)event
{
	NSURL *myURI = [NSURL URLWithString: [NSString stringWithFormat:@"/web/epgsimilar?sRef=%@&eventid=%@", [event.service.sref urlencode], event.eit] relativeToURL: _baseAddress];

	const BaseXMLReader *streamReader = [[Enigma2EventXMLReader alloc] initWithDelegateAndGetServices:delegate getServices:YES];
	CXMLDocument *doc = [streamReader parseXMLFileAtURL: myURI parseError: nil];
	[streamReader autorelease];
	return doc;
}

- (CXMLDocument *)getNow:(NSObject<NowSourceDelegate> *)delegate bouquet:(NSObject<ServiceProtocol> *)bouquet isRadio:(BOOL)isRadio
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
		sref = [bouquet.sref urlencode];
	NSURL *myURI = [NSURL URLWithString: [NSString stringWithFormat:@"/web/epgnow?bRef=%@", sref] relativeToURL:_baseAddress];

	const BaseXMLReader *streamReader = [[Enigma2EventXMLReader alloc] initWithNowDelegate: delegate];
	CXMLDocument *doc = [streamReader parseXMLFileAtURL: myURI parseError: nil];
	[streamReader autorelease];
	return doc;
}

- (CXMLDocument *)getNext:(NSObject<NextSourceDelegate> *)delegate bouquet:(NSObject<ServiceProtocol> *)bouquet isRadio:(BOOL)isRadio
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
		sref = [bouquet.sref urlencode];
	NSURL *myURI = [NSURL URLWithString: [NSString stringWithFormat:@"/web/epgnext?bRef=%@", sref] relativeToURL:_baseAddress];

	const BaseXMLReader *streamReader = [[Enigma2EventXMLReader alloc] initWithNextDelegate: delegate];
	CXMLDocument *doc = [streamReader parseXMLFileAtURL: myURI parseError: nil];
	[streamReader autorelease];
	return doc;
}

- (NSURL *)getStreamURLForService:(NSObject<ServiceProtocol> *)service
{
	// TODO: add support for custom port and un/pw but lets stick to the defaults for testing
	NSURL *streamURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@:8001/%@", [_baseAddress host], [service.sref urlencode]]];
	return streamURL;
}

#pragma mark Timer

- (CXMLDocument *)fetchTimers:(NSObject<TimerSourceDelegate> *)delegate
{
	NSURL *myURI = [NSURL URLWithString: @"/web/timerlist" relativeToURL: _baseAddress];

	const BaseXMLReader *streamReader = [[Enigma2TimerXMLReader alloc] initWithDelegate: delegate];
	CXMLDocument *doc = [streamReader parseXMLFileAtURL: myURI parseError: nil];
	[streamReader autorelease];
	return doc;
}

- (Result *)addTimer:(NSObject<TimerProtocol> *) newTimer
{
	NSString *relativeURL = [NSString stringWithFormat: @"/web/timeradd?sRef=%@&begin=%d&end=%d&name=%@&description=%@&eit=%@&disabled=%d&justplay=%d&afterevent=%d&repeated=%d&dirname=%@", [newTimer.service.sref urlencode], (int)[newTimer.begin timeIntervalSince1970], (int)[newTimer.end timeIntervalSince1970], [newTimer.title urlencode], [newTimer.tdescription urlencode], newTimer.eit, newTimer.disabled ? 1 : 0, newTimer.justplay ? 1 : 0, newTimer.afterevent, newTimer.repeated, newTimer.location ? [newTimer.location urlencode] : @""];
	return [self getResultFromSimpleXmlWithRelativeString: relativeURL];
}

- (Result *)editTimer:(NSObject<TimerProtocol> *) oldTimer: (NSObject<TimerProtocol> *) newTimer
{
	NSString *relativeURL = [NSString stringWithFormat: @"/web/timerchange?sRef=%@&begin=%d&end=%d&name=%@&description=%@&eit=%@&disabled=%d&justplay=%d&afterevent=%d&repeated=%d&dirname=%@&channelOld=%@&beginOld=%d&endOld=%d&deleteOldOnSave=1", [newTimer.service.sref urlencode], (int)[newTimer.begin timeIntervalSince1970], (int)[newTimer.end timeIntervalSince1970], [newTimer.title urlencode], [newTimer.tdescription urlencode], newTimer.eit, newTimer.disabled ? 1 : 0, newTimer.justplay ? 1 : 0, newTimer.afterevent, newTimer.repeated, newTimer.location ? [newTimer.location urlencode] : @"", [oldTimer.service.sref urlencode], (int)[oldTimer.begin timeIntervalSince1970], (int)[oldTimer.end timeIntervalSince1970]];
	return [self getResultFromSimpleXmlWithRelativeString: relativeURL];
}

- (Result *)delTimer:(NSObject<TimerProtocol> *) oldTimer
{
	NSString *relativeURL = [NSString stringWithFormat: @"/web/timerdelete?sRef=%@&begin=%d&end=%d", [oldTimer.service.sref urlencode], (int)[oldTimer.begin timeIntervalSince1970], (int)[oldTimer.end timeIntervalSince1970]];
	return [self getResultFromSimpleXmlWithRelativeString: relativeURL];}

#pragma mark Recordings

- (Result *)playMovie:(NSObject<MovieProtocol> *) movie
{
	return [self zapInternal: movie.sref];
}

- (CXMLDocument *)fetchLocationlist:(NSObject <LocationSourceDelegate> *)delegate
{
	NSURL *myURI = [NSURL URLWithString: @"/web/getlocations" relativeToURL: _baseAddress];

	const BaseXMLReader *streamReader = [[Enigma2LocationXMLReader alloc] initWithDelegate: delegate];
	CXMLDocument *doc = [streamReader parseXMLFileAtURL: myURI parseError: nil];
	[streamReader autorelease];
	return doc;
}

- (CXMLDocument *)fetchMovielist:(NSObject<MovieSourceDelegate> *)delegate withLocation: (NSString *)location
{
	NSString *dirname = nil;
	if(location == nil)
		dirname = @"/hdd/movie/";
	else
		dirname = [location urlencode];
	NSURL *myURI = [NSURL URLWithString: [NSString stringWithFormat: @"/web/movielist?dirname=%@", dirname] relativeToURL: _baseAddress];

	const BaseXMLReader *streamReader = [[Enigma2MovieXMLReader alloc] initWithDelegate: delegate];
	CXMLDocument *doc = [streamReader parseXMLFileAtURL: myURI parseError: nil];
	[streamReader autorelease];
	return doc;
}

- (Result *)delMovie:(NSObject<MovieProtocol> *) movie
{
	NSString *relativeURL = [NSString stringWithFormat:@"/web/moviedelete?sRef=%@", [movie.sref urlencode]];
	return [self getResultFromSimpleXmlWithRelativeString: relativeURL];
}

- (Result *)instantRecord
{
	// TODO: we only allow infinite instant records for now
	Result *result = [self getResultFromSimpleXmlWithRelativeString: @"/web/recordnow?recordnow=infinite"];

	// work around buggy webif
	if(!result.result && [result.resulttext hasPrefix:@"Entity 'nbsp' not defined"])
	{
		result.resulttext = NSLocalizedString(@"Unable to determine result, please upgrade your WebInterface if you intend to use this functionality", @"");
	}
	return result;
}

- (NSURL *)getStreamURLForMovie:(NSObject<MovieProtocol> *)movie
{
	NSURL *streamURL = [NSURL URLWithString: [NSString stringWithFormat: @"/file?file=%@", [movie.filename urlencode]] relativeToURL: _baseAddress];
	return streamURL;
}

#pragma mark MediaPlayer

- (CXMLDocument *)fetchFiles: (NSObject<FileSourceDelegate> *)delegate path:(NSString *)path
{
	NSURL *myURI = [NSURL URLWithString: [NSString stringWithFormat:@"/web/mediaplayerlist?path=%@", [path urlencode]] relativeToURL: _baseAddress];

	const BaseXMLReader *streamReader = [[Enigma2FileXMLReader alloc] initWithDelegate: delegate];
	CXMLDocument *doc = [streamReader parseXMLFileAtURL: myURI parseError: nil];
	[streamReader autorelease];
	return doc;
}

- (CXMLDocument *)fetchPlaylist: (NSObject<FileSourceDelegate> *)delegate
{
	return [self fetchFiles:delegate path:@"playlist"];
}

- (Result *)addTrack:(NSObject<FileProtocol> *)track startPlayback:(BOOL)play
{
	NSString *action = nil;
	if(play)
		action = @"play";
	else
		action = @"add";

	NSString *relativeURL = [NSString stringWithFormat:@"/web/mediaplayer%@?root=%@&file=%@", action, [track.root urlencode], [track.sref urlencode]];
	return [self getResultFromSimpleXmlWithRelativeString: relativeURL];
}

- (Result *)playTrack:(NSObject<FileProtocol> *) track
{
	NSString *relativeURL = [NSString stringWithFormat:@"/web/mediaplayerplay?root=playlist&file=%@", [track.sref urlencode]];
	return [self getResultFromSimpleXmlWithRelativeString: relativeURL];
}

- (Result *)removeTrack:(NSObject<FileProtocol> *) track
{
	NSString *relativeURL = [NSString stringWithFormat:@"/web/mediaplayerremove?file=%@", [track.sref urlencode]];
	return [self getResultFromSimpleXmlWithRelativeString: relativeURL];
}

- (Result *)mediaplayerCommand:(NSString *)command
{
	NSString *relativeURL = [NSString stringWithFormat:@"/web/mediaplayercmd?command=%@", command];
	return [self getResultFromSimpleXmlWithRelativeString: relativeURL];
}

- (CXMLDocument *)getMetadata: (NSObject<MetadataSourceDelegate> *)delegate
{
	NSURL *myURI = [NSURL URLWithString: @"/web/mediaplayercurrent" relativeToURL: _baseAddress];

	const BaseXMLReader *streamReader = [[Enigma2MetadataXMLReader alloc] initWithDelegate: delegate];
	CXMLDocument *doc = [streamReader parseXMLFileAtURL: myURI parseError: nil];
	[streamReader autorelease];
	return doc;
}

- (NSData *)getFile: (NSString *)fullpath;
{
	NSURL *myURI = [NSURL URLWithString: [NSString stringWithFormat: @"/file?file=%@", [fullpath urlencode]] relativeToURL: _baseAddress];

	NSData *data = [SynchronousRequestReader sendSynchronousRequest:myURI
												  returningResponse:nil
															  error:nil];
	
	return data;
}

#pragma mark Control

- (CXMLDocument *)getAbout:(NSObject <AboutSourceDelegate>*)delegate
{
	NSURL *myURI = [NSURL URLWithString: @"/web/about" relativeToURL: _baseAddress];

	const BaseXMLReader *streamReader = [[Enigma2AboutXMLReader alloc] initWithDelegate: delegate];
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

- (void)sendPowerstate: (NSInteger) newState
{
	NSURL *myURI = [NSURL URLWithString: [NSString stringWithFormat:@"/web/powerstate?newstate=%d", newState] relativeToURL: _baseAddress];

	[SynchronousRequestReader sendSynchronousRequest:myURI
								   returningResponse:nil
											   error:nil];
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

- (BOOL)toggleMuted
{
	NSURL *myURI = [NSURL URLWithString: @"/web/vol?set=mute" relativeToURL: _baseAddress];

	NSData *data = [SynchronousRequestReader sendSynchronousRequest:myURI
												  returningResponse:nil
															  error:nil];

	const NSString *myString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

	const NSRange myRange = [myString rangeOfString: @"<e2ismuted>True</e2ismuted>"];
	[myString release];
	return (myRange.length > 0);
}

- (Result *)setVolume:(NSInteger) newVolume
{
	NSString *relativeURL = [NSString stringWithFormat:@"/web/vol?set=set%d", newVolume];
	return [self getResultFromSimpleXmlWithRelativeString: relativeURL];
}

- (Result *)sendButton:(NSInteger) type
{
	NSString *relativeURL = [NSString stringWithFormat: @"/web/remotecontrol?command=%d", type];
	return [self getResultFromSimpleXmlWithRelativeString: relativeURL];
}

#pragma mark Signal

- (void)getSignal: (NSObject<SignalSourceDelegate> *)delegate
{
	NSURL *myURI = [NSURL URLWithString: @"/web/signal" relativeToURL: _baseAddress];

	const BaseXMLReader *streamReader = [[Enigma2SignalXMLReader alloc] initWithDelegate: delegate];
	[streamReader parseXMLFileAtURL:myURI parseError: nil];
	[streamReader autorelease];
}

#pragma mark Messaging

- (Result *)sendMessage:(NSString *)message: (NSString *)caption: (NSInteger)type: (NSInteger)timeout
{
	NSString *relativeURL = [NSString stringWithFormat: @"/web/message?text=%@&type=%d&timeout=%d", [message  urlencode], type, timeout];
	return [self getResultFromSimpleXmlWithRelativeString: relativeURL];
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
			return NSLocalizedString(@"Attention", @"Message type");
		case kEnigma2MessageTypeInfo:
			return NSLocalizedString(@"Info", @"Message type");
		case kEnigma2MessageTypeMessage:
			return NSLocalizedString(@"Message", @"Message type");
		case kEnigma2MessageTypeYesNo:
			return NSLocalizedString(@"Yes/No", @"Message type");
		default:
			return @"???";
	}
}

#pragma mark Screenshots

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

	NSURL *myURI = [NSURL URLWithString: [NSString stringWithFormat: @"/grab?format=jpg%@", appendType] relativeToURL: _baseAddress];

	NSData *data = [SynchronousRequestReader sendSynchronousRequest:myURI
												  returningResponse:nil
															  error:nil];

	return data;
}

@end
