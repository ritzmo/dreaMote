//
//  SaxXmlReader.h
//  dreaMote
//
//  Created by Moritz Venn on 15.01.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <libxml/tree.h>

// needed for interface and some variables
#import "BaseXMLReader.h"

typedef struct
{
	const xmlChar* localname;
	const xmlChar* prefix;
	const xmlChar* uri;
	const xmlChar* value;
	const xmlChar* end;
} xmlSAX2Attributes;

/*!
 @brief SAX XML Reader.
 */
@interface SaxXmlReader : BaseXMLReader
{
@private
	xmlParserCtxtPtr _xmlParserContext;
@protected
	NSMutableString *currentString;
}

- (void)elementFound:(const xmlChar *)localname prefix:(const xmlChar *)prefix uri:(const xmlChar *)URI namespaceCount:(int)namespaceCount namespaces:(const xmlChar **)namespaces attributeCount:(int)attributeCount defaultAttributeCount:(int)defaultAttributeCount attributes:(xmlSAX2Attributes *)attributes;
- (void)endElement:(const xmlChar *)localname prefix:(const xmlChar *)prefix uri:(const xmlChar *)URI;
- (void)sendErroneousObject;
- (void)sendTerminatingObject;

@property (nonatomic, retain) NSMutableString *currentString;

@end
