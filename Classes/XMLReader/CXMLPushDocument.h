//
//  CXMLPushDocument.h
//  dreaMote
//
//  Created by Moritz Venn on 31.12.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#ifdef LAME_ASYNCHRONOUS_DOWNLOAD

#import "CXMLDocument.h"

#include <libxml/parser.h>
#include <libxml/tree.h>

#ifndef LIBXML_PUSH_ENABLED
#error libxml2 not compiled with push support 
#endif

@class CXMLElement;

/*!
 @brief Modifies CXMLDocument to support libxml2 push mode.
 */
@interface CXMLPushDocument : CXMLDocument {
@private
	NSError **_parseError; /*!< @brief Pointer to error. */
	xmlParserCtxtPtr _ctxt; /*!< @brief libxml2 parser context */
}

/*!
 @brief Standard initializer.
 
 @param outError Will be pointed to error if one occurs.
 */
- (id)initWithError: (NSError **)outError;

/*!
 @brief Parse a chunk of data.
 
 @param chunk Chunk of data.
 */
- (void)parseChunk: (NSData *)chunk;

/*!
 @brief Abort parsing.
 
 @note Will be called by creator when we should prematurely end parsing.
 */
- (void)abortParsing;

/*!
 @brief Finish parsing.
 
 @note Will be called by creator when no more data units should be parsed.
 */
- (void)doneParsing;



/*!
 @brief Successfully parsed Document?
 */
@property (readonly) BOOL success;

@end

#endif
