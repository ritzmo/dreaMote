//
//  RemoteConnectorObject.h
//  dreaMote
//
//  Created by Moritz Venn on 11.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "RemoteConnector.h"

/*!
 @interface RemoteConnectorObject
 @abstract Manages list of known and active Connection(s).
 @discussion By using this static Class we can easily share some ressources
 between the active UIViews and this eased development a lot.
 */
@interface RemoteConnectorObject : NSObject {
}

/*!
 @function connectTo
 @abstract Connect to given Connection.
 
 @param connectionIndex Index of Connection in List.
 @return YES if Connector instance was created.
 */
+ (BOOL)connectTo: (NSInteger)connectionIndex;

/*!
 @function disconnect
 @abstract Close active connection.
 */
+ (void)disconnect;


/*!
 @function getConnections
 @abstract Return list of known Connections.
 
 @return List of known Connections.
 */
+ (NSMutableArray *)getConnections;

/*!
 @function loadConnections
 @abstract Load list of known Connections.
 
 @return YES if loaded successfully, NO means we have created a new list.
 */
+ (BOOL)loadConnections;

/*!
 @function saveConnections
 @abstract Save list of known Connections.
 */
+ (void)saveConnections;



/*!
 @function autodetectConnector
 @abstract Try to automatically detect correct Connector for given Connection.
 
 @param connection Dictionary containing Connection data.
 @return Connector Id (see: @link availableConnectors enum availableConnectors @/link).
 */
+ (enum availableConnectors)autodetectConnector: (NSDictionary *)connection;

/*!
 @function isConnected
 @abstract Returns if we have an active connector instance.

 @return YES if there is an active connector instance.
 */
+ (BOOL)isConnected;

/*!
 @function isSingleBouquet
 @abstract Returns if active Connection uses Single Bouquet mode.
 @discussion This function is requires for Enigma2 to function properly in said mode.

 @return YES if active Connection uses Single Bouquet mode.
 */
+ (BOOL)isSingleBouquet;

/*!
 @function getConnectedId
 @abstract Returns Id of currently active Connection.
 @discussion If active Connection is not found in List of known Connections this function
 returns the Id of current default Connection.
 This eases some situations in the GUI which would have to be checked specifically otherwise.
 
 @return Id of active connection.
 */
+ (NSInteger)getConnectedId;

/*!
 @function sharedRemoteConnector
 @abstract Returns active connector instance.

 @return Active Connector.
 */
+ (NSObject<RemoteConnector> *)sharedRemoteConnector;
 	
@end
