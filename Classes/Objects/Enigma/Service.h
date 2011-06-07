//
//  Service.h
//  dreaMote
//
//  Created by Moritz Venn on 01.01.09.
//  Copyright 2008-2011 Moritz Venn. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CXMLNode;

#import "ServiceProtocol.h"

/*!
 @brief Service in Enigma.
 */
@interface EnigmaService : NSObject <ServiceProtocol>
{
@private
	CXMLNode *_node; /*!< @brief CXMLNode describing this Service. */
	/* Picons */
	BOOL _calculatedPicon; /*!< @brief Did we try to load the picon before? */
	UIImage *_picon; /*!< @brief Picon. */
}

/*!
 @brief Standard initializer.
 
 @param node Pointer to CXMLNode describing this Service.
 @return EnigmaService instance.
 */
- (id)initWithNode: (CXMLNode *)node;

@end
