//
//  BaseXMLReader.h
//  dreaMote
//
//  Created by Moritz Venn on 31.12.08.
//  Copyright 2008-2011 Moritz Venn. All rights reserved.
//

#ifdef LAME_ASYNCHRONOUS_DOWNLOAD
#import <XMLReader/CXMLPushDocument.h>
typedef CXMLPushDocument OurXMLDocument;
#else
#import <CXMLDocument.h>
typedef CXMLDocument OurXMLDocument;
#endif
#import <CXMLElement.h>

#import <Connector/RemoteConnector.h>

#import <Delegates/DataSourceDelegate.h>

/*!
 @brief Protocol used to guarantee that XML readers implement common functionality.
 */
@protocol XMLReader
/*!
 @brief Send fake object back to delegate to indicate a failure
 */
- (void)sendErroneousObject;
@end

/*!
 @brief Basic XML Reader Class.

 Download a website and read it in as XML.
 Stores contents in a CXMLDocument.
 */
@interface BaseXMLReader : NSObject <XMLReader>
{
@protected
	BOOL _done; /*!< @brief Finished parsing? */
	NSObject<DataSourceDelegate> *_delegate; /*!< @brief Delegate. */
	OurXMLDocument *document; /*!< @brief CXMLDocument. */
	NSTimeInterval _timeout; /*!< @brief Timeout for requests. */
}

/*!
 @brief Download and parse XML document.
 
 @param URL URL to download.
 @param error Will be pointed to NSError if one occurs.
 @return Parsed XML Document.
 */
- (CXMLDocument *)parseXMLFileAtURL: (NSURL *)URL parseError: (NSError **)error;

/*!
 @brief If using TouchXML to parse XML, this is the pointer to the document.
 */
@property (nonatomic, readonly) CXMLDocument *document;

/*!
 @brief Expected encoding of document.
 */
@property (nonatomic) NSStringEncoding encoding;

@end
