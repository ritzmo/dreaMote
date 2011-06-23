//
//  Enigma2Connector.m
//  dreaMote
//
//  Created by Moritz Venn on 08.03.08.
//  Copyright 2008-2011 Moritz Venn. All rights reserved.
//

#import "Enigma2Connector.h"

#import <Constants.h>

#import <Objects/EventProtocol.h>
#import <Objects/MovieProtocol.h>
#import <Objects/ServiceProtocol.h>
#import <Objects/TimerProtocol.h>
#import <Objects/Generic/Movie.h>
#import <Delegates/MediaPlayerShuffleDelegate.h>

#import <Connector/RemoteConnectorObject.h> /* usesAdvancedRemote */

#import <SynchronousRequestReader.h>
#import <XMLReader/Enigma2/AboutXMLReader.h>
#if IS_FULL()
	#import <XMLReader/Enigma2/AutoTimerXMLReader.h>
#endif
#import <XMLReader/Enigma2/CurrentXMLReader.h>
#import <XMLReader/Enigma2/EPGRefreshSettingsXMLReader.h>
#import <XMLReader/Enigma2/EventXMLReader.h>
#import <XMLReader/Enigma2/FileXMLReader.h>
#import <XMLReader/Enigma2/MetadataXMLReader.h>
#import <XMLReader/Enigma2/MovieXMLReader.h>
#import <XMLReader/Enigma2/LocationXMLReader.h>
#import <XMLReader/Enigma2/ServiceXMLReader.h>
#import <XMLReader/Enigma2/SignalXMLReader.h>
#import <XMLReader/Enigma2/SleepTimerXMLReader.h>
#import <XMLReader/Enigma2/TimerXMLReader.h>
#import <XMLReader/Enigma2/VolumeXMLReader.h>

#import <ViewController/EnigmaRCEmulatorController.h>

#import <Categories/NSMutableArray+Shuffling.h>
#import <Categories/NSString+URLEncode.h>

enum powerStates {
	kStandbyState = 0,
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

static NSString *webifIdentifier[WEBIF_VERSION_MAX] = {
	nil, nil, @"1.5+beta", @"1.5+beta3", @"1.6.5", @"1.6.8"
};

@implementation Enigma2Connector

- (const BOOL const)hasFeature: (enum connectorFeatures)feature
{
	switch(_webifVersion)
	{
		// version not yet determined, assume up2date
		case WEBIF_VERSION_UNKNOWN:
			break;
		// should never occur: unhandled internal version; assume it's old though to not cause any trouble.
		default:
		case WEBIF_VERSION_OLD:
			if(feature == kFeaturesSatFinder)
				return NO;
			/* FALL THROUGH */
		case WEBIF_VERSION_1_5b:
			if(feature == kFeaturesRecordingLocations)
			   return NO;
			/* FALL THROUGH */
		case WEBIF_VERSION_1_5b3:
			if(feature == kFeaturesSleepTimer)
				return NO;
			/* FALL THROUGH */
		case WEBIF_VERSION_1_6_5:
			if(feature == kFeaturesMediaPlayerPlaylistHandling)
				return NO;
			/* FALL THROUGH */
		case WEBIF_VERSION_1_6_8:
			break;
	}

	return
		(feature != kFeaturesMessageCaption) &&
		(feature != kFeaturesComplicatedRepeated);
}

- (const NSUInteger const)getMaxVolume
{
	return 100;
}

- (id)initWithAddress:(NSString *)address andUsername:(NSString *)inUsername andPassword:(NSString *)inPassword andPort:(NSInteger)inPort useSSL:(BOOL)ssl andAdvancedRc:(BOOL)advancedRc
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
			remoteAddress = [NSString stringWithFormat: @"%@%@", scheme, address];
			if(inPort > 0)
				remoteAddress = [remoteAddress stringByAppendingFormat: @":%d", inPort];

			_baseAddress = [[NSURL alloc] initWithString:remoteAddress];
			_username = [inUsername retain];
			_password = [inPassword retain];
		}
		_advancedRc = advancedRc;
	}
	return self;
}

- (void)dealloc
{
	[_baseAddress release];
	[_password release];
	[_username release];

	[super dealloc];
}

- (void)freeCaches
{
	// NOTE: We don't use any caches
}

+ (NSObject <RemoteConnector>*)newWithConnection:(const NSDictionary *)connection
{
	NSString *address = [connection objectForKey: kRemoteHost];
	NSString *username = [[connection objectForKey: kUsername] urlencode];
	NSString *password = [[connection objectForKey: kPassword] urlencode];
	const NSInteger port = [[connection objectForKey: kPort] integerValue];
	const BOOL ssl = [[connection objectForKey: kSSL] boolValue];
	const BOOL advancedRc = [[connection objectForKey: kAdvancedRemote] boolValue];

	return (NSObject <RemoteConnector>*)[[Enigma2Connector alloc] initWithAddress:address andUsername:username andPassword:password andPort:port useSSL:ssl andAdvancedRc:advancedRc];
}

+ (NSArray *)knownDefaultConnections
{
	NSNumber *connector = [NSNumber numberWithInteger:kEnigma2Connector];
	NSNumber *eighty = [NSNumber numberWithInteger:80];
	return [NSArray arrayWithObjects:
				[NSDictionary dictionaryWithObjectsAndKeys:
					@"dm7025", kRemoteHost,
					@"root", kUsername,
					@"", kPassword,
					eighty, kPort,
					@"NO", kSSL,
					@"NO", kAdvancedRemote,
					connector, kConnector,
					nil],
				[NSDictionary dictionaryWithObjectsAndKeys:
					@"dm800", kRemoteHost,
					@"root", kUsername,
					@"", kPassword,
					eighty, kPort,
					@"NO", kSSL,
					@"NO", kAdvancedRemote,
					connector, kConnector,
					nil],
				[NSDictionary dictionaryWithObjectsAndKeys:
					@"dm800se", kRemoteHost,
					@"root", kUsername,
					@"", kPassword,
					eighty, kPort,
					@"NO", kSSL,
					@"NO", kAdvancedRemote,
					connector, kConnector,
					nil],
				[NSDictionary dictionaryWithObjectsAndKeys:
					@"dm8000", kRemoteHost,
					@"root", kUsername,
					@"", kPassword,
					eighty, kPort,
					@"NO", kSSL,
					@"YES", kAdvancedRemote,
					connector, kConnector,
					nil],
				[NSDictionary dictionaryWithObjectsAndKeys:
					@"dm500hd", kRemoteHost,
					@"root", kUsername,
					@"", kPassword,
					eighty, kPort,
					@"NO", kSSL,
					@"NO", kAdvancedRemote,
					connector, kConnector,
				 nil],
				[NSDictionary dictionaryWithObjectsAndKeys:
					@"vuplus", kRemoteHost,
					@"root", kUsername,
					@"vuplus", kPassword,
					eighty, kPort,
					@"NO", kSSL,
					@"NO", kAdvancedRemote,
					connector, kConnector,
				 nil],
			nil];
}

- (UIViewController *)newRCEmulator
{
	return [[EnigmaRCEmulatorController alloc] init];
}

- (BOOL)isReachable:(NSError **)error
{
	NSURL *myURI = [NSURL URLWithString:@"/web/about" relativeToURL:_baseAddress];

	NSHTTPURLResponse *response;
	NSData *data = [SynchronousRequestReader sendSynchronousRequest:myURI
												  returningResponse:&response
															  error:error];

	// TODO: check webif version
	if([response statusCode] == 200)
	{
		if(error != nil && !_wasWarned)
		{
			CXMLDocument *dom = [[CXMLDocument alloc] initWithData:data options:0 error:nil];
			const NSArray *resultNodes = [dom nodesForXPath:@"/e2abouts/e2about/e2webifversion" error:nil];
			for(CXMLElement *currentChild in resultNodes)
			{
				NSMutableString *stringValue = [[currentChild stringValue] mutableCopy];
				// XXX: reading out versions like these is quite difficult, so we artificial relabel them so 1.6.0 > 1.6rc > 1.6beta
				[stringValue replaceOccurrencesOfString:@"beta" withString:@"+beta" options:0 range:NSMakeRange(0, [stringValue length])];
				[stringValue replaceOccurrencesOfString:@"rc" withString:@"+rc" options:0 range:NSMakeRange(0, [stringValue length])];
				NSInteger i = WEBIF_VERSION_1_5b;

				_webifVersion = WEBIF_VERSION_OLD;
				for(; i < WEBIF_VERSION_MAX; ++i)
				{
					// version is older than identifier, abort
					if([stringValue compare:webifIdentifier[i]] == NSOrderedAscending)
						break;
					// newer or equal to this version, abort
					else
						_webifVersion = i;
				}
				[stringValue release];

				// only warn on old version, but suggest updating to the newest one
				if(_webifVersion < WEBIF_VERSION_1_6_5)
				{
					*error = [NSError errorWithDomain:@"myDomain"
												code:98
											userInfo:[NSDictionary dictionaryWithObject:[NSString stringWithFormat:NSLocalizedString(@"You are using version %@ of the web interface.\nFor full functionality updating to version %@ is suggested.", @""), [currentChild stringValue], webifIdentifier[WEBIF_VERSION_MAX-1]] forKey:NSLocalizedDescriptionKey]];
				}
			}

			[dom release];
			_wasWarned = YES;
		}
		return YES;
	}
	else
	{
		// no connection error but unexpected status, generate error
		if(error != nil && *error == nil)
		{
			*error = [NSError errorWithDomain:@"myDomain"
										 code:99
									 userInfo:[NSDictionary dictionaryWithObject:[NSString stringWithFormat:NSLocalizedString(@"Connection to remote host failed with status code %d.", @""), [response statusCode]] forKey:NSLocalizedDescriptionKey]];
		}
		return NO;
	}
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
		dom = [[CXMLDocument alloc] initWithData:data options:0 error:&error];
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
			if([[currentChild stringValue] boolValue])
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
	// check if this is actually a movie
	NSString *sref = service.sref;
	if([[sref substringToIndex:20] isEqualToString:@"1:0:0:0:0:0:0:0:0:0:"])
	{
		// create fake movie object and retrieve url using appropriate method
		NSString *filename = [sref substringFromIndex:20];
		GenericMovie *movie = [[GenericMovie alloc] init];
		movie.filename = filename;
		NSURL *streamURL = [self getStreamURLForMovie:movie];
		[movie release];
		return streamURL;
	}
	else
	{
		// TODO: add support for custom port and un/pw but lets stick to the defaults for testing
		NSURL *streamURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@:8001/%@", [_baseAddress host], [sref urlencode]]];
		return streamURL;
	}
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
	Result *result = nil;
	NSString *relativeURL = nil;
	if(newTimer.eit != nil && ![newTimer.eit isEqualToString:@""])
	{
		relativeURL = [NSString stringWithFormat: @"/web/timeraddbyeventid?sRef=%@&eventid=%@&disabled=%d&justplay=%d&afterevent=%d&dirname=%@", [newTimer.service.sref urlencode], newTimer.eit, newTimer.disabled ? 1 : 0, newTimer.justplay ? 1 : 0, newTimer.afterevent, newTimer.location ? [newTimer.location urlencode] : @""];

		// succeeded or "normal" error
		result = [self getResultFromSimpleXmlWithRelativeString:relativeURL];
		if(result.result || ![result.resulttext isEqualToString:@"EventId not found"])
			return result;
	}

	relativeURL = [NSString stringWithFormat: @"/web/timeradd?sRef=%@&begin=%d&end=%d&name=%@&description=%@&disabled=%d&justplay=%d&afterevent=%d&repeated=%d&dirname=%@", [newTimer.service.sref urlencode], (int)[newTimer.begin timeIntervalSince1970], (int)[newTimer.end timeIntervalSince1970], [newTimer.title urlencode], [newTimer.tdescription urlencode], newTimer.disabled ? 1 : 0, newTimer.justplay ? 1 : 0, newTimer.afterevent, newTimer.repeated, newTimer.location ? [newTimer.location urlencode] : @""];
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
	return [self getResultFromSimpleXmlWithRelativeString: relativeURL];
}

- (Result *)cleanupTimers:(const NSArray *)timers
{
	NSString *relativeURL = @"/web/timercleanup?cleanup=true";
	return [self getResultFromSimpleXmlWithRelativeString: relativeURL];
}

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

	// work around buggy webif (was fixed in 1.6.6)
	if(_webifVersion <= WEBIF_VERSION_1_6_5)
	{
		if(!result.result && [result.resulttext hasPrefix:@"Entity 'nbsp' not defined"])
			result.resulttext = NSLocalizedString(@"Unable to determine result, please upgrade your WebInterface if you intend to use this functionality", @"");
	}
	return result;
}

- (NSURL *)getStreamURLForMovie:(NSObject<MovieProtocol> *)movie
{
	NSURL *streamURL = nil;
	if([_username isEqualToString:@""])
		streamURL = [NSURL URLWithString:[NSString stringWithFormat:@"/file?file=%@", [movie.filename urlencode]] relativeToURL:_baseAddress];
	else // inject username & password into url
		streamURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@://%@:%@@%@:%d/file?file=%@", [_baseAddress scheme], _username, _password, [_baseAddress host], [[_baseAddress port] integerValue], [movie.filename urlencode]]];

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

- (void)shufflePlaylist:(NSObject<MediaPlayerShuffleDelegate> *)delegate playlist:(NSMutableArray *)playlist
{
	if([self hasFeature:kFeaturesMediaPlayerPlaylistHandling])
	{
		Result *result = [self getResultFromSimpleXmlWithRelativeString:@"/web/mediaplayercmd?command=shuffle"];
		// native shuffle succeeded, abort
		if(result.result)
		{
			[delegate performSelectorOnMainThread:@selector(finishedShuffling) withObject:nil waitUntilDone:NO];
			return;
		}
		// native shuffle failed, continue with non-native one
	}

	[playlist shuffle];

	NSUInteger count = 2 * playlist.count;
	Result *result = nil;
	for(NSObject<FileProtocol> *file in playlist)
	{
		result = [self removeTrack:file];
		if(result.result)
			/*result = */[self addTrack:file startPlayback:NO];

		count -= 2;
		NSNumber *number = [NSNumber numberWithUnsignedInteger:count];
		[delegate performSelectorOnMainThread:@selector(remainingShuffleActions:) withObject:number waitUntilDone:NO];
	}
	[delegate performSelectorOnMainThread:@selector(finishedShuffling) withObject:nil waitUntilDone:NO];
}

#pragma mark AutoTimer

#if IS_FULL()
- (CXMLDocument *)fetchAutoTimers:(NSObject<AutoTimerSourceDelegate> *)delegate
{

	NSURL *myURI = [NSURL URLWithString:@"/autotimer" relativeToURL:_baseAddress];

	const BaseXMLReader *streamReader = [[Enigma2AutoTimerXMLReader alloc] initWithDelegate:delegate];
	CXMLDocument *doc = [streamReader parseXMLFileAtURL:myURI parseError:nil];
	[streamReader autorelease];
	return doc;
}

- (Result *)addAutoTimer:(AutoTimer *)newTimer
{
	newTimer.idno = -1;
	return [self editAutoTimer:newTimer];
}

- (Result *)delAutoTimer:(AutoTimer *)oldTimer
{
	NSString *relativeURL = [NSString stringWithFormat:@"/autotimer/remove?id=%d", oldTimer.idno];
	return [self getResultFromSimpleXmlWithRelativeString:relativeURL];
}

- (Result *)editAutoTimer:(AutoTimer *)changeTimer
{
	NSMutableString *timerString = [NSMutableString stringWithCapacity:100];

	[timerString appendString:@"/autotimer/edit?"];
	[timerString appendFormat:@"match=%@&name=%@&enabled=%d&justplay=%d", [changeTimer.match urlencode], [changeTimer.name urlencode], changeTimer.enabled ? 1 : 0, changeTimer.justplay ? 1 : 0];
	[timerString appendFormat:@"&searchType=%@&searchCase=%@&overrideAlternatives=%d", (changeTimer.searchType == SEARCH_TYPE_EXACT) ? @"exact" : @"partial", (changeTimer.searchCase == CASE_SENSITIVE) ? @"sensitive" : @"insensitive", changeTimer.overrideAlternatives ? 1 : 0];
	[timerString appendFormat:@"&avoidDuplicateDescription=%d&location=%@", (int)changeTimer.avoidDuplicateDescription, changeTimer.location ? [changeTimer.location urlencode] : @""];

	if(changeTimer.encoding)
	{
		[timerString appendFormat:@"&encoding=%@", [changeTimer.encoding urlencode]];
	}
	else
	{
		[timerString appendString:@"&encoding=UTF-8"];
	}

	if(changeTimer.offsetAfter > -1 && changeTimer.offsetBefore > -1)
	{
		[timerString appendFormat:@"&offset=%d,%d", changeTimer.offsetBefore, changeTimer.offsetAfter];
	}
	else
	{
		[timerString appendFormat:@"&offset="];
	}

	if(changeTimer.maxduration > -1)
	{
		[timerString appendFormat:@"&maxduration=%d", changeTimer.maxduration];
	}
	else
	{
		[timerString appendString:@"&maxduration="];
	}

	if(changeTimer.afterEventAction != kAfterEventMax)
	{
		[timerString appendFormat:@"&afterevent=%d", changeTimer.afterEventAction];
	}
	else
	{
		[timerString appendString:@"&afterevent=default"];
	}

	if(changeTimer.from && changeTimer.to)
	{
		const NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
		NSDateComponents *comps = [gregorian components:NSHourCalendarUnit | NSMinuteCalendarUnit fromDate:changeTimer.from];
		[timerString appendFormat:@"&timespanFrom=%d:%d", [comps hour], [comps minute]];
		comps = [gregorian components:NSHourCalendarUnit | NSMinuteCalendarUnit fromDate:changeTimer.to];
		[timerString appendFormat:@"&timespanTo=%d:%d", [comps hour], [comps minute]];
		[gregorian release];
	}
	else
	{
		[timerString appendString:@"&timespanFrom=&timespanTo="];
	}

	if(changeTimer.before && changeTimer.after)
	{
		[timerString appendFormat:@"&before=%d&after=%d", (int)[changeTimer.before timeIntervalSince1970], (int)[changeTimer.after timeIntervalSince1970]];
	}
	else
	{
		[timerString appendString:@"&before=&after="];
	}

	if(changeTimer.tags.count)
	{
		for(NSString *tag in changeTimer.tags)
		{
			[timerString appendFormat:@"&tag=%@", [tag urlencode]];
		}
	}
	else
	{
		[timerString appendString:@"&tag="];
	}

	[timerString appendString:@"&services="];
	if(changeTimer.services.count)
	{
		for(NSObject<ServiceProtocol> *service in changeTimer.services)
		{
			[timerString appendFormat:@"%@,", [service.sref urlencode]];
		}
	}

	[timerString appendString:@"&bouquets="];
	if(changeTimer.bouquets.count)
	{
		for(NSObject<ServiceProtocol> *service in changeTimer.bouquets)
		{
			[timerString appendFormat:@"%@,", [service.sref urlencode]];
		}
	}

	if(changeTimer.includeTitle.count)
	{
		for(NSString *filter in changeTimer.includeTitle)
		{
			[timerString appendFormat:@"&title=%@", [filter urlencode]];
		}
	}
	else
	{
		[timerString appendString:@"&title="];
	}

	if(changeTimer.includeShortdescription.count)
	{
		for(NSString *filter in changeTimer.includeShortdescription)
		{
			[timerString appendFormat:@"&shortdescription=%@", [filter urlencode]];
		}
	}
	else
	{
		[timerString appendString:@"&shortdescription="];
	}

	if(changeTimer.includeDescription.count)
	{
		for(NSString *filter in changeTimer.includeDescription)
		{
			[timerString appendFormat:@"&description=%@", [filter urlencode]];
		}
	}
	else
	{
		[timerString appendString:@"&description="];
	}

	if(changeTimer.includeDayOfWeek.count)
	{
		for(NSString *filter in changeTimer.includeDayOfWeek)
		{
			[timerString appendFormat:@"&dayofweek=%@", [filter urlencode]];
		}
	}
	else
	{
		[timerString appendString:@"&dayofweek="];
	}

	if(changeTimer.excludeTitle.count)
	{
		for(NSString *filter in changeTimer.excludeTitle)
		{
			[timerString appendFormat:@"&!title=%@", [filter urlencode]];
		}
	}
	else
	{
		[timerString appendString:@"&!title="];
	}

	if(changeTimer.excludeShortdescription.count)
	{
		for(NSString *filter in changeTimer.excludeShortdescription)
		{
			[timerString appendFormat:@"&!shortdescription=%@", [filter urlencode]];
		}
	}
	else
	{
		[timerString appendString:@"&!shortdescription="];
	}

	if(changeTimer.excludeDescription.count)
	{
		for(NSString *filter in changeTimer.excludeDescription)
		{
			[timerString appendFormat:@"&!description=%@", [filter urlencode]];
		}
	}
	else
	{
		[timerString appendString:@"&!description="];
	}

	if(changeTimer.excludeDayOfWeek.count)
	{
		for(NSString *filter in changeTimer.excludeDayOfWeek)
		{
			[timerString appendFormat:@"&!dayofweek=%@", [filter urlencode]];
		}
	}
	else
	{
		[timerString appendString:@"&!dayofweek="];
	}

	if(changeTimer.idno != -1)
		[timerString appendFormat:@"&id=%d", changeTimer.idno];

	return [self getResultFromSimpleXmlWithRelativeString:timerString];
}
#endif

#pragma mark EPGRefresh

- (CXMLDocument *)getEPGRefreshSettings:(NSObject<EPGRefreshSettingsSourceDelegate> *)delegate
{
	NSURL *myURI = [NSURL URLWithString:@"/epgrefresh/get" relativeToURL:_baseAddress];

	const BaseXMLReader *streamReader = [[Enigma2EPGRefreshSettingsXMLReader alloc] initWithDelegate:delegate];
	CXMLDocument *doc = [streamReader parseXMLFileAtURL:myURI parseError:nil];
	[streamReader autorelease];
	return doc;
}

- (CXMLDocument *)getEPGRefreshServices:(NSObject<ServiceSourceDelegate> *)delegate
{
	NSURL *myURI = [NSURL URLWithString:@"/epgrefresh" relativeToURL:_baseAddress];

	const BaseXMLReader *streamReader = [[Enigma2ServiceXMLReader alloc] initWithDelegate:delegate];
	CXMLDocument *doc = [streamReader parseXMLFileAtURL:myURI parseError:nil];
	[streamReader autorelease];
	return doc;
}

- (Result *)setEPGRefreshSettings:(EPGRefreshSettings *)settings andServices:(NSArray *)services andBouquets:(NSArray *)bouquets
{
	NSString *settingsString = [NSString stringWithFormat:@"/epgrefresh/set?enabled=%@&begin=%d&end=%d&interval=%d&delay_standby=%d&inherit_autotimer=%@&afterevent=%@&force=%@&wakeup=%@&adapter=%@&parse_autotimer=%@",
								settings.enabled ? @"true" : @"",
								settings.begin ? (int)[settings.begin timeIntervalSince1970] : 0,
								settings.end ? (int)[settings.end timeIntervalSince1970] : 0,
								settings.interval, settings.delay_standby,
								settings.inherit_autotimer ? @"true" : @"",
								settings.afterevent ? @"true" : @"",
								settings.force ? @"true" : @"",
								settings.wakeup ? @"true" : @"",
								settings.adapter,
								settings.parse_autotimer ? @"true" : @""];

	Result *result = [self getResultFromSimpleXmlWithRelativeString:settingsString];
	if(result.result)
	{
		NSMutableString *servicesString = [NSMutableString stringWithCapacity:100];
		[servicesString appendString:@"/epgrefresh/add?multi=1"];
		if(services.count)
		{
			for(NSObject<ServiceProtocol> *service in services)
			{
				[servicesString appendFormat:@"&sref=%@", [service.sref urlencode]];
			}
		}
		if(bouquets.count)
		{
			for(NSObject<ServiceProtocol> *service in bouquets)
			{
				[servicesString appendFormat:@"&sref=%@", [service.sref urlencode]];
			}
		}

		result = [self getResultFromSimpleXmlWithRelativeString:servicesString];
	}
	return result;
}

#pragma mark SleepTimer

- (CXMLDocument *)getSleepTimerSettings:(NSObject<SleepTimerSourceDelegate> *)delegate
{
	NSURL *myURI = [NSURL URLWithString:@"/web/sleeptimer?cmd=get" relativeToURL:_baseAddress];

	const BaseXMLReader *streamReader = [[Enigma2SleepTimerXMLReader alloc] initWithDelegate:delegate];
	CXMLDocument *doc = [streamReader parseXMLFileAtURL:myURI parseError:nil];
	[streamReader autorelease];
	return doc;
}

- (CXMLDocument *)setSleepTimerSettings:(SleepTimer *)settings delegate:(NSObject<SleepTimerSourceDelegate> *)delegate
{
	NSURL *myURI = [NSURL URLWithString:[NSString stringWithFormat:@"/web/sleeptimer?cmd=set&enabled=%@&time=%d&action=%@",
										 settings.enabled ? @"True" : @"False", settings.time, (settings.action == sleeptimerShutdown) ? @"shutdown" : @"standby"] relativeToURL:_baseAddress];

	const BaseXMLReader *streamReader = [[Enigma2SleepTimerXMLReader alloc] initWithDelegate:delegate];
	CXMLDocument *doc = [streamReader parseXMLFileAtURL:myURI parseError:nil];
	[streamReader autorelease];
	return doc;
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
	[self sendPowerstate: kStandbyState];
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
	const NSString *rcu = _advancedRc ? @"advanced" : @"standard";
	NSString *relativeURL = [NSString stringWithFormat: @"/web/remotecontrol?command=%d&rcu=%@", type, rcu];
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
