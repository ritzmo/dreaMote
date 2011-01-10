//
//  Metadata.h
//  dreaMote
//
//  Created by Moritz Venn on 10.01.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "CXMLNode.h"
#import "MetadataProtocol.h"

/*!
 @brief Metadata in Enigma2.
 */
@interface Enigma2Metadata : NSObject<MetadataProtocol>
{
@private
	CXMLNode *_node; /*!< @brief CXMLNode describing this Metadata information. */
}

/*!
 @brief Standard initializer.
 
 @param node Pointer to CXMLNode describing this Metadata.
 @return Enigma2Metadata instance.
 */
- (id)initWithNode: (CXMLNode *)node;

@end
