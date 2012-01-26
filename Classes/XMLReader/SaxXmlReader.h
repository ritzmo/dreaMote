//
//  SaxXmlReader.h
//  dreaMote
//
//  Created by Moritz Venn on 15.01.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

#import <SynchronousRequestReader.h>

#import <Delegates/DataSourceDelegate.h>

#import <libxml/tree.h>

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
 @brief Protocol used to guarantee that XML readers implement common functionality.
 */
@protocol XmlReader
/*!
 @brief The XML Document could not be loaded.
 Should be overriden by children to send an erroneous object to the delegate.
 @param error The connection error.
 */
- (void)errorLoadingDocument:(NSError *)error;

/*!
 @brief Finished parsing current document.
 */
- (void)finishedParsingDocument;
@end

/*!
 @brief SAX XML Reader.

 Download a website and read it in as XML.
 */
@interface SaxXmlReader : SynchronousRequestReader <StreamingReader, XmlReader>
{
@private
	xmlParserCtxtPtr _xmlParserContext; /*!< @brief Parser context of libxml2. */
@protected
	NSObject<DataSourceDelegate> *_delegate; /*!< @brief Delegate. */
	NSTimeInterval _timeout; /*!< @brief Timeout for requests. */
	NSMutableString *currentString; /*!< @brief String that is currently being completed. */
	NSMutableArray *currentItems; /*!< @brief Items waiting to be dispatched to the main thread. */
}

/*!
 @brief Download and parse XML document.

 @param URL URL to download.
 @param error Will be pointed to NSError if one occurs.
 @return Parsed XML Document.
 */
- (BOOL)parseXMLFileAtURL: (NSURL *)URL parseError: (NSError **)error;

/*!
 @brief Currently received string.
 */
@property (nonatomic, strong) NSMutableString *currentString;

/*!
 @brief Array of objects to dispatch.
 For performance reasons sometimes we dispatch multiple items at once.
 This array can be used to store the items beforehand.
 */
@property (nonatomic, strong) NSMutableArray *currentItems;


/*!
 @brief Delegate.
 */
@property (nonatomic, strong) NSObject<DataSourceDelegate> *delegate;

/*!
 @brief Expected encoding of document.
 */
@property (nonatomic) NSStringEncoding encoding;

@end