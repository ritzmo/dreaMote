//
//  CurrentXMLReader.h
//  dreaMote
//
//  Created by Moritz Venn on 26.10.09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "BaseXMLReader.h"
#import "EventSourceDelegate.h"
#import "ServiceSourceDelegate.h"

/*!
 @brief Enigma currentservicedata XML Reader.
 */
@interface EnigmaCurrentXMLReader : BaseXMLReader
{
@private
	NSObject<EventSourceDelegate, ServiceSourceDelegate> *_delegate; /*!< @brief Delegate. */
}

/*!
 @brief Standard initializer.
 
 @param target Delegate.
 @return EnigmaCurrentXMLReader instance.
 */
- (id)initWithDelegate:(NSObject<EventSourceDelegate, ServiceSourceDelegate> *)delegate;

@end
