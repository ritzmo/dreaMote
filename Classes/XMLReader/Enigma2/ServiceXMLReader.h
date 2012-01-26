//
//  ServiceXMLReader.h
//  dreaMote
//
//  Created by Moritz Venn on 31.12.08.
//  Copyright 2008-2012 Moritz Venn. All rights reserved.
//

#import <XMLReader/SaxXmlReader.h>

#import <Delegates/ServiceSourceDelegate.h>

/*!
 @brief Enigma2 Service XML Reader.
 */
@interface Enigma2ServiceXMLReader : SaxXmlReader

/*!
 @brief Standard initializer.

 @param target Delegate.
 @return Enigma2ServiceXMLReader instance.
 */
- (id)initWithDelegate:(NSObject<ServiceSourceDelegate> *)delegate;

/*!
 @brief Standard initializer.

 @param target Delegate.
 @param atOnce Only send a single message to the main thread.
 @return Enigma2ServiceXMLReader instance.
 */
- (id)initWithDelegate:(NSObject<ServiceSourceDelegate> *)delegate atOnce:(BOOL)atOnce;

@end
