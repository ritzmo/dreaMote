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
#import "NowNextSourceDelegate.h"

/*!
 @brief Enigma2 Event XML Reader.
 This XMLReader is implemented as streaming parser based on the SAX interface
 of libxml2.
 */
@interface Enigma2EventXMLReader : SaxXmlReader
{
@private
	BOOL _getServices; /*!< @brief Add service object. */
	SEL _delegateSelector; /*!< @brief Selector to perform on delegate. */
}

/*!
 @brief Standard initializer.

 @param target Delegate.
 @return Enigma2EventXMLReader instance.
 */
- (id)initWithDelegate:(NSObject<EventSourceDelegate> *)delegate;

/*!
 @brief Initializer with explicit value for getServices.

 @param target Delegate.
 @param getServices Value of _getServices to use.
 @return Enigma2EventXMLReader instance.
 */
- (id)initWithDelegateAndGetServices:(NSObject<EventSourceDelegate> *)delegate getServices:(BOOL)getServices;

/*!
 @brief Standard initializer.

 @param target Delegate.
 @return Enigma2EventXMLReader instance.
 */
- (id)initWithNowNextDelegate:(NSObject<NowSourceDelegate, NextSourceDelegate> *)delegate;

/*!
 @brief Standard initializer.

 @param target Delegate.
 @return Enigma2EventXMLReader instance.
 */
- (id)initWithNowDelegate:(NSObject<NowSourceDelegate> *)delegate;

/*!
 @brief Standard initializer.

 @param target Delegate.
 @return Enigma2EventXMLReader instance.
 */
- (id)initWithNextDelegate:(NSObject<NextSourceDelegate> *)delegate;

@end
