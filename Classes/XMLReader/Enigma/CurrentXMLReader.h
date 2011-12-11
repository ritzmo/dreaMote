//
//  CurrentXMLReader.h
//  dreaMote
//
//  Created by Moritz Venn on 26.10.09.
//  Copyright 2009-2011 Moritz Venn. All rights reserved.
//

#import <XMLReader/SaxXmlReader.h>

#import <Delegates/EventSourceDelegate.h>
#import <Delegates/ServiceSourceDelegate.h>

/*!
 @brief Enigma currentservicedata XML Reader.
 */
@interface EnigmaCurrentXMLReader : SaxXmlReader

/*!
 @brief Standard initializer.
 
 @param target Delegate.
 @return EnigmaCurrentXMLReader instance.
 */
- (id)initWithDelegate:(NSObject<EventSourceDelegate, ServiceSourceDelegate> *)delegate;

@end
