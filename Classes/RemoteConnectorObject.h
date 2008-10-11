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

+ (BOOL)connectTo: (NSInteger)connectionIndex;
+ (void)disconnect;

+ (NSMutableArray *)getConnections;
+ (BOOL)loadConnections;
+ (void)saveConnections;

+ (enum availableConnectors)autodetectConnector: (NSDictionary *)connection;
+ (BOOL)isConnected;
+ (NSInteger)getConnectedId;
+ (NSObject<RemoteConnector> *)sharedRemoteConnector;
 	
@end
