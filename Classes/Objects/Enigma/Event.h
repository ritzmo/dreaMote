//
//  Event.h
//  dreaMote
//
//  Created by Moritz Venn on 01.01.09.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "CXMLNode.h"

#import "EventProtocol.h"

/*!
 @brief Event in Enigma.
 */
@interface EnigmaEvent : NSObject <EventProtocol>
{
@private
	NSDate *_begin; /*!< @brief Begin. */
	NSDate *_end; /*!< @brief End. */

	NSString *timeString; /*!< @brief Cache for Begin/End Textual representation. */

	CXMLNode *_node; /*!< @brief CXMLNode describing this Event. */
}

/*!
 @brief Standard initializer.
 
 @param CXMLNode Pointer to CXMLNode describing this Event.
 @return EnigmaEvent instance.
 */
- (id)initWithNode: (CXMLNode *)node;

@end
