//
//  RemoteConnectorObject.h
//  dreaMote
//
//  Created by Moritz Venn on 11.03.08.
//  Copyright 2008-2010 Moritz Venn. All rights reserved.
//

#import "RemoteConnector.h"

/*!
 @brief Manages list of known and active Connection(s).

 By using this static Class we can easily share some ressources
 between the active UIViews and this eased development a lot.
 */
@interface RemoteConnectorObject : NSObject {
}

/*!
 @brief Connect to given Connection.
 
 @param connectionIndex Index of Connection in List.
 @return YES if Connector instance was created.
 */
+ (BOOL)connectTo: (NSUInteger)connectionIndex;

/*!
 @brief Close active connection.
 */
+ (void)disconnect;


/*!
 @brief Return list of known Connections.
 
 @return List of known Connections.
 */
+ (NSMutableArray *)getConnections;

/*!
 @brief Load list of known Connections.
 
 @return YES if loaded successfully, NO means we have created a new list.
 */
+ (BOOL)loadConnections;

/*!
 @brief Save list of known Connections.
 */
+ (void)saveConnections;



/*!
 @brief Try to automatically detect correct Connector for given Connection.
 
 @param connection Dictionary containing Connection data.
 @return Connector Id (see enum availableConnectors).
 @see enum availableConnectors
 */
+ (enum availableConnectors)autodetectConnector: (NSDictionary *)connection;

/*!
 @brief Returns if we have an active connector instance.

 @return YES if there is an active connector instance.
 */
+ (BOOL)isConnected;

/*!
 @brief Returns if active Connection uses Single Bouquet mode.
 @note This function is required for Enigma2 to function properly in said mode.

 @return YES if active Connection uses Single Bouquet mode.
 */
+ (BOOL)isSingleBouquet;

/*!
 @brief Returns if active Connection uses Advanced Remote.
 @note This function is required for Enigma2 to function properly in said mode.
 
 @return YES if active Connection uses Advanced Remote.
 */
+ (BOOL)usesAdvancedRemote;

/*!
 @brief Returns Id of currently active Connection.
 @note If active Connection is not found in List of known Connections this function
 returns the Id of current default Connection.
 This eases some situations in the GUI which would have to be checked specifically otherwise.
 
 @return Id of active connection.
 */
+ (NSInteger)getConnectedId;

/*!
 @brief Returns active connector instance.

 @return Active Connector.
 */
+ (NSObject<RemoteConnector> *)sharedRemoteConnector;
 	
@end
