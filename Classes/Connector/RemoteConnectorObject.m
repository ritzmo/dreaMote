//
//  RemoteConnectorObject.m
//  dreaMote
//
//  Created by Moritz Venn on 11.03.08.
//  Copyright 2008-2011 Moritz Venn. All rights reserved.
//

#import "Constants.h"

#import "RemoteConnectorObject.h"
#import "RemoteConnector.h"

#import <SystemConfiguration/SystemConfiguration.h>

#if INCLUDE_FEATURE(Enigma2)
	#import "Enigma2Connector.h"
#endif
#if INCLUDE_FEATURE(Enigma)
	#import "Enigma1Connector.h"
#endif
#if INCLUDE_FEATURE(Neutrino)
	#import "NeutrinoConnector.h"
#endif
#if INCLUDE_FEATURE(SVDRP)
	#import "SVDRPConnector.h"
#endif

#import "NSString+URLEncode.h"

@interface RemoteConnectorObject()
+ (RemoteConnectorObject *)singleton;
@property (nonatomic, retain) NSMutableArray *connections;
@property (nonatomic, retain) NSDictionary *connection;
@property (nonatomic, retain) NSMutableArray *netServices;
@end

@interface RemoteConnectorObject(AutoDiscovery)
- (BOOL)startDiscovery;
- (void)stopDiscovery;
@end

@implementation RemoteConnectorObject

@synthesize connections, connection, netServices;

static NSObject<RemoteConnector> *_sharedRemoteConnector = nil;
static RemoteConnectorObject *singleton;

- (void)dealloc
{
	singleton = nil;
	[netServiceBrowser release];
	[netServices release];
	[connections release];
	[connection release];

	[super dealloc];
}

+ (RemoteConnectorObject *)singleton
{
	if(!singleton)
	{
		@synchronized(self)
		{
			if(!singleton)
				singleton = [[RemoteConnectorObject alloc] init];
		}
	}
	return singleton;
}

+ (BOOL)connectTo: (NSUInteger)connectionIndex
{
	RemoteConnectorObject *singleton = [RemoteConnectorObject singleton];
	NSArray *connections = singleton.connections;
	if(!connections || connectionIndex >= [connections count])
		return NO;

	NSDictionary *connection = [connections objectAtIndex: connectionIndex];
	const NSInteger connectorId = [[connection objectForKey: kConnector] integerValue];

	if(_sharedRemoteConnector)
	{
		[_sharedRemoteConnector autorelease]; // delay release
		_sharedRemoteConnector = nil;
	}

	singleton.connection = nil;

	switch(connectorId)
	{
#if INCLUDE_FEATURE(Enigma2)
		case kEnigma2Connector:
			_sharedRemoteConnector = [Enigma2Connector newWithConnection:connection];
			break;
#endif
#if INCLUDE_FEATURE(Enigma)
		case kEnigma1Connector:
			_sharedRemoteConnector = [Enigma1Connector newWithConnection:connection];
			break;
#endif
#if INCLUDE_FEATURE(Neutrino)
		case kNeutrinoConnector:
			_sharedRemoteConnector = [NeutrinoConnector newWithConnection:connection];
			break;
#endif
#if INCLUDE_FEATURE(SVDRP)
		case kSVDRPConnector:
			_sharedRemoteConnector = [SVDRPConnector newWithConnection:connection];
			break;
#endif
		default:
			return NO;
	}

	singleton.connection = connection;
	return YES;
}

+ (void)disconnect
{
	if(_sharedRemoteConnector)
	{
		[_sharedRemoteConnector release];
		_sharedRemoteConnector = nil;
	}

	[RemoteConnectorObject singleton].connection = nil;
}

+ (BOOL)loadConnections
{
	NSString *finalPath = [kConfigPath stringByExpandingTildeInPath];
	BOOL retVal = YES;

	NSMutableArray *connections = [NSMutableArray arrayWithContentsOfFile:finalPath];
	if(connections == nil)
	{
		connections = [NSMutableArray array];
		retVal = NO;
	}
	[RemoteConnectorObject singleton].connections = connections;

	// post notification
	[[NSNotificationCenter defaultCenter] postNotificationName:kReadConnectionsNotification object:self userInfo:nil];
	return retVal;
}

+ (NSMutableArray *)getConnections
{
	NSMutableArray *connections = [RemoteConnectorObject singleton].connections;
#if IS_DEBUG()
	NSParameterAssert(connections != nil);
#endif
	return connections;
}

+ (void)saveConnections
{
	NSString *finalPath = [kConfigPath stringByExpandingTildeInPath];
	[[RemoteConnectorObject singleton].connections writeToFile: finalPath atomically: YES];
}

#pragma mark - NSNetServiceDelegate

- (void)netServiceDidResolveAddress:(NSNetService *)netService
{
	netService.delegate = nil;
	[netServices addObject:netService];
	[netService release];
}

- (void)netService:(NSNetService *)netService didNotResolve:(NSDictionary *)errorDict
{
	// ignore
	netService.delegate = nil;
	[netService release];
}

#pragma mark - NSNetServiceBrowserDelegate

- (void)netServiceBrowser:(NSNetServiceBrowser *)netServiceBrowser didFindService:(NSNetService *)netService moreComing:(BOOL)moreServicesComing
{
	if(![netServices containsObject:netService])
	{
		netService.delegate = self;
		[netService retain]; // we have to retain the service or it will be released before the resolve can finish, so release it in resolve callbacks
		[netService resolveWithTimeout:3]; // arbitrary value
	}
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)netServiceBrowser didRemoveService:(NSNetService *)netService moreComing:(BOOL)moreServicesComing
{
	[netServices removeObject:netService];
}

#pragma mark - Autodetection

- (BOOL)startDiscovery
{
	if(netServiceBrowser)
		[self stopDiscovery];

	netServiceBrowser = [[NSNetServiceBrowser alloc] init];
	if(!netServiceBrowser)
		return NO;

	if(!netServices)
		netServices = [[NSMutableArray alloc] init];

	netServiceBrowser.delegate = self;
	[netServiceBrowser searchForServicesOfType:@"_http._tcp." inDomain:@""];

	return YES;
}

- (void)stopDiscovery
{
	if(!netServiceBrowser)
		return;

	[netServiceBrowser stop];
	[netServiceBrowser release];
	netServiceBrowser = nil;

	[netServices removeAllObjects];
}

+ (void)start
{
	[[RemoteConnectorObject singleton] startDiscovery];
}

+ (void)stop
{
	[[RemoteConnectorObject singleton] stopDiscovery];
}

+ (NSArray *)autodetectConnections
{
	NSObject <RemoteConnector>* connector = nil;
	NSMutableArray *array = [NSMutableArray array]; // will keep track of found connections
	NSArray *addresses = nil; // possible connections
	NSArray *bonjour = nil;
	Class<RemoteConnector> currentConnector = NULL;
	RemoteConnectorObject *singleton = [RemoteConnectorObject singleton];

	NSInteger i = 0;
	for(; i < kMaxConnector; ++i)
	{
		switch(i)
		{
#if INCLUDE_FEATURE(Enigma2)
			case kEnigma2Connector:
				currentConnector = [Enigma2Connector class];
				break;
#endif
#if INCLUDE_FEATURE(Enigma)
			case kEnigma1Connector:
				currentConnector = [Enigma1Connector class];
				break;
#endif
#if INCLUDE_FEATURE(Neutrino)
			case kNeutrinoConnector:
				currentConnector = [NeutrinoConnector class];
				break;
#endif
#if INCLUDE_FEATURE(SVDRP)
			case kSVDRPConnector:
				currentConnector = [SVDRPConnector class];
				break;
#endif
			default:
				continue;
		}

		addresses = [currentConnector knownDefaultConnections];
		bonjour = [currentConnector matchNetServices:singleton.netServices];
		if(bonjour)
		{
			addresses = [addresses mutableCopy];
			// TODO: filter for duplicates (are we able to detect them realiably?)
			[(NSMutableArray *)addresses addObjectsFromArray:bonjour];
			[addresses autorelease];
		}

		for(NSDictionary *connection in addresses)
		{
			SCNetworkReachabilityRef reachability = SCNetworkReachabilityCreateWithName(NULL, [[connection objectForKey:kRemoteHost] UTF8String]);
			SCNetworkReachabilityFlags flags;
			if(SCNetworkReachabilityGetFlags(reachability, &flags))
			{
				if(flags & kSCNetworkReachabilityFlagsReachable)
				{
					// host is currently reachable, add to list of possible connections but first try to login
					connector = [currentConnector newWithConnection:connection];
					if([connector isReachable:nil])
					{
						[array addObject:connection];
					}
					// username/password/port did not match, but as the host was found add it to the "somewhere on this network"-list
					else
					{
						NSMutableDictionary *mutableConnection = [connection mutableCopy];
						[mutableConnection setValue:@"YES" forKey:kLoginFailed];
						[array addObject:mutableConnection];
						[mutableConnection release];
					}
					[connector release];
				}
			}
			CFRelease(reachability);
		}
	}

	return array;
}

+ (enum availableConnectors)autodetectConnector: (NSDictionary *)connection
{
	NSObject <RemoteConnector>* connector = nil;

#if INCLUDE_FEATURE(Enigma2)
	connector = [Enigma2Connector newWithConnection:connection];
	if([connector isReachable:nil])
	{
		[connector release];
		return kEnigma2Connector;
	}
	[connector release];
#endif

#if INCLUDE_FEATURE(Enigma)
	connector = [Enigma1Connector newWithConnection:connection];
	if([connector isReachable:nil])
	{
		[connector release];
		return kEnigma1Connector;
	}
	[connector release];
#endif

	#if INCLUDE_FEATURE(Neutrino)
	connector = [NeutrinoConnector newWithConnection:connection];
	if([connector isReachable:nil])
	{
		[connector release];
		return kNeutrinoConnector;
	}
	[connector release];
#endif

#if INCLUDE_FEATURE(SVDRP)
	connector = [SVDRPConnector newWithConnection:connection];
	if([connector isReachable:nil])
	{
		[connector release];
		return kSVDRPConnector;
	}
	[connector release];
#endif

	return kInvalidConnector;
}

#pragma mark -

+ (BOOL)isConnected
{
	return (_sharedRemoteConnector != nil);
}

+ (BOOL)isSingleBouquet
{
	const id value = [[RemoteConnectorObject singleton].connection objectForKey: kSingleBouquet];
	if(value == nil)
		return NO;
	return [value boolValue];
}

+ (BOOL)usesAdvancedRemote
{
	const id value = [[RemoteConnectorObject singleton].connection objectForKey: kAdvancedRemote];
	if(value == nil)
		return NO;
	return [value boolValue];
}

+ (BOOL)showNowNext
{
	if([_sharedRemoteConnector hasFeature:kFeaturesNowNext])
	{
		const id value = [[RemoteConnectorObject singleton].connection objectForKey: kShowNowNext];
		if(value)
			return [value boolValue];
	}
	return NO;
}

+ (NSInteger)getConnectedId
{
	RemoteConnectorObject *singleton = [RemoteConnectorObject singleton];
	const NSUInteger index = [singleton.connections indexOfObject:singleton.connection];
	if(index == NSNotFound)
		return [[NSUserDefaults standardUserDefaults]
					integerForKey: kActiveConnection];
	return index;
}

+ (NSObject<RemoteConnector> *)sharedRemoteConnector
{
	return [[_sharedRemoteConnector retain] autorelease];
}

+ (NSURLCredential *)getCredential
{
	NSDictionary *connection = [RemoteConnectorObject singleton].connection;
	return [NSURLCredential credentialWithUser:[connection objectForKey:kUsername]
									  password:[connection objectForKey:kPassword]
								   persistence:NSURLCredentialPersistenceNone];
}

@end
