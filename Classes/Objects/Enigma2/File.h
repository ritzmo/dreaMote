//
//  File.h
//  dreaMote
//
//  Created by Moritz Venn on 05.01.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CXMLNode;

#import "FileProtocol.h"

/*!
 @brief File in Enigma2.
 */
@interface Enigma2File : NSObject <FileProtocol>
{
@private
	CXMLNode *_node; /*!< @brief CXMLNode describing this File. */
}

/*!
 @brief Standard initializer.
 
 @param node Pointer to CXMLNode describing this Event.
 @return Enigma2File instance.
 */
- (id)initWithNode: (CXMLNode *)node;

@end
