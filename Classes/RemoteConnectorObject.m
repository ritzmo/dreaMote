//
//  RemoteConnectorObject.m
//  dreaMote
//
//  Created by Moritz Venn on 11.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "Constants.h"

#import "RemoteConnectorObject.h"
#import "RemoteConnector.h"

#import "Enigma2Connector.h"
#import "Enigma1Connector.h"
#import "NeutrinoConnector.h"
#import "SVDRPConnector.h"

#define configPath @"~/Library/Preferences/com.ritzMo.dreaMote.Connections.plist"

@implementation RemoteConnectorObject

static NSObject<RemoteConnector> *_sharedRemoteConnector = nil;
static NSMutableArray *_connections = nil;
static NSDictionary *_connection;

+ (BOOL)connectTo: (NSInteger)connectionIndex
{
	if(!_connections || connectionIndex >= [_connections count])
		return NO;

	const NSDictionary *connection = [_connections objectAtIndex: connectionIndex];

	NSString *remoteHost = [connection objectForKey: kRemoteHost];
	NSString *username = [[connection objectForKey: kUsername]  stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding];
	NSString *password = [[connection objectForKey: kPassword] stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding];
	const NSInteger connectorId = [[connection objectForKey: kConnector] integerValue];
	const NSInteger port = [[connection objectForKey: kPort] integerValue];

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
			_sharedRemoteConnector = [Enigma2Connector newWithAddress: remoteHost andUsername: username andPassword: password andPort: port];
			break;
		case kEnigma1Connector:
			_sharedRemoteConnector = [Enigma1Connector newWithAddress: remoteHost andUsername: username andPassword: password andPort: port];
			break;
		case kNeutrinoConnector:
			_sharedRemoteConnector = [NeutrinoConnector newWithAddress: remoteHost andUsername: username andPassword: password andPort: port];
			break;
		case kSVDRPConnector:
			_sharedRemoteConnector = [SVDRPConnector newWithAddress: remoteHost andUsername: username andPassword: password andPort: port];
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
	NSString *finalPath = [configPath stringByExpandingTildeInPath];

	_connections = [[NSMutableArray arrayWithContentsOfFile: finalPath] retain];

	if(_connections == nil)
	{
		_connections = [[NSMutableArray array] retain];
		return NO;
	}
	return YES;
}

+ (NSMutableArray *)getConnections
{
	NSParameterAssert(_connections != nil);
	return _connections;
}

+ (void)saveConnections
{
	NSString *finalPath = [configPath stringByExpandingTildeInPath];

	[_connections writeToFile: finalPath atomically: YES];
	[_connections release];
	_connections = nil;
}

+ (enum availableConnectors)autodetectConnector: (NSDictionary *)connection
{
	NSObject <RemoteConnector>* connector = nil;

	NSString *remoteHost = [connection objectForKey: kRemoteHost];
	NSString *username = [connection objectForKey: kUsername];
	NSString *password = [connection objectForKey: kPassword];

	connector = [Enigma2Connector newWithAddress: remoteHost andUsername: username andPassword: password andPort: 0];
	if([connector isReachable])
	{
		[connector release];
		return kEnigma2Connector;
	}

	[connector release];
	connector = [Enigma1Connector newWithAddress: remoteHost andUsername: username andPassword: password andPort: 0];
	if([connector isReachable])
	{
		[connector release];
		return kEnigma1Connector;
	}

	[connector release];
	connector = [NeutrinoConnector newWithAddress: remoteHost andUsername: username andPassword: password andPort: 0];
	if([connector isReachable])
	{
		[connector release];
		return kNeutrinoConnector;
	}
	
	[connector release];
	connector = [SVDRPConnector newWithAddress: remoteHost andUsername: username andPassword: password andPort: 2001];
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
