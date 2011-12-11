//
//  SignalXMLReader.h
//  dreaMote
//
//  Created by Moritz Venn on 15.06.09.
//  Copyright 2009-2011 Moritz Venn. All rights reserved.
//

#import <XMLReader/SaxXmlReader.h>

#import <Delegates/SignalSourceDelegate.h>

/*!
 @brief Enigma Signal XML Reader.
 */
@interface EnigmaSignalXMLReader : SaxXmlReader

/*!
 @brief Standard initializer.
 
 @param target Delegate.
 @return EnigmaSignalXMLReader instance.
 */
- (id)initWithDelegate:(NSObject<SignalSourceDelegate> *)delegate;

@end
