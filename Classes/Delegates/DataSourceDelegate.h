//
//  DataSourceDelegate.h
//  dreaMote
//
//  Created by Moritz Venn on 16.01.11.
//  Copyright 2011 Moritz Venn. All rights reserved.
//

@class SaxXmlReader;
@class CXMLDocument;

/*!
 @brief DataSourceDelegate.

 Objects wanting to be called back by a Data Source, you need to implement
 this Protocol. All other SourceDelegates inherit this protocol.
 */
@protocol DataSourceDelegate <NSObject>

/*!
 @brief Document was parsed successfully.

 @param dataSource Source that triggered this action.
*/
- (void)dataSourceDelegateFinishedParsingDocument:(SaxXmlReader *)dataSource;

/*!
 @brief Failed to parse Document.

 @param dataSource Source that triggered this action.
 @param error Error which occured.
*/
- (void)dataSourceDelegate:(SaxXmlReader *)dataSource errorParsingDocument:(NSError *)error;

@end