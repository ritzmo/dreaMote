//
//  LocationXMLReader.h
//  dreaMote
//
//  Created by Moritz Venn on 01.01.11.
//  Copyright 2011-2012 Moritz Venn. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <XMLReader/SaxXmlReader.h>
#import <Delegates/LocationSourceDelegate.h>

/*!
 @brief Enigma2 Location XML Reader.
 */
@interface Enigma2LocationXMLReader : SaxXmlReader

/*!
 @brief Standard initializer.
 
 @param target Delegate.
 @return EnigmaLocationXMLReader instance.
 */
- (id)initWithDelegate:(NSObject<LocationSourceDelegate> *)delegate;

@end
