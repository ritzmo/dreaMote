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

@interface CXMLPushDocument : CXMLDocument {
@private
	NSError **_parseError;
	xmlParserCtxtPtr _ctxt;
	BOOL success;
}

- (id)initWithError: (NSError **)outError;
- (void)parseChunk: (NSData *)chunk;
- (void)abortParsing;
- (NSError *)doneParsing;

@property (readonly) BOOL success;

@end

#endif
