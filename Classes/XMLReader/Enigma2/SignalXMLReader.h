//
//  SignalXMLReader.h
//  dreaMote
//
//  Created by Moritz Venn on 08.06.09.
//  Copyright 2009-2011 Moritz Venn. All rights reserved.
//

#import "SaxXmlReader.h"

#import <Delegates/SignalSourceDelegate.h>

/*!
 @brief Enigma2 Signal XML Reader.
 */
@interface Enigma2SignalXMLReader : SaxXmlReader
{
}

/*!
 @brief Standard initializer.
 
 @param target Delegate.
 @return Enigma2SignalXMLReader instance.
 */
- (id)initWithDelegate:(NSObject<SignalSourceDelegate> *)delegate;

@end
