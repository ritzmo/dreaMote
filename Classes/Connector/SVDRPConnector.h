//
//  SVDRPConnector.h
//  dreaMote
//
//  Created by Moritz Venn on 03.01.09.
//  Copyright 2009-2012 Moritz Venn. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "RemoteConnector.h"

// Forward declaration
@class BufferedSocket;

/*!
 @brief Connector for SVDRP based STBs.
 */
@interface SVDRPConnector : NSObject <RemoteConnector> {
@private
	NSMutableDictionary *_serviceCache; /*!< @brief Cached List of Services */
	NSString *_address; /*!< @brief Hostname or Address of SVDRP Server */
	NSInteger _port; /*!< @brief Port SVDRP runs on */

	BufferedSocket *_socket; /*!< @brief Socket used to communicate with SVDRP Server */
}

@end
