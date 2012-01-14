//
//  SVDRPConnector.m
//  dreaMote
//
//  Created by Moritz Venn on 03.01.09.
//  Copyright 2009-2011 Moritz Venn. All rights reserved.
//

#import "SVDRPConnector.h"

#import <SmallSockets/BufferedSocket.h>
#import <Constants.h>

#import <Delegates/AppDelegate.h>

#import <Objects/Generic/Event.h>
#import <Objects/Generic/Movie.h>
#import <Objects/Generic/Service.h>
#import <Objects/Generic/Volume.h>
#import <Objects/SVDRP/Timer.h>

#import <Delegates/EventSourceDelegate.h>
#import <Delegates/MovieSourceDelegate.h>
#import <Delegates/ServiceSourceDelegate.h>
#import <Delegates/SignalSourceDelegate.h>
#import <Delegates/TimerSourceDelegate.h>
#import <Delegates/VolumeSourceDelegate.h>

#import <ViewController/SVDRPRCEmulatorController.h>

typedef enum
{
	parserCancel = 1,
	parserContinue = 2,
	parserFinished = 3,
} parserReturn;

@implementation SVDRPConnector

- (const BOOL const)hasFeature: (enum connectorFeatures)feature
{
	return
		(feature == kFeaturesRecordInfo) ||
		(feature == kFeaturesSingleBouquet) ||
		(feature == kFeaturesRecordDelete) ||
		(feature == kFeaturesTimerTitle);
}

- (const NSUInteger const)getMaxVolume
{
	return 255;
}

- (id)initWithAddress:(NSString *)inAddress andPort:(NSInteger)inPort
{
	if((self = [super init]))
	{
		_address = inAddress;
		_port = inPort > 0 ? inPort : 2001;
		_serviceCache = nil;
	}
	return self;
}

- (void)freeCaches
{
	_serviceCache = nil;
}

+ (NSObject <RemoteConnector>*)newWithConnection:(const NSDictionary *)connection inBackground:(BOOL)background
{
	NSString *address = [connection objectForKey: kRemoteHost];
	const NSInteger port = [[connection objectForKey: kPort] integerValue];

	return [[SVDRPConnector alloc] initWithAddress:address andPort:port];
}

+ (NSArray *)knownDefaultConnections
{
	// TODO: find out if there are any default connection data for svdrp
	return nil;
}

+ (NSArray *)matchNetServices:(NSArray *)netServices
{
	// XXX: implement this?
	return nil;
}

- (UIViewController *)newRCEmulator
{
	return [[SVDRPRCEmulatorController alloc] init];
}

- (NSString *)description
{
	return @"SVDRP";
}

#pragma mark Common

- (void)getSocket
{
	_socket = [BufferedSocket bufferedSocket];

	@try {
		[_socket connectToHostName: _address port: _port];
		[_socket setBlocking: YES];
		[_socket readDataUpToString: @"\n"]; // NOTE: we need to skip the welcome line
	}
	@catch (NSException * e) {
#if IS_DEBUG()
		NSLog(@"SVDRPConnector failed in getSocket");
		[e raise];
#endif
		_socket = nil;
	}
}

- (NSString *)readSocketLine
{
	NSString *retVal = nil;
	@try {
		NSData *data = [_socket readDataUpToString: @"\r\n"];
		const NSString *tmp = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
		if([tmp length] > 2)
			retVal = [tmp substringToIndex: [tmp length] - 2];
	}
	@catch (NSException * e) {
		// ignore
	}
	@finally {
		return retVal;
	}
}

- (BOOL)isReachable:(NSError **)error
{
	if(!_socket)
		[self getSocket];

	if([_socket isConnected])
	{
		return YES;
	}
	else
	{
		if(error != nil)
		{
			*error = [NSError errorWithDomain:@"myDomain"
										 code:100
									 userInfo:[NSDictionary dictionaryWithObject:NSLocalizedString(@"Remote host unreachable.", @"") forKey:NSLocalizedDescriptionKey]];
		}
		return NO;
	}
}

- (void)indicateError:(NSObject<DataSourceDelegate> *)delegate error:(NSError *)error
{
	// check if delegate wants to be informated about errors
	SEL errorParsing = @selector(dataSourceDelegate:errorParsingDocument:);
	NSMethodSignature *sig = [delegate methodSignatureForSelector:errorParsing];
	if(delegate && [delegate respondsToSelector:errorParsing] && sig)
	{
		if(error == nil)
		{
			error = [NSError errorWithDomain:@"myDomain"
										code:100
									userInfo:[NSDictionary dictionaryWithObject:NSLocalizedString(@"Remote host unreachable.", @"") forKey:NSLocalizedDescriptionKey]];
		}
		__unsafe_unretained NSError *invocationError = error;

		NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:sig];
		[invocation retainArguments];
		[invocation setTarget:delegate];
		[invocation setSelector:errorParsing];
		[invocation setArgument:&invocationError atIndex:3];
		[invocation performSelectorOnMainThread:@selector(invoke) withObject:NULL
								  waitUntilDone:NO];
	}
}

- (void)indicateSuccess:(NSObject<DataSourceDelegate> *)delegate
{
	// check if delegate wants to be informated about parsing end
	SEL finishedParsing = @selector(dataSourceDelegateFinishedParsingDocument:);
	NSMethodSignature *sig = [delegate methodSignatureForSelector:finishedParsing];
	if(delegate && [delegate respondsToSelector:finishedParsing] && sig)
	{
		NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:sig];
		[invocation retainArguments];
		[invocation setTarget:delegate];
		[invocation setSelector:finishedParsing];
		[invocation performSelectorOnMainThread:@selector(invoke) withObject:NULL
								  waitUntilDone: NO];
	}
}

#pragma mark Services

- (Result *)zapTo:(NSObject<ServiceProtocol> *) service
{
	Result *result = [Result createResult];

	[APP_DELEGATE addNetworkOperation];
	if(!_socket || ![_socket isConnected])
		[self getSocket];
	if(![_socket isConnected])
	{
		result.result = NO;
		result.resulttext = NSLocalizedString(@"Unable to connect to remote host.", @"Unable to initiate connection.");
		return result;
	}

	[_socket writeString: [NSString stringWithFormat: @"CHAN %@\r\n", service.sref]];

	[APP_DELEGATE removeNetworkOperation];

	// XXX: we should really parse the return message
	NSString *ret = [self readSocketLine];
	NSLog(@"%@", ret);
	result.result = YES;
	result.resulttext = ret;
	return result;
}

// TODO: does the vdr actually have bouquets?
// FIXME: for now we just return a fake service, we don't support favourite online mode anyway
- (BaseXMLReader *)fetchBouquets: (NSObject<ServiceSourceDelegate> *)delegate isRadio:(BOOL)isRadio
{
	if(isRadio)
	{
#if IS_DEBUG()
		[NSException raise:@"ExcUnsupportedFunction" format:@""];
#endif
		return nil;
	}

	NSObject<ServiceProtocol> *newService = [[GenericService alloc] init];
	newService.sname = NSLocalizedString(@"All Services", @"");
	newService.sref = @"dc";

	[delegate performSelectorOnMainThread: @selector(addService:)
							   withObject: newService
							waitUntilDone: NO];

	[self indicateSuccess:delegate];
	return nil;
}

/* parse a service */
- (parserReturn)parseServie: (NSString *)line service:(NSObject<ServiceProtocol> *)newService
{
	if([line length] < 4 || ![[line substringToIndex: 3] isEqualToString: @"250"])
	{
		return parserCancel;
	}

	// marker
	if([line characterAtIndex:4] == ':')
	{
		newService.sname = [line substringFromIndex:5];
	}
	else
	{
		NSRange range;
		const NSArray *components = [line componentsSeparatedByString: @":"];
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
		newService.sname = [name stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
	}

	// Last line
	if([[line substringToIndex: 4] isEqualToString: @"250 "])
		return parserFinished;
	return parserContinue;
}

- (BaseXMLReader *)fetchServices: (NSObject<ServiceSourceDelegate> *)delegate bouquet:(NSObject<ServiceProtocol> *)bouquet isRadio:(BOOL)isRadio
{
	if(isRadio)
	{
#if IS_DEBUG()
		[NSException raise:@"ExcUnsupportedFunction" format:@""];
#endif
		return nil;
	}

	[APP_DELEGATE addNetworkOperation];
	if(!_socket || ![_socket isConnected])
		[self getSocket];
	if(![_socket isConnected])
	{
		NSObject<ServiceProtocol> *fakeObject = [[GenericService alloc] init];
		fakeObject.sname = NSLocalizedString(@"Error retrieving Data", @"");
		[delegate performSelectorOnMainThread: @selector(addService:)
								   withObject: fakeObject
								waitUntilDone: NO];

		[self indicateError:delegate error:nil];
		return nil;
	}
	_serviceCache = [NSMutableDictionary dictionaryWithCapacity: 50]; // XXX: any suggestions for a good starting value?

	[_socket writeString: @"LSTC\r\n"];

	NSString *line = nil;
	NSObject<ServiceProtocol> *newService = nil;
	parserReturn rc = parserContinue;
	while(rc == parserContinue && (line = [self readSocketLine]))
	{
		newService = [[GenericService alloc] init];

		@try
		{
			rc = [self parseServie:line service:newService];
		}
		@catch(NSException *e)
		{
			NSError *error = [NSError errorWithDomain:@"myDomain"
												 code:110
											 userInfo:[NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"%@: %@", [e name], [e reason]] forKey:NSLocalizedDescriptionKey]];
			[APP_DELEGATE removeNetworkOperation];
			[self indicateError:delegate error:error];
			return nil;
		}

		if(rc != parserCancel)
		{
			[delegate performSelectorOnMainThread:@selector(addService:)
									   withObject:newService
									waitUntilDone:NO];
			if(newService.sref)
				[_serviceCache setObject: newService forKey: newService.sref];
		}
	}

	[APP_DELEGATE removeNetworkOperation];

	[self indicateSuccess:delegate];
	return nil;
}

- (BaseXMLReader *)fetchEPG: (NSObject<EventSourceDelegate> *)delegate service:(NSObject<ServiceProtocol> *)service
{
	[APP_DELEGATE addNetworkOperation];
	if(!_socket || ![_socket isConnected])
		[self getSocket];
	if(![_socket isConnected])
	{
		NSObject<EventProtocol> *fakeObject = [[GenericEvent alloc] init];
		fakeObject.title = NSLocalizedString(@"Error retrieving Data", @"");
		[delegate performSelectorOnMainThread: @selector(addEvent:)
								   withObject: fakeObject
								waitUntilDone: NO];

		[self indicateError:delegate error:nil];
		return nil;
	}

	[_socket writeString: [NSString stringWithFormat: @"LSTE %@\r\n", service.sref]];

	NSString *line = nil;
	NSObject<EventProtocol> *newEvent = nil;
	while((line = [self readSocketLine]))
	{
		if([line length] < 5 || ![[line substringToIndex:3] isEqualToString:@"215"] || [line isEqualToString:@"215 End of EPG data"])
		{
			break;
		}

		NSString *firstFive = [line substringToIndex:5];
		if([firstFive isEqualToString:@"215-E"])
		{
			if(newEvent != nil)
			{
				NSLog(@"Already got event... buggy SVDRP?");
				newEvent = nil;
			}

			const NSArray *components = [line componentsSeparatedByString: @" "];
			if([components count] < 4)
			{
				NSError *error = [NSError errorWithDomain:@"myDomain"
													 code:111
												 userInfo:[NSDictionary dictionaryWithObject:NSLocalizedString(@"Illegal response returned by VDR-server! Aborting.", @"") forKey:NSLocalizedDescriptionKey]];
				[APP_DELEGATE removeNetworkOperation];
				[self indicateError:delegate error:error];
				break;
			}

			newEvent = [[GenericEvent alloc] init];
			newEvent.eit = [components objectAtIndex: 1];
			[newEvent setBeginFromString: [components objectAtIndex: 2]];
			[newEvent setEndFromDurationString: [components objectAtIndex: 3]];
		}
		else if([firstFive isEqualToString:@"215-T"])
		{
			newEvent.title = [[line substringFromIndex:5] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
		}
		else if([firstFive isEqualToString:@"215-S"])
		{
			newEvent.sdescription = [[line substringFromIndex:5] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
		}
		else if([firstFive isEqualToString:@"215-D"])
		{
			NSMutableString *desc = [[[line substringFromIndex:5] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] mutableCopy];
			// replace | by \n
			[desc replaceOccurrencesOfString:@"|" withString:@"\n" options:NSLiteralSearch range:NSMakeRange(0, [desc length])];
			newEvent.edescription = desc;
		}
		else if([firstFive isEqualToString:@"215-e"])
		{
			[delegate performSelectorOnMainThread: @selector(addEvent:)
									   withObject: newEvent
									waitUntilDone: NO];
			newEvent = nil;
		}
	}
	if(newEvent != nil)
	{
		NSLog(@"Event was not released... buggy SVDRP?");
	}

	[APP_DELEGATE removeNetworkOperation];

	[self indicateSuccess:delegate];
	return nil;
}

#pragma mark Timer

/* parse a timer */
- (parserReturn)parseTimer:(NSString *)line timer:(SVDRPTimer *)newTimer calendar:(const NSCalendar *)gregorian components:(NSDateComponents **)comps
{
	if([line length] < 4 || ![[line substringToIndex: 3] isEqualToString: @"250"])
	{
		return parserCancel;
	}

	const NSArray *components = [line componentsSeparatedByString: @":"];
	NSRange range;
	NSInteger tmpInteger;

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
	NSObject<ServiceProtocol> *service = [_serviceCache objectForKey: [components objectAtIndex: 1]];
	if(service)
	{
		newTimer.service = service;
	}
	else
	{
		service = [[GenericService alloc] init];
		service.sname = @"???";
		service.sref = [components objectAtIndex: 1];
		newTimer.service = service;
	}

	// Day
	line = [components objectAtIndex: 2];
	// repeating timer with startdate in MTWTF--
	tmpInteger = [line length];
	if(tmpInteger == 7)
	{
		*comps = [gregorian components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit) fromDate: [NSDate date]];
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
		[*comps setYear: [[line substringWithRange: range] integerValue]];

		range.location = 6;
		range.length = 2;
		[*comps setMonth: [[line substringWithRange: range] integerValue]];

		range.location = 8;
		range.length = 2;
		[*comps setDay: [[line substringWithRange: range] integerValue]];
	}

	// Start
	line = [components objectAtIndex: 3];
	[*comps setHour: [[line substringToIndex: 2] integerValue]];
	[*comps setMinute: [[line substringFromIndex: 2] integerValue]];
	newTimer.begin = [gregorian dateFromComponents: *comps];

	// Stop
	line = [components objectAtIndex: 4];
	[*comps setHour: [[line substringToIndex: 2] integerValue]];
	[*comps setMinute: [[line substringFromIndex: 2] integerValue]];
	NSDate *end = [gregorian dateFromComponents: *comps];
	if([newTimer.begin compare: end] == NSOrderedDescending)
		end = [end dateByAddingTimeInterval:86400];
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

	// Last line
	if([[[components objectAtIndex: 0] substringToIndex: 4] isEqualToString: @"250 "])
		return parserFinished;
	return parserContinue;
}

- (BaseXMLReader *)fetchTimers: (NSObject<TimerSourceDelegate> *)delegate
{
	[APP_DELEGATE addNetworkOperation];
	if(!_socket || ![_socket isConnected])
		[self getSocket];
	if(![_socket isConnected])
	{
		SVDRPTimer *fakeObject = [[SVDRPTimer alloc] init];
		fakeObject.title = NSLocalizedString(@"Error retrieving Data", @"");
		fakeObject.state = 0;
		fakeObject.valid = NO;
		[delegate performSelectorOnMainThread: @selector(addTimer:)
								   withObject: fakeObject
								waitUntilDone: NO];

		[self indicateError:delegate error:nil];
		return nil;
	}
	// Try to refresh cache if none present
	if(_serviceCache == nil)
		[self fetchServices: nil bouquet: nil isRadio: NO];

	[_socket writeString: @"LSTT\r\n"];

	NSString *line = nil;
	const NSCalendar *gregorian = [[NSCalendar alloc]
							initWithCalendarIdentifier: NSGregorianCalendar];
	NSDateComponents *comps = [[NSDateComponents alloc] init];
	parserReturn rc = parserContinue;
	while(rc == parserContinue && (line = [self readSocketLine]))
	{
		SVDRPTimer *newTimer = [[SVDRPTimer alloc] init];

		@try
		{
			rc = [self parseTimer:line timer:newTimer calendar:gregorian components:&comps];
		}
		@catch (NSException *e)
		{
			NSError *error = [NSError errorWithDomain:@"myDomain"
												 code:110
											 userInfo:[NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"%@: %@", [e name], [e reason]] forKey:NSLocalizedDescriptionKey]];
			[APP_DELEGATE removeNetworkOperation];
			[self indicateError:delegate error:error];
			return nil;
		}

		if(rc != parserCancel)
		{
			[delegate performSelectorOnMainThread:@selector(addTimer:)
									   withObject:newTimer
									waitUntilDone:NO];
		}
	}

	[APP_DELEGATE removeNetworkOperation];
	[self indicateSuccess:delegate];
	return nil;
}

- (Result *)addTimer:(NSObject<TimerProtocol> *) newTimer
{
	Result *result = [Result createResult];

	[APP_DELEGATE addNetworkOperation];
	if(!_socket || ![_socket isConnected])
		[self getSocket];
	if(![_socket isConnected])
	{
		result.result = NO;
		result.resulttext = NSLocalizedString(@"Unable to connect to remote host.", @"Unable to initiate connection.");
		return result;
	}

	NSString *timerString;
	const NSInteger flags = newTimer.disabled ? 1 : 0;

	const NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier: NSGregorianCalendar];
	const NSDateComponents *beginComponents = [gregorian components: NSYearCalendarUnit | NSMonthCalendarUnit |  NSDayCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit fromDate: newTimer.begin];
	const NSDateComponents *endComponents = [gregorian components: NSHourCalendarUnit | NSMinuteCalendarUnit fromDate: newTimer.end];

	NSString *dayStr = [NSString stringWithFormat: @"%d-%d-%d",
						[beginComponents year], [beginComponents month], [beginComponents day]];

	timerString = [NSString stringWithFormat: @"%d:%@:%d:%d:%@:%@:%@:%@",
				   flags, newTimer.service.sref, dayStr,
				   [beginComponents hour] * 100 + [beginComponents minute],
				   [endComponents hour] * 100 + [endComponents minute], 50, 50,
				   newTimer.title, @""];

	[_socket writeString: [NSString stringWithFormat: @"NEWT %@\r\n", timerString]];
	[APP_DELEGATE removeNetworkOperation];

	NSString *ret = [self readSocketLine];
	if([ret length] < 4 || ![[ret substringFromIndex: 4] isEqualToString: timerString])
	{
		result.result = NO;
		result.resulttext = ret;
	}
	else
	{
		result.result = YES;
	}

	return result;
}

- (Result *)editTimer:(NSObject<TimerProtocol> *) oldTimer: (NSObject<TimerProtocol> *) newTimer
{
	Result *result = [Result createResult];

	[APP_DELEGATE addNetworkOperation];
	if(!_socket || ![_socket isConnected])
		[self getSocket];
	if(![_socket isConnected])
	{
		result.result = NO;
		result.resulttext = NSLocalizedString(@"Unable to connect to remote host.", @"Unable to initiate connection.");
		return result;
	}

	// we need the timer id of vdr!
	// XXX: we should figure out a better way to detect an svdrptimer though
	if(![newTimer respondsToSelector: @selector(toString)])
	{
		result.result = NO;
		result.resulttext = [NSString stringWithFormat:NSLocalizedString(@"Invalid timer object received: %@.", @"[SVDRPConnector {edit,del}Timer:] did not receive an SVDRPTimer as parameter."), newTimer];
		return result;
	}
	const NSString *timerString = [NSString stringWithFormat: @"%@ %@", ((SVDRPTimer *)newTimer).tid, [(SVDRPTimer *)newTimer toString]];

	[_socket writeString: [NSString stringWithFormat: @"MODT %@\r\n", timerString]];
	[APP_DELEGATE removeNetworkOperation];

	NSString *ret = [self readSocketLine];
	result.result = [ret isEqualToString: [NSString stringWithFormat: @"250 %@", timerString]];
	result.resulttext = ret;
	return result;
}

- (Result *)delTimer:(NSObject<TimerProtocol> *) oldTimer
{
	Result *result = [Result createResult];

	[APP_DELEGATE addNetworkOperation];
	if(!_socket || ![_socket isConnected])
		[self getSocket];
	if(![_socket isConnected])
	{
		result.result = NO;
		result.resulttext = NSLocalizedString(@"Unable to connect to remote host.", @"Unable to initiate connection.");
		return result;
	}

	// we need the timer id of vdr!
	// XXX: we should figure out a better way to detect an svdrptimer though
	if(![oldTimer respondsToSelector: @selector(toString)])
	{
		result.result = NO;
		result.resulttext = [NSString stringWithFormat:NSLocalizedString(@"Invalid timer object received: %@.", @"[SVDRPConnector {edit,del}Timer:] did not receive an SVDRPTimer as parameter."), oldTimer];
		return result;
	}

	[_socket writeString: [NSString stringWithFormat: @"DELT %@\r\n", ((SVDRPTimer *)oldTimer).tid]];
	[APP_DELEGATE removeNetworkOperation];

	NSString *ret = [self readSocketLine];
	result.result = [ret isEqualToString: [NSString stringWithFormat: @"250 Timer \"%@\" deleted", ((SVDRPTimer *)oldTimer).tid]];
	result.resulttext = ret;
	return result;
}

- (Result *)cleanupTimers:(const NSArray *)timers
{
	// TODO: implement?
	return nil;
}

#pragma mark Recordings

- (Result *)playMovie:(NSObject<MovieProtocol> *) movie
{
	Result *result = [Result createResult];

	[APP_DELEGATE addNetworkOperation];
	if(!_socket || ![_socket isConnected])
		[self getSocket];
	if(![_socket isConnected])
	{
		result.result = NO;
		result.resulttext = NSLocalizedString(@"Unable to connect to remote host.", @"Unable to initiate connection.");
		return result;
	}

	[_socket writeString: [NSString stringWithFormat: @"PLAY %@\r\n", movie.sref]];

	[APP_DELEGATE removeNetworkOperation];

	// XXX: we should really parse the return message
	NSString *ret = [self readSocketLine];
	NSLog(@"%@", ret);
	result.result = YES;
	result.resulttext = ret;
	return result;
}

/* helper routine to improve readability a bit */
- (parserReturn)parseMovie: (NSString *)line movie:(NSObject<MovieProtocol> *)movie calendar:(const NSCalendar *)gregorian comps:(NSDateComponents *)comps
{
	if([line length] < 4 || ![[line substringToIndex: 3] isEqualToString: @"250"])
	{
		return parserCancel;
	}

	NSRange range;
	parserReturn rc = ([line characterAtIndex:3] == ' ') ? parserFinished : parserContinue;

	range.location = 4;
	range.length = [line length] - 4;
	range = [line rangeOfString: @" " options: NSLiteralSearch range: range];
	range.length = range.location - 4;
	range.location = 4;
	movie.sref = [line substringWithRange: range];
	line = [line substringFromIndex: range.location + range.length];

	const NSArray *components = [line componentsSeparatedByString: @" "];
	line = [components objectAtIndex: 1];
	range.location = 0;
	range.length = 2;
	[comps setDay: [[line substringWithRange: range] integerValue]];
	range.location = 3;
	[comps setMonth: [[line substringWithRange: range] integerValue]];
	range.location = 6;
	[comps setYear: 2000 + [[line substringWithRange: range] integerValue]];
	line = [components objectAtIndex: 2];
	range.location = 0;
	[comps setHour: [[line substringWithRange: range] integerValue]];
	range.location = 3;
	[comps setMinute: [[line substringWithRange: range] integerValue]];
	movie.time = [gregorian dateFromComponents: comps];

	range.location = 3;
	range.length = [components count] - 3;
	movie.title = [[components subarrayWithRange: range] componentsJoinedByString: @" "];
	return rc;
}

- (BaseXMLReader *)fetchMovielist: (NSObject<MovieSourceDelegate> *)delegate withLocation: (NSString *)location
{
	if(location != nil)
	{
#if IS_DEBUG()
		[NSException raise:@"ExcUnsupportedFunction" format:@""];
#endif
		return nil;
	}

	[APP_DELEGATE addNetworkOperation];
	if(!_socket || ![_socket isConnected])
		[self getSocket];
	if(![_socket isConnected])
	{
		NSObject<MovieProtocol> *fakeObject = [[GenericMovie alloc] init];
		fakeObject.title = NSLocalizedString(@"Error retrieving Data", @"");
		[delegate performSelectorOnMainThread: @selector(addMovie:)
								   withObject: fakeObject
								waitUntilDone: NO];

		[self indicateError:delegate error:nil];
		return nil;
	}

	[_socket writeString: @"LSTR\r\n"];

	NSString *line = nil;
	NSObject<MovieProtocol> *movie = nil;
	const NSCalendar *gregorian = [[NSCalendar alloc]
							 initWithCalendarIdentifier: NSGregorianCalendar];
	NSDateComponents *comps = [[NSDateComponents alloc] init];
	parserReturn rc = parserContinue;
	while(rc == parserContinue && (line = [self readSocketLine]))
	{
		movie = [[GenericMovie alloc] init];

		@try
		{
			// no indicates something is oddly invalid, abort
			rc = [self parseMovie:line movie:movie calendar:gregorian comps:comps];
		}
		@catch(NSException *e)
		{
			NSError *error = [NSError errorWithDomain:@"myDomain"
												 code:110
											 userInfo:[NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"%@: %@", [e name], [e reason]] forKey:NSLocalizedDescriptionKey]];
			[APP_DELEGATE removeNetworkOperation];
			[self indicateError:delegate error:error];
			return nil;
		}

		if(rc != parserCancel)
		{
			[delegate performSelectorOnMainThread:@selector(addMovie:)
									   withObject:movie
									waitUntilDone:NO];
		}

	}

	[APP_DELEGATE removeNetworkOperation];
	[self indicateSuccess:delegate];
	return nil;
}

- (Result *)delMovie:(NSObject<MovieProtocol> *) movie
{
	Result *result = [Result createResult];

	[APP_DELEGATE addNetworkOperation];
	if(!_socket || ![_socket isConnected])
		[self getSocket];
	if(![_socket isConnected])
	{
		result.result = NO;
		result.resulttext = NSLocalizedString(@"Unable to connect to remote host.", @"Unable to initiate connection.");
		return result;
	}

	[_socket writeString: [NSString stringWithFormat: @"DELR %@\r\n", movie.sref]];

	[APP_DELEGATE removeNetworkOperation];

	// XXX: we should really parse the return message
	NSString *ret = [self readSocketLine];
	NSLog(@"%@", ret);
	result.result = YES;
	result.resulttext = ret;
	return result;
}

#pragma mark Control

- (void)getVolume: (NSObject<VolumeSourceDelegate> *)delegate
{
	GenericVolume *volumeObject = nil;

	[APP_DELEGATE addNetworkOperation];
	if(!_socket || ![_socket isConnected])
		[self getSocket];
	if(![_socket isConnected])
		return;

	[_socket writeString: @"VOLU\r\n"];

	volumeObject = [[GenericVolume alloc] init];

	const NSString *line = [self readSocketLine];
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

	[APP_DELEGATE removeNetworkOperation];

	[delegate performSelectorOnMainThread: @selector(addVolume:)
							   withObject: volumeObject
							waitUntilDone: NO];
}

- (void)getSignal:(id)target action:(SEL)action
{
#if IS_DEBUG()
	[NSException raise:@"ExcUnsupportedFunction" format:@""];
#endif
}

- (BOOL)toggleMuted
{
	[APP_DELEGATE addNetworkOperation];
	if(!_socket || ![_socket isConnected])
		[self getSocket];
	if(![_socket isConnected])
		return NO;

	[_socket writeString: @"VOLU mute\r\n"];

	const NSString *ret = [self readSocketLine];
	return [ret isEqualToString: @"250 Audio is mute"];
}

- (Result *)setVolume:(NSInteger) newVolume
{
	Result *result = [Result createResult];

	[APP_DELEGATE addNetworkOperation];
	if(!_socket || ![_socket isConnected])
		[self getSocket];
	if(![_socket isConnected])
	{
		result.result = NO;
		result.resulttext = NSLocalizedString(@"Unable to connect to remote host.", @"Unable to initiate connection.");
		return result;
	}

	[_socket writeString: [NSString stringWithFormat: @"VOLU %d\r\n", newVolume]];

	[APP_DELEGATE removeNetworkOperation];

	NSString *ret = [self readSocketLine];
	result.result = [ret isEqualToString: [NSString stringWithFormat: @"250 Audio volume is %d", newVolume]];
	result.resulttext = ret;
	return result;
}

- (Result *)sendButton:(NSInteger) type
{
	Result *result = [Result createResult];
	NSString *buttonCode = nil;
	switch(type)
	{
		case kButtonCode0: buttonCode = @"0"; break;
		case kButtonCode1: buttonCode = @"1"; break;
		case kButtonCode2: buttonCode = @"2"; break;
		case kButtonCode3: buttonCode = @"3"; break;
		case kButtonCode4: buttonCode = @"4"; break;
		case kButtonCode5: buttonCode = @"5"; break;
		case kButtonCode6: buttonCode = @"6"; break;
		case kButtonCode7: buttonCode = @"7"; break;
		case kButtonCode8: buttonCode = @"8"; break;
		case kButtonCode9: buttonCode = @"9"; break;
		case kButtonCodeUp: buttonCode = @"Up"; break;
		case kButtonCodeDown: buttonCode = @"Down"; break;
		case kButtonCodeLeft: buttonCode = @"Left"; break;
		case kButtonCodeRight: buttonCode = @"Right"; break;
		case kButtonCodeMenu: buttonCode = @"Menu"; break;
		case kButtonCodeOK: buttonCode = @"Ok"; break;
		case kButtonCodeRed: buttonCode = @"Red"; break;
		case kButtonCodeGreen: buttonCode = @"Green"; break;
		case kButtonCodeYellow: buttonCode = @"Yellow"; break;
		case kButtonCodeBlue: buttonCode = @"Blue"; break;
		case kButtonCodeInfo: buttonCode = @"Info"; break;
		case kButtonCodeNext: buttonCode = @"Next"; break;
		case kButtonCodePrevious: buttonCode = @"Prev"; break;
		case kButtonCodePower: buttonCode = @"Power"; break;
		case kButtonCodeBouquetUp: buttonCode = @"Channel+"; break;
		case kButtonCodeBouquetDown: buttonCode = @"Channel-"; break;
		case kButtonCodeVolUp: buttonCode = @"Volume+"; break;
		case kButtonCodeVolDown: buttonCode = @"Volume-"; break;
		case kButtonCodeMute: buttonCode = @"Mute"; break;
		case kButtonCodeAudio: buttonCode = @"Audio"; break;
		// Map Text -> Subtitles
		case kButtonCodeText: buttonCode = @"Subtitles"; break;
		// Map Video -> Recordings
		case kButtonCodeVideo: buttonCode = @"Recordings"; break;
		// Unmapped
/*
		case kButtonCodePlay: buttonCode = @"Play"; break;
		case kButtonCodePause: buttonCode = @"Pause"; break;
		case kButtonCodeStop: buttonCode = @"Stop"; break;
		case kButtonCodeRecord: buttonCode = @"Record"; break;
		case kButtonCodeFastFwd: buttonCode = @"FastFwd"; break;
		case kButtonCodeFastRwd: buttonCode = @"FastRwd"; break;
		case kButtonCodePrevChannel: buttonCode = @"PrevChannel"; break;
		case kButtonCodeSchedule: buttonCode = @"Schedule"; break;
		case kButtonCodeChannels: buttonCode = @"Channels"; break;
		case kButtonCodeTimers: buttonCode = @"Timers"; break;
		case kButtonCodeSetup: buttonCode = @"Setup"; break;
		case kButtonCodeCommands: buttonCode = @"Commands"; break;
		case kButtonCodeUser1: buttonCode = @"User1"; break;
		case kButtonCodeUser2: buttonCode = @"User2"; break;
		case kButtonCodeUser3: buttonCode = @"User3"; break;
		case kButtonCodeUser4: buttonCode = @"User4"; break;
		case kButtonCodeUser5: buttonCode = @"User5"; break;
		case kButtonCodeUser6: buttonCode = @"User6"; break;
		case kButtonCodeUser7: buttonCode = @"User7"; break;
		case kButtonCodeUser8: buttonCode = @"User8"; break;
		case kButtonCodeUser9: buttonCode = @"User9"; break;
*/
	}
	if(buttonCode == nil)
	{
		result.result = NO;
		result.resulttext = NSLocalizedString(@"Unable to map button to keycode!", @"");
		return result;
	}

	[APP_DELEGATE addNetworkOperation];
	if(!_socket || ![_socket isConnected])
		[self getSocket];
	if(![_socket isConnected])
	{
		result.result = NO;
		result.resulttext = NSLocalizedString(@"Unable to connect to remote host.", @"Unable to initiate connection.");
		return result;
	}

	[_socket writeString: [NSString stringWithFormat: @"HITK %@\r\n", buttonCode]];
	[APP_DELEGATE removeNetworkOperation];

	NSString *ret = [self readSocketLine];
	result.result = [ret isEqualToString: [NSString stringWithFormat: @"250 Key \"%@\" accepted", buttonCode]];
	result.resulttext = ret;
	return result;
}

#pragma mark Messaging

- (Result *)sendMessage:(NSString *)message: (NSString *)caption: (NSInteger)type: (NSInteger)timeout
{
	Result *result = [Result createResult];

	[APP_DELEGATE addNetworkOperation];
	if(!_socket || ![_socket isConnected])
		[self getSocket];
	if(![_socket isConnected])
	{
		result.result = NO;
		result.resulttext = NSLocalizedString(@"Unable to connect to remote host.", @"Unable to initiate connection.");
		return result;
	}

	[_socket writeString: [NSString stringWithFormat: @"MESG %@\r\n", message]];
	[APP_DELEGATE removeNetworkOperation];

	NSString *ret = [self readSocketLine];
	result.result = [ret isEqualToString: @"250 Message queued"];
	result.resulttext = ret;
	return result;
}

- (const NSUInteger const)getMaxMessageType
{
	return 0;
}

- (NSString *)getMessageTitle: (NSUInteger)type
{
	return nil;
}

#pragma mark Screenshots

- (NSData *)getScreenshot: (enum screenshotType)type
{
	// XXX: somehow possible, but a long way :-)
	return nil;
}

#pragma mark Unsupported

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

- (BaseXMLReader *)fetchLocationlist: (NSObject<LocationSourceDelegate> *)delegate;
{
#if IS_DEBUG()
	[NSException raise:@"ExcUnsupportedFunction" format:@""];
#endif
	return nil;
}

@end
