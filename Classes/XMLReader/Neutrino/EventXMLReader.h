//
//  EventXMLReader.h
//  dreaMote
//
//  Created by Moritz Venn on 31.12.08.
//  Copyright 2008-2012 Moritz Venn. All rights reserved.
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
	NSDate *_getCurrent; /*!< @brief Cached NSDate of "now" if getting current, else -1. */
	NSInteger _currentCounter; /*!< @brief How many events are still to be retrieved if getting current? */
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
 @param getCurrent We are actually supposed to fill the "current" view with data.
 @return NeutrinoEventXMLReader instance.
 */
- (id)initWithDelegate:(NSObject<EventSourceDelegate> *)delegate andGetCurrent:(BOOL)getCurrent;
@end
