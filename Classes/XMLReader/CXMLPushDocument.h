//
//  CXMLPushDocument.h
//  dreaMote
//
//  Created by Moritz Venn on 31.12.08.
//  Copyright 2008-2011 Moritz Venn. All rights reserved.
//

#ifdef LAME_ASYNCHRONOUS_DOWNLOAD

#import "CXMLDocument.h"

#include <libxml/parser.h>
#include <libxml/tree.h>

#ifndef LIBXML_PUSH_ENABLED
#error libxml2 not compiled with push support 
#endif

/*!
 @brief Modifies CXMLDocument to support libxml2 push mode.
 */
@interface CXMLPushDocument : CXMLDocument {
@private
	BOOL _done; /*!< @brief Done parsing document. */
	NSError * __unsafe_unretained *_parseError; /*!< @brief Pointer to error. */
	xmlParserCtxtPtr _ctxt; /*!< @brief libxml2 parser context */
}

/*!
 @brief Standard initializer.
 
 @param outError Will be pointed to error if one occurs.
 */
- (id)initWithError: (NSError * __unsafe_unretained *)outError;



/*!
 @brief Finished parsing document?
 */
@property (readonly) BOOL done;

@end

#endif
