//
//  ServiceXMLReader.h
//  dreaMote
//
//  Created by Moritz Venn on 13.03.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import <XMLReader/SaxXmlReader.h>

#import <Delegates/ServiceSourceDelegate.h>

/*!
 @brief Neutrino Service XML Reader.
 */
@interface NeutrinoServiceXMLReader : SaxXmlReader

/*!
 @brief Standard initializer.

 @param target Delegate.
 @return NeutrinoServiceXMLReader instance.
 */
- (id)initWithDelegate:(NSObject<ServiceSourceDelegate> *)delegate;

@end
