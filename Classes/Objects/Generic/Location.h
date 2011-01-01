//
//  Location.h
//  dreaMote
//
//  Created by Moritz Venn on 01.01.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "LocationProtocol.h"

/*!
 @brief Generic Location.
 */
@interface GenericLocation : NSObject <LocationProtocol>
{
@private	
	NSString *_fullpath; /*!< @brief Full path. */
	BOOL _isValid; /*!< @brief Is this a valid location? */
}

@end
