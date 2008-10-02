//
//  RemoteConnectorObject.m
//  Untitled
//
//  Created by Moritz Venn on 11.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "RemoteConnectorObject.h"
#import "RemoteConnector.h"

#import "Enigma2Connector.h"
#import "Enigma1Connector.h"

@implementation RemoteConnectorObject

static NSObject<RemoteConnector> *_sharedRemoteConnector = nil;

+ (void)createConnector: (NSString *)remoteHost: (NSString *)username: (NSString *)password: (NSInteger) connectorId
{
	NSString *remoteAddress;
	if([username isEqualToString: @""])
		remoteAddress = [NSString stringWithFormat: @"http://%@", remoteHost];
	else
		remoteAddress = [NSString stringWithFormat: @"http://%@:%@@%@", username,
					  password, remoteHost];

	if(_sharedRemoteConnector)
		[_sharedRemoteConnector release];

	switch(connectorId)
	{
		case kEnigma2Connector:
			_sharedRemoteConnector = [(NSObject <RemoteConnector>*)[Enigma2Connector createClassWithAddress: remoteAddress] retain];
			break;
		case kEnigma1Connector:
			_sharedRemoteConnector = [(NSObject <RemoteConnector>*)[Enigma1Connector createClassWithAddress: remoteAddress] retain];
			break;
		default:
			break;
	}
}

+ (void)_setSharedRemoteConnector:(NSObject<RemoteConnector> *)shared
{
	NSParameterAssert(_sharedRemoteConnector == nil);
	_sharedRemoteConnector = [shared retain];
}

+ (void)_releaseSharedRemoteConnector
{
	NSParameterAssert(_sharedRemoteConnector != nil);
	[_sharedRemoteConnector release];
	_sharedRemoteConnector = nil;
}

+ (NSObject<RemoteConnector> *)sharedRemoteConnector
{
	NSParameterAssert(_sharedRemoteConnector != nil);
	return _sharedRemoteConnector;
}

@end
