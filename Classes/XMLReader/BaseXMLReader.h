//
//  BaseXMLReader.h
//  dreaMote
//
//  Created by Moritz Venn on 31.12.08.
//  Copyright 2008-2011 Moritz Venn. All rights reserved.
//

#import <Delegates/DataSourceDelegate.h>

/*!
 @brief Protocol used to guarantee that XML readers implement common functionality.
 */
@protocol XMLReader
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
 @brief Basic XML Reader Class.

 Download a website and read it in as XML.
 Stores contents in a CXMLDocument.
 */
@interface BaseXMLReader : NSObject <XMLReader>
{
@protected
	BOOL _done; /*!< @brief Finished parsing? */
	NSObject<DataSourceDelegate> *_delegate; /*!< @brief Delegate. */
	NSTimeInterval _timeout; /*!< @brief Timeout for requests. */
}

/*!
 @brief Download and parse XML document.
 
 @param URL URL to download.
 @param error Will be pointed to NSError if one occurs.
 @return Parsed XML Document.
 */
- (void)parseXMLFileAtURL: (NSURL *)URL parseError: (NSError **)error;

/*!
 @brief Delegate.
 */
@property (nonatomic, strong) NSObject<DataSourceDelegate> *delegate;

/*!
 @brief Expected encoding of document.
 */
@property (nonatomic) NSStringEncoding encoding;

@end
