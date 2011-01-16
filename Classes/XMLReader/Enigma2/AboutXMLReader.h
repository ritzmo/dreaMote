//
//  AboutXMLReader.h
//  dreaMote
//
//  Created by Moritz Venn on 08.01.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "BaseXMLReader.h"
#import "AboutSourceDelegate.h"

/*!
 @brief Enigma2 About XML Reader.
 */
@interface Enigma2AboutXMLReader : BaseXMLReader
{
}

/*!
 @brief Standard initializer.
 
 @param target Delegate.
 @return EnigmaAboutXMLReader instance.
 */
- (id)initWithDelegate:(NSObject<AboutSourceDelegate> *)delegate;

@end
