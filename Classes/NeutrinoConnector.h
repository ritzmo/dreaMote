//
//  NeutrinoConnector.h
//  dreaMote
//
//  Created by Moritz Venn on 15.10.08.
//  Copyright 2008-2011 Moritz Venn. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "RemoteConnector.h"

#import "CXMLDocument.h"

/*!
 @brief Connector for Neutrino based STBs.
 */
@interface NeutrinoConnector : NSObject <RemoteConnector> {
@private
	NSURL *_baseAddress; /*!< @brief Base URL of STB */

	/*!
	 @brief Cached Bouquet XML.
	 
	 For performance Reasons the Service list is only fetched once when entering
	 the Bouquet list so we have to cache this (already parsed) XML in memory.
	 We also use this XML when reading the Timer list to associate the Id with a
	 name.
	 */
	CXMLDocument *_cachedBouquetsXML;
}

@end
