//
//  EPGRefreshSettingsXMLReader.h
//  dreaMote
//
//  Created by Moritz Venn on 15.04.11..
//  Copyright 2011-2012 Moritz Venn. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "SaxXmlReader.h"
#import "EPGRefreshSettingsSourceDelegate.h"

/*!
 @brief Enigma2 EPGRefresh Settings XML Reader.
 This XMLReader is implemented as streaming parser based on the SAX interface
 of libxml2.
 */
@interface Enigma2EPGRefreshSettingsXMLReader : SaxXmlReader
{
@private
	NSString *lastSettingName; /*!< @brief Name of last settings. */
	EPGRefreshSettings *settings; /*!< @brief Settings. */
}

/*!
 @brief Standard initializer.

 @param target Delegate.
 @return Enigma2EPGRefreshSettingsXMLReader instance.
 */
- (id)initWithDelegate:(NSObject<EPGRefreshSettingsSourceDelegate> *)delegate;

@end
