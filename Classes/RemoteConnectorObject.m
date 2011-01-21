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

#import "Enigma2Connector.h"
#import "Enigma1Connector.h"
#import "NeutrinoConnector.h"
#import "SVDRPConnector.h"

@implementation RemoteConnectorObject

static NSObject<RemoteConnector> *_sharedRemoteConnector = nil;
static NSMutableArray *_connections = nil;
static NSDictionary *_connection;

+ (BOOL)connectTo: (NSUInteger)connectionIndex
{
	if(!_connections || connectionIndex >= [_connections count])
		return NO;

	const NSDictionary *connection = [_connections objectAtIndex: connectionIndex];

	NSString *remoteHost = [connection objectForKey: kRemoteHost];
	NSString *username = [[connection objectForKey: kUsername]  stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding];
	NSString *password = [[connection objectForKey: kPassword] stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding];
	const NSInteger connectorId = [[connection objectForKey: kConnector] integerValue];
	const NSInteger port = [[connection objectForKey: kPort] integerValue];
	const BOOL useSSL = [[connection objectForKey: kSSL] boolValue];

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
		case kEnigma2Connector:
			_sharedRemoteConnector = [Enigma2Connector newWithAddress: remoteHost andUsername: username andPassword: password andPort: port useSSL: useSSL];
			break;
		case kEnigma1Connector:
			_sharedRemoteConnector = [Enigma1Connector newWithAddress: remoteHost andUsername: username andPassword: password andPort: port useSSL: useSSL];
			break;
		case kNeutrinoConnector:
			_sharedRemoteConnector = [NeutrinoConnector newWithAddress: remoteHost andUsername: username andPassword: password andPort: port useSSL: useSSL];
			break;
		case kSVDRPConnector:
			_sharedRemoteConnector = [SVDRPConnector newWithAddress: remoteHost andUsername: username andPassword: password andPort: port useSSL: useSSL];
			break;
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

+ (enum availableConnectors)autodetectConnector: (NSDictionary *)connection
{
	NSObject <RemoteConnector>* connector = nil;

	NSString *remoteHost = [connection objectForKey: kRemoteHost];
	NSString *username = [connection objectForKey: kUsername];
	NSString *password = [connection objectForKey: kPassword];
	const BOOL useSSL = [[connection objectForKey: kSSL] boolValue];

	connector = [Enigma2Connector newWithAddress: remoteHost andUsername: username andPassword: password andPort: 0 useSSL: useSSL];
	if([connector isReachable])
	{
		[connector release];
		return kEnigma2Connector;
	}

	[connector release];
	connector = [Enigma1Connector newWithAddress: remoteHost andUsername: username andPassword: password andPort: 0 useSSL: useSSL];
	if([connector isReachable])
	{
		[connector release];
		return kEnigma1Connector;
	}

	[connector release];
	connector = [NeutrinoConnector newWithAddress: remoteHost andUsername: username andPassword: password andPort: 0 useSSL: useSSL];
	if([connector isReachable])
	{
		[connector release];
		return kNeutrinoConnector;
	}
	
	[connector release];
	connector = [SVDRPConnector newWithAddress: remoteHost andUsername: username andPassword: password andPort: 2001 useSSL: useSSL];
	if([connector isReachable])
	{
		[connector release];
		return kSVDRPConnector;
	}

	[connector release];

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
	NSParameterAssert(_sharedRemoteConnector != nil);
	return _sharedRemoteConnector;
}

@end
