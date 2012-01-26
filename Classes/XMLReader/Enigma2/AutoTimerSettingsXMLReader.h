//
//  AutoTimerSettingsXMLReader.h
//  dreaMote
//
//  Created by Moritz Venn on 02.12.11.
//  Copyright 2011-2012 Moritz Venn. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "SaxXmlReader.h"
#import "AutoTimerSettingsSourceDelegate.h"

/*!
 @brief Enigma2 AutoTimer Settings XML Reader.
 This XMLReader is implemented as streaming parser based on the SAX interface
 of libxml2.
 */
@interface Enigma2AutoTimerSettingsXMLReader : SaxXmlReader
{
@private
	NSString *lastSettingName; /*!< @brief Name of last settings. */
	AutoTimerSettings *settings; /*!< @brief Settings. */
}

/*!
 @brief Standard initializer.

 @param target Delegate.
 @return Enigma2AutoTimerSettingsXMLReader instance.
 */
- (id)initWithDelegate:(NSObject<AutoTimerSettingsSourceDelegate> *)delegate;

@end
