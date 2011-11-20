//
//  TagXMLReader.h
//  dreaMote
//
//  Created by Moritz Venn on 20.11.11.
//  Copyright (c) 2011 Moritz Venn. All rights reserved.
//

#import "SaxXmlReader.h"

#import <Delegates/TagSourceDelegate.h>

@interface Enigma2TagXMLReader : SaxXmlReader
/*!
 @brief Standard initializer.

 @param target Delegate.
 @return Enigma2TagXMLReader instance.
 */
- (id)initWithDelegate:(NSObject<TagSourceDelegate> *)delegate;
@end
