//
//  SVDRPConnector.m
//  dreaMote
//
//  Created by Moritz Venn on 03.01.09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "SVDRPConnector.h"

#import "BufferedSocket.h"
#import <sys/socket.h>

#import "Objects/Generic/Service.h"
#import "Objects/Generic/Event.h"
#import "Objects/Generic/Volume.h"
#import "Objects/SVDRP/Timer.h"

@implementation SVDRPConnector

- (const BOOL)hasFeature: (enum connectorFeatures)feature
{
	// XXX: still wip, so work on core features first :-)
	return NO;
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
		port = inPort;
	}
	return self;
}

- (void)dealloc
{
	[address release];
	[socket release];

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
		[socket readDataUpToString: @"\n"]; // XXX: we need to skip the welcome line
	}
	@catch (NSException * e) {
		return;
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

	// TODO: what about a response?
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
	
	[socket writeString: @"LSTC\r\n"];

	NSString *line = nil;
	while(true)
	{
		line = [[NSString alloc] initWithData: [socket readDataUpToString: @"\r\n"] encoding: NSUTF8StringEncoding];
		if(!line || ![[line substringToIndex: 3] isEqualToString: @"250"])
		{
			[line release];
			break;
		}

		Service *newService = [[Service alloc] init];

		NSArray *components = [line componentsSeparatedByString: @":"];
		[line release];
		NSString *name = [components objectAtIndex: 0];
		NSRange range = [name rangeOfString: @" "];
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
		[newService release];
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
	
	[socket writeString: @"LSTE\r\n"];
	
	NSString *line = nil;
	Event *newEvent = nil;
	while(true)
	{
		line = [[NSString alloc] initWithData: [socket readDataUpToString: @"\r\n"] encoding: NSUTF8StringEncoding];
		if(!line)
		{
			[line release];
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
			NSRange range = [line rangeOfString: @" "];
			// XXX: do we need to cut/replace anything?
			newEvent.title = [line substringFromIndex: range.location];
		}
		else if([[line substringToIndex: 5] isEqualToString: @"215-S"])
		{
			NSRange range = [line rangeOfString: @" "];
			// XXX: do we need to cut/replace anything?
			newEvent.sdescription = [line substringFromIndex: range.location];
		}
		else if([[line substringToIndex: 5] isEqualToString: @"215-D"])
		{
			NSRange range = [line rangeOfString: @" "];
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

	[socket writeString: @"LSTT\r\n"];

	NSString *line = nil;
	NSRange range;
	NSInteger tmpInteger;
	NSCalendar *gregorian = [[NSCalendar alloc]
							initWithCalendarIdentifier:NSGregorianCalendar];
	NSDateComponents *comps = [[NSDateComponents alloc] init];
	while(true)
	{
		line = [[NSString alloc] initWithData: [socket readDataUpToString: @"\r\n"] encoding: NSUTF8StringEncoding];
		if(!line || ![[line substringToIndex: 3] isEqualToString: @"250"])
		{
			[line release];
			break;
		}

		SVDRPTimer *newTimer = [[SVDRPTimer alloc] init];

		NSArray *components = [line componentsSeparatedByString: @":"];
		[line release];

		// Id:
		line = [components objectAtIndex: 0];
		range = [line rangeOfString: @" " options: NSBackwardsSearch];
		range.length = range.location - 4;
		range.location = 4;
		newTimer.tid = [line substringFromIndex: 4];

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
		Service *service = [[Service alloc] init];
		service.sname = @"???";
		service.sref = [components objectAtIndex: 1];
		newTimer.service = service;
		[service release];

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
	}
	[comps release];
	[gregorian release];

	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	return nil;
}

// TODO: implement
- (CXMLDocument *)fetchMovielist:(id)target action:(SEL)action
{
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	if(!socket || ![socket isConnected])
		[self getSocket];
	
	[socket writeString: @"LSTR\r\n"];
	
	// TODO: fetch response.
	
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

	NSString *line = [[NSString alloc] initWithData: [socket readDataUpToString: @"\r\n"] encoding: NSUTF8StringEncoding];
	if([line isEqualToString: @"250 Audio is mute"])
	{
		volumeObject.current = 0;
		volumeObject.ismuted = YES;
	}
	else
	{
		// 250 Audio volume is 
		volumeObject.current = [[line substringFromIndex: 21] integerValue];
		volumeObject.ismuted = NO;
	}
	[line release];

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

	NSString *line = [[[NSString alloc] initWithData: [socket readDataUpToString: @"\r\n"] encoding: NSUTF8StringEncoding] autorelease];
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

	[socket readDataUpToString: @"\r\n"];
	return YES;
}

- (NSString *)anyTimerToString:(NSObject<TimerProtocol> *) timer
{
	NSString *timerString = nil;
	if([timer respondsToSelector: @selector(toString)])
		timerString = [(SVDRPTimer *)timer toString];
	else
	{
		NSInteger flags = timer.disabled ? 1 : 0;
		
		NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier: NSGregorianCalendar];
		NSDateComponents *beginComponents = [gregorian components: NSYearCalendarUnit | NSMonthCalendarUnit |  NSDayCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit fromDate: timer.begin];
		NSDateComponents *endComponents = [gregorian components: NSYearCalendarUnit | NSMonthCalendarUnit |  NSDayCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit fromDate: timer.end];
		[gregorian release];
		
		NSString *dayStr = [NSString stringWithFormat: @"%d-%d-%d",
					[beginComponents year], [beginComponents month], [beginComponents day]];

		timerString = [NSString stringWithFormat: @"%d:%@:%d:%d:%@:%@:%@:%@",
					flags, timer.service.sref, dayStr,
					[beginComponents hour] * 100 + [beginComponents minute],
					[endComponents hour] * 100 + [endComponents minute], 50, 50,
					timer.title, @""];
	}
	return timerString;
}

- (BOOL)addTimer:(NSObject<TimerProtocol> *) newTimer
{
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	if(!socket || ![socket isConnected])
		[self getSocket];
	if(![socket isConnected])
		return NO;

	[socket writeString: [NSString stringWithFormat: @"UPDT %@\r\n", [self anyTimerToString: newTimer]]];
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

	// XXX: we should really parse the return message
	[socket readDataUpToString: @"\r\n"];
	return YES;
}

- (BOOL)editTimer:(NSObject<TimerProtocol> *) oldTimer: (NSObject<TimerProtocol> *) newTimer
{
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	if(!socket || ![socket isConnected])
		[self getSocket];
	if(![socket isConnected])
		return NO;

	[socket writeString: [NSString stringWithFormat: @"UPDT %@\r\n", [self anyTimerToString: newTimer]]];
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	
	// XXX: we should really parse the return message
	[socket readDataUpToString: @"\r\n"];
	return YES;
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

	[socket writeString: [NSString stringWithFormat: @"DELT %@\r\n", [(SVDRPTimer *)oldTimer toString]]];
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

	// XXX: we should really parse the return message
	[socket readDataUpToString: @"\r\n"];
	return YES;
}

- (BOOL)sendButton:(NSInteger) type
{
	// TODO: implement
	return NO;
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

	// XXX: we should really parse the return message
	[socket readDataUpToString: @"\r\n"];
	return YES;
}

- (NSData *)getScreenshot: (enum screenshotType)type
{
	// XXX: somehow possible, but a long way :-)
	return nil;
}

- (void)freeCaches
{
	return;
}

@end
