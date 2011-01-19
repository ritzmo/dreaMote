//
//  DataSourceDelegate.h
//  dreaMote
//
//  Created by Moritz Venn on 16.01.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

@class BaseXMLReader;
@class CXMLDocument;

/*!
 @brief DataSourceDelegate.

 Objects wanting to be called back by a Data Source, you need to implement
 this Protocol. All other SourceDelegates inherit this protocol.
 */
@protocol DataSourceDelegate <NSObject>

/*!
 @brief Document was parsed successfully.

 @note For SaxXmlReader based readers the document is always nil.

 @param dataSource Source that triggered this action.
 @param document Document that was just parsed.
*/
- (void)dataSourceDelegate:(BaseXMLReader *)dataSource finishedParsingDocument:(CXMLDocument *)document;

/*!
 @brief Failed to parse Document.

 @note For SaxXmlReader based readers the document is always nil.

 @param dataSource Source that triggered this action.
 @param document Document that was just parsed.
 @param error Error which occured.
*/
- (void)dataSourceDelegate:(BaseXMLReader *)dataSource errorParsingDocument:(CXMLDocument *)document error:(NSError *)error;

@end