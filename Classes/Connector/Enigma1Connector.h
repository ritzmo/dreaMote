//
//  Enigma1Connector.h
//  dreaMote
//
//  Created by Moritz Venn on 08.03.08.
//  Copyright 2008-2011 Moritz Venn. All rights reserved.
//


#import <UIKit/UIKit.h>

#import "RemoteConnector.h"

#import <CXMLDocument.h>

typedef enum
{
	CACHE_TYPE_TV = 0 << 0,
	CACHE_TYPE_RADIO = 1 << 0,
	CACHE_MASK_BOUQUET = 0 << 1,
	CACHE_MASK_PROVIDER = 1 << 1,
} cacheType;

/*!
 @brief Connector for Enigma based STBs.
 */
@interface Enigma1Connector : NSObject <RemoteConnector> {
@private
	NSURL *_baseAddress; /*!< @brief Base URL of STB */
	NSLock *_bouquetsCacheLock; /*!< @brief Lock for _cachedBouquetsXML. */

	/*!
	 @brief Cached Bouquet XML.

	 For performance Reasons the Service list is only fetched once when entering
	 the Bouquet list so we have to cache this (already parsed) XML in memory.
	*/
	CXMLDocument *_cachedBouquetsXML;
	cacheType _cacheType;
}

@end
