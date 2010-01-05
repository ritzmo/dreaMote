//
//  Bouquet.h
//  dreaMote
//
//  Created by Moritz Venn on 01.01.09.
//  Copyright 2008-2010 Moritz Venn. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CXMLElement;

#import "ServiceProtocol.h"

/*!
 @brief Bouquet in Neutrino.

 @note Neutrino uses the Generic Service for normal Services.
 */
@interface NeutrinoBouquet : NSObject <ServiceProtocol>
{
@private
	CXMLElement *_node; /*!< @brief CXMLNode describing this Bouquet. */
}

/*!
 @brief Standard initializer.
 
 @param node Pointer to CXMLNode describing this Bouquet.
 @return NeutrinoBouquet instance.
 */
- (id)initWithNode: (CXMLElement *)node;

@end
