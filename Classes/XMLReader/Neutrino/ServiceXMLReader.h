//
//  ServiceXMLReader.h
//  dreaMote
//
//  Created by Moritz Venn on 13.03.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "SaxXmlReader.h"
#import "ServiceSourceDelegate.h"

/*!
 @brief Neutrino Service XML Reader.
 */
@interface NeutrinoServiceXMLReader : SaxXmlReader
{
@private
	NSObject<ServiceProtocol> *currentService; /*!< @brief Current Service. */
}

/*!
 @brief Standard initializer.

 @param target Delegate.
 @return NeutrinoServiceXMLReader instance.
 */
- (id)initWithDelegate:(NSObject<ServiceSourceDelegate> *)delegate;

@end
