//
//  MetadataXMLReader.h
//  dreaMote
//
//  Created by Moritz Venn on 10.01.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "BaseXMLReader.h"
#import "MetadataSourceDelegate.h"

/*!
 @brief Enigma2 Metadata XML Reader.
 */
@interface Enigma2MetadataXMLReader : BaseXMLReader
{
@private
	NSObject<MetadataSourceDelegate> *_delegate; /*!< @brief Delegate. */
}

/*!
 @brief Standard initializer.
 
 @param target Delegate.
 @return EnigmaMetadataXMLReader instance.
 */
- (id)initWithDelegate:(NSObject<MetadataSourceDelegate> *)delegate;

@end
