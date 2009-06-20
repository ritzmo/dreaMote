//
//  SVDRPConnector.h
//  dreaMote
//
//  Created by Moritz Venn on 03.01.09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "RemoteConnector.h"

@class BufferedSocket;

/*!
 @interface SVDRPConnector
 @abstract Connector for SVDRP based STBs.
 */
@interface SVDRPConnector : NSObject <RemoteConnector> {
@private
	NSMutableDictionary *serviceCache;
	NSString *address;
	NSInteger port;

	BufferedSocket *socket;
}

@end
