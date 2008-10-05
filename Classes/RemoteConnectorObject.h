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
+ (NSMutableArray *)getConnections;
+ (BOOL)loadConnections;
+ (void)saveConnections;
+ (BOOL)isConnected;
+ (NSObject<RemoteConnector> *)sharedRemoteConnector;
 	
@end
