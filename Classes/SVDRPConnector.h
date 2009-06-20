//
//  SVDRPConnector.h
//  dreaMote
//
//  Created by Moritz Venn on 03.01.09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
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
	NSMutableDictionary *serviceCache; /*!< @brief Cached List of Services */
	NSString *address; /*!< @brief Hostname or Address of SVDRP Server */
	NSInteger port; /*!< @brief Port SVDRP runs on */

	BufferedSocket *socket; /*!< @brief Socket used to communicate with SVDRP Server */
}

@end
