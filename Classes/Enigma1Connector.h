//
//  Enigma1Connector.h
//  dreaMote
//
//  Created by Moritz Venn on 08.03.08.
//  Copyright 2008-2010 Moritz Venn. All rights reserved.
//


#import <UIKit/UIKit.h>

#import "RemoteConnector.h"

#import "CXMLDocument.h"

/*!
 @brief Connector for Enigma based STBs.
 */
@interface Enigma1Connector : NSObject <RemoteConnector> {
@private
	NSURL *_baseAddress; /*!< @brief Base URL of STB */

	/*!
	 @brief Cached Bouquet XML.

	 For performance Reasons the Service list is only fetched once when entering
	 the Bouquet list so we have to cache this (already parsed) XML in memory.
	*/
	CXMLDocument *_cachedBouquetsXML;
}

@end
