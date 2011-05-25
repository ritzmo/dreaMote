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
 @brief Neutrino Event XML Reader.
 */
@interface NeutrinoEventXMLReader : SaxXmlReader
{
@private
	BOOL _getServices; /*!< @brief Get Services? */
	NSObject<EventProtocol> *currentEvent; /*!< @brief Current Event. */
	NSObject<ServiceProtocol> *currentService; /*!< @brief Current Service. */
}

/*!
 @brief Standard initializer.
 
 @param target Delegate.
 @return NeutrinoEventXMLReader instance.
 */
- (id)initWithDelegate:(NSObject<EventSourceDelegate> *)delegate;

/*!
 @brief Extended initializer.
 Allows to toggle retrieval of service(s).

 @param target Delegate.
 @param getServices Are we supposed to retrieve the service?
 @return NeutrinoEventXMLReader instance.
 */
- (id)initWithDelegate:(NSObject<EventSourceDelegate> *)delegate andGetServices:(BOOL)getServices;
@end
