//
//  VolumeXMLReader.h
//  dreaMote
//
//  Created by Moritz Venn on 31.12.08.
//  Copyright 2008-2011 Moritz Venn. All rights reserved.
//

#import "SaxXmlReader.h"

#import <Delegates/VolumeSourceDelegate.h>

/*!
 @brief Enigma2 Volume XML Reader.
 */
@interface Enigma2VolumeXMLReader : SaxXmlReader

/*!
 @brief Standard initializer.
 
 @param target Delegate.
 @return Enigma2VolumeXMLReader instance.
 */
- (id)initWithDelegate:(NSObject<VolumeSourceDelegate> *)delegate;


@end
