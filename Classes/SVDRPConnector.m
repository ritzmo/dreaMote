//
//  SVDRPConnector.m
//  dreaMote
//
//  Created by Moritz Venn on 03.01.09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "SVDRPConnector.h"

#import "BufferedSocket.h"

#import "Objects/Generic/Event.h"
#import "Objects/Generic/Movie.h"
#import "Objects/Generic/Service.h"
#import "Objects/Generic/Volume.h"
#import "Objects/SVDRP/Timer.h"

#import "SVDRPRCEmulatorController.h"

@implementation SVDRPConnector

- (const BOOL)hasFeature: (enum connectorFeatures)feature
{
	return
		(feature == kFeaturesRecordInfo) ||
		(feature == kFeaturesSingleBouquet) ||
		(feature == kFeaturesRecordDelete);
}

- (NSInteger)getMaxVolume
{
	return 255;
}

- (id)initWithAddress: (NSString *)inAddress andUsername: (NSString *)inUsername andPassword: (NSString *)inPassword andPort: (NSInteger)inPort
{
	if(self = [super init])
	{
		address = [inAddress retain];
		port = inPort > 0 ? inPort : 2001;
		serviceCache = nil;
	}
	return self;
}

- (void)dealloc
{
	[address release];
	[socket release];
	[serviceCache release];

	[super dealloc];
}

+ (NSObject <RemoteConnector>*)createClassWithAddress:(NSString *) address andUsername: (NSString *)inUsername andPassword: (NSString *)inPassword andPort: (NSInteger)inPort
{
	return (NSObject <RemoteConnector>*)[[SVDRPConnector alloc] initWithAddress: address andUsername: inUsername andPassword: inPassword andPort: inPort];
}

- (void)getSocket
{
	[socket release];
	socket = [[BufferedSocket bufferedSocket] retain];

	@try {
		[socket connectToHostName: address port: port];
		[socket setBlocking: YES];
		[socket readDataUpToString: @"\n"]; // XXX: we need to skip the welcome line
	}
	@catch (NSException * e) {
		return;
	}
}

- (NSString *)readSocketLine
{
	NSString *retVal = nil;
	@try {
		NSData *data = [socket readDataUpToString: @"\r\n"];
		NSString *tmp = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
		if([tmp length] > 2)
			retVal = [tmp substringToIndex: [tmp length] - 2];
		[tmp release];
	}
	@catch (NSException * e) {
		// ignore
	}
	@finally {
		return retVal;
	}
}

- (BOOL)isReachable
{
	if(!socket)
		[self getSocket];
	return [socket isConnected];
}

- (BOOL)zapTo:(NSObject<ServiceProtocol> *) service
{
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	if(!socket || ![socket isConnected])
		[self getSocket];
	if(![socket isConnected])
		return NO;

	[socket writeString: [NSString stringWithFormat: @"CHAN %@\r\n", service.sref]];

	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

	// XXX: we should really parse the return message
	NSString *ret = [self readSocketLine];
	NSLog(ret);
	return YES;
}

- (BOOL)playMovie:(NSObject<MovieProtocol> *) movie
{
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	if(!socket || ![socket isConnected])
		[self getSocket];
	if(![socket isConnected])
		return NO;

	[socket writeString: [NSString stringWithFormat: @"PLAY %@\r\n", movie.sref]];

	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

	// XXX: we should really parse the return message
	NSString *ret = [self readSocketLine];
	NSLog(ret);
	return YES;
}

// TODO: does the vdr actually have bouquets?
// XXX: for now we just return a fake service, we don't support favourite online mode anyway
- (CXMLDocument *)fetchBouquets:(id)target action:(SEL)action
{
	NSObject<ServiceProtocol> *newService = [[Service alloc] init];
	newService.sname = NSLocalizedString(@"All Services", @"");
	newService.sref = @"dc";

	[target performSelectorOnMainThread: action withObject: newService waitUntilDone: NO];
	[newService release];
	return nil;
}

- (CXMLDocument *)fetchServices:(id)target action:(SEL)action bouquet:(NSObject<ServiceProtocol> *)bouquet
{
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	if(!socket || ![socket isConnected])
		[self getSocket];
	if(![socket isConnected])
	{
		Service *fakeObject = [[Service alloc] init];
		fakeObject.sname = NSLocalizedString(@"Error retrieving Data", @"");
		[target performSelectorOnMainThread: action withObject: fakeObject waitUntilDone: NO];
		[fakeObject release];

		return nil;
	}
	if(serviceCache != nil)
		[serviceCache release];
	serviceCache = [[NSMutableDictionary dictionaryWithCapacity: 50] retain]; // XXX: any suggestions for a good starting value?

	[socket writeString: @"LSTC\r\n"];

	NSString *line = nil;
	NSRange range;
	Service *newService = nil;
	while(line = [self readSocketLine])
	{
		if([line length] < 4 || ![[line substringToIndex: 3] isEqualToString: @"250"])
		{
			break;
		}

		newService = [[Service alloc] init];

		NSArray *components = [line componentsSeparatedByString: @":"];
		NSString *name = [components objectAtIndex: 0];
		range.location = 4;
		range.length = [name length] - 4;
		range = [name rangeOfString: @" " options: NSLiteralSearch range: range];
		name = [name substringFromIndex: range.location];
		range.length = range.location-4;
		range.location = 4;
		newService.sref = [[components objectAtIndex: 0] substringWithRange: range];

		range = [name rangeOfString: @";" options: NSBackwardsSearch];
		if(range.length)
			name = [name substringToIndex: range.location];
		range = [name rangeOfString: @"," options: NSBackwardsSearch];
		if(range.length)
			name = [name substringToIndex: range.location];
		newService.sname = name;

		[target performSelectorOnMainThread: action withObject: newService waitUntilDone: NO];
		[serviceCache setObject: newService forKey: newService.sref];
		[newService release];

		// Last line
		if([[line substringToIndex: 4] isEqualToString: @"250 "])
			break;
	}

	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

	return nil;
}

- (CXMLDocument *)fetchEPG:(id)target action:(SEL)action service:(NSObject<ServiceProtocol> *)service
{
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	if(!socket || ![socket isConnected])
		[self getSocket];
	if(![socket isConnected])
	{
		Event *fakeObject = [[Event alloc] init];
		fakeObject.title = NSLocalizedString(@"Error retrieving Data", @"");
		[target performSelectorOnMainThread: action withObject: fakeObject waitUntilDone: NO];
		[fakeObject release];

		return nil;
	}

	[socket writeString: [NSString stringWithFormat: @"LSTE %@\r\n", service.sref]];

	NSString *line = nil;
	NSRange range;
	Event *newEvent = nil;
	while(line = [self readSocketLine])
	{
		if([line length] < 5 || [line isEqualToString: @"215 End of EPG data"])
		{
			break;
		}

		if([[line substringToIndex: 5] isEqualToString: @"215-E"])
		{
			newEvent = [[Event alloc] init];

			NSArray *components = [line componentsSeparatedByString: @" "];
			newEvent.eit = [components objectAtIndex: 1];
			[newEvent setBeginFromString: [components objectAtIndex: 2]];
			[newEvent setEndFromDurationString: [components objectAtIndex: 3]];
		}
		else if([[line substringToIndex: 5] isEqualToString: @"215-T"])
		{
			range = [line rangeOfString: @" "];
			// XXX: do we need to cut/replace anything?
			newEvent.title = [line substringFromIndex: range.location];
		}
		else if([[line substringToIndex: 5] isEqualToString: @"215-S"])
		{
			range = [line rangeOfString: @" "];
			// XXX: do we need to cut/replace anything?
			newEvent.sdescription = [line substringFromIndex: range.location];
		}
		else if([[line substringToIndex: 5] isEqualToString: @"215-D"])
		{
			range = [line rangeOfString: @" "];
			// XXX: do we need to cut/replace anything?
			newEvent.edescription = [line substringFromIndex: range.location];
		}
		else if([[line substringToIndex: 5] isEqualToString: @"215-e"])
		{
			[target performSelectorOnMainThread: action withObject: newEvent waitUntilDone: NO];
			[newEvent release];
		}
	}

	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

	return nil;
}

- (CXMLDocument *)fetchTimers:(id)target action:(SEL)action
{
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	if(!socket || ![socket isConnected])
		[self getSocket];
	if(![socket isConnected])
	{
		SVDRPTimer *fakeObject = [[SVDRPTimer alloc] init];
		fakeObject.title = NSLocalizedString(@"Error retrieving Data", @"");
		fakeObject.state = 0;
		fakeObject.valid = NO;
		[target performSelectorOnMainThread: action withObject: fakeObject waitUntilDone: NO];
		[fakeObject release];

		return nil;
	}
	// Try to refresh cache if none present
	if(serviceCache == nil)
		[self fetchServices: nil action: nil bouquet: nil];	

	[socket writeString: @"LSTT\r\n"];

	NSString *line = nil;
	NSRange range;
	NSInteger tmpInteger;
	NSCalendar *gregorian = [[NSCalendar alloc]
							initWithCalendarIdentifier: NSGregorianCalendar];
	NSDateComponents *comps = [[NSDateComponents alloc] init];
	while(line = [self readSocketLine])
	{
		if([line length] < 4 || ![[line substringToIndex: 3] isEqualToString: @"250"])
		{
			break;
		}

		SVDRPTimer *newTimer = [[SVDRPTimer alloc] init];

		NSArray *components = [line componentsSeparatedByString: @":"];

		// Id:
		line = [components objectAtIndex: 0];
		range = [line rangeOfString: @" " options: NSBackwardsSearch];
		range.length = range.location - 4;
		range.location = 4;
		newTimer.tid = [line substringWithRange: range];

		// Flags:
		//		1 the timer is active (and will record if it hits)
		//		2 this is an instant recording timer
		//		4 this timer uses VPS
		//		8 this timer is currently recording (may only be up-to-date with SVDRP)
		//		All other bits are reserved for future use.
		line = [components objectAtIndex: 0];
		tmpInteger = [[line substringFromIndex: range.length + 4] integerValue];
		newTimer.disabled = (tmpInteger & 1);
		newTimer.flags = (tmpInteger & ~1);

		// Channel
		// This is a channel number, so we have to cache the names in fetchServices
		Service *service = [serviceCache objectForKey: [components objectAtIndex: 1]];
		if(service)
		{
			newTimer.service = service;
		}
		else
		{
			service = [[Service alloc] init];
			service.sname = @"???";
			service.sref = [components objectAtIndex: 1];
			newTimer.service = service;
			[service release];
		}

		// Day
		line = [components objectAtIndex: 2];
		// repeating timer with startdate in MTWTF--
		tmpInteger = [line length];
		if(tmpInteger == 7)
		{
			comps = [gregorian components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit) fromDate: [NSDate date]];
			newTimer.repeat = line;
		}
		// repeating timer with startdate in MTWTF--@YYYY-MM-DD
		else if(tmpInteger == 18)
		{
			newTimer.repeat = [line substringToIndex: 8];
			line = [line substringFromIndex: 9];
			tmpInteger = 10;
		}
		// a) single timer in ISO-Notation (YYYY-MM-DD)
		if(tmpInteger == 10)
		{
			range.location = 0;
			range.length = 4;
			[comps setYear: [[line substringWithRange: range] integerValue]];

			range.location = 6;
			range.length = 2;
			[comps setMonth: [[line substringWithRange: range] integerValue]];

			range.location = 8;
			range.length = 2;
			[comps setDay: [[line substringWithRange: range] integerValue]];
		}

		// Start
		line = [components objectAtIndex: 3];
		[comps setHour: [[line substringToIndex: 2] integerValue]];
		[comps setMinute: [[line substringFromIndex: 2] integerValue]];
		newTimer.begin = [gregorian dateFromComponents: comps];

		// Stop
		line = [components objectAtIndex: 4];
		[comps setHour: [[line substringToIndex: 2] integerValue]];
		[comps setMinute: [[line substringFromIndex: 2] integerValue]];
		NSDate *end = [gregorian dateFromComponents: comps];
		if([newTimer.begin compare: end] == NSOrderedDescending)
			end = [end addTimeInterval: 86400];
		newTimer.end = end;

		// Determine state
		if([newTimer.begin timeIntervalSinceNow] > 0)
			newTimer.state = kTimerStateWaiting;
		else if([newTimer.end timeIntervalSinceNow] > 0)
			newTimer.state = kTimerStateRunning;
		else
			newTimer.state = kTimerStateFinished;

		// Priority, Lifetime, File, Auxiliary
		newTimer.priority = [components objectAtIndex: 5];
		newTimer.lifetime = [components objectAtIndex: 6];
		newTimer.file = [components objectAtIndex: 7];
		newTimer.auxiliary = [components objectAtIndex: 8];

		// XXX: we don't get any information about a title, so use the filename for now
		newTimer.title = newTimer.file;

		[target performSelectorOnMainThread: action withObject: newTimer waitUntilDone: NO];
		[newTimer release];

		// Last line
		if([[[components objectAtIndex: 0] substringToIndex: 4] isEqualToString: @"250 "])
			break;
	}
	//[comps release];
	[gregorian release];

	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	return nil;
}

// TODO: test this
- (CXMLDocument *)fetchMovielist:(id)target action:(SEL)action
{
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	if(!socket || ![socket isConnected])
		[self getSocket];

	[socket writeString: @"LSTR\r\n"];

	NSString *line = nil;
	Movie *movie = nil;
	NSRange range;
	NSCalendar *gregorian = [[NSCalendar alloc]
							 initWithCalendarIdentifier: NSGregorianCalendar];
	NSDateComponents *comps = [[NSDateComponents alloc] init];
	while(line = [self readSocketLine])
	{
		if([line length] < 4 || ![[line substringToIndex: 3] isEqualToString: @"250"])
		{
			break;
		}

		movie = [[Movie alloc] init];

		range.location = 4;
		range.length = [line length] - 4;
		range = [line rangeOfString: @" " options: NSLiteralSearch range: range];
		range.length = range.location - 4;
		range.location = 4;
		movie.sref = [line substringWithRange: range];
		line = [line substringFromIndex: range.location + range.length];

		NSArray *components = [line componentsSeparatedByString: @" "];
		line = [components objectAtIndex: 0];
		range.location = 0;
		range.length = 2;
		[comps setDay: [[line substringWithRange: range] integerValue]];
		range.location = 3;
		[comps setMonth: [[line substringWithRange: range] integerValue]];
		range.location = 6;
		[comps setYear: 2000 + [[line substringWithRange: range] integerValue]];
		line = [components objectAtIndex: 1];
		range.location = 0;
		[comps setHour: [[line substringWithRange: range] integerValue]];
		range.location = 3;
		[comps setMinute: [[line substringWithRange: range] integerValue]];

		range.location = 3;
		range.length = [components count] - 3;
		movie.title = [[components subarrayWithRange: range] componentsJoinedByString: @" "];

		[target performSelectorOnMainThread: action withObject: movie waitUntilDone: NO];
		[movie release];

		// Last line
		if([[line substringToIndex: 4] isEqualToString: @"250 "])
			break;
	}
	//[comps release];
	[gregorian release];

	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	return nil;
}

- (void)sendPowerstate: (NSString *) newState
{
	// XXX: not possible with svdrp?
	return;
}

- (void)shutdown
{
	return;
}

- (void)standby
{
	return;
}

- (void)reboot
{
	return;
}

- (void)restart
{
	// XXX: not available
	return;
}

- (void)getVolume:(id)target action:(SEL)action
{
	Volume *volumeObject = [[Volume alloc] init];

	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	if(!socket || ![socket isConnected])
		[self getSocket];
	if(![socket isConnected])
		return;

	[socket writeString: @"VOLU\r\n"];

	NSString *line = [self readSocketLine];
	if([line isEqualToString: @"250 Audio is mute"])
	{
		volumeObject.current = 0;
		volumeObject.ismuted = YES;
	}
	else
	{
		// 250 Audio volume is ?
		NSRange range;
		range.location = 21;
		range.length = [line length] - 21 - 2;
		volumeObject.current = [[line substringWithRange: range] integerValue];
		volumeObject.ismuted = NO;
	}

	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

	[target performSelectorOnMainThread:action withObject:volumeObject waitUntilDone:NO];
	[volumeObject release];
}

- (BOOL)toggleMuted
{
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	if(!socket || ![socket isConnected])
		[self getSocket];
	if(![socket isConnected])
		return NO;

	[socket writeString: @"VOLU mute\r\n"];

	NSString *line = [self readSocketLine];
	return [line isEqualToString: @"250 Audio is mute"];
}

- (BOOL)setVolume:(NSInteger) newVolume
{
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	if(!socket || ![socket isConnected])
		[self getSocket];
	if(![socket isConnected])
		return NO;
	
	[socket writeString: [NSString stringWithFormat: @"VOLU %d\r\n", newVolume]];

	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

	NSString *ret = [self readSocketLine];
	return [ret isEqualToString: [NSString stringWithFormat: @"250 Audio volume is %d", newVolume]];
}

- (BOOL)addTimer:(NSObject<TimerProtocol> *) newTimer
{
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	if(!socket || ![socket isConnected])
		[self getSocket];
	if(![socket isConnected])
		return NO;

	NSString *timerString;
	NSInteger flags = newTimer.disabled ? 1 : 0;

	NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier: NSGregorianCalendar];
	NSDateComponents *beginComponents = [gregorian components: NSYearCalendarUnit | NSMonthCalendarUnit |  NSDayCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit fromDate: newTimer.begin];
	NSDateComponents *endComponents = [gregorian components: NSHourCalendarUnit | NSMinuteCalendarUnit fromDate: newTimer.end];
	[gregorian release];

	NSString *dayStr = [NSString stringWithFormat: @"%d-%d-%d",
						[beginComponents year], [beginComponents month], [beginComponents day]];

	timerString = [NSString stringWithFormat: @"%d:%@:%d:%d:%@:%@:%@:%@",
				   flags, newTimer.service.sref, dayStr,
				   [beginComponents hour] * 100 + [beginComponents minute],
				   [endComponents hour] * 100 + [endComponents minute], 50, 50,
				   newTimer.title, @""];

	[socket writeString: [NSString stringWithFormat: @"NEWT %@\r\n", timerString]];
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

	NSString *ret = [self readSocketLine];
	if([ret length] < 4)
		return NO;
	return [[ret substringFromIndex: 4] isEqualToString: timerString];
}

- (BOOL)editTimer:(NSObject<TimerProtocol> *) oldTimer: (NSObject<TimerProtocol> *) newTimer
{
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	if(!socket || ![socket isConnected])
		[self getSocket];
	if(![socket isConnected])
		return NO;

	// we need the timer id of vdr!
	// XXX: we should figure out a better way to detect an svdrptimer though
	if(![newTimer respondsToSelector: @selector(toString)])
		return NO;
	NSString *timerString = [NSString stringWithFormat: @"%@ %@", ((SVDRPTimer *)newTimer).tid, [(SVDRPTimer *)newTimer toString]];

	[socket writeString: [NSString stringWithFormat: @"MODT %@\r\n", timerString]];
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

	NSString *ret = [self readSocketLine];
	return [ret isEqualToString: [NSString stringWithFormat: @"250 %@", timerString]];
}

- (BOOL)delTimer:(NSObject<TimerProtocol> *) oldTimer
{
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	if(!socket || ![socket isConnected])
		[self getSocket];
	if(![socket isConnected])
		return NO;

	// we need the timer id of vdr!
	// XXX: we should figure out a better way to detect an svdrptimer though
	if(![oldTimer respondsToSelector: @selector(toString)])
		return NO;

	[socket writeString: [NSString stringWithFormat: @"DELT %@\r\n", ((SVDRPTimer *)oldTimer).tid]];
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

	NSString *ret = [self readSocketLine];
	return [ret isEqualToString: [NSString stringWithFormat: @"250 Timer \"%@\" deleted", ((SVDRPTimer *)oldTimer).tid]];
}

- (BOOL)sendButton:(NSInteger) type
{
	NSString *buttonCode = nil;
	switch(type)
	{
		case kButtonCode0:
			buttonCode = @"0";
			break;
		case kButtonCode1:
			buttonCode = @"1";
			break;
		case kButtonCode2:
			buttonCode = @"2";
			break;
		case kButtonCode3:
			buttonCode = @"3";
			break;
		case kButtonCode4:
			buttonCode = @"4";
			break;
		case kButtonCode5:
			buttonCode = @"5";
			break;
		case kButtonCode6:
			buttonCode = @"6";
			break;
		case kButtonCode7:
			buttonCode = @"7";
			break;
		case kButtonCode8:
			buttonCode = @"8";
			break;
		case kButtonCode9:
			buttonCode = @"9";
			break;
		case kButtonCodeUp:
			buttonCode = @"Up";
			break;
		case kButtonCodeDown:
			buttonCode = @"Down";
			break;
		case kButtonCodeLeft:
			buttonCode = @"Left";
			break;
		case kButtonCodeRight:
			buttonCode = @"Right";
			break;
		case kButtonCodeMenu:
			buttonCode = @"Menu";
			break;
		case kButtonCodeOK:
			buttonCode = @"Ok";
			break;
		case kButtonCodeRed:
			buttonCode = @"Red";
			break;
		case kButtonCodeGreen:
			buttonCode = @"Green";
			break;
		case kButtonCodeYellow:
			buttonCode = @"Yellow";
			break;
		case kButtonCodeBlue:
			buttonCode = @"Blue";
			break;
		case kButtonCodeInfo:
			buttonCode = @"Info";
			break;
		case kButtonCodeNext:
			buttonCode = @"Next";
			break;
		case kButtonCodePrevious:
			buttonCode = @"Prev";
			break;
		case kButtonCodePower:
			buttonCode = @"Power";
			break;
		case kButtonCodeBouquetUp:
			buttonCode = @"Channel+";
			break;
		case kButtonCodeBouquetDown:
			buttonCode = @"Channel-";
			break;
		case kButtonCodeVolUp:
			buttonCode = @"Volume+";
			break;
		case kButtonCodeVolDown:
			buttonCode = @"Volume-";
			break;
		case kButtonCodeMute:
			buttonCode = @"Mute";
			break;
		case kButtonCodeAudio:
			buttonCode = @"Audio";
			break;
		case kButtonCodeText: // Map Text -> Subtitles
			buttonCode = @"Subtitles";
			break;
		case kButtonCodeVideo: // Map Video -> Recordings
			buttonCode = @"Recordings";
			break;
		// Unmapped
/*
		case kButtonCodePlay:
			buttonCode = @"Play";
			break;
		case kButtonCodePause:
			buttonCode = @"Pause";
			break;
		case kButtonCodeStop:
			buttonCode = @"Stop";
			break;
		case kButtonCodeRecord:
			buttonCode = @"Record";
			break;
		case kButtonCodeFastFwd:
			buttonCode = @"FastFwd";
			break;
		case kButtonCodeFastRwd:
			buttonCode = @"FastRwd";
			break;			
		case kButtonCodePrevChannel:
			buttonCode = @"PrevChannel";
			break;
		case kButtonCodeSchedule:
			buttonCode = @"Schedule";
			break;
		case kButtonCodeChannels:
			buttonCode = @"Channels";
			break;
		case kButtonCodeTimers:
			buttonCode = @"Timers";
			break;
		case kButtonCodeSetup:
			buttonCode = @"Setup";
			break;
		case kButtonCodeCommands:
			buttonCode = @"Commands";
			break;
		case kButtonCodeUser1:
			buttonCode = @"User1";
			break;
		case kButtonCodeUser2:
			buttonCode = @"User2";
			break;
		case kButtonCodeUser3:
			buttonCode = @"User3";
			break;
		case kButtonCodeUser4:
			buttonCode = @"User4";
			break;
		case kButtonCodeUser5:
			buttonCode = @"User5";
			break;
		case kButtonCodeUser6:
			buttonCode = @"User6";
			break;
		case kButtonCodeUser7:
			buttonCode = @"User7";
			break;
		case kButtonCodeUser8:
			buttonCode = @"User8";
			break;
		case kButtonCodeUser9:
			buttonCode = @"User9";
			break;
*/
	}
	if(buttonCode == nil)
		return NO;

	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	if(!socket || ![socket isConnected])
		[self getSocket];
	if(![socket isConnected])
		return NO;

	[socket writeString: [NSString stringWithFormat: @"HITK %@\r\n", buttonCode]];
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

	NSString *ret = [self readSocketLine];
	return [ret isEqualToString: [NSString stringWithFormat: @"250 Key \"%@\" accepted", buttonCode]];
}

- (BOOL)sendMessage:(NSString *)message: (NSString *)caption: (NSInteger)type: (NSInteger)timeout
{
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	if(!socket || ![socket isConnected])
		[self getSocket];
	if(![socket isConnected])
		return NO;

	[socket writeString: [NSString stringWithFormat: @"MESG %@\r\n", message]];
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

	NSString *ret = [self readSocketLine];
	return [ret isEqualToString: @"250 Message queued"];
}

- (NSInteger)getMaxMessageType
{
	return 0;
}

- (NSString *)getMessageTitle: (NSInteger)type
{
	return nil;
}

- (NSData *)getScreenshot: (enum screenshotType)type
{
	// XXX: somehow possible, but a long way :-)
	return nil;
}

- (BOOL)delMovie:(NSObject<MovieProtocol> *) movie
{
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	if(!socket || ![socket isConnected])
		[self getSocket];
	if(![socket isConnected])
		return NO;

	[socket writeString: [NSString stringWithFormat: @"DELR %@\r\n", movie.sref]];

	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

	// XXX: we should really parse the return message
	NSString *ret = [self readSocketLine];
	NSLog(ret);
	return YES;
}


- (void)openRCEmulator: (UINavigationController *)navigationController
{
	UIViewController *targetViewController = [[SVDRPRCEmulatorController alloc] init];
	[navigationController pushViewController:targetViewController animated:YES];
	[targetViewController release];
}

- (void)freeCaches
{
	[serviceCache release];
	serviceCache = nil;
	return;
}

@end
