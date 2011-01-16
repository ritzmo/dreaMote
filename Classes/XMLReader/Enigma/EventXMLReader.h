//
//  EventXMLReader.h
//  dreaMote
//
//  Created by Moritz Venn on 31.12.08.
//  Copyright 2008-2011 Moritz Venn. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "SaxXmlReader.h"
#import "EventSourceDelegate.h"

/*!
 @brief Enigma Event XML Reader.
 */
@interface EnigmaEventXMLReader : SaxXmlReader
{
@private
	NSObject<EventProtocol> *currentEvent; /*!< @brief Current Event. */
}

/*!
 @brief Standard initializer.

 @param target Delegate.
 @return EnigmaEventXMLReader instance.
 */
- (id)initWithDelegate:(NSObject<EventSourceDelegate> *)delegate;

@end
