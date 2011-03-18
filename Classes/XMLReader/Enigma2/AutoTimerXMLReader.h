//
//  AutoTimerXMLReader.h
//  dreaMote
//
//  Created by Moritz Venn on 17.03.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "SaxXmlReader.h"

#import "../../Objects/Generic/Service.h"

@class AutoTimer;
@protocol AutoTimerSourceDelegate;

typedef enum
{
	autoTimerWhereInvalid,
	autoTimerWhereTitle,
	autoTimerWhereShortdescription,
	autoTimerWhereDescription,
	autoTimerWhereDayOfWeek,
} autoTimerWhereType;

/*!
 @brief Enigma2 AutoTimer XML Reader.
 This XMLReader is implemented as streaming parser based on the SAX interface
 of libxml2.
 */
@interface Enigma2AutoTimerXMLReader : SaxXmlReader
{
@private
	autoTimerWhereType autoTimerWhere; /*!< @brief Current Include/Exclude where-Attribute. */
	AutoTimer *currentAT; /*!< @brief Current AutoTimer. */
	NSObject<ServiceProtocol> *currentService; /*!< @brief Current Service/Bouquet. */
}

/*!
 @brief Standard initializer.

 @param target Delegate.
 @return Enigma2AutoTimerXMLReader instance.
 */
- (id)initWithDelegate:(NSObject<AutoTimerSourceDelegate> *)delegate;

@end
