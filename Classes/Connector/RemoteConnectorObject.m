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

@implementation RemoteConnectorObject

static NSObject<RemoteConnector> *_sharedRemoteConnector = nil;
static NSMutableArray *_connections = nil;
static NSDictionary *_connection;

+ (BOOL)connectTo: (NSUInteger)connectionIndex
{
	if(!_connections || connectionIndex >= [_connections count])
		return NO;

	const NSDictionary *connection = [_connections objectAtIndex: connectionIndex];
	const NSInteger connectorId = [[connection objectForKey: kConnector] integerValue];

	if(_sharedRemoteConnector)
	{
		[_sharedRemoteConnector release];
		_sharedRemoteConnector = nil;
	}
	
	if(_connection)
	{
		[_connection release];
		_connection = nil;
	}

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

	_connection = [connection retain];
	return YES;
}

+ (void)disconnect
{
	if(_sharedRemoteConnector)
	{
		[_sharedRemoteConnector release];
		_sharedRemoteConnector = nil;
	}

	if(_connection)
	{
		[_connection release];
		_connection = nil;
	}
}

+ (BOOL)loadConnections
{
	NSString *finalPath = [kConfigPath stringByExpandingTildeInPath];
	BOOL retVal = YES;

	if(_connections)
	{
		[_connections release];
	}
	_connections = [[NSMutableArray arrayWithContentsOfFile: finalPath] retain];

	if(_connections == nil)
	{
		_connections = [[NSMutableArray array] retain];
		retVal = NO;
	}

	// post notification
	[[NSNotificationCenter defaultCenter] postNotificationName:kReadConnectionsNotification object:self userInfo:nil];
	return retVal;
}

+ (NSMutableArray *)getConnections
{
	NSParameterAssert(_connections != nil);
	return _connections;
}

+ (void)saveConnections
{
	NSString *finalPath = [kConfigPath stringByExpandingTildeInPath];
	[_connections writeToFile: finalPath atomically: YES];
}

+ (NSArray *)autodetectConnections
{
	NSObject <RemoteConnector>* connector = nil;
	NSMutableArray *array = [NSMutableArray array]; // will keep track of found connections
	NSArray *addresses = nil; // possible connections
	Class<RemoteConnector> currentConnector = NULL;

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

+ (BOOL)isConnected
{
	return (_sharedRemoteConnector != nil);
}

+ (BOOL)isSingleBouquet
{
	const id value = [_connection objectForKey: kSingleBouquet];
	if(value == nil)
		return NO;
	return [value boolValue];
}

+ (BOOL)usesAdvancedRemote
{
	const id value = [_connection objectForKey: kAdvancedRemote];
	if(value == nil)
		return NO;
	return [value boolValue];
}

+ (BOOL)showNowNext
{
	if([_sharedRemoteConnector hasFeature:kFeaturesNowNext])
	{
		const id value = [_connection objectForKey: kShowNowNext];
		if(value)
			return [value boolValue];
	}
	return NO;
}

+ (NSInteger)getConnectedId
{
	const NSUInteger index = [_connections indexOfObject: _connection];
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
	return [NSURLCredential credentialWithUser:[_connection objectForKey:kUsername]
									  password:[_connection objectForKey:kPassword]
								   persistence:NSURLCredentialPersistenceNone];
}

@end
