//
//  Event.h
//  dreaMote
//
//  Created by Moritz Venn on 31.12.08.
//  Copyright 2008-2011 Moritz Venn. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "CXMLNode.h"

#import "EventProtocol.h"

@class GenericService;

/*!
 @brief Event in Enigma2.
 */
@interface Enigma2Event : NSObject <EventProtocol>
{
@private
	NSString *_timeString; /*!< @brief Cache for Begin/End Textual representation. */
	NSDate *_begin; /*!< @brief Begin. */
	NSDate *_end; /*!< @brief End. */
	GenericService *_service; /*!< @brief Cached Service. */

	CXMLNode *_node; /*!< @brief CXMLNode describing this Event. */
}

/*!
 @brief Standard initializer.
 
 @param node Pointer to CXMLNode describing this Event.
 @return Enigma2Event instance.
 */
- (id)initWithNode: (CXMLNode *)node;

@end
