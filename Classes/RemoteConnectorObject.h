//
//  RemoteConnectorObject.h
//  Untitled
//
//  Created by Moritz Venn on 11.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "RemoteConnector.h"

@interface RemoteConnectorObject : NSObject {
}

+ (void)createConnector: (NSString *)remoteHost: (NSString *)username: (NSString *)password: (NSInteger) connectorId;
+ (void)_setSharedRemoteConnector:(NSObject<RemoteConnector> *)shared;
+ (void)_releaseSharedRemoteConnector;
+ (NSObject<RemoteConnector> *)sharedRemoteConnector;
 	
@end
