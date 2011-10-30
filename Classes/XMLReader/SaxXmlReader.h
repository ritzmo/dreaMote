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
 @brief Protocol for streaming readers
 */
@protocol StreamingReader
/*!
 @brief Element has begun.

 @param localname the local name of the element
 @param prefix the element namespace prefix if available
 @param uri the element namespace name if available
 @param namespaceCount number of namespace definitions on that node
 @param namespaces pointer to the array of prefix/URI pairs namespace definitions
 @param attributeCount the number of attributes on that node
 @param defaultAttributeCount the number of defaulted attributes.
 @param attributes pointer to the array of (localname/prefix/URI/value/end) attribute values.
 */
- (void)elementFound:(const xmlChar *)localname prefix:(const xmlChar *)prefix uri:(const xmlChar *)URI namespaceCount:(int)namespaceCount namespaces:(const xmlChar **)namespaces attributeCount:(int)attributeCount defaultAttributeCount:(int)defaultAttributeCount attributes:(xmlSAX2Attributes *)attributes;

/*!
 @brief Element has ended.

 @param localname the local name of the element
 @param prefix the element namespace prefix if available
 @param uri the element namespace name if available
 */
- (void)endElement:(const xmlChar *)localname prefix:(const xmlChar *)prefix uri:(const xmlChar *)URI;
@end

/*!
 @brief SAX XML Reader.
 */
@interface SaxXmlReader : BaseXMLReader <StreamingReader>
{
@private
	NSError *failureReason; /*!< @brief Reason for parsing failure. */
	xmlParserCtxtPtr _xmlParserContext; /*!< @brief Parser context of libxml2. */
@protected
	NSMutableString *currentString; /*!< @brief String that is currently being completed. */
}

/*!
 @brief Currently received string.
 */
@property (nonatomic, strong) NSMutableString *currentString;

@end
