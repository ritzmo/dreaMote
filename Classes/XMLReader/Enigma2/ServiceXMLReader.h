//
//  ServiceXMLReader.h
//  dreaMote
//
//  Created by Moritz Venn on 31.12.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "BaseXMLReader.h"
#import "ServiceSourceDelegate.h"

/*!
 @brief Enigma2 Service XML Reader.
 */
@interface Enigma2ServiceXMLReader : BaseXMLReader
{
@private
	NSObject<ServiceSourceDelegate> *_delegate; /*!< @brief Delegate. */
}

/*!
 @brief Standard initializer.
 
 @param target Delegate.
 @return Enigma2ServiceXMLReader instance.
 */
- (id)initWithDelegate:(NSObject<ServiceSourceDelegate> *)delegate;

@end
