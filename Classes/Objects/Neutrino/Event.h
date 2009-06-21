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
 @brief Event in Neutrino.
 */
@interface NeutrinoEvent : NSObject <EventProtocol>
{
@private
	NSString *timeString; /*!< @brief Cache for Begin/End Textual representation. */

	CXMLNode *_node; /*!< @brief CXMLNode describing this Event. */
}

/*!
 @brief Standard initializer.
 
 @param node Pointer to CXMLNode describing this Event.
 @return NeutrinoEvent instance.
 */
- (id)initWithNode: (CXMLNode *)node;

@end
