//
//  SignalXMLReader.h
//  dreaMote
//
//  Created by Moritz Venn on 15.06.09.
//  Copyright 2009-2011 Moritz Venn. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "BaseXMLReader.h"
#import "SignalSourceDelegate.h"

/*!
 @brief Enigma Signal XML Reader.
 */
@interface EnigmaSignalXMLReader : BaseXMLReader
{
}

/*!
 @brief Standard initializer.
 
 @param target Delegate.
 @return EnigmaSignalXMLReader instance.
 */
- (id)initWithDelegate:(NSObject<SignalSourceDelegate> *)delegate;

@end
