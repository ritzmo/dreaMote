//
//  FileXMLReader.h
//  dreaMote
//
//  Created by Moritz Venn on 05.01.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "SaxXmlReader.h"
#import "FileSourceDelegate.h"

/*!
 @brief Enigma2 File XML Reader.
 */
@interface Enigma2FileXMLReader : SaxXmlReader
{
@private
	NSObject<FileProtocol> *currentFile; /*!< @brief Current File. */
}

/*!
 @brief Standard initializer.

 @param target Delegate.
 @return Enigma2FileXMLReader instance.
 */
- (id)initWithDelegate:(NSObject<FileSourceDelegate> *)delegate;

@end
