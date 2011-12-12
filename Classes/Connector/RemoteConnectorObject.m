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
@property (nonatomic, strong) NSMutableArray *connections;
@property (nonatomic, strong) NSDictionary *connection;
@property (nonatomic, strong) NSMutableArray *netServices;
@property (nonatomic, readonly) NSOperationQueue *queue;
@end

@interface RemoteConnectorObject(AutoDiscovery)
- (BOOL)startDiscovery;
- (void)stopDiscovery;
@end

@implementation RemoteConnectorObject

@synthesize connections, connection, netServices, queue;

static NSObject<RemoteConnector> *_sharedRemoteConnector = nil;
static RemoteConnectorObject *singleton;

- (id)init
{
	if((self = [super init]))
	{
		queue = [[NSOperationQueue alloc] init];
	}
	return self;
}

- (void)dealloc
{
	singleton = nil;
}

+ (RemoteConnectorObject *)singleton
{
	static dispatch_once_t remoteConnectorObjectInitializer;
	dispatch_once(&remoteConnectorObjectInitializer, ^{
		singleton = [[RemoteConnectorObject alloc] init];
	});
	return singleton;
}

+ (BOOL)connectTo: (NSUInteger)connectionIndex
{
	RemoteConnectorObject *singleton = [RemoteConnectorObject singleton];
	NSArray *connections = singleton.connections;
	if(!connections || connectionIndex >= [connections count])
		return NO;

	NSObject<RemoteConnector> *sharedRemoteConnector = nil;
	NSDictionary *connection = [connections objectAtIndex: connectionIndex];
	const NSInteger connectorId = [[connection objectForKey: kConnector] integerValue];

	singleton.connection = nil;

	switch(connectorId)
	{
#if INCLUDE_FEATURE(Enigma2)
		case kEnigma2Connector:
			sharedRemoteConnector = [Enigma2Connector newWithConnection:connection];
			break;
#endif
#if INCLUDE_FEATURE(Enigma)
		case kEnigma1Connector:
			sharedRemoteConnector = [Enigma1Connector newWithConnection:connection];
			break;
#endif
#if INCLUDE_FEATURE(Neutrino)
		case kNeutrinoConnector:
			sharedRemoteConnector = [NeutrinoConnector newWithConnection:connection];
			break;
#endif
#if INCLUDE_FEATURE(SVDRP)
		case kSVDRPConnector:
			sharedRemoteConnector = [SVDRPConnector newWithConnection:connection];
			break;
#endif
		default:
			return NO;
	}
	_sharedRemoteConnector = sharedRemoteConnector;

	singleton.connection = connection;
	return YES;
}

+ (void)disconnect
{
	_sharedRemoteConnector = nil;
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
	// save default connection for next launch
	RemoteConnectorObject *singleton = [RemoteConnectorObject singleton];
	const NSUInteger index = [singleton.connections indexOfObject:singleton.connection];
	if(index != NSNotFound)
		[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithUnsignedInteger:index] forKey:kActiveConnection];

	NSString *finalPath = [kConfigPath stringByExpandingTildeInPath];
	[[RemoteConnectorObject singleton].connections writeToFile: finalPath atomically: YES];
}

#pragma mark - NSNetServiceDelegate

- (void)netServiceDidResolveAddress:(NSNetService *)netService
{
	netService.delegate = nil;
	[netServices addObject:netService];
}

- (void)netService:(NSNetService *)netService didNotResolve:(NSDictionary *)errorDict
{
	// ignore
	netService.delegate = nil;
}

#pragma mark - NSNetServiceBrowserDelegate

- (void)netServiceBrowser:(NSNetServiceBrowser *)netServiceBrowser didFindService:(NSNetService *)netService moreComing:(BOOL)moreServicesComing
{
	if(![netServices containsObject:netService])
	{
		netService.delegate = self;
		 // we have to retain the service or it will be released before the resolve can finish, so release it in resolve callbacks
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
			NSMutableArray *newAddresses = [addresses mutableCopy];
			// TODO: filter for duplicates (are we able to detect them realiably?)
			[newAddresses addObjectsFromArray:bonjour];
			addresses = newAddresses;
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
					}
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
		return kEnigma2Connector;
	}
#endif

#if INCLUDE_FEATURE(Enigma)
	connector = [Enigma1Connector newWithConnection:connection];
	if([connector isReachable:nil])
	{
		return kEnigma1Connector;
	}
#endif

	#if INCLUDE_FEATURE(Neutrino)
	connector = [NeutrinoConnector newWithConnection:connection];
	if([connector isReachable:nil])
	{
		return kNeutrinoConnector;
	}
#endif

#if INCLUDE_FEATURE(SVDRP)
	connector = [SVDRPConnector newWithConnection:connection];
	if([connector isReachable:nil])
	{
		return kSVDRPConnector;
	}
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

+ (BOOL)hideOutdatedWarning
{
	const id value = [[RemoteConnectorObject singleton].connection objectForKey:kHideOutdatedWarning];
	if(value == nil)
		return NO;
	return [value boolValue];
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
	return _sharedRemoteConnector;
}

+ (NSURLCredential *)getCredential
{
	NSDictionary *connection = [RemoteConnectorObject singleton].connection; // retain to prevent dictionary from being freed by another thread
	NSString *username = [connection objectForKey:kUsername];
	NSString *password = [connection objectForKey:kPassword];
	NSURLCredential *retVal = nil;
	if([username length])
	{
		// make sure username & password exist for a little while
		retVal = [NSURLCredential credentialWithUser:username
											password:password
										 persistence:NSURLCredentialPersistenceForSession];
	}
	 // decrease refcount again
	return retVal;
}

+ (void)cancelPendingOperations
{
	NSOperationQueue *queue = singleton.queue; // either null (and thus no operations to cancel) or valid
	[queue cancelAllOperations];
}

+ (void)queueInvocationWithTarget:(id)target selector:(SEL)sel
{
	NSOperationQueue *queue = singleton ? singleton.queue : [RemoteConnectorObject singleton].queue; // odd, but slightly faster
	NSInvocationOperation *operation = [[NSInvocationOperation alloc] initWithTarget:target selector:sel object:nil];
	[queue addOperation:operation];
}

+ (void)queueBlock:(void (^)(void))block
{
	NSOperationQueue *queue = singleton ? singleton.queue : [RemoteConnectorObject singleton].queue; // odd, but slightly faster
	[queue addOperationWithBlock:block];
}

@end