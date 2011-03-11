//
//  Service.h
//  dreaMote
//
//  Created by Moritz Venn on 11.03.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CXMLElement;

#import "ServiceProtocol.h"

/*!
 @brief Service in Neutrino.
 */
@interface NeutrinoService : NSObject <ServiceProtocol>
{
@private
	CXMLElement *_node; /*!< @brief CXMLNode describing this Service. */
	NSString *_sref; /*!< @brief Cached service reference. */
	NSString *_sname; /*!< @brief Cached service name. */
}

/*!
 @brief Standard initializer.
 
 @param node Pointer to CXMLNode describing this Service.
 @return NeutrinoService instance.
 */
- (id)initWithNode: (CXMLElement *)node;

@end
