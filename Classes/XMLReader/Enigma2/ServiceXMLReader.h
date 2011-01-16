//
//  ServiceXMLReader.h
//  dreaMote
//
//  Created by Moritz Venn on 31.12.08.
//  Copyright 2008-2011 Moritz Venn. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "SaxXmlReader.h"
#import "ServiceSourceDelegate.h"

/*!
 @brief Enigma2 Service XML Reader.
 */
@interface Enigma2ServiceXMLReader : SaxXmlReader
{
@private
	NSObject<ServiceSourceDelegate> *_delegate; /*!< @brief Delegate. */
	NSObject<ServiceProtocol> *currentService; /*!< @brief Current Service. */
}

/*!
 @brief Standard initializer.

 @param target Delegate.
 @return Enigma2ServiceXMLReader instance.
 */
- (id)initWithDelegate:(NSObject<ServiceSourceDelegate> *)delegate;

@end
