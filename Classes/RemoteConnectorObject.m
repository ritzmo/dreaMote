//
//  RemoteConnectorObject.m
//  Untitled
//
//  Created by Moritz Venn on 11.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "RemoteConnectorObject.h"
#import "RemoteConnector.h"

@implementation RemoteConnectorObject

static NSObject<RemoteConnector> *_sharedRemoteConnector = nil;

+ (void)_setSharedRemoteConnector:(NSObject<RemoteConnector> *)shared
{
	NSParameterAssert(_sharedRemoteConnector == nil);
	_sharedRemoteConnector = [shared retain];
}

+ (NSObject<RemoteConnector> *)sharedRemoteConnector
{
	NSParameterAssert(_sharedRemoteConnector != nil);
	return _sharedRemoteConnector;
}

- (id)init
{
	if ((self = [super init]))
	{
		NSParameterAssert(_sharedRemoteConnector != nil);
		connector = _sharedRemoteConnector;
	}
	return self;
}

@end
