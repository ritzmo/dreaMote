//
//  RemoteConnectorObject.m
//  Untitled
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

@implementation RemoteConnectorObject

static NSObject<RemoteConnector> *_sharedRemoteConnector = nil;
static NSMutableArray *_connections = nil;
static NSDictionary *_connection;

+ (BOOL)connectTo: (NSInteger)connectionIndex
{
	if(!_connections || connectionIndex >= [_connections count])
		return NO;

	NSDictionary *connection = [_connections objectAtIndex: connectionIndex];

	NSString *remoteHost = [connection objectForKey: kRemoteHost];
	NSString *username = [connection objectForKey: kUsername];
	NSString *password = [connection objectForKey: kPassword];
	NSInteger connectorId = [[connection objectForKey: kConnector] integerValue];

	NSString *remoteAddress;
	if([username isEqualToString: @""])
		remoteAddress = [NSString stringWithFormat: @"http://%@", remoteHost];
	else
		remoteAddress = [NSString stringWithFormat: @"http://%@:%@@%@", username,
					  password, remoteHost];

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
			_sharedRemoteConnector = (NSObject <RemoteConnector>*)[Enigma2Connector createClassWithAddress: remoteAddress];
			break;
		case kEnigma1Connector:
			_sharedRemoteConnector = (NSObject <RemoteConnector>*)[Enigma1Connector createClassWithAddress: remoteAddress];
			break;
#ifdef ENABLE_NEUTRINO_CONNECTOR
		case kNeutrinoConnector:
			_sharedRemoteConnector = (NSObject <RemoteConnector>*)[NeutrinoConnector createClassWithAddress: remoteAddress];
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
	NSString *finalPath = [@"~/Library/Preferences/com.ritzMo.dreaMote.Connections.plist" stringByExpandingTildeInPath];

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
	NSString *finalPath = [@"~/Library/Preferences/com.ritzMo.dreaMote.Connections.plist" stringByExpandingTildeInPath];

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

	NSString *remoteAddress;
	if([username isEqualToString: @""])
		remoteAddress = [NSString stringWithFormat: @"http://%@", remoteHost];
	else
		remoteAddress = [NSString stringWithFormat: @"http://%@:%@@%@", username,
						 password, remoteHost];
	
	connector = (NSObject <RemoteConnector>*)[Enigma2Connector createClassWithAddress: remoteAddress];
	if([connector isReachable])
	{
		[connector release];
		return kEnigma2Connector;
	}

	[connector release];
	connector = (NSObject <RemoteConnector>*)[Enigma1Connector createClassWithAddress: remoteAddress];
	if([connector isReachable])
	{
		[connector release];
		return kEnigma1Connector;
	}
#ifdef ENABLE_NEUTRINO_CONNECTOR
	[connector release];
	connector = (NSObject <RemoteConnector>*)[NeutrinoConnector createClassWithAddress: remoteAddress];
	if([connector isReachable])
	{
		[connector release];
		return kNeutrinoConnector;
	}
#endif
	[connector release];

	return kInvalidConnector;
}

+ (BOOL)isConnected
{
	return (_sharedRemoteConnector != nil);
}

+ (NSInteger)getConnectedId
{
	NSUInteger index = [_connections indexOfObject: _connection];
	if(index == NSNotFound)
		return [[[NSUserDefaults standardUserDefaults] objectForKey: kActiveConnection] integerValue];
	return index;
}

+ (NSObject<RemoteConnector> *)sharedRemoteConnector
{
	NSParameterAssert(_sharedRemoteConnector != nil);
	return _sharedRemoteConnector;
}

@end
