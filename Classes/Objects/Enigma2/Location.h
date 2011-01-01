//
//  Location.h
//  dreaMote
//
//  Created by Moritz Venn on 01.01.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "CXMLNode.h"

#import "LocationProtocol.h"

/*!
 @brief Location in Enigma2.
 */
@interface Enigma2Location : NSObject <LocationProtocol>
{
@private
	CXMLNode *_node; /*!< @brief CXMLNode describing this Location. */
}


/*!
 @brief Standard initializer.
 
 @param node Pointer to CXMLNode describing this Location.
 @return Enigma2Location instance.
 */
- (id)initWithNode: (CXMLNode *)node;

@end
