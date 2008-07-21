//
//  RemoteConnectorObject.h
//  Untitled
//
//  Created by Moritz Venn on 11.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "RemoteConnector.h"

@interface RemoteConnectorObject : NSObject {
	NSObject<RemoteConnector> *connector;
}
 	
+ (void)_setSharedRemoteConnector:(NSObject<RemoteConnector> *)shared;
+ (NSObject<RemoteConnector> *)sharedRemoteConnector;
 	
@end
