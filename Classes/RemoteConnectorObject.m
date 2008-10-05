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

@implementation RemoteConnectorObject

static NSObject<RemoteConnector> *_sharedRemoteConnector = nil;
static NSMutableArray *_connections = nil;

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
		[_sharedRemoteConnector dealloc];
		_sharedRemoteConnector = nil;
	}

	switch(connectorId)
	{
		case kEnigma2Connector:
			_sharedRemoteConnector = [(NSObject <RemoteConnector>*)[Enigma2Connector createClassWithAddress: remoteAddress] retain];
			break;
		case kEnigma1Connector:
			_sharedRemoteConnector = [(NSObject <RemoteConnector>*)[Enigma1Connector createClassWithAddress: remoteAddress] retain];
			break;
		default:
			return NO;
	}
	
	return YES;
}

+ (void)disconnect
{
	if(_sharedRemoteConnector)
	{
		[_sharedRemoteConnector dealloc];
		_sharedRemoteConnector = nil;
	}
}

+ (BOOL)loadConnections
{
	NSString *finalPath = [@"~/Library/Preferences/Connections.plist" stringByExpandingTildeInPath];
	
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
	NSString *finalPath = [@"~/Library/Preferences/Connections.plist" stringByExpandingTildeInPath];

	[_connections writeToFile: finalPath atomically: YES];
}

+ (BOOL)isConnected
{
	return (_sharedRemoteConnector != nil);
}

+ (NSObject<RemoteConnector> *)sharedRemoteConnector
{
	NSParameterAssert(_sharedRemoteConnector != nil);
	return _sharedRemoteConnector;
}

@end
