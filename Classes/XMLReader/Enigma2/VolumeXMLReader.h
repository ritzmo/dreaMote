//
//  VolumeXMLReader.h
//  dreaMote
//
//  Created by Moritz Venn on 31.12.08.
//  Copyright 2008-2010 Moritz Venn. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "BaseXMLReader.h"
#import "VolumeSourceDelegate.h"

/*!
 @brief Enigma2 Volume XML Reader.
 */
@interface Enigma2VolumeXMLReader : BaseXMLReader
{
@private
	NSObject<VolumeSourceDelegate> *_delegate; /*!< @brief Delegate. */
}

/*!
 @brief Standard initializer.
 
 @param target Delegate.
 @return Enigma2VolumeXMLReader instance.
 */
- (id)initWithDelegate:(NSObject<VolumeSourceDelegate> *)delegate;


@end
