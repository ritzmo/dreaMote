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
 @brief Enigma2 getcurrent XML Reader.
 */
@interface Enigma2CurrentXMLReader : SaxXmlReader

/*!
 @brief Standard initializer.
 
 @param target Delegate.
 @return Enigma2CurrentXMLReader instance.
 */
- (id)initWithDelegate:(NSObject<EventSourceDelegate, ServiceSourceDelegate> *)delegate;

@end
